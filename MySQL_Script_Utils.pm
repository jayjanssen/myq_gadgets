# Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  The copyrights 
# embodied in the content of this file are licensed by Yahoo! Inc.  
# under the BSD (revised) open source license

package MySQL_Script_Utils;

use strict;

use Exporter;
use Getopt::Long qw/ :config no_ignore_case /;

use vars qw/ $DEBUG $HELP $USER $PASS $HOST $PORT %DEFAULT_OPTIONS 
             $PASSWORD_ON @ISA @EXPORT $DEFAULT_OPTIONS_STRING
           /;

@ISA = qw/ Exporter /;
@EXPORT = qw/ $HOST &parse_options &print_debug &mysql_call 
              &format_number &format_percent &format_memory
              $DEFAULT_OPTIONS_STRING
            /;


$DEBUG = 0;
$HELP = 0;
$HOST = '';

die "'mysql' binary not found in your \$PATH\n" if !`which mysql`;

$DEFAULT_OPTIONS_STRING = " [-d] [-?] [-u user [-p [pass]]] [-h host] [-P <port>]";
my %DEFAULT_OPTIONS = (
    'help|?' => \$HELP,
    'debug|d' => \$DEBUG,
    'host|h=s' => \$HOST,
    'P=i' => \$PORT,
    'user|u=s' => \$USER,
    'p:s' => \$PASS,
);

sub print_debug {
    return if( !$DEBUG );

    my( $string ) = @_;
    print STDERR "DEBUG: $string\n";
}

sub format_number {
    my( $num, $sig, $max_len, $debug ) = @_;

    # return 0 if( $num <= 0 );

    my $format = "%." . $sig . "f";

    my $raw_kilo = $num / 1000;
    my $raw_mega = $raw_kilo / 1000;
    my $raw_giga = $raw_mega / 1000;

    my $kilo = sprintf( $format, $raw_kilo );
    my $mega = sprintf( $format, $raw_mega );
    my $giga = sprintf( $format, $raw_giga );
    my $one = sprintf( $format, $num );

    print "$giga, $mega, $kilo, $one\n" if( $debug );

    if( $raw_giga >= 1 ) {
        if( length( $giga ) < $max_len ) {
            return $giga . 'g';
        } else {
            $sig > 0 ? 
                return &format_number( $num, $sig - 1, $max_len, $debug ) :
                return $giga . 'g';
        }
    } elsif( $raw_mega >= 1 ) {
        if( length( $mega ) < $max_len ) {
            return $mega . 'm';
        } else {
            $sig > 0 ? 
                return &format_number( $num, $sig - 1, $max_len, $debug ) :
                return $mega . 'm';
        }
    } elsif( $raw_kilo >= 1 ) {
        if( length( $kilo ) < $max_len ) {
            return $kilo . 'k';
        } else {
            $sig > 0 ? 
                return &format_number( $num, $sig - 1, $max_len, $debug ) :
                return $kilo . 'k';
        }
    } else {
        if( length( $one ) <= $max_len ) {
            return $one;
        } else {
            $sig > 0 ? 
                return &format_number( $num, $sig - 1, $max_len, $debug ) :
                return $one;
        }

    }
}

sub format_percent {
    my( $top, $bottom ) = @_;

    return 0 if( $bottom == 0 );

    my $raw = sprintf( "%.1f", ($top / $bottom) * 100 );

    while( length( $raw ) > 4 ) {
        chop $raw;
    }
    if( $raw =~ m/\.$/ ) {
        chop $raw;
        $raw = ' ' . $raw;
    }

    return "$raw%";
}

sub format_memory {
    my( $num, $sig, $max_len, $debug ) = @_;

    return 0 if( $num <= 0 );

    my $format = "%." . $sig . "f";

    my $raw_kilo = $num / (2**10);
    my $raw_mega = $num / (2**20) ;
    my $raw_giga = $num / (2**30);
    my $raw_tera = $num / (2**40);

    my $kilo = sprintf( $format, $raw_kilo );
    my $mega = sprintf( $format, $raw_mega );
    my $giga = sprintf( $format, $raw_giga );
    my $tera = sprintf( $format, $raw_tera );
    my $one = sprintf( $format, $num );

    print "$tera, $giga, $mega, $kilo, $one\n" if( $debug );

    if( $raw_tera >= 1 ) {
        if( length( $tera ) < $max_len ) {
            return $tera . 'T';
        } else {
            $sig > 0 ?
                return &format_memory( $num, $sig - 1, $max_len, $debug ) :
                return $tera . 'T';
        }
    } elsif( $raw_giga >= 1 ) {
        if( length( $giga ) < $max_len ) {
            return $giga . 'G';
        } else {
            $sig > 0 ?
                return &format_memory( $num, $sig - 1, $max_len, $debug ) :
                return $giga . 'G';
        }
    } elsif( $raw_mega >= 1 ) {
        if( length( $mega ) < $max_len ) {
            return $mega . 'M';
        } else {
            $sig > 0 ?
                return &format_memory( $num, $sig - 1, $max_len, $debug ) :
                return $mega . 'M';
        }
    } elsif( $raw_kilo >= 1 ) {
        if( length( $kilo ) < $max_len ) {
            return $kilo . 'K';
        } else {
            $sig > 0 ?
                return &format_memory( $num, $sig - 1, $max_len, $debug ) :
                return $kilo . 'K';
        }
    } else {
        if( length( $one ) <= $max_len ) {
            return $one;
        } else {
            $sig > 0 ?
                return &format_memory( $num, $sig - 1, $max_len, $debug ) :
                return $one;
        }

    }


}


sub parse_options {
    my( $options ) = @_;
    $PASSWORD_ON = grep( /-p/, @ARGV );

    my $opt_res = GetOptions( (%DEFAULT_OPTIONS, %$options) );

    return 0 if( not $opt_res or $HELP );


    return 1;
}


sub mysql_call {
    my ( $sql, $user, $pass, $host, $port ) = ('', '', '', '', '' );
    ( $sql, $host, $port ) = @_;

    # Prompt for a password the first time we need it, and only if -p was 
    # given on the command line (could be passwordless)
    if( $PASSWORD_ON and $PASS eq '' ) {
        print "Password: ";
        system "stty -echo"; $PASS =<STDIN>;
        system "stty echo";
        $PASS =~ s/\s+$//g; # filter training whitespace
        print "\n";
    }

    if( $host eq '' ) {
        $host = $HOST;
    }
    if( $port eq '' ) {
        $port = $PORT;
    }
    if( $user eq '' ) {
        $user = $USER;
    }
    if( $pass eq '' ) {
        $pass = $PASS;
    }

    my ( $user_str, $pass_str, $host_str, $port_str ) = ('', '', '', '', '' );

    $user_str = ' --user=' . $user if( $user ne '' );
    $pass_str = ' \'--password=' . $pass . '\'' if( $pass ne '' );
    $host_str = ' --host=' . $host if( $host ne '' );
    $port_str = ' --port=' . $port if( $port ne '' );

    &print_debug( "echo \"$sql\" | mysql $user_str $pass_str $host_str $port_str" );
    my @output = `echo "$sql" | mysql $user_str $pass_str $host_str $port_str`;

    my $rc = $? >> 8;
    if( $rc ) {
        die "Error accessing mysql\n";
    }

    return \@output;
}

1;

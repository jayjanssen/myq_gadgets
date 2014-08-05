# Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  The copyrights 
# embodied in the content of this file are licensed by Yahoo! Inc.  
# under the BSD (revised) open source license

package MySQL_Script_Utils;

use strict;
use utf8;

use Exporter;
use Getopt::Long qw/ :config no_ignore_case /;

use vars qw/ $DEBUG $HELP $USER $PASS $HOST $PORT %DEFAULT_OPTIONS 
             $PASSWORD_ON @ISA @EXPORT $DEFAULT_OPTIONS_STRING
           /;

@ISA = qw/ Exporter /;
@EXPORT = qw/ $HOST &parse_options &print_debug &mysql_call 
              &format_number &format_percent &format_memory
							&format_microseconds
              $DEFAULT_OPTIONS_STRING
            /;


$DEBUG = 0;
$HELP = 0;
$HOST = '';

warn "'mysql' binary not found in your \$PATH\n" if !`which mysql`;

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

sub raw_format_number {
  my( $units, $num, $sig, $max_len, $debug ) = @_;
	
	$sig = 0 if( $sig < 0 );
	
	print "Num: $num\n" if $debug;
	
	foreach my $factor( sort keys %$units ) {
		my $raw = $num / $factor;
		
		my $string = sprintf( "%." . $sig . "f%s", $raw, $units->{$factor} );
		print "Trying factor: $factor, $raw => $string\n" if $debug;
		
		if( $raw != 0 and length( $string ) <= $max_len + $sig ) {
			print "\tThese are our units\n" if $debug;
			
			my $left = $max_len - length( $string );
			if( $left < 0 ) {
				print "\tcan we pare down the sig?\n" if $debug;
				# Return a pared down $sig or what we've got (may not fit in $max_len)
				$sig > 0 ?
					return &raw_format_number( $units, $num, $sig - 1, $max_len, $debug ) :
					return $string;
			} elsif( $left > 1 and $factor ne 1 ) {
				print "\tadd some decimal places\n" if $debug;
		
				# Add some decimal places
				my $decimal = $left - 1;
				return sprintf( "%." . $decimal . "f" . $units->{$factor}, $raw );
			} else {
				print "\tas is\n" if $debug;
				
				return $string;
			}
		}
		# Else, try the next smaller factor
	}
	
	# if we get here, we have no factor
	my $string = sprintf( "%." . $sig . "f", $num );
	print "Using $string\n" if $debug;
	
  if( length( $string ) <= $max_len ) {
		return $string;
  } else {
      $sig > 0 ? 
					return &raw_format_number( $units, $num, $sig - 1, $max_len, $debug ) :
          return $string;
  }
}

sub format_number {
		my %units = (
			1 => '',
			1000 => 'k',
			1000000 => 'm',
			1000000000 => 'g'
		);
		
		return &raw_format_number( \%units, @_ );
}

sub format_memory {
	my %units = (
		1 => 'b',
		1024 => 'K',
		1048576 => 'M',
		1073741824 => 'G',
		1099511627776 => 'T'
	);
	
	return &raw_format_number( \%units, @_ );
}

# Takes microsecons
sub format_microseconds {
	my %units = (
		1000000000 => 'ks',
		1000000 => 's',
		1000 => 'ms',
		1 => 'µs',
		
	);
	
	return &raw_format_number( \%units, @_ );
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

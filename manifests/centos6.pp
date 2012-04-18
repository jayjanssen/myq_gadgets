group { "puppet":
  ensure => "present",
}

File { owner => 0, group => 0, mode => 0644 }

file { '/etc/motd':
  content => "Welcome to your Vagrant-built virtual machine!
              Managed by Puppet.\n"
}

yumrepo {
  'rpmforge':
    descr       => "RHEL \$releasever - RPMforge.net -dag",
    enabled     => 0,
    baseurl     => "http://apt.sw.be/redhat/el6/en/\$basearch/rpmforge",
    mirrorlist  => "http://apt.sw.be/redhat/el6/en/mirrors-rpmforge",
    gpgcheck    => 0;
  'rpmforge-extras':
    descr       => "RHEL \$releasever - RPMforge.net -extras",
    enabled     => 0,
    baseurl     => "http://apt.sw.be/redhat/el6/en/\$basearch/extras",
    mirrorlist  => "http://apt.sw.be/redhat/el6/en/mirrors-rpmforge-extras",
    gpgcheck    => 0;
  'rpmforge-testing':
    descr       => "RHEL \$releasever - RPMforge.net -testing",
    enabled     => 0,
    baseurl     => "http://apt.sw.be/redhat/el6/en/\$basearch/testing",
    mirrorlist  => "http://apt.sw.be/redhat/el6/en/mirrors-rpmforge-testing",
    gpgcheck    => 0;
  'percona':
	descr	=> "CentOS \$releasever - Percona",
	enabled => 1,
	baseurl => "http://repo.percona.com/centos/\$releasever/os/\$basearch/",
	gpgcheck => 0;
}


package {
  'telnet': ensure => 'installed';
  'vim-minimal': ensure => 'installed';
  'screen': ensure => 'installed';

  'Percona-Server-server-55': ensure => 'installed',
		require => [ Package['Percona-Server-shared-compat'] ];
  'Percona-Server-client-55': ensure => 'installed';
  'Percona-Server-shared-compat': ensure => 'installed';
  'percona-toolkit': ensure => 'installed';
}

service {
  'mysql': ensure => 'running';
}


class splunk::forwarder {

  case $operatingsystem {

    windows: {
      notify { "Installing SplunkFowarder for $operatingsystem": }
      $package_name = 'UniversalForwarder'
      $file_name = 'splunkforwarder-6.0-182611-x64-release.msi'
      $provider_name = 'windows'
      $source_path = '\\fileserver\Packages\Splunk\splunkforwarder-6.0-182611-x64-release.msi'
      $install_options = ['AGREETOLICENSE=Yes', '/quiet']
      $tps_dirs = [ 'C:\Program Files\SplunkUniversalForwarder\etc\apps\tps_prod_deploymentclient', 'C:\Program Files\SplunkUniversalForwarder\etc\apps\tps_prod_deploymentclient\local']
      $tps_deploymentclient = 'C:\Program Files\SplunkUniversalForwarder\etc\apps\tps_prod_deploymentclient\local\deploymentclient.conf'
      $service_name = 'splunkforwarder'
    }

    centos: {
      notify { "Installing SplunkFowarder for $operatingsystem": }
      $package_name = 'splunkforwarder-6.0-182037.x86_64'
      $file_name = 'splunkforwarder-6.0-182037-linux-2.6-x86_64.rpm'
      $provider_name = 'rpm'
      #$source_path = 'puppet:///modules/splunk/splunkforwarder-6.0-182037-linux-2.6-x86_64.rpm'
      $source_path = "http://fileserver/puppet/splunk/$file_name"
      $install_options = ['AGREETOLICENSE=Yes', '/quiet']
      $tps_dirs = [ '/opt/splunkforwarder/etc/apps/tps_prod_deploymentclient', '/opt/splunkforwarder/etc/apps/tps_prod_deploymentclient/local']
      $tps_deploymentclient = '/opt/splunkforwarder/etc/apps/tps_prod_deploymentclient/local/deploymentclient.conf'
      $service_name = 'splunk'
    }

    ubuntu: {
      notify { "Installing SplunkFowarder for $operatingsystem": }
      $package_name = 'splunkforwarder-6.0-182037-linux-2.6-amd64'
      $file_name = 'splunkforwarder-6.0-182037-linux-2.6-amd64.deb'
      $provider_name = 'dpkg'
      #$source_path = 'puppet:///modules/splunk/splunkforwarder-6.0-182037-linux-2.6-amd64.deb'
      $source_path = "http://fileserver/puppet/splunk/$file_name"
      $install_options = ['AGREETOLICENSE=Yes', '/quiet']
      $tps_dirs = [ '/opt/splunkforwarder/etc/apps/tps_prod_deploymentclient', '/opt/splunkforwarder/etc/apps/tps_prod_deploymentclient/local']
      $tps_deploymentclient = '/opt/splunkforwarder/etc/apps/tps_prod_deploymentclient/local/deploymentclient.conf'
      $service_name = 'splunk'
    }
  }

  if ($operatingsystem =~ /(?i:windows)/) {
    package { $package_name:
      provider => $provider_name,
      source => $source_path,
      ensure => installed,
      install_options => $install_options,
      before => [ File[$tps_dirs], File[$tps_deploymentclient] ],
    }
  }
  elsif ($operatingsystem =~ /(?i:centos|ubuntu)/) {
    package { $package_name:
      provider => $provider_name,
      source => $source_path,
      ensure => installed,
      before => [ File[$tps_dirs], File[$tps_deploymentclient] ],
    }
  }

  service { $service_name:
    ensure => "running",
    enable => true,
    require => Package[$package_name],
  }

  file {
    $tps_dirs:
    ensure => directory;
    $tps_deploymentclient:
    ensure => present,
    content => template("splunk/deploymentclient.erb"),
    notify => Service[$service_name],
    require => Package[$package_name],
  }

  if ($operatingsystem =~ /(?i:centos|ubuntu)/) {
    exec { 'start_splunk':
    path => '/opt/splunkforwarder/bin/',
    command => '/opt/splunkforwarder/bin/splunk start --no-prompt --answer-yes --accept-license; /opt/splunkforwarder/bin/splunk enable boot-start',
    creates => '/etc/init.d/splunk',
    before => Service[$service_name]
    }
  }
}

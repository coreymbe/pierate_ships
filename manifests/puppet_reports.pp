# @summary This class adds the puppet report integration for PE & OSP
#
# @example
#   include pierate_ships::puppet_reports
class pierate_ships::puppet_reports(
  Enum['datadog'] $merchant = $pierate_ships::merchant,
) {

  package {'puppetserver_dogapi':
    ensure   => present,
    name     => 'dogapi',
    provider => 'puppetserver_gem',
  }

  # Account for the differences in Puppet Enterprise and Open Source and Agent
  $agent_node = $facts['agent_only_node']

  if $facts['is_pe'] {
    $ini_setting    = 'pe_ini_setting'
    $ini_subsetting = 'pe_ini_subsetting'
    $service        = 'pe-puppetserver'
  }
  else {
    $ini_setting    = 'ini_setting'
    $ini_subsetting = 'ini_subsetting'
    $service        = 'puppetserver'
  }

  Resource[$ini_subsetting] { "enable ${merchant} reporting":
    ensure               => present,
    path                 => '/etc/puppetlabs/puppet/puppet.conf',
    section              => 'master',
    setting              => 'reports',
    subsetting           => $merchant,
    subsetting_separator => ',',
    notify               => Service[$service],
  }
}

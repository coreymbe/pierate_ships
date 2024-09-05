# @summary This class adds the puppet report integration for PE & OSP
#
# @param [Array[Struct[{'merchant' => String[Enum['datadog']], 'auth_token' => String, 'site' => String,}]]] merchant_fleet
#   The fleet of merchants to ship data to
class pierate_ships::puppet_reports (
  Hash[String, Array] $merchant_fleet = $pierate_ships::merchant_fleet,
) {
  package { 'puppetserver_dogapi':
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

  $merchant_fleet.each |$ship| {
    Resource[$ini_subsetting] { "enable ${ship[0]} reporting":
      ensure               => present,
      path                 => '/etc/puppetlabs/puppet/puppet.conf',
      section              => 'master',
      setting              => 'reports',
      subsetting           => $ship[0],
      subsetting_separator => ',',
      notify               => Service[$service],
    }
  }
}

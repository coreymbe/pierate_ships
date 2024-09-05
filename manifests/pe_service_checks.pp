# @summary This class adds the service check integration for Puppet Enterprise
#
# @param [Array[Struct[{'merchant' => String[Enum['datadog']], 'auth_token' => String, 'site' => String,}]]] merchant_fleet
#   The fleet of merchants to ship data to
# @param [String] check_interval
#   Interval to run the service checks
class pierate_ships::pe_service_checks (
  Hash[String, Array] $merchant_fleet = $pierate_ships::merchant_fleet,
  String $check_interval = '2',
) {
  $merchant_fleet.each |$ship| {
    file { "/etc/puppetlabs/pierate_ships/${ship[0]}/pe_service_checks.rb":
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0755',
      require => File["/etc/puppetlabs/pierate_ships/${ship[0]}"],
      source  => 'puppet:///modules/pierate_ships/pe_service_checks.rb',
    }

    cron { 'pe_service_checks':
      ensure  => present,
      command => "/etc/puppetlabs/pierate_ships/${ship[0]}/pe_service_checks.rb",
      user    => 'pe-puppet',
      minute  => "*/${check_interval}",
      require => File["/etc/puppetlabs/pierate_ships/${ship[0]}/pe_service_checks.rb"],
    }
  }
}

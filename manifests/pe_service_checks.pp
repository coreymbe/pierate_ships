# @summary This class adds the service check integration for Puppet Enterprise
#
# @example
#   include pierate_ships::pe_service_checks
class pierate_ships::pe_service_checks(
  Enum['datadog'] $merchant = $pierate_ships::merchant,
  Optional[String] $check_interval = '2',
){

  file { "/etc/puppetlabs/pierate_ships/${merchant}/pe_service_checks.rb":
    ensure  => file,
    owner   => 'pe-puppet',
    group   => 'pe-puppet',
    mode    => '0755',
    require => File["/etc/puppetlabs/pierate_ships/${merchant}"],
    source  => 'puppet:///modules/pierate_ships/pe_service_checks.rb',
  }

  cron { 'pe_service_checks':
    ensure  => present,
    command => "/etc/puppetlabs/pierate_ships/${merchant}/pe_service_checks.rb",
    user    => 'pe-puppet',
    minute  => "*/${check_interval}",
    require => File["/etc/puppetlabs/pierate_ships/${merchant}/pe_service_checks.rb"],
  }
}

# @summary One stop shop for shipping Puppet data
#
# @example
#   include pierate_ships
#
# @param [String] pe_console
#   The FQDN of the PE Console
# @param [Array[Struct[{'merchant' => String[Enum['datadog']], 'auth_token' => String, 'site' => String,}]]] merchant_fleet
#   The fleet of merchants to ship data to
# @param [Boolean] run_reporting
#   Whether to ship Puppet reports
# @param [Boolean] event_reporting
#   Whether to ship Puppet events
# @param [Boolean] service_checks
#   Whether to ship PE service checks
# @param [Array] event_types
#   The types of events to ship
# @param [Optional[Array]] metric_filters
#   Filters for metrics
class pierate_ships (
  String $auth_token = undef,
  String $pe_console = $settings::report_server,
  Hash[String, Array] $merchant_fleet = undef,
  Boolean $run_reporting = false,
  Boolean $event_reporting = false,
  Boolean $service_checks = false,
  Array $event_types = ['orchestrator','rbac','classifier','pe-console','code-manager'],
  Optional[Array] $metric_filters = undef,
) {
  # Account for the differences in running on Primary Server or Agent Node
  if $facts[pe_server_version] != undef {
    $ini_setting    = 'pe_ini_setting'
    $ini_subsetting = 'pe_ini_subsetting'
    $service        = 'pe-puppetserver'
    $owner          = 'pe-puppet'
    $group          = 'pe-puppet'
  }
  else {
    $ini_setting    = 'ini_setting'
    $ini_subsetting = 'ini_subsetting'
    $service        = 'puppetserver'
    $owner          = 'puppet'
    $group          = 'puppet'
  }

  file { '/etc/puppetlabs/pierate_ships':
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  $merchant_fleet.each |$ship, $dock| {
    # Secure credential data
    $merchant_secrets = {
      'api_key' => $dock[0],
      'api_url' => $dock[1],
    }
    $secrets = Deferred('pierate_ships::secure', [$merchant_secrets])

    file { "/etc/puppetlabs/pierate_ships/${ship}":
      ensure => directory,
      owner  => $owner,
      group  => $group,
    }

    file { "/etc/puppetlabs/pierate_ships/${ship}/settings.yaml":
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0640',
      require => File["/etc/puppetlabs/pierate_ships/${ship}"],
      content => epp('pierate_ships/settings.yaml.epp'),
      notify  => Service[$service],
    }

    file { "/etc/puppetlabs/pierate_ships/${ship}/secrets.yaml":
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0600',
      require => File["/etc/puppetlabs/pierate_ships/${ship}"],
      content => Sensitive(Deferred('inline_epp', [file('pierate_ships/secrets.yaml.epp'), $secrets])),
      notify  => Service[$service],
    }
  }

  if $run_reporting {
    include pierate_ships::puppet_reports
  }
  if $event_reporting {
    include pierate_ships::event_reports
  }
  if $service_checks {
    include pierate_ships::pe_service_checks
  }
}

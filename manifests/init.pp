# @summary One stop shop for shipping Puppet data
#
# @example
#   include pierate_ships
class pierate_ships (
  String $auth_token = undef,
  String $pe_console = $settings::report_server,
  Enum['datadog'] $merchant = undef,
  String $merchant_site = 'https://api.datadoghq.com',
  Boolean $run_reporting = false,
  Boolean $event_reporting = false,
  Boolean $service_checks = false,
  Array $event_types = ['orchestrator','rbac','classifier','pe-console','code-manager'],
  Optional[Array] $metric_filters = undef,
){
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

  file {'/etc/puppetlabs/pierate_ships':
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  # Secure credential data
  $merchant_secrets = {
    'api_key' => $auth_token,
    'api_url' => $merchant_site,
  }
  $secrets = Deferred('pierate_ships::secure', [$merchant_secrets])

  file {"/etc/puppetlabs/pierate_ships/${merchant}":
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { "/etc/puppetlabs/pierate_ships/${merchant}/settings.yaml":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    require => File["/etc/puppetlabs/pierate_ships/${merchant}"],
    content => epp('pierate_ships/settings.yaml.epp'),
    notify  => Service[$service],
  }
  file { "/etc/puppetlabs/pierate_ships/${merchant}/secrets.yaml":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0600',
    require => File["/etc/puppetlabs/pierate_ships/${merchant}"],
    content => Sensitive(Deferred('inline_epp', [file('pierate_ships/secrets.yaml.epp'), $secrets])),
    notify  => Service[$service],
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

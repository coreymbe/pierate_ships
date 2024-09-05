# @summary This class adds the event reporting integration for Puppet Enterprise
#
# @param [Array[Struct[{'merchant' => String[Enum['datadog']], 'auth_token' => String, 'site' => String,}]]] merchant_fleet
#   The fleet of merchants to ship data to
class pierate_ships::event_reports (
  Hash[String, Array] $merchant_fleet = $pierate_ships::merchant_fleet,
) {
  if $pe_event_forwarding::confdir != undef {
    $confdir_base_path = $pe_event_forwarding::confdir
  }
  else {
    $confdir_base_path = pe_event_forwarding::base_path($settings::confdir, undef)
  }

  # Account for the differences in Server and Agent nodes
  $agent_node = $facts['agent_only_node']

  if $agent_node {
    $owner          = 'root'
    $group          = 'root'
  }
  else {
    $owner          = 'pe-puppet'
    $group          = 'pe-puppet'
  }

  package { 'puppet_dogapi':
    ensure   => present,
    name     => 'dogapi',
    provider => 'puppet_gem',
  }

  $merchant_fleet.each |$ship| {
    file { "${confdir_base_path}/pe_event_forwarding/processors.d/${ship[0]}_pe_events.rb":
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0755',
      source  => "puppet:///modules/pierate_ships/${ship[0]}_pe_events.rb",
      require => [
        Class['pe_event_forwarding'],
      ],
    }
  }
}

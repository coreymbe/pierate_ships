# @summary This class adds the event reporting integration for Puppet Enterprise
#
# @example
#   include pierate_ships::event_reports
class pierate_ships::event_reports (
  Enum['datadog'] $merchant = $pierate_ships::merchant,
){
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

  package {'puppet_dogapi':
    ensure   => present,
    name     => 'dogapi',
    provider => 'puppet_gem',
  }

  file { "${confdir_base_path}/pe_event_forwarding/processors.d/${merchant}_pe_events.rb":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    source  => "puppet:///modules/pierate_ships/${merchant}_pe_events.rb",
    require => [
      Class['pe_event_forwarding'],
    ],
  }
}

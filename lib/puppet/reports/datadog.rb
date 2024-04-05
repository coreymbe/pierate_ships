require 'puppet'
require 'time'
require 'yaml'
require 'json'
require 'dogapi'

Puppet::Reports.register_report(:datadog) do
  settings_file = '/etc/puppetlabs/pierate_ships/datadog/settings.yaml'
  secrets_file = '/etc/puppetlabs/pierate_ships/datadog/secrets.yaml'
  settings = YAML.load_file(settings_file)
  secrets = YAML.load_file(secrets_file)
  API_KEY = secrets['api_key']
  API_URL = secrets['api_url']
  PE_CONSOLE = settings['pe_console']

  def sourcetypetime(time, duration = 0)
    parsed_time = time.is_a?(String) ? Time.parse(time) : time
    total = Time.parse((parsed_time + duration).iso8601(3))
    '%10.3f' % total.to_f
  end
  
  def process      
    epoch = sourcetypetime(time, metrics['time']['total'])

    #log_data = logs.each do |data|
    #  data.select { |_k, v| !v.nil? }
    #end

    report = {
      'host' => host,
      'time' => epoch,
      'event' => {
        'cached_catalog_status' =>  cached_catalog_status,
        'catalog_uuid' => catalog_uuid,
        'certname' => host,
        'configuration_version' => configuration_version,
        'corrective_change' => corrective_change,
        'environment' => environment,
        'noop' => noop,
        'noop_pending' => noop_pending,
        'pe_console' => PE_CONSOLE,
        'producer' => Puppet[:certname],
        'puppet_version' => puppet_version,
        'resource_events' => resource_statuses.select { |_k, v| v.events.count > 0 },
        'report_format' => report_format,
        'status' => status,
        'time' => (time + metrics['time']['total']).iso8601(3),
        'transaction_uuid' => transaction_uuid,
      },
    }

    event_status = {
      'failed' => {
        'event_title' => "Puppet failed on #{host}",
        'alert_type' => 'error',
        'event_priority' => 'normal',
      },
      'changed' => {
        'event_title' => "Puppet changed resources on #{host}",
        'alert_type' => 'success',
        'event_priority' => 'normal',
      },
      'unchanged' => {
        'event_title' =>  "Puppet ran on, and left #{host} unchanged",
        'alert_type' => 'success',
        'event_priority' => 'low',
      },
    }
    
    event_data = report.to_json

    dog = Dogapi::Client.new(API_KEY, nil, host, nil, nil, nil, API_URL)
    dog.emit_event(Dogapi::Event.new(event_data,
      msg_title: event_status[status]['event_title'],
      event_type: 'config_management.run',
      event_object: host,
      alert_type: event_status[status]['alert_type'],
      priority: event_status[status]['event_priority'],
      source_type_name: 'puppet'),
      host: @msg_host)

    Puppet.info "Report sent for #{host} to Datadog"
  end
end

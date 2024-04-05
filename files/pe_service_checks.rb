#!/opt/puppetlabs/puppet/bin/ruby
require 'puppet'
require 'json'
require 'dogapi'
require 'yaml'

def post_service_status()
  secrets_file  = '/etc/puppetlabs/pierate_ships/datadog/secrets.yaml'
  secrets       = YAML.load_file(secrets_file)
  api_key       = secrets['api_key']
  api_url       = secrets['api_url']
  server        = Puppet[:certname]

  headers = {'Content-Type'  => 'application/json; charset=utf-8'}
  ssl_options = {ssl_context: { verify_peer: false }}
  client = Puppet.runtime[:http]

  services = {
    '4433' => ['activity-service', 'classifier-service', 'pe-console', 'rbac-service'],
    '8140' => ['server'],
    '8143' => ['orchestrator-service'],
    '8081' => ['puppetdb-status']
  }
  states = {
    'running' => 0,
    'error'   => 2,
    'unknown' => 3
  }
  checks = {}

  services.each do |port, names|
    uri = URI.parse("https://#{server}:#{port}/status/v1/services")
    response = client.get(uri, headers: headers, options: ssl_options)
    status = JSON.parse(response.body)
    names.each do |service|
      if service == 'puppetdb-status'
        checks['puppetdb-service'] = status[service]['state']
      else
        checks[service] = status[service]['state']
      end
    end
  end

  dog = Dogapi::Client.new(api_key, nil, server, nil, nil, nil, api_url)
  checks.each do |service, status|
    dog.service_check("puppet.#{service}", server, states[status])
  end
end

post_service_status()

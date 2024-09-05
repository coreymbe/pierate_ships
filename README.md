# pierate_ships

## Table of Contents

1. [Description](#description)
2. [Setup - Getting started with pierate_ships](#setup)
3. [Usage - Additional configuration options](#usage)

## Description

The idea behind this module is to provide a one-stop shop for shipping Puppet data to different observability platforms.

## Setup

Apply the `pierate_ships` class to the primary Puppet Server node with the following parameters.

> **Note**: This module is under development and currently only supports the Datadog platform.

##### Required Parameters:
  * `$merchant_fleet` - The fleet of merchants to ship data to. This parameter accepts an Array of Structs that include the `merchant`, `auth_token`, and `site` (API URL) for each observability platform.

**Example**:

```
node 'puppet-primary.server.example.com' {
  class { 'pierate_ships':
    merchant_fleet => [{'merchant' => 'datadog', 'auth_token' => 'abcd1234, 'site' => 'https://api.datadoghq.com'}],
  }
}
```

## Usage

With the required parameters provided you can now select which types of data you wish to ship.

> **Note** These parameters accept a boolean value.

##### Additional Parameters:

  * `run_reporting` - Ship puppet report data.
  * `event_reporting` - Ship data collected by the [`pe_event_forwarding` module](https://forge.puppet.com/puppetlabs/pe_event_forwarding). (**Puppet Enterprise**)
  * `service_checks` - Ship service check data collected by this module. (**Puppet Enterprise**)

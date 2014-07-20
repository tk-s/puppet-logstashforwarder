# == Define: logstashforwarder::service::init
#
# This class exists to coordinate all service management related actions,
# functionality and logical units in a central place.
#
# <b>Note:</b> "service" is the Puppet term and type for background processes
# in general and is used in a platform-independent way. E.g. "service" means
# "daemon" in relation to Unix-like systems.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
define logstashforwarder::service::init{

  #### Service management

  # set params: in operation
  if $logstashforwarder::ensure == 'present' {

    case $logstashforwarder::status {
      # make sure service is currently running, start it on boot
      'enabled': {
        $service_ensure = 'running'
        $service_enable = true
      }
      # make sure service is currently stopped, do not start it on boot
      'disabled': {
        $service_ensure = 'stopped'
        $service_enable = false
      }
      # make sure service is currently running, do not start it on boot
      'running': {
        $service_ensure = 'running'
        $service_enable = false
      }
      # do not start service on boot, do not care whether currently running
      # or not
      'unmanaged': {
        $service_ensure = undef
        $service_enable = false
      }
      # unknown status
      # note: don't forget to update the parameter check in init.pp if you
      #       add a new or change an existing status.
      default: {
        fail("\"${logstashforwarder::status}\" is an unknown service status value")
      }
    }

  # set params: removal
  } else {

    # make sure the service is stopped and disabled (the removal itself will be
    # done by package.pp)
    $service_ensure = 'stopped'
    $service_enable = false

  }

  $notify_service = $logstashforwarder::restart_on_change ? {
    true  => Service[$name],
    false => undef,
  }


  if ( $logstashforwarder::status != 'unmanaged' ) {

    # defaults file content. Either from a hash or file
    if ($logstashforwarder::init_defaults_file != undef) {
      $defaults_content = undef
      $defaults_source  = $logstashforwarder::init_defaults_file
    } elsif ($logstashforwarder::init_defaults != undef and is_hash($logstashforwarder::init_defaults) ) {
      $defaults_content = template("${module_name}/etc/sysconfig/defaults.erb")
      $defaults_source  = undef
    } else {
      $defaults_content = undef
      $defaults_source  = undef
    }

    # Check if we are going to manage the defaults file.
    if ( $defaults_content != undef or $defaults_source != undef ) {

      file { "${logstashforwarder::params::defaults_location}/${name}":
        ensure  => $logstashforwarder::ensure,
        source  => $defaults_source,
        content => $defaults_content,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Service[$name],
        notify  => $notify_service
      }

    }

    # init file from template
    if ($logstashforwarder::init_template != undef) {

      file { "/etc/init.d/${name}":
        ensure  => $logstashforwarder::ensure,
        content => template($logstashforwarder::init_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        before  => Service[$name],
        notify  => $notify_service
      }

    }

  }

  if $logstashforwarder::ensure != 'present' {
    # action
    service { $name:
      ensure     => $service_ensure,
      enable     => $service_enable,
      name       => $logstashforwarder::params::service_name,
      hasstatus  => $logstashforwarder::params::service_hasstatus,
      hasrestart => $logstashforwarder::params::service_hasrestart,
      pattern    => $logstashforwarder::params::service_pattern,
    }
  }
}

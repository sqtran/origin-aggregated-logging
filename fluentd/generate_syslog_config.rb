# This ruby script creates the dynamic configuration file 
# needed for the fluentd-remote-syslog plugin.

@env_vars = nil

# Loops through environment variables for the remote-syslog plugin
def init_environment_vars()
  prefix = 'REMOTE_SYSLOG_'
  @env_vars = [
    ['HOST', 'remote_syslog', nil],
    ['PORT', 'port', nil], 
    ['REMOVE_TAG_PREFIX', 'remove_tag_prefix', nil],
    ['TAG_KEY', 'tag_key', nil],
    ['FACILITY', 'facility', nil], 
    ['SEVERITY', 'severity', nil], 
    ['USE_RECORD', 'use_record', nil],
    ['PAYLOAD_KEY', 'payload_key', nil]
  ]

  @env_vars.each { |r| 
    r[2] = ENV[prefix + r[0]]
  }
end


def create_default_file()    
  file_name = "/etc/fluent/configs.d/dynamic/output-remote-syslog.conf"
  c =   
'<store>
@type syslog_buffered
'
  @env_vars.each { |r| 
     c << r[1]  << ' ' << r[2] << "\n" unless !r[2]
  }
  c << '</store>'

  File.open(file_name, 'w') { |f| f.write(c) }
end

init_environment_vars()
create_default_file()

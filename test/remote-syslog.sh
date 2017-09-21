#!/bin/bash

# This is a test suite for the fluent-plugin-remote-syslog settings.
# These tests verify that the configuration files are properly generated based
# on the values of the environment variables.

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/deployer/scripts/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "Remote Syslog Configuration Tests"

original_param1="$(oc set env ds/logging-fluentd -o jsonpath={..env[?\(@.name==\"USE_REMOTE_SYSLOG\"\)].value})"
original_param2="$(oc set env ds/logging-fluentd -o jsonpath={..env[?\(@.name==\"REMOTE_SYSLOG_HOST\"\)].value})"

function reset_fluentd_daemonset() {
 os::log::info Restoring original fluentd daemonset environment variable

 reset_params="USE_REMOTE_SYSLOG=$original_param1 REMOTE_SYSLOG_HOST"

 if [[ ! "$original_param2" = "" ]] ; then
    reset_params="$reset_params=$original_param2"
 else 
    reset_params="$reset_params-"
 fi

 os::log::info "oc set env daemonset/logging-fluentd $reset_params"
}


os::log::info Starting fluentd-plugin-remote-syslog tests at $( date )


os::log::info Test 1, expecting generate_syslog_config.rb to have created configuration file

fpod=`get_running_pod fluentd`
os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod"

os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1)"
os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

fpod=`get_running_pod fluentd`
os::cmd::try_until_success "oc exec $fpod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" 


os::log::info Test 2, expecting generate_syslog_config.rb to not create a configuration file

os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod"

os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST-)"
os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "


fpod=`get_running_pod fluentd`
os::cmd::try_until_failure "oc exec $fpod find /etc/fluent/configs.d/dynamic/output-remote-syslog.conf" 


os::log::info Test 3, expecting generate_syslog_config.rb to generate multiple stores

os::log::debug "$( oc label node --all logging-infra-fluentd- )"
os::cmd::try_until_failure "oc get pod $fpod"

os::log::debug "$( oc set env daemonset/logging-fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=127.0.0.1 REMOTE_SYSLOG_HOST2=127.0.0.1)"
os::log::debug "$( oc label node --all logging-infra-fluentd=true --overwrite=true )"
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

fpod=`get_running_pod fluentd`
os::cmd::try_until_text "oc exec $fpod grep '<store>' /etc/fluent/configs.d/dynamic/output-remote-syslog.conf | wc " "2"


reset_fluentd_daemonset
os::test::junit::reconcile_output

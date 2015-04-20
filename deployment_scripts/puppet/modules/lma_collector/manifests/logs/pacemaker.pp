#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
class lma_collector::logs::pacemaker {
  include lma_collector::params
  include lma_collector::service

  heka::decoder::sandbox { 'pacemaker':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/generic_syslog.lua" ,
    config     => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Class['lma_collector::service'],
  }

  # Use the <PRI> token as the delimiter because Pacemaker may log messages
  # with newlines and the configuration of the Syslog daemon doesn't escape
  # them.
  heka::splitter::regex { 'pacemaker':
    config_dir    => $lma_collector::params::config_dir,
    delimiter     => '(<[0-9]+>)',
    delimiter_eol => false,
    notify        => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'pacemaker':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'pacemaker',
    splitter       => 'pacemaker',
    file_match     => 'pacemaker\.log$',
    differentiator => '[ \'pacemaker\' ]',
    require        => [Heka::Decoder::Sandbox['pacemaker'], Heka::Splitter::Regex['pacemaker']],
    notify         => Class['lma_collector::service'],
  }
}

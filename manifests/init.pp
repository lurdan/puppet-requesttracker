# Class: requesttracker
#
class requesttracker ( $version = 'present', $major = false, $db = 'mysql' ) {

  if $major {
    $rtmajor = $major
  } else {
    $rtmajor = $::lsbdistcodename ? {
      'lenny' => '3.6',
      'squeeze' => '3.8',
      'wheezy' => '4',
    }
  }

  package {
    'requesttracker':
      name => "request-tracker${rtmajor}",
      ensure => $version,
      responsefile => defined(Apt::Preseed['requesttracker']) ? {
        true => '/var/cache/debconf/requesttracker.preseed',
        default => false,
      };
    "rt-db-${db}":
      name => "rt${rtmajor}-db-${db}",
      before => Package['requesttracker'];
  }
#  'libdatetime-perl':
#    before => Package['requesttracker'];

  exec { 'update-rt-siteconfig':
    command => '/usr/sbin/update-rt-siteconfig',
    refreshonly => true,
  }
}

# Definition: requesttracker::plugin
#
# Usage:
#  requesttracker::plugin {
#    'calendar':
#      config => template('rt-siteconfig-calendar.erb');
#    'jsgantt':
#      config => template('rt-siteconfig-jsgantt.erb');
# }

define requesttracker::plugin ( $config ) {
  realize(Requesttracker::Siteconfig['Plugins'])

  $package_name = $name ? {
    'calendar' => "rt${requesttracker::rtmajor}-extension-calendar",
    'jsgantt' => "rt${requesttracker::rtmajor}-extension-jsgantt",
	'gravatar' => "rt${requesttracker::rtmajor}-extension-gravatar",
    #'' => "rt${requesttracker::rtmajor}-",
  }

  package { "$package_name":
    require => Package['requesttracker'],
#    before => Service['requesttracker'],
  }

  requesttracker::siteconfig { "$name":
    content => $config,
  }
}

# Definition: requesttracker::siteconfig
#
# set config file to /etc/requesttracker/RT_SiteConfig.d/.
#
# Parameters:
#   $content: required, pass through to file resource.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   requesttracker::siteconfig { "jafont":
#     content => "Set(%ChartFont, 'ja' => '/usr/share/fonts/truetype/ttf-japanese-gothic.ttf');",
#   }
define requesttracker::siteconfig ( $content, $order = '40' ) {
  file { "/etc/request-tracker${requesttracker::rtmajor}/RT_SiteConfig.d/${order}-${name}":
    content => $content,
    require => Package['requesttracker'],
    notify => Exec['update-rt-siteconfig'],
  }
}

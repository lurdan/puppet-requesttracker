# Class: request-tracker
#
class request-tracker ( $version = 'present', $major = false, $db = 'mysql' ) {

  if $major {
    $_major = $major
  } else {
    $_major = $::lsbdistcodename ? {
      'lenny' => '3.6',
      'squeeze' => '3.8',
      'wheezy' => '4',
    }
  }

  package {
    'request-tracker':
      name => "request-tracker${_major}",
      ensure => $version,
      responsefile => defined(Apt::Preseed['request-tracker']) ? {
        true => '/var/cache/debconf/request-tracker.preseed',
        default => false,
      };
    "rt-db-${db}":
      name => "rt${_major}-db-${db}",
      before => Package['request-tracker'];
  }
#  'libdatetime-perl':
#    before => Package['request-tracker'];

  exec { 'update-rt-siteconfig':
    command => '/usr/sbin/update-rt-siteconfig',
    refreshonly => true,
  }
}

# Definition: request-tracker::plugin
#
# Usage:
#  request-tracker::plugin {
#    'calendar':
#      config => template('rt-siteconfig-calendar.erb');
#    'jsgantt':
#      config => template('rt-siteconfig-jsgantt.erb');
# }

define request-tracker::plugin ( $config ) {
  realize(Request-tracker::Siteconfig['Plugins'])

  $package_name = $name ? {
    'calendar' => "rt${request-tracker::_major}-extension-calendar",
    'jsgantt' => "rt${request-tracker::_major}-extension-jsgantt",
	'gravatar' => "rt${request-tracker::_major}-extension-gravatar",
    #'' => "rt${request-tracker::_major}-",
  }

  package { "$package_name":
    require => Package['request-tracker'],
#    before => Service['request-tracker'],
  }

  request-tracker::siteconfig { "$name":
    content => $config,
  }
}

# Definition: request-tracker::siteconfig
#
# set config file to /etc/request-tracker/RT_SiteConfig.d/.
#
# Parameters:
#   $content: required, pass through to file resource.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   request-tracker::siteconfig { "jafont":
#     content => "Set(%ChartFont, 'ja' => '/usr/share/fonts/truetype/ttf-japanese-gothic.ttf');",
#   }
define request-tracker::siteconfig ( $content, $order = '40' ) {
  file { "/etc/request-tracker${request-tracker::_major}/RT_SiteConfig.d/${order}-${name}":
    content => $content,
    require => Package['request-tracker'],
    notify => Exec['update-rt-siteconfig'],
  }
}

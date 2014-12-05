class awsfunctions (
  $aws_access_key_id     = undef,
  $aws_secret_access_key = undef,
  $install_rubydevel     = false,
  $install_rubygems      = false,
  $manage_fog_gem        = false
) {

  if $install_rubydevel {
    package { 'ruby-devel':
      ensure => present,
      before => Package['rubygems']
    }
  }

  if $install_rubygems {
    package { 'rubygems':
      ensure => present,
      before => Package['fog']
    }
  }

  if $manage_fog_gem {
    package { 'rubygem-nokogiri':
      ensure => present
    } ->
    package { 'fog':
      ensure   => present,
      provider => 'gem'
    }
  }

  file { '/etc/puppet/fog_cred':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('awsfunctions/fog_cred.erb')
  }

}

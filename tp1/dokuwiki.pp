class dokuwiki ($site = 'recettes') {
	package {
	'apache2':
	  ensure   => present,
	}

	package {
	'php7.3':
	  ensure   => present,
	  name     => 'php7.3',
	  provider => apt
	}

	file {
	'download':
	  ensure => present,
	  path   => '/usr/src/dokuwiki.tgz',
	  source => 'https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz'
	}

	exec {
	'unzip':
	  command => 'tar xavf dokuwiki.tgz',
	  cwd     => '/usr/src',
	  path    => ['/usr/bin'],
	  unless  => 'find /usr/src/dokuwiki-2020-07-29',
	  require => File['download']
	}

	file {
	'rename':
	  ensure  => present,
	  source  => '/usr/src/dokuwiki-2020-07-29',
	  path    => '/usr/src/dokuwiki',
	  require => Exec['unzip']
	}

	file {
	'rights recettes and cp':
	  ensure  => directory,
	  path    => '/var/www/$site.wiki',
	  source  => '/usr/src/dokuwiki',
	  recurse => true,
	  owner   => 'www-data',
	  group   => 'www-data',
	  require => [File['rename']]
	}
}

node server0 {
  class {
    dokuwiki:
      site => "politique",
  }
}

node server1 {
  class {dokuwiki:}
}

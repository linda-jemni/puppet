class dokuwiki {
    package { 'apache2':
            ensure => present
    }
    package {
        'php7.3':
            ensure => present
    }
      file { 'dokuwiki::download_dokuwiki':
      ensure => present,
      path   => '/usr/src/dokuwiki.tgz',
      source => 'https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz'
    }
    exec {
        'dokuwiki::extract_dokuwiki':
            command => 'tar xavf dokuwiki.tgz',
            cwd     => '/usr/src',
            path    => ['/usr/bin'],
            require => File['dokuwiki::download_dokuwiki'],
            before  => File['dokuwiki::rename_dokuwiki'],
            unless  => 'test -d /usr/src/dokuwiki-2020-07-29/'
    }
    file { 'dokuwiki::rename_dokuwiki':
      ensure  => present,
      path    => '/usr/src/dokuwiki',
      source  => '/usr/src/dokuwiki-2020-07-29',
      require => Exec['dokuwiki::extract_dokuwiki'],
      before  => File['dokuwiki::delete_dokuwiki']
    }
    file { 'dokuwiki::delete_dokuwiki':
      ensure  => absent,
      path    => '/usr/src/dokuwiki-2020-07-29',
      require => File['dokuwiki::rename_dokuwiki']
    }
}
    define deploy_site($siteName) {
        file {
          $siteName:
            ensure  => directory,
            path    => "/var/www/${siteName}",
            source  => '/usr/src/dokuwiki',
            recurse => true,
            owner   => 'www-data',
            group   => 'www-data',
            require => File['dokuwiki::rename_dokuwiki']
  }
      file { "template $siteName":
      ensure  => file,
      path    => "/etc/apache2/sites-enabled/${siteName}.conf",
      content => template("/vagrant/tp/Puppet_PMN/apache.conf.erb")
  }
}

node 'server0' {
  include dokuwiki
  deploy_site {
    'politique.wiki':
      siteName => 'politique.wiki'
  }
    deploy_site {
    'recette.wiki':
      siteName => 'recettes.wiki'
  }
     deploy_site {
    'Tajineworld.wiki':
      siteName => 'Tajineworld.wiki'
  }


}

node 'server1' {
  include dokuwiki
  deploy_site {
    'politique.wiki':
      siteName => 'politique.wiki'
  }
    deploy_site {
    'recette.wiki':
      siteName => 'recettes.wiki'
  }
}

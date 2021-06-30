class dokuwiki {
    $source_path = '/usr/src'
    $binary_path = '/usr/bin'
    $web_path = '/var/www'

    package { 'apache2':
            ensure => present
    }

    package { 'php7.3':
            ensure => present
    }


    file { 'download-dokuwiki':
            ensure => present,
            source => 'https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz',
            path   => "${source_path}/dokuwiki.tgz"
    }


    exec { 'extract-dokuwiki':
            command => 'tar xavf dokuwiki.tgz',
            cwd     => "${source_path}",
            path    => ["${binary_path}"],
            require => File['download-dokuwiki'],
            unless  => "test -d ${source_path}/dokuwiki-2020-07-29"
    }

    file { 'rename-dokuwiki-2020-07-29':
            ensure  => present,
            source  => "${source_path}/dokuwiki-2020-07-29",
            path    => "${source_path}/dokuwiki",
            require => Exec['extract-dokuwiki']
    }
}


$source_path = '/usr/src'
$web_path = '/var/www'

define deploy_dokuwiki ($env="") {
    file { "$env":
            ensure  => directory,
            source  => "${source_path}/dokuwiki",
            path    => "${web_path}/${env}",
            recurse => true,
            owner   => 'www-data',
            group   => 'www-data',
            require => File['rename-dokuwiki-2020-07-29']
    }
}

node 'server0' {
    include dokuwiki
    
    deploy_dokuwiki { "recettes.wiki":
        env => "recettes.wiki",
    }

    deploy_dokuwiki { "tajineworld.com":
        env => "tajineworld.com",
    }
}

node 'server1' {
    include dokuwiki
    deploy_dokuwiki { "politique.wiki":
        env => "politique.wiki",
    }
}
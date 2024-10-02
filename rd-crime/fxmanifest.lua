fx_version 'cerulean'
game 'gta5'

author 'Ronin Development'
description 'RD-Crime - Advanced Headbag and Ziptie System'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua', -- You can add more language files here
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'qb-target' -- or 'ox_target', depending on your config
}

lua54 'yes'
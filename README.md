# dyndns-updater
Keep DNS Record Updated For Home Machine

This is a simple daemon that wakes up every two hours to check if our
IP address has changed since the last time we checked.  If a change is
detected update.dyn.com is contacted to update our DNS A record.

The service daemon wants a YAML file in ~/.config/secrets.yaml to
obtain necessary secrets and service URLs.  You must provide these
keys at a minimum:

    dyn:
        checkip: 'http://checkip.dyndns.org/'
        tsig:
            name: 'tsig-name'
            secret: 'tsig-secret'
        server: 'update.dyndns.com'
        zones: ['dns-name1', 'dns-name2', ...]

See DynDNS for the necessary name and secret to update DNS A records.

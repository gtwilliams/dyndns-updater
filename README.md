dyndns-updater
==============

Keep DNS Record Updated For Home Machine
----------------------------------------


This is a simple daemon that wakes up every two hours to check if our
IP address has changed since the last time we checked.  If a change is
detected update.dyn.com is contacted to update our DNS A record.

Some routers handle this stuff automatically, but my ISP (ATT) doesn't
provide that in its router.

Prerequisites
-------------


The daemon program requires Perl and `/usr/bin/nsupdate`.  These are
provided by the Fedora packages *perl-interpreter* and *bind-utils*,
respectively.  In addition, the Perl program uses the following Perl
modules provided by the corresponding Fedora packages:

| Perl Module | Fedora Package |
|:------------|:---------------|
|LWP::UserAgent | perl-libwww-perl|
|File::Basename | perl-File-Basename|
|Getopt::Std | perl-Getopt-Std|
|Sys::Syslog | perl-Sys-Syslog|
|YAML::XS | perl-YAML-LibYAML|

Check your distribution for appropriate packages.

Installation
------------


The installation will require `/usr/bin/make`, `/usr/bin/perl`, and
`/usr/bin/pod2man`.  These are provided by Fedora packages *make*,
*perl-interpreter*, and *perl-podlators* respectively.  Check your
distribution for appropriate packages.

The service daemon wants a YAML file in `~/.config/secrets.yaml` to
obtain necessary secrets and service URLs.  You must provide these
keys at a minimum:

    dyn:
        checkip: 'http://checkip.dyndns.org/'
        tsig:
            name: 'tsig-name'
            secret: 'tsig-secret'
        server: 'update.dyndns.com'
        zones: ['dns-name1', 'dns-name2', ...]

See DynDNS for the necessary name and secret to update DNS A records,
[Dynamic DNS Updates via TSIG](https://help.dyn.com/tsig/).

To install this daemon, clone this repository on your own machine then
change to the directory that contains this file and type,

    make

The daemon will be installed in `~/.local/bin`, its manual page in
`~/.local/man/man1`, and a systemd service file will be installed in
`~/.config/systemd/user`.

To start the daemon,

    systemctl --user start dyn-update.service

Check the system journal to see any error messages from the daemon:

    journalctl --user -f

To get the daemon to start every time you log in, enable the service
with this command:

    systemctl --user enable dyn-update.service

If you want the daemon to run whenever you reboot (regardless of
whether you log in or not), you need to enter this command:

    sudo loginctl enable-linger <login-name>

Now anything defined in the user's default.target (this daemon) will
automatically start at boot time without the need to log in.

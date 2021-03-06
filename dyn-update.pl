#!/usr/bin/perl
# Copyright (c) 2021, 2022 Garry T. Williams
#
# This is free software.  You can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3 or any
# later version.  You should have a copy of the GNU General Public
# License supplied with this program.

use strict;
use warnings;
use LWP::UserAgent ();
use File::Basename qw/basename dirname/;
use Getopt::Std qw/getopts/;
use Sys::Syslog qw/:macros/;
use YAML::XS qw/LoadFile/;

# From Sys::Syslog qw/:macros/, we make a constant that the system
# journal will understand, like "<4>" at the beginning of a message
# that will be logged by the journal.  These constants come from
# sys/syslog.h:
# #define LOG_EMERG      0   /* system is unusable */
# #define LOG_ALERT      1   /* action must be taken immediately */
# #define LOG_CRIT       2   /* critical conditions */
# #define LOG_ERR        3   /* error conditions */
# #define LOG_WARNING    4   /* warning conditions */
# #define LOG_NOTICE     5   /* normal but significant condition */
# #define LOG_INFO       6   /* informational */
# #define LOG_DEBUG      7   /* debug-level messages */

use constant LT => '<';
use constant GT => '>';

my $EMERG   = LT . LOG_EMERG   . GT;
my $ALERT   = LT . LOG_ALERT   . GT;
my $CRIT    = LT . LOG_CRIT    . GT;
my $ERR     = LT . LOG_ERR     . GT;
my $WARNING = LT . LOG_WARNING . GT;
my $NOTICE  = LT . LOG_NOTICE  . GT;
my $INFO    = LT . LOG_INFO    . GT;
my $DEBUG   = LT . LOG_DEBUG   . GT;

$SIG{__DIE__} = sub {
    # Don't mark up messsage, if die inside of eval block:
    die @_ if $^S;
    die "$ERR$_[0]";
};

my %opts;
{
    my $me = basename $0;
    my $usage = "usage: $me [ -i secs ]\n";
    getopts('i:', \%opts) || die $usage;
    $opts{i} ||= 7200;
    if ($opts{i} < 600) {
        warn "${INFO}sleep time is less than 10 minutes\n";
        warn "${INFO}consider increasing -i option\n";
    }
}

my $home  = (getpwuid($<))[7];
my $cfg   = LoadFile("$home/.config/secrets.yaml")->{dyn};
my $cmds  = "$home/.cache/dyn/ip-in";
my @args  = ('-y', "hmac-md5:$cfg->{tsig}{name}:$cfg->{tsig}{secret}", $cmds);
my $cache = "$home/.cache/dyn/ip";
my $chg   = '/usr/bin/nsupdate';

$|++;

while (1) {
    my $resp = LWP::UserAgent->new()->get($cfg->{checkip});
    unless ($resp->is_success()) {
        warn "${NOTICE}GET $cfg->{checkip}: ", $resp->code(),
            ": ", $resp->message(), "\n";
        next;
    }

    my $doc = $resp->decoded_content();
    my $ip;
    unless (($ip) = $doc =~ /Current IP Address:\s+(\d+\.\d+\.\d+\.\d+)/) {
        warn "${NOTICE}GET $cfg->{checkip}: $doc\n";
        next;
    }

    my $old = '';
    my $fh;
    if (!open($fh, '<', $cache)) {
        warn "${INFO}creating $cache\n";
        mkdir dirname $cache;
        open $fh, '>', $cache or die "can't open $cache: $!\n";
        print $fh $ip;
        close $fh or die "can't close $cache: $!\n";
    }

    else {
        $old = <$fh>;
        chomp $old if $old;
        close $fh;
    }

    next unless !$old || $old ne $ip;

    open $fh, '>', $cmds or die "can't open $cmds: $!\n";
    print $fh "server $cfg->{server}\n";
    for (@{$cfg->{zones}}) {
        print $fh "zone $_\n";
        print $fh "update add $_ 60 A $ip\n";
        print $fh "send\n";
        print $fh "answer\n";
    }

    close $fh or die "can't close $cmds: $!\n";

    system($chg, @args) && die "$chg failed with $?\n";
    open $fh, '>', $cache or die "can't open $cache: $!\n";
    print $fh $ip;
    close $fh or die "can't close $cache: $!\n";
    unlink $cmds;
}

continue {
    sleep $opts{i};
}

__END__

=pod

=head1 NAME

dyn-update - keep DynDNS up to date

=head1 SYNOPSIS

    dyn-update [ -i seconds ]

=head1 OPTIONS

=over

=item B<-i>

The B<-i> option specifies in seconds how long to sleep between
checks.  If the option is not specified, it will default to 7200, two
hours.

=back

=head1 DESCRIPTION

This systemd user daemon wakes up periodically to check if the public
IP address configured by our Internet provider has changed.  If it
has, then the DynDNS site is notified to change our A record.

=head1 FILES

=head2 ~/.config/secrets.yaml

The F<~/.config/secrets.yaml> file is a YAML format file that must
contain a C<dyn> key that contains these four keys:

    dyn:
        checkip: 'http://checkip.dyndns.org/'
        tsig:
            name: tsig name
            secret: tsig secret
        server: 'update.dyndns.com'
        zones: [ list of zones to update ]

=head2 ~/.cache/dyn/ip

The F<~/.cache/dyn/ip> file contains the last IP address that was
obtained.  If we check and the current is different, we know that an
update is required.

=head1 COPYRIGHT

Copyright (c) 2021, 2022 Garry T. Williams

=head1 AUTHOR

Garry T. Williams <gtwilliams@gmail.com>

=head1 SEE ALSO

L<https://yaml.org/>, L<https://help.dyn.com/tsig/>, nsupdate(1)

=cut

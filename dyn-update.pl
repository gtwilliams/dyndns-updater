#!/usr/bin/perl
# Copyright (c) 2021 Garry T. Williams

use strict;
use warnings;
use LWP::UserAgent ();
use File::Basename qw/dirname/;
use Sys::Syslog qw/:macros/;
use YAML::XS qw/LoadFile/;

# From Sys::Syslog qw/:macros/, we make a constant that the system
# journal will understand, like "<4>" at the beginning or a message
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

my $cfg = LoadFile('/home/garry/.config/secrets.yaml')->{dyn};

my $NAME   = $cfg->{tsig}{name};
my $SECRET = $cfg->{tsig}{secret};

my $check = $cfg->{checkip};
my $cache = '/home/garry/.cache/dyn/ip';
my $cmds  = '/home/garry/.cache/dyn/ip-in';
my $chg   = '/usr/bin/nsupdate';
my @args  = ('-y', "hmac-md5:$NAME:$SECRET", $cmds);

$|++;

while (1) {
    my $doc = LWP::UserAgent->new()->get($check)->decoded_content();
    my $ip;
    unless (($ip) = $doc =~ /Current IP Address:\s+(\d+\.\d+\.\d+\.\d+)/) {
        warn "${NOTICE}GET $check failed\n";
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
        chomp $old;
        close $fh;
    }

    if ($old ne $ip) {
        open $fh, '>', $cmds or die "can't open $cmds: $!\n";
        print $fh <<HERE;
        server update.dyndns.com
        zone garry.is-a-geek.org
        update add garry.is-a-geek.org 60 A $ip
        send
        answer
HERE

        close $fh or die "can't close $cmds: $!\n";
        system($chg, @args) and die "$chg failed with $?\n";
        open $fh, '>', $cache or die "can't open $cache: $!\n";
        print $fh $ip;
        close $fh or die "can't close $cache: $!\n";
        unlink $cmds;
    }
}

continue {
    sleep 7200;
}

#!perl
#
# todo: ssh key path
# ssh path
# scp path

use warnings;
use strict;
use List::Util qw(max);
use Gnu::Template qw(Template);
use Gnu::ArgParse;
use Gnu::FileUtil qw(SlurpFile);
use Gnu::StringUtil qw(Trim);
use Gnu::DebugUtil qw(DumpHash);

my @HOSTS;

MAIN:
   $| = 1;
   ArgBuild("*^help *^debug");
   ArgParse(@ARGV) or die ArgGetError();
   ArgAddConfig() or die ArgGetError();

   my ($cmd, $host, $file) = map{$_ || ""} ArgGetAll();
   #print "cmd:$cmd, host:$host, file:$file\n";

   GetHosts();

   Usage() if ArgIs("help") || ArgIs("") < 2;

   Connect ($host)        if $cmd =~ /^shell$/i;
   Get     ($host, $file) if $cmd =~ /^get$/i;
   Put     ($host, $file) if $cmd =~ /^put$/i;

   print "unknown command '$cmd'. Try /help\n";

   exit(0);


# todo - make hosts file path relative to perl file
#
sub GetHosts {
   open (my $fh, "<", "hosts.cfg") or die "cannot open hosts.cfg";  
   while (my $line = <$fh>) {
      chomp $line;
      next if !$line || $line =~ /^#/;
      push @HOSTS, ParseHost($line);
   }
   close $fh;
}

sub ParseHost {
   my ($line) = @_;

   my ($id, $alias, $host, $key, $user, $descr) = map{Trim($_)} split(",", $line);
   return {
      id    => $id   ,
      alias => $alias,
      host  => $host ,
      key   => $key  ,
      user  => $user ,
      descr => $descr
   }
}

sub ListHosts {
   my $sizes = HostFieldSizes();
   foreach my $host (@HOSTS) {
      print sprintf ("   [%-*s or %-*s] %-*s  %-*s\n",
         $sizes->{id   }, $host->{id   },
         $sizes->{alias}, $host->{alias},
         $sizes->{host }, $host->{host },
         $sizes->{descr}, $host->{descr});
   }
}

sub HostFieldSizes() {
   my $sizes = {};
   foreach my $host (@HOSTS) {
      foreach my $key (keys %{$host}) {
         my $len = length $host->{$key};
         $sizes->{$key} = defined $sizes->{$key} ? max($sizes->{$key}, $len) : $len;
      }
   }
   return $sizes;
}

# ssh.exe -i %key6 %usr6@demo2.helpsteps.com
sub Connect {
   my ($hostname) = @_;

   print "connect host=$host\n";

   my $host = FindHost($hostname) or die "Cant find host '$hostname'\n";

#   my $keypath = "keys/$host->{key}";
   my $keypath = "/Users/Craig/.ssh2/$host->{key}";
   my $cmd = "ssh.exe -i $keypath $host->{user}\@$host->{host}";

   print "$cmd\n";
   system($cmd);
   exit(0);
}

# scp.exe -i %key2 %usr2@ext.trivoxhealth.com:%destdir%%file .
sub Get {
   my ($hostname, $file) = @_;

   print "get host=$host file=$file\n";

   my $host = FindHost($hostname) or die "Cant find host '$hostname'\n";

#   my $keypath = "keys/$host->{key}";
   my $keypath = "/Users/Craig/.ssh2/$host->{key}";
   my $cmd = "scp.exe -i $keypath $host->{user}\@$host->{host}:$file .";
   print "$cmd\n";
   system($cmd);
   exit(0);
}

#scp.exe -i %key1 %file %usr1@iciss-bch-proxy1.tch.harvard.edu:%destdir.
sub Put {
   my ($hostname, $file) = @_;

   print "put host=$host file=$file\n";

   my $host = FindHost($hostname) or die "Cant find host '$hostname'\n";

#   my $keypath = "keys/$host->{key}";
   my $keypath = "/Users/Craig/.ssh2/$host->{key}";

   my $cmd = "scp.exe -i $keypath $file $host->{user}\@$host->{host}:/tmp/.";

   print "$cmd\n";
   system($cmd);
   exit(0);
}


sub FindHost {
   my ($hostname) = @_;

   my %hostmap = map{$_->{id} => $_, $_->{alias} => $_} @HOSTS;
   return $hostmap{$hostname};
}


sub Usage
   {
   print Template("usage");
   ListHosts();

   exit(0);
   }


__DATA__

[usage]
connect.pl  -  Connect to a host or xfer a file

Get a remote shell (SSH):
   connect.pl shell <host>

Get A file from a remote host (SCP):
    connect.pl get <host> <file>

Send A file to a remote host (SCP):
    connect.pl put <host> <file>

Examples:
   connect.pl shell cf
   connect.pl shell craigfitz
   connect.pl get cf readme.txt
   connect.pl get cf /var/www/html/index.txt
   connect.pl put cf readme.txt
   connect.pl put cf /var/www/html/index.txt

Hosts:
[fini]

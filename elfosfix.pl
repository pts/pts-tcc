#! /bin/sh
eval '(exit $?0)' && eval 'PERL_BADLANG=x;PATH="$PATH:.";export PERL_BADLANG\
 PATH;exec perl -x -S -- "$0" ${1+"$@"};#'if 0;eval 'setenv PERL_BADLANG x\
;setenv PATH "$PATH":.;exec perl -x -S -- "$0" $argv:q;#'.q
#!perl -w
+push@INC,'.';$0=~/(.*)/s;do(index($1,"/")<0?"./$1":$1);die$@if$@__END__+if 0
;#Don't touch/remove lines 1--7: http://www.inf.bme.hu/~pts/Magic.Perl.Header
#
# elffix.pl -- fix OS codes in ELF header
# by pts@fazekas.hu at Fri Sep 29 13:54:21 CEST 2006
#
# fixes uclibc-0.9.26 statically compiled Linux ELF executables so that they
# run of 
use integer;
use strict;

#** ELF operating system codes from FreeBSD's /usr/share/misc/magic
my %ELF_os_codes=qw{
SYSV 0
HP-UX 1
NetBSD 2
GNU/Linux 3
GNU/Hurd 4
86Open 5
Solaris 6
Monterey 7
IRIX 8
FreeBSD 9
Tru64 10
Novell 11
OpenBSD 12
ARM 97
embedded 255
};
my $from_oscode=$ELF_os_codes{'SYSV'};
my $to_oscode=$ELF_os_codes{'GNU/Linux'};

for my $fn (@ARGV) {
  my $f;
  if (!open $f, '+<', $fn) {
    print STDERR "$0: $fn: $!\n";
    next
  }
  my $head;
  # vvv Imp: continue on next file instead of die()ing
  die if 8!=sysread($f,$head,8);
  if (substr($head,0,4)ne"\177ELF") {
    print STDERR "$0: $fn: not an ELF file\n";
    close($f); next;
  }
  if (vec($head,7,8)==$to_oscode) {
    print STDERR "$0: info: $fn: already fixed\n";
  }
  if ($from_oscode!=$to_oscode && vec($head,7,8)==$from_oscode) {
    vec($head,7,8)=$to_oscode;
    die if 0!=sysseek($f,0,0);
    die if length($head)!=syswrite($f,$head);
  }
  close($f);
}

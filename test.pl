# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use Convert::IBM390p qw(:all);
$loaded = 1;
print "ok 1\n";

################### End of black magic.

my $failed = 0;
#----- asc2eb
print "asc2eb...........";
my ($asc, $eb);
$asc = ".<(+|!\$*%\@=[]A2";
$eb = asc2eb($asc);
was_it_ok(2, $eb eq "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2");

#----- eb2asc
print "eb2asc...........";
$eb = "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2";
$asc = eb2asc($eb);
was_it_ok(3, $asc eq ".<(+|!\$*%\@=[]A2");

#----- eb2ascp
print "eb2ascp..........";
$eb = "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2\x00\xFE";
$asc = eb2ascp($eb);
was_it_ok(4, $asc eq ".<(+|!\$*%\@=[]A2  ");

#----- hexdump
print "hexdump..........";
my ($string, @hdump);
$string = "Now is the time for all good Perls to come to the aid of
their systems";
@hdump = hexdump($string, 4);
was_it_ok(5, (@hdump == 3) && $hdump[0] eq 
  "000004: 4E6F7720 69732074 68652074 696D6520  666F7220 616C6C20 676F6F64 20506572  *Now is the time for all good Per*\n");

#----- pdi
print "pdi..............";
my (@pd, @perlnum);
@pd = (pack("H4", "012C"), pack("H2", "0C"), pack("H6", "00345D"));
@perlnum = (pdi($pd[0]), pdi($pd[1]), pdi($pd[2], 2));
was_it_ok(6, $perlnum[0] == 12 &&
    $perlnum[1] == 0 &&
    $perlnum[2] == -3.45);

#----- pdi with undefined result
print "   ..............";
my $perlnum = pdi(pack("H6", "0B01C9"));
was_it_ok(7, ! defined($perlnum));

#----- pdo
print "pdo..............";
@perlnum = (5.67, 0, -89);
@pd = (pdo($perlnum[0], 3,2), pdo($perlnum[1],3), pdo($perlnum[2],3));
was_it_ok(8, $pd[0] eq "\x00\x56\x7C" &&
    $pd[1] eq "\x00\x00\x0C" &&
    $pd[2] eq "\x00\x08\x9D");

#----- pdo with undefined result
print "   ..............";
my $pd = pdo("notanum");
was_it_ok(9, ! defined($pd));

#----- zdi
print "zdi..............";
my @zd = (pack("H*", "F0F0F3F9C8"), pack("H*", "F0F0F4F9D0"));
@perlnum = (zdi($zd[0]), zdi($zd[1]));
was_it_ok(10, ($perlnum[0] == 398) && ($perlnum[1] == -490));

#----- zdi with undefined result
print "   ..............";
$perlnum = zdi(pack("H*", "F0F0A3F98C"));
was_it_ok(11, ! defined($perlnum));

#----- zdo
print "zdo..............";
@zd = (zdo(5.67, 4,2), zdo(0, 3), zdo(-89, 3));
was_it_ok(12, $zd[0] eq "\xF0\xF5\xF6\xC7" &&
    $zd[1] eq "\xF0\xF0\xC0" &&
    $zd[2] eq "\xF0\xF8\xD9");

#----- zdo with undefined result
print "   ..............";
$perlnum = zdo("notanum");
was_it_ok(13, ! defined($perlnum));

if ($failed == 0) { print "All tests successful.\n"; }
else {
   $tt = ($failed == 1) ? "1 test" : "$failed tests";
   print "$tt failed!  There is no joy in Mudville.\n";
}


sub was_it_ok {
 my ($num, $test) = @_;
 if ($test) { print "ok $num\n"; }
 else       { print "not ok $num\n"; $failed++; }
}

package Convert::IBM390p;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(asc2eb eb2asc eb2ascp hexdump pdi pdo fcs_xlate);
$VERSION = '0.01';

use Carp;

# $warninv = issue warning message if a field is invalid.  Default
# is FALSE (don't issue the message).  Used by pdi and pdo.
my $warninv = 0;

my ($a2e_table, $e2a_table, $e2ap_table);
$a2e_table = pack "H512",
 "00010203372d2e2f1605150b0c0d0e0f101112133c3d322618193f271c1d1e1f".
 "405a7f7b5b6c507d4d5d5c4e6b604b61f0f1f2f3f4f5f6f7f8f97a5e4c7e6e6f".
 "7cc1c2c3c4c5c6c7c8c9d1d2d3d4d5d6d7d8d9e2e3e4e5e6e7e8e9ade0bd5f6d".
 "79818283848586878889919293949596979899a2a3a4a5a6a7a8a9c04fd0a107".
 "202122232425061728292a2b2c090a1b30311a333435360838393a3b04143eff".
 "41aa4ab19fb26ab5bbb49a8ab0caafbc908feafabea0b6b39dda9b8bb7b8b9ab".
 "6465626663679e687471727378757677ac69edeeebefecbf80fdfefbfcbaae59".
 "4445424643479c4854515253585556578c49cdcecbcfcce170dddedbdc8d8edf";

$e2a_table = pack "H512",
 "000102039c09867f978d8e0b0c0d0e0f101112139d0a08871819928f1c1d1e1f".
 "808182838485171b88898a8b8c050607909116939495960498999a9b14159e1a".
 "20a0e2e4e0e1e3e5e7f1a22e3c282b7c26e9eaebe8edeeefecdf21242a293b5e".
 "2d2fc2c4c0c1c3c5c7d1a62c255f3e3ff8c9cacbc8cdcecfcc603a2340273d22".
 "d8616263646566676869abbbf0fdfeb1b06a6b6c6d6e6f707172aabae6b8c6a4".
 "b57e737475767778797aa1bfd05bdeaeaca3a5b7a9a7b6bcbdbedda8af5db4d7".
 "7b414243444546474849adf4f6f2f3f57d4a4b4c4d4e4f505152b9fbfcf9faff".
 "5cf7535455565758595ab2d4d6d2d3d530313233343536373839b3dbdcd9da9f";

$e2ap_table =
  " " x 64 .
  "           .<(+|&         !\$*); -/         ,%_>?         `:#\@\'=\"".
  " abcdefghi       jklmnopqr       ~stuvwxyz   [               ]  ".
  "{ABCDEFGHI      }JKLMNOPQR      \\ STUVWXYZ      0123456789      ";

# ASCII to EBCDIC
sub asc2eb {
 my $String = shift;
 return fcs_xlate($String, $a2e_table);
}

# EBCDIC to ASCII
sub eb2asc {
 my $String = shift;
 return fcs_xlate($String, $e2a_table);
}

# EBCDIC to ASCII printable
sub eb2ascp {
 my $String = shift;
 return fcs_xlate($String, $e2ap_table);
}

# Packed Decimal In -- returns a Perl number
sub pdi {
 my ($packed, $ndec) = @_;
 $ndec ||= 0;
 my ($w, $xdigits, $arabic, $sign);
 $w = 2 * length($packed);
 $xdigits = unpack("H$w", $packed);
 $arabic = substr($xdigits, 0, $w-1);
 $sign = substr($xdigits, $w-1, 1);
 if ( $arabic !~ /^\d+$/ || $sign !~ /^[a-f]$/ ) {
    Carp::carp "pdi: Invalid packed value $xdigits"
      if $Convert::IBM390p::warninv;
    return undef();
 }
 $arabic = 0 - $arabic  if $sign =~ /[bd]/;
 $arabic /= 10 ** $ndec  if $ndec != 0;
 return $arabic + 0;
}

# Packed Decimal Out -- converts a Perl number to a packed field
sub pdo {
 my ($num, $outwidth, $ndec) = @_;
 $outwidth ||= 8;
 $ndec ||= 0;
 if ( $num !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ) {
    Carp::carp "pdo: Input is not a number" if $Convert::IBM390p::warninv;
    return undef();
 }
 my ($outdig, $digits, $sign);
 $outdig = $outwidth * 2 - 1;
# sprintf will round to the appropriate number of places.
 $digits = sprintf("%0${outdig}d", abs($num * (10 ** $ndec)));
 $sign = ($num >= 0) ? "C" : "D";
 $outwidth *= 2;
 return pack("H$outwidth", $digits . $sign);
}

# Print an entire string in hexdump format, 32 bytes at a time
# (like a sysabend dump).
sub hexdump {
 my ($String, $startad, $charset) = @_;
 $startad ||= 0;
 $charset ||= "ascii";
 my ($i, $j, $d, $str, $pri, $hexes);
 my @outlines = ();
 my $L = length($String);
 for ($i = 0; $i < $L; $i += 32) {
    $str = substr($String, $i,32);
#   Generate a printable version of the string.
    if ($charset =~ m/ebc/i) {
       $pri = eb2ascp $str;
    } else {
       $pri = $str;
       $pri =~ tr/\000-\037\177-\377/ /;
    }
    $hexes = unpack("H64", $str);
    $hexes =~ tr/a-f/A-F/;
    if (($L - $i) < 32) {   # Pad with blanks if necessary.
       $pri = pack("A32", $pri);
       $hexes = pack("A64", $hexes);
    }
    $d = sprintf("%06X: ", $startad + $i);
    for ($j = 0; $j < 64; $j += 8) {
       $d .= substr($hexes, $j, 8) . " ";
       $d .= " " if $j == 24;
    }
    $d .= " *$pri*\n";
    push @outlines, $d;
 }
 return @outlines;
}

# Full Collating Sequence Translate -- like tr///, but assumes that
# the searchstring is a complete 8-bit collating sequence
# (x'00' - x'FF').  I couldn't get tr to do this, and I have my
# doubts about whether it would be possible on systems where char
# is signed.  This approach works on AIX, where char is unsigned,
# and at least has a fighting chance of working elsewhere.
# The second argument is one of the translation tables defined
# above ($a2e_table, etc.).
sub fcs_xlate {
 my ($instring, $to_table) = @_;
 my ($i, $outstring);
 $outstring = "";
 for ($i = 0; $i < length($instring); $i++) {
    $outstring .= substr($to_table, ord(substr($instring, $i,1)), 1);
 }
 return $outstring;
}

1;

__END__

=head1 NAME

Convert::IBM390p -- functions for manipulating mainframe data

=head1 SYNOPSIS

  use Convert::IBM390p qw(...whatever...);

  $eb  = asc2eb($string);
  $asc = eb2asc($string);
  $asc = eb2ascp($string);

  $num = pdi($packed [,ndec]);
  $packed = pdo($num [,outbytes [,ndec]]);

  @lines = hexdump($string [,startaddr [,charset]]);

=head1 DESCRIPTION

B<Convert::IBM390p> supplies various functions that you may find useful
when messing with IBM System/3[679]0 data.  No functions are exported
automatically; you must ask for the ones you want.

By the way, this module is called "IBM390p" because it will deal with
data from any mainframe operating system.  Nothing about it is
specific to MVS, VM, VSE, or OS/390.

=head1 FUNCTIONS

=over 2

=item B<asc2eb> STRING

Converts a character string from ASCII to EBCDIC.  The translation
table is taken from the LE/370 code set converter EDCUI1EY; it
translates ISO8859-1 to IBM-1047.  For more information, see "IBM
C/C++ for MVS/ESA V3R2 Programming Guide", SC09-2164.

=item B<eb2asc> STRING

Converts a character string from EBCDIC to ASCII.  EBCDIC character
strings ordinarily come from files transferred from mainframes
via the binary option of FTP.  The translation table is taken from
the LE/370 code set converter EDCUEYI1; it translates IBM-1047 to
ISO8859-1 (see above).

=item B<eb2ascp> STRING

Like eb2asc, but the output will contain only printable ASCII characters.

=item B<pdi> PACKED [NDEC]

Packed Decimal In: converts an EBCDIC packed number to a Perl number.
The first argument is the packed field; the second (optional) is a
number of decimal places to assume (default = 0).  For instance:

  pdi(x'00123C')    => 123
  pdi(x'01235D', 2) => -12.35
  pdi(x'0C', 1)     => 0

If the first argument is not a valid packed field, pdi will return
the undefined value.  By default, no warning message will be issued
in this case, but if you set the variable $Convert::IBM390p::warninv
to 1 (or any other true value), a warning will be issued.

=item B<pdo> NUMBER [OUTBYTES [NDEC]]

Packed Decimal Out: converts a Perl number to a packed field.  
The first argument is a Perl number; the second is the number of bytes
to put in the output field (default = 8); the third is the number of
decimal places to round to (default = 0).  For instance:

  pdo(-234)          => x'000000000000234D'
  pdo(-234, 5)       => x'000000234D'
  pdo(356.777, 5, 2) => x'000035678C'
  pdo(0, 4)          => x'0000000C'

If the first argument is not a valid Perl number, pdo will return
the undefined value.  By default, no warning message will be issued
in this case, but if you set the variable $Convert::IBM390p::warninv
to 1 (or any other true value), a warning will be issued.

=item B<hexdump> STRING [STARTADDR [CHARSET]]

Generate a hexadecimal dump of STRING.  The dump is similar to a
SYSABEND dump in MVS: each line contains an address, 32 bytes of
hexadecimal data, and the same data in printable form.  This function
returns an array of lines, each of which is terminated with a newline.
This allows them to be printed immediately; for instance, you can say
"print hexdump($crud);".

The second and third arguments are optional.  The second specifies 
a starting address for the dump (default = 0); the third specifies
the character set to use for the printable data at the end of each
line ("ascii" or "ebcdic", in upper or lower case; default = ascii).

=back

=head1 AUTHOR

Convert::IBM390p was written by Geoffrey Rommel E<lt>grommel@sears.comE<gt>
in January 1999.

=cut

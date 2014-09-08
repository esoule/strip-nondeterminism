#
# Copyright 2014 Andrew Ayer
#
# This file is part of strip-nondeterminism.
#
# strip-nondeterminism is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# strip-nondeterminism is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with strip-nondeterminism.  If not, see <http://www.gnu.org/licenses/>.
#
package StripNondeterminism::handlers::gzip;

use strict;
use warnings;

use File::Temp qw/tempfile/;
use File::Basename;

use constant {
	FTEXT    => 1 << 0,
	FHCRC    => 1 << 1,
	FEXTRA   => 1 << 2,
	FNAME    => 1 << 3,
	FCOMMENT => 1 << 4,
};

sub normalize {
	my ($filename) = @_;

	open(my $fh, '<', $filename) or die "Unable to open $filename for reading: $!";
	my ($out_fh, $out_filename) = tempfile(DIR => dirname($filename), UNLINK => 1);

	# See RFC 1952

	# 0   1   2   3   4   5   6   7   8   9   10
	# +---+---+---+---+---+---+---+---+---+---+
	# |ID1|ID2|CM |FLG|     MTIME     |XFL|OS |
	# +---+---+---+---+---+---+---+---+---+---+

	# Read the current header
	my $hdr;
	my $bytes_read = read($fh, $hdr, 10);
	return unless $bytes_read == 10;
	my ($id1, $id2, $cm, $flg, $mtime, $xfl, $os) = unpack('CCCCl<CC', $hdr);
	return unless $id1 == 31 and $id2 == 139;

	my $new_flg = $flg;
	$new_flg &= ~FNAME;	# Don't include filename
	$new_flg &= ~FHCRC;	# Don't include header CRC (not all implementations support it)
	$mtime = 0;		# Zero out mtime (this is what `gzip -n` does)
	# TODO: question: normalize some of the other fields, such as OS?

	# Write a new header
	print $out_fh pack('CCCCl<CC', $id1, $id2, $cm, $new_flg, $mtime, $xfl, $os);

	if ($flg & FEXTRA) {	# Copy through
		# 0   1   2
		# +---+---+=================================+
		# | XLEN  |...XLEN bytes of "extra field"...|
		# +---+---+=================================+
		my $buf;
		read($fh, $buf, 2) == 2 or die "$filename: Malformed gzip file";
		my ($xlen) = unpack('v', $buf);
		read($fh, $buf, $xlen) == $xlen or die "$filename: Malformed gzip file";
		print $out_fh pack('vA*', $xlen, $buf);
	}
	if ($flg & FNAME) {	# Read but do not copy through
		# 0
		# +=========================================+
		# |...original file name, zero-terminated...|
		# +=========================================+
		while (1) {
			my $buf;
			read($fh, $buf, 1) == 1 or die "$filename: Malformed gzip file";
			last if ord($buf) == 0;
		}
	}
	if ($flg & FCOMMENT) {	# Copy through
		# 0
		# +===================================+
		# |...file comment, zero-terminated...|
		# +===================================+
		while (1) {
			my $buf;
			read($fh, $buf, 1) == 1 or die "$filename: Malformed gzip file";
			print $out_fh $buf;
			last if ord($buf) == 0;
		}
	}
	if ($flg & FHCRC) {	# Read but do not copy through
		# 0   1   2
		# +---+---+
		# | CRC16 |
		# +---+---+
		my $buf;
		read($fh, $buf, 2) == 2 or die "$filename: Malformed gzip file";
	}

	# Copy through the rest of the file.
	# TODO: also normalize concatenated gzip files.  This will require reading and understanding
	# each DEFLATE block (see RFC 1951), since gzip doesn't include lengths anywhere.
	while (1) {
		my $buf;
		my $bytes_read = read($fh, $buf, 4096);
		defined($bytes_read) or die "$filename: read failed: $!";
		print $out_fh $buf;
		last if $bytes_read == 0;
	}

	chmod((stat($fh))[2] & 07777, $out_filename);
	rename($out_filename, $filename) or die "$filename: unable to overwrite: rename: $!";
}

1;

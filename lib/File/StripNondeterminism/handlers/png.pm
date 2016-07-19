#
# Copyright 2015 Chris Lamb <lamby@debian.org>
# Copyright 2015 Andrew Ayer <agwa@andrewayer.name>
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
package File::StripNondeterminism::handlers::png;

use strict;
use warnings;

use File::Basename qw/dirname/;
use POSIX qw/strftime/;
use Archive::Zip;

sub crc {
	my ($data) = @_;
	return Archive::Zip::computeCRC32($data);
}

sub chunk {
	my ($type, $data) = @_;
	return pack('Na4a*N', length($data), $type, $data, crc($type . $data));
}

sub time_chunk {
	my ($seconds) = @_;
	my ($sec, $min, $hour, $mday, $mon, $year) = gmtime($seconds);
	return chunk('tIME', pack('nCCCCC', 1900+$year, $mon+1, $mday, $hour, $min, $sec));
}

sub text_chunk {
	my ($keyword, $data) = @_;
	return chunk('tEXt', pack('Z*a*', $keyword, $data));
}

sub normalize {
	my ($filename) = @_;

	my $canonical_time = $File::StripNondeterminism::canonical_time;

	my $tempfile = File::Temp->new(DIR => dirname($filename));

	my $buf;
	my $bytes_read;

	open(my $fh, '+<', $filename) or die "$filename: open: $!";
	read($fh, my $magic, 8); $magic eq "\x89PNG\r\n\x1a\n"
		or die "$filename: does not appear to be a PNG";
	print $tempfile $magic;

	while (read($fh, my $header, 8) == 8) {
		my ($len, $type) = unpack('Na4', $header);

		# Include the trailing CRC when reading
		$len += 4;
		# We cannot trust the value of $len, so we only read(2) if it
		# has a sane size.
		if ($len < 4096) {
			read $fh, my $data, $len + 4;

			if ($type eq "tIME") {
				print $tempfile time_chunk($canonical_time) if defined($canonical_time);
				next;
			} elsif (($type =~ /[tiz]EXt/) && ($data =~ /^(date:[^\0]+|Creation Time)\0/)) {
				print $tempfile text_chunk($1, strftime("%Y-%m-%dT%H:%M:%S-00:00",
								gmtime($canonical_time))) if defined($canonical_time);
				next;
			}
		}

		# Read/write in chunks
		print $tempfile $header;
		while (($len > 0) && ($bytes_read = read($fh, $buf, 4096))) {
			$len = $len - $bytes_read;
			print $tempfile $buf;
		}

		# Stop processing immediately in case there's garbage after the
		# PNG datastream. (https://bugs.debian.org/802057)
		last if $type eq 'IEND';
	}

	# Copy through trailing garbage.  Conformant PNG files don't have trailing
	# garbage (see http://www.w3.org/TR/PNG/#15FileConformance item c), however
	# in the interest of strip-nondeterminism being as transparent as possible,
	# we preserve the garbage.
	while ($bytes_read = read($fh, $buf, 4096)) {
		print $tempfile $buf;
	}
	defined($bytes_read) or die "$filename: read failed: $!";

	chmod((stat($fh))[2] & 07777, $tempfile->filename);
	rename($tempfile->filename, $filename)
		or die "$filename: unable to overwrite: rename: $!";
	$tempfile->unlink_on_destroy(0);

	close $fh;
}

1;

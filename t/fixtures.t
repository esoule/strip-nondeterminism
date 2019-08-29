#!perl

#
# Copyright 2016 Chris Lamb <lamby@debian.org>
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

use strict;
use warnings;

use File::Basename qw(basename);
use File::Compare qw(compare);
use File::Copy qw(copy);
use File::Temp qw(tempdir);
use File::StripNondeterminism;
use Test::More;

# perlfunc(1)
my %STAT = (
	0 => "dev (device number of filesystem)",
	# 1 => "ino (inode number)",
	2 => "mode (file mode (type and permissions))",
	3 => "nlink (number of hard links to the file)",
	4 => "uid (numeric user ID of file's owner)",
	5 => "gid (numeric group ID of file's owner)",
	6 => "rdev (the device identifier; special files only)",
	# 7 => "size (total size of file, in bytes)",
	# 8 => "atime (last access time in seconds since the epoch)",
	# 9 => "mtime (last modified time in seconds since the epoch)",
	# 10 => "ctime (inode change time in seconds since the epoch)",
	# 11 => "blksize (preferred I/O size in bytes for interacting with the file)",
	# 12 => "blocks (actual number of system-specific blocks allocated on disk)",
);

File::StripNondeterminism::init();

# Enable all normalizers for tests
for (File::StripNondeterminism::all_normalizers()) {
	File::StripNondeterminism::enable_normalizer($_);
}

# = 2015-02-05 10:09:31
$File::StripNondeterminism::canonical_time = 1423159771;

my @fixtures = glob('t/fixtures/*/*.in');
plan tests => scalar @fixtures;

sub handler_name {
	eval {
		my $obj = B::svref_2object(shift());
		return $obj->GV->STASH->NAME;
	} || "unknown handler";
}


foreach my $filename (@fixtures) {
	# Use a temporary directory per fixture so we can check whether any
	# extraneous files are leftover.
	my $temp = tempdir( CLEANUP => 1 );

	my $in = "$temp/" . basename($filename, '.in');
	(my $out = $filename) =~ s/\.in$/.out/;

	copy($filename, $in) or die "Copy failed: $!";

	my $normalizer = File::StripNondeterminism::get_normalizer_for_file($in);

	subtest $filename => sub {
		isnt(undef, $normalizer, "Normalizer found for $in");

		my @stat_before = lstat $in;
		$normalizer->($in) if defined $normalizer;
		my @stat_after = lstat $in;

		ok(compare($in, $out) == 0, "Test output $in matched expected $out");

		# Check that file attributes remain unchanged.
		foreach my $i (sort keys %STAT) {
			is($stat_before[$i], $stat_after[$i], "$filename: $STAT{$i}");
		}

		my @files = glob("$temp/*");
		ok(scalar(@files) == 1, "Unexpected files leftover: " . join(" ", @files));

		done_testing;
	}
}

done_testing;

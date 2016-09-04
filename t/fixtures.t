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

my @fixtures = glob('t/fixtures/*/*.in');

$File::StripNondeterminism::canonical_time = 1423159771;

foreach my $filename (@fixtures) {
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
		foreach (my $i = 0; $i < @stat_after; $i++) {
			next if (
				$i == 7 # size
				|| $i == 8 # atime
				|| $i == 9 # mtime
				|| $i == 10 # ctime
			);
			is($stat_before[$i], $stat_after[$i], "$filename: stat[$i]");
		}

		ok(compare($in, $out) == 0, "Got expected output");

		my @files = glob("$temp/*");
		ok(scalar(@files) == 1, "Unexpected files leftover: " . join(" ", @files));

		done_testing;
	}
}

done_testing;

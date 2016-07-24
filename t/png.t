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

use File::Basename qw(basename);
use File::Compare qw(compare);
use File::Copy qw(copy);
use File::Temp qw(tempdir);
use File::StripNondeterminism;
use Test::More;

$dir = tempdir( CLEANUP => 1 );

my @fixtures = glob('t/fixtures/png/*.in.png');
plan tests => scalar @fixtures;

foreach (@fixtures) {
	my $name = basename($_, '.in.png');
	my $path = "$dir/$name.in.png";

	copy("t/fixtures/png/$name.in.png", $path) or die "Copy failed: $!";

	$normalizer = File::StripNondeterminism::get_normalizer_for_file($path);
	$normalizer->($path);

	ok(compare($path, "t/fixtures/png/$name.out.png") == 0, $name);
}

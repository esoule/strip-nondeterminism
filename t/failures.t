#!perl

#
# Copyright 2017 Chris Lamb <lamby@debian.org>
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
use File::Copy qw(copy);
use File::Temp qw(tempdir);
use File::StripNondeterminism;
use Test::More;

File::StripNondeterminism::init();

my $temp = tempdir( CLEANUP => 1 );
my @failures = glob('t/failures/*/*');

plan tests => scalar @failures;

foreach my $filename (@failures) {
	my $in = $temp . "/" . basename($filename);
	copy($filename, $in) or die "Copy failed: $!";

	eval {
		my $normalizer = File::StripNondeterminism::get_normalizer_for_file($in);
		$normalizer->($in);
	};
	ok($@ ne "");
}

done_testing;

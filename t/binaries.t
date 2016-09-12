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

use Test::More;

my %BINARIES = (
	'bin/strip-nondeterminism --help' => 0,
	'bin/dh_strip_nondeterminism --help' => 1,
);

plan tests => scalar keys %BINARIES;

foreach my $cmd (sort keys %BINARIES) {
	my $expected = $BINARIES{$cmd};
	system("$cmd >/dev/null 2>&1");
	my $ret = $? >> 8;

	ok($ret == $expected, "$cmd returns $ret");
}

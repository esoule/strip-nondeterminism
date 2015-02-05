#!perl

#
# Copyright 2015 Chris Lamb <lamby@debian.org>
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

use File::Temp 'tempdir';
use Test::More tests => 2;
use File::StripNondeterminism;

$dir = tempdir( CLEANUP => 1 );
$path = "$dir/test.reg";

open(my $fh, '>', $path) or die("error opening $path");
print $fh 'a:1:{s:13:"_lastmodified";i:1422064771;}';
close $fh;

$normalizer = File::StripNondeterminism::get_normalizer_for_file($path);
isnt(undef, $normalizer);
$normalizer->($path);

open FILE,$path or die("error opening $path");
is(<FILE>, 'a:1:{s:13:"_lastmodified";i:0;}');

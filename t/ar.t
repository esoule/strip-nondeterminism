#!perl

#
# Copyright 2015 Andrew Ayer
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
use Test::More tests => 3;
use File::StripNondeterminism;

my $ORIGINAL = <<'EOF';
!<arch>
afile/          1425249797  501   501   100600  1136      `
cerebral atrophy, n:
	The phenomena which occurs as brain cells become weak and sick, and
impair the brain's performance.  An abundance of these "bad" cells can cause
symptoms related to senility, apathy, depression, and overall poor academic
performance.  A certain small number of brain cells will deteriorate due to
everday activity, but large amounts are weakened by intense mental effort
and the assimilation of difficult concepts.  Many college students become
victims of this dread disorder due to poor habits such as overstudying.

cerebral darwinism, n:
	The theory that the effects of cerebral atrophy can be reversed
through the purging action of heavy alcohol consumption.  Large amounts of
alcohol cause many brain cells to perish due to oxygen deprivation.  Through
the process of natural selection, the weak and sick brain cells will die
first, leaving only the healthy cells.  This wonderful process leaves the
imbiber with a healthier, more vibrant brain, and increases mental capacity.
Thus, the devastating effects of cerebral atrophy are reversed, and academic
performance actually increases beyond previous levels.
bfile/          1425249797  501   501   100644  80        `
take forceful action:
	Do something that should have been done a long time ago.
cfile/          1425249797  501   501   100775  39        `
Don't Worry, Be Happy.
		-- Meher Baba

dfile/          1425249797  501   501   100664  256       `
"Well, well, well!  Well if it isn't fat stinking billy goat Billy Boy in
poison!  How art thou, thou globby bottle of cheap stinking chip oil?  Come
and get one in the yarbles, if ya have any yarble, ya eunuch jelly thou!"
		-- Alex in "Clockwork Orange"
EOF

my $STRIPPED = <<'EOF';
!<arch>
afile/          0           0     0     644     1136      `
cerebral atrophy, n:
	The phenomena which occurs as brain cells become weak and sick, and
impair the brain's performance.  An abundance of these "bad" cells can cause
symptoms related to senility, apathy, depression, and overall poor academic
performance.  A certain small number of brain cells will deteriorate due to
everday activity, but large amounts are weakened by intense mental effort
and the assimilation of difficult concepts.  Many college students become
victims of this dread disorder due to poor habits such as overstudying.

cerebral darwinism, n:
	The theory that the effects of cerebral atrophy can be reversed
through the purging action of heavy alcohol consumption.  Large amounts of
alcohol cause many brain cells to perish due to oxygen deprivation.  Through
the process of natural selection, the weak and sick brain cells will die
first, leaving only the healthy cells.  This wonderful process leaves the
imbiber with a healthier, more vibrant brain, and increases mental capacity.
Thus, the devastating effects of cerebral atrophy are reversed, and academic
performance actually increases beyond previous levels.
bfile/          0           0     0     644     80        `
take forceful action:
	Do something that should have been done a long time ago.
cfile/          0           0     0     755     39        `
Don't Worry, Be Happy.
		-- Meher Baba

dfile/          0           0     0     644     256       `
"Well, well, well!  Well if it isn't fat stinking billy goat Billy Boy in
poison!  How art thou, thou globby bottle of cheap stinking chip oil?  Come
and get one in the yarbles, if ya have any yarble, ya eunuch jelly thou!"
		-- Alex in "Clockwork Orange"
EOF

my $STRIPPED_WITH_TIME = <<'EOF';
!<arch>
afile/          1409289384  0     0     644     1136      `
cerebral atrophy, n:
	The phenomena which occurs as brain cells become weak and sick, and
impair the brain's performance.  An abundance of these "bad" cells can cause
symptoms related to senility, apathy, depression, and overall poor academic
performance.  A certain small number of brain cells will deteriorate due to
everday activity, but large amounts are weakened by intense mental effort
and the assimilation of difficult concepts.  Many college students become
victims of this dread disorder due to poor habits such as overstudying.

cerebral darwinism, n:
	The theory that the effects of cerebral atrophy can be reversed
through the purging action of heavy alcohol consumption.  Large amounts of
alcohol cause many brain cells to perish due to oxygen deprivation.  Through
the process of natural selection, the weak and sick brain cells will die
first, leaving only the healthy cells.  This wonderful process leaves the
imbiber with a healthier, more vibrant brain, and increases mental capacity.
Thus, the devastating effects of cerebral atrophy are reversed, and academic
performance actually increases beyond previous levels.
bfile/          1409289384  0     0     644     80        `
take forceful action:
	Do something that should have been done a long time ago.
cfile/          1409289384  0     0     755     39        `
Don't Worry, Be Happy.
		-- Meher Baba

dfile/          1409289384  0     0     644     256       `
"Well, well, well!  Well if it isn't fat stinking billy goat Billy Boy in
poison!  How art thou, thou globby bottle of cheap stinking chip oil?  Come
and get one in the yarbles, if ya have any yarble, ya eunuch jelly thou!"
		-- Alex in "Clockwork Orange"
EOF

my $dir = tempdir(CLEANUP => 1) or die "tempdir failed: $!";
my $path1 = "$dir/files1.a";
my $path2 = "$dir/files2.a";
my $fh;

for my $path ($path1, $path2) {
	open($fh, '>', $path) or die("error opening $path");
	binmode $fh;
	print $fh $ORIGINAL;
	close $fh;
}

# Test 1: make sure normalizer was found
my $normalizer = File::StripNondeterminism::get_normalizer_for_file($path1);
isnt(undef, $normalizer);

# Test 2: normalize without a canonical time
$normalizer->($path1);
open($fh, '<', $path1) or die("error opening $path1");
binmode $fh;
is(do { local $/; <$fh> }, $STRIPPED);
close $fh;

# Test 3: normalize with a canonical time
$File::StripNondeterminism::canonical_time = 1409289384;
$normalizer->($path2);

open($fh, '<', $path2) or die("error opening $path2");
binmode $fh;
is(do { local $/; <$fh> }, $STRIPPED_WITH_TIME);
close $fh;

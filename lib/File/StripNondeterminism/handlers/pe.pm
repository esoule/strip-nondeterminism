#
# Copyright 2014 Chris West (Faux)
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
package File::StripNondeterminism::handlers::pe;

use strict;
use warnings;

use Fcntl ":seek";

sub normalize {
	my ($filename) = @_;
	open(my $f, "+<", $filename) or die("couldn't open $filename: $!");
	binmode($f);
	read($f, my $mx, 2) or die("couldn't try to read initial header: $!");
	return if ($mx ne 'MZ');

	seek($f, 0x3A, SEEK_CUR) or die("couldn't jump to e_lfanew location: $!");
	read($f, my $encoded_off, 4) or die("couldn't read e_lfanew field: $!");
	my $off = unpack("V", $encoded_off);
	seek($f, $off, SEEK_SET) or die("couldn't seek to start of PE section: $!");

	read($f, my $pe, 2) or die("couldn't read PE header: $!");
	return if $pe ne 'PE';

	seek($f, 2+2+2, SEEK_CUR) or die("couldn't skip mMachine and mNumberOfSections: $!");
	read($f, my $encoded_time, 4) or die("couldn't read timestamp: $!");
	my $time = unpack("V", $encoded_time);

	$encoded_time = pack("V", $File::StripNondeterminism::canonical_time // 0);

	seek($f, -4, SEEK_CUR) or die("impossibly couldn't seek to where we were before: $!");
	print $f $encoded_time;
	close($f) or die("couldn't close file: $!");
}

1;

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
package StripNondeterminism::handlers::jar;

use strict;
use warnings;

use Archive::Zip;
use StripNondeterminism::handlers::zip;

sub _jar_filename_cmp ($$) {
	my ($a, $b) = @_;
	# META-INF/ and META-INF/MANIFEST.MF are expected to be the first entries in the Zip archive.
	return 0 if $a eq $b;
	for (qw{META-INF/ META-INF/MANIFEST.MF}) {
		return -1 if $a eq $_;
		return  1 if $b eq $_;
	}
	return $a cmp $b;
}

sub normalize {
	my ($jar_filename) = @_;
	return StripNondeterminism::handlers::zip::normalize($jar_filename, \&_jar_filename_cmp);
}

1;

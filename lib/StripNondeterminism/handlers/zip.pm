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
package StripNondeterminism::handlers::zip;

use strict;
use warnings;

use Archive::Zip;

# A magic number from Archive::Zip for the earliest timestamp that
# can be represented by a Zip file.  From the Archive::Zip source:
# "Note, this isn't exactly UTC 1980, it's 1980 + 12 hours and 1
# minute so that nothing timezoney can muck us up."
use constant SAFE_EPOCH => 315576060;

sub normalize {
	my ($zip_filename, $filename_cmp) = @_;
	$filename_cmp ||= sub { $a cmp $b };
	my $zip = Archive::Zip->new($zip_filename);
	my @filenames = sort $filename_cmp $zip->memberNames();
	for my $filename (@filenames) {
		my $member = $zip->removeMember($filename);
		$zip->addMember($member);
		$member->setLastModFileDateTimeFromUnix(SAFE_EPOCH);
	}
	$zip->overwrite();
}

1;

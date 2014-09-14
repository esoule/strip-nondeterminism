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

use File::Temp;
use Archive::Zip qw/:CONSTANTS :ERROR_CODES/;

# A magic number from Archive::Zip for the earliest timestamp that
# can be represented by a Zip file.  From the Archive::Zip source:
# "Note, this isn't exactly UTC 1980, it's 1980 + 12 hours and 1
# minute so that nothing timezoney can muck us up."
use constant SAFE_EPOCH => 315576060;

# Extract and return the first $nbytes of $member (an Archive::Zip::Member)
sub peek_member {
	my ($member, $nbytes) = @_;
	my $old_compression_method = $member->desiredCompressionMethod(COMPRESSION_STORED);
	$member->rewindData() == AZ_OK or die "failed to rewind ZIP member";
	my ($buffer, $status) = $member->readChunk($nbytes);
	die "failed to read ZIP member" if $status != AZ_OK && $status != AZ_STREAM_END;
	$member->endRead();
	$member->desiredCompressionMethod($old_compression_method);
	return $$buffer;
}

# Normalize the contents of $member (an Archive::Zip::Member) with $normalizer
sub normalize_member {
	my ($member, $normalizer) = @_;

	# Extract the member to a temporary file.
	my $tempdir = File::Temp->newdir();
	my $filename = "$tempdir/member";
	$member->extractToFileNamed($filename);

	# Normalize the temporary file.
	if ($normalizer->($filename)) {
		# Normalizer modified the temporary file.
		# Replace the member's contents with the temporary file's contents.
		open(my $fh, '<', $filename) or die "Unable to open $filename: $!";
		$member->contents(do { local $/; <$fh> });
	}

	unlink($filename);
}

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
	return 1;
}

1;

#
# Copyright 2021 Chris Lamb <lamby@debian.org>
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
package File::StripNondeterminism::handlers::pyzip;

use strict;
use warnings;

use File::StripNondeterminism;
use File::StripNondeterminism::Common qw(copy_data);
use File::Basename;
use File::StripNondeterminism::handlers::zip;
use File::Temp;
use Fcntl q/SEEK_SET/;

=head1 ABOUT

Python supports running .zip'd .py files:

	$ cat __main__.py
	#!/usr/bin/python3
	print("Hello World")
	$ zip pyzip.zip __main__.py
	$ head -1 __main__.py | cat - pyzip.zip > pyzip
	$ chmod a+x pyzip 

They require special handling to not mangle the shebang.

=head1 DEPRECATION PLAN

Unclear, as many tools can, after all, generate these .zip files.

=cut

sub is_pyzip_file {
	my ($filename) = @_;

	my $fh;
	my $str;

	return
	  open($fh, '<', $filename)
	  && read($fh, $str, 32)
	  && $str =~ /^#!.*\n\x{50}\x{4b}\x{03}\x{04}/s;
}

sub normalize {
	my ($filename) = @_;

	my $buf;

	# Create a .zip file without the shebang
	my $stripped = File::Temp->new(DIR => dirname($filename));
	open my $fh, '<', $filename;

	# Save the shebang for later
	my $shebang = <$fh>; 

	# Copy through the rest of the file
	while (read($fh, $buf, 4096) // die "$filename: read failed: $!") {
		print $stripped $buf;
	}
	$stripped->close;
	close $fh;

	# Normalize the stripped version
	my $modified = File::StripNondeterminism::handlers::zip::normalize(
		$stripped->filename
	);

	# If we didnt change anything, no need to mess around with a new file
	return 0 if not $modified;

	# Create a file with the existing shebang
	my $pyzip = File::Temp->new(DIR => dirname($filename));
	print $pyzip $shebang;
	open $fh, '<', $stripped->filename;
	while (read($fh, $buf, 4096)) {
		print $pyzip $buf;
	}
	close $fh;
	$pyzip->close;

	# Copy the result, preserving the attributes of the original
	copy_data($pyzip->filename, $filename)
	  or die "$filename: unable to overwrite: copy_data: $!";

	return 1;
}

1;

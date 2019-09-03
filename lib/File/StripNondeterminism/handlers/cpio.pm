# Copyright © 2017 Bernhard M. Wiedemann <bmwiedemann@opensuse.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package File::StripNondeterminism::handlers::cpio;

use strict;
use warnings;

use File::StripNondeterminism;

=head1 DEPRECATION PLAN

This was added in mid-2017. As-of 2020-04-30, Debian ships a total of 8 .cpio
files in binary packages and none of these appear to be integral to the working
of those package.

After consulting with the original (Bernhard, ie. OpenSuse) this handler is a
good candidate to commence deprecation via initially making it optional.

=cut

sub normalize {
	my ($file) = @_;
	# if we cannot load the Cpio module, we just leave the file alone
	# to not have Archive::Cpio as a hard requirement
	# for strip-nondeterminism
	if (not eval {require Archive::Cpio}) {
		if ($File::StripNondeterminism::verbose) {
			print STDERR "Archive::Cpio not found\n";
		}
		return 0;
	}
	my $cpio = Archive::Cpio->new;
	eval {$cpio->read($file)};
	return 0 if $@; # not a cpio archive if it throws an error
	foreach my $e ($cpio->get_files()) {
		$e->{mtime} = $File::StripNondeterminism::canonical_time;
	}
	$cpio->write($file);
	return 1;
}

1;

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
package StripNondeterminism;

use strict;
use warnings;

use StripNondeterminism::handlers::ar;
use StripNondeterminism::handlers::gzip;
use StripNondeterminism::handlers::jar;
use StripNondeterminism::handlers::zip;

our($VERSION);

$VERSION = '0.001'; # 0.001

sub _get_file_type {
	my $file=shift;
	open (FILE, '-|') # handle all filenames safely
		|| exec('file', $file)
		|| die "can't exec file: $!";
	my $type=<FILE>;
	close FILE;
	return $type;
}

sub get_normalizer_for_file {
	$_ = shift;

	return undef if -d $_; # Skip directories

	# ar
	if (m/\.a$/ && _get_file_type($_) =~ m/ar archive/) {
		return \&StripNondeterminism::handlers::ar::normalize;
	}
	# gzip
	if (m/\.gz$/ && _get_file_type($_) =~ m/gzip compressed data/) {
		return \&StripNondeterminism::handlers::gzip::normalize;
	}
	# jar
	if (m/\.jar$/ && _get_file_type($_) =~ m/Zip archive data/) {
		return \&StripNondeterminism::handlers::jar::normalize;
	}
	# zip
	if (m/\.zip$/ && _get_file_type($_) =~ m/Zip archive data/) {
		return \&StripNondeterminism::handlers::zip::normalize;
	}
	return undef;
}

sub get_normalizer_by_name {
	$_ = shift;
	return \&StripNondeterminism::handlers::ar::normalize if $_ eq 'ar';
	return \&StripNondeterminism::handlers::gzip::normalize if $_ eq 'gzip';
	return \&StripNondeterminism::handlers::jar::normalize if $_ eq 'jar';
	return \&StripNondeterminism::handlers::zip::normalize if $_ eq 'zip';
	return undef;
}

1;

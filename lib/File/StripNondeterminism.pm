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
package File::StripNondeterminism;

use strict;
use warnings;

use File::StripNondeterminism::handlers::ar;
use File::StripNondeterminism::handlers::gettext;
use File::StripNondeterminism::handlers::gzip;
use File::StripNondeterminism::handlers::jar;
use File::StripNondeterminism::handlers::javadoc;
use File::StripNondeterminism::handlers::pearregistry;
use File::StripNondeterminism::handlers::png;
use File::StripNondeterminism::handlers::javaproperties;
use File::StripNondeterminism::handlers::zip;

our($VERSION, $canonical_time, $clamp_time);

$VERSION = '0.022'; # 0.022

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
		return \&File::StripNondeterminism::handlers::ar::normalize;
	}
	# gettext
	if (m/\.g?mo$/ && _get_file_type($_) =~ m/GNU message catalog/) {
		return \&File::StripNondeterminism::handlers::gettext::normalize;
	}
	# gzip
	if (m/\.(gz|dz)$/ && _get_file_type($_) =~ m/gzip compressed data/) {
		return \&File::StripNondeterminism::handlers::gzip::normalize;
	}
	# jar
	if (m/\.(jar|war|hpi)$/ && _get_file_type($_) =~ m/(Java|Zip) archive data/) {
		return \&File::StripNondeterminism::handlers::jar::normalize;
	}
	# javadoc
	if (m/\.html$/ && File::StripNondeterminism::handlers::javadoc::is_javadoc_file($_)) {
		return \&File::StripNondeterminism::handlers::javadoc::normalize;
	}
	# pear registry
	if (m/\.reg$/ && File::StripNondeterminism::handlers::pearregistry::is_registry_file($_)) {
		return \&File::StripNondeterminism::handlers::pearregistry::normalize;
	}
	# PNG
	if (m/\.png$/ && _get_file_type($_) =~ m/PNG image data/) {
		return \&File::StripNondeterminism::handlers::png::normalize;
	}
	# pom.properties, version.properties
	if (m/(pom|version)\.properties$/ && File::StripNondeterminism::handlers::javaproperties::is_java_properties_file($_)) {
		return \&File::StripNondeterminism::handlers::javaproperties::normalize;
	}
	# zip
	if (m/\.(zip|pk3|epub|whl|xpi|htb|zhfst)$/ && _get_file_type($_) =~ m/Zip archive data|EPUB document/) {
		return \&File::StripNondeterminism::handlers::zip::normalize;
	}
	return undef;
}

sub get_normalizer_by_name {
	$_ = shift;
	return \&File::StripNondeterminism::handlers::ar::normalize if $_ eq 'ar';
	return \&File::StripNondeterminism::handlers::gettext::normalize if $_ eq 'gettext';
	return \&File::StripNondeterminism::handlers::gzip::normalize if $_ eq 'gzip';
	return \&File::StripNondeterminism::handlers::jar::normalize if $_ eq 'jar';
	return \&File::StripNondeterminism::handlers::javadoc::normalize if $_ eq 'javadoc';
	return \&File::StripNondeterminism::handlers::pearregistry::normalize if $_ eq 'pearregistry';
	return \&File::StripNondeterminism::handlers::png::normalize if $_ eq 'png';
	return \&File::StripNondeterminism::handlers::javaproperties::normalize if $_ eq 'javaproperties';
	return \&File::StripNondeterminism::handlers::zip::normalize if $_ eq 'zip';
	return undef;
}

1;

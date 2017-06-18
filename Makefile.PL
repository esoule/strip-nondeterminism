use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MMVER = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
	NAME		=> 'File::StripNondeterminism',
	AUTHOR => [
		'Andrew Ayer <agwa@andrewayer.name>',
		'Chris Lamb <lamby@debian.org>'
	],
	VERSION_FROM	=> 'lib/File/StripNondeterminism.pm',
	ABSTRACT	=> 'tool for stripping nondeterminism from files',
	EXE_FILES	=> [qw(bin/dh_strip_nondeterminism bin/strip-nondeterminism)],
	PREREQ_PM => {
		'Archive::Cpio'	=> 0, # required to pass tests
		'Archive::Zip'	=> 0,
		'Getopt::Long'	=> 0,
	},
	LICENSE		=> "gpl",
	dist		=> { COMPRESS => 'gzip -9nf', SUFFIX => 'gz', },
	clean		=> { FILES => 'StripNondeterminism-*' },
);

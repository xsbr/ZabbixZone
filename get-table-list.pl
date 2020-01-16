#!/usr/bin/env perl
# NAME
#     get-table-list.pl - List current and historic Zabbix database tables
#
# SYNOPSIS
#     This is mainly a helper script for developing the backup script.
#
#     It connects to svn://svn.zabbix.com (using Subversion client "svn") and
#     fetches the schema definitions of all tagged Zabbix versions beginning
#     from 1.3.1 (this takes a while).
#
#     It then prints out a list of all tables together with the first and last
#     Zabbix version where they were used.
#
# HISTORY
#     v0.1 - 2014-09-19 First version
#
# AUTHOR
#     Jens Berthold (maxhq), 2020
use strict;
use warnings;

use version;

my $REPO = 'https://git.zabbix.com/scm/zbx/zabbix.git';
my $REPO_WEB = 'https://git.zabbix.com/projects/ZBX/repos/zabbix/raw';
my $tabinfo = {};     # for each table, create a list of Zabbix versions that know it
my $tabinfo_old = {}; # old data from zabbix_dump

sub stop {
	my ($msg) = @_;
	print "ERROR: $msg\n";
	exit;
}

# sort version numbers correctly
sub cmpver {
	my ($a, $b) = @_;

	# split version parts: 1.2.3rc1 --> 1  2  3rc1
	my @a_parts = split /\./, $a;
	my @b_parts = split /\./, $b;

	for (my $i=0; $i<scalar(@a_parts); $i++) {
		return 1 if $i >= scalar(@b_parts);
		# split number parts: 3rc1 --> 3  rc  1
		my ($a_num, $a_type, $a_idx) = $a_parts[$i] =~ m/^(\d+)(\D+)?(\d+)?$/;
		my ($b_num, $b_type, $b_idx) = $b_parts[$i] =~ m/^(\d+)(\D+)?(\d+)?$/;
		my $cmp;
		# 3 before 4
		$cmp = $a_num <=> $b_num;   return $cmp unless $cmp == 0;
		# 3rc1 before 3
		return -1 if     $a_type and not $b_type;
		return  1 if not $a_type and     $b_type;
		# a1 before b1
		$cmp = ($a_type//"") cmp ($b_type//""); return $cmp unless $cmp == 0;
		# rc1 before rc2
		$cmp = ($a_idx//0) <=> ($b_idx//0);   return $cmp unless $cmp == 0;
	}
	# 1.2 before 1.2.1
	return -1 if scalar(@a_parts) < scalar(@b_parts);
	# equal
	return 0;
}

# Read old table informations from zabbix-dump
open my $fh, '<', './zabbix-dump' or stop("Couldn't find 'zabbix-dump': $!");
my $within_data_section = 0;
while (<$fh>) {
    chomp;
    if (/^__DATA__/) { $within_data_section = 1; next }
    next unless $within_data_section;
    my ($table, $from, undef, $to, $mode) = split /\s+/;

    $tabinfo_old->{$table} = {
	    from => $from,
        to => $to,
        schema_only => ($mode//"") eq "SCHEMAONLY" ? 1 : 0,
	};
}

# Check for Git client
`which git` or stop("No Git client found");

# Get tag list from repo:
#	7f6b20903537b9bbf72fe2b75ab7fac557856aad	refs/tags/1.0
#	693709cc4a80777f7759856c853b38cbc920f068	refs/tags/1.1
print "Querying existing tags from $REPO...\n";
my @tags_raw = `git ls-remote -t $REPO`;
# remove trailing newline
chomp @tags_raw;
# skip release candidates, betas and tags like "zabicom-xxx"
@tags_raw = grep { m{ refs/tags/ \d+ \. \d+ ( \. \d+ )? $}x } @tags_raw;

# Create HashRef:
#   1.0 => 7f6b20903537b9bbf72fe2b75ab7fac557856aad
#   1.1 => 693709cc4a80777f7759856c853b38cbc920f068
my $tags = { map { m{^ (\w+) \s+ refs/tags/ (.*) $}x; $2 => $1 } @tags_raw };

# Loop over tags and read table schema
print "Reading table schemas...\n";
for my $tag (sort { cmpver($a,$b) } keys %$tags) {
	next if cmpver($tag, "1.3.1") < 0; # before Zabbix 1.3.1, schema was stored as pure SQL

	my $schema;
	my $subdir;

	printf " - %-8s %s", $tag, "Looking for schema...";
	# search in subdir /schema (<= 1.9.8) and /src for schema.(sql|tmpl)
	for my $sub (qw(schema src)) {
		# file list:
		#	100644 blob 1f0a05eb826dfcdb26f9429ad30c720454374ca1	data.tmpl
		#	100644 blob b98b5eecc62731508c09d9e76d7aed9d4eb201f2	schema.tmpl
		my @files_raw = `curl -s $REPO_WEB/create/$sub?at=refs%2Ftags%2F$tag`;
		next unless @files_raw; # directory not found?
		chomp @files_raw; # remove trailing newline
		my @files = map { /^ \d+ \s+ \w+ \s+ \w+ \s+ (.*) $/x; $1 } @files_raw;

		($schema) = grep /^schema\.(sql|tmpl)/, @files;
		$subdir = $sub;
		last;
	}
	if (!$schema) {
		print "\nNo schema found in tag $tag\n";
		next;
	}
	print " Processing ($schema)... ";
	my @table = `curl -s $REPO_WEB/create/$subdir/$schema?at=refs%2Ftags%2F$tag`;
	for (@table) {
		chomp;
		next unless m/^TABLE/;
		my (undef, $table) = split /\|/;
		$tabinfo->{$table} //= [];
		push @{$tabinfo->{$table}}, $tag;
	}
	print " Done\n";
}

#
# Print out results
#
print "\n\n";
print "TABLE                      FIRST USE  LAST USE  MODE\n";
print "----------------------------------------------------\n";
for my $tab (sort keys %$tabinfo) {
	my $mode = $tabinfo_old->{$tab}
		? ($tabinfo_old->{$tab}->{schema_only} ? '  SCHEMAONLY' : '')
		: '  <-- NEW TABLE! Only store schema?';
	printf "%-26s %-8s - %-8s%s\n", $tab, $tabinfo->{$tab}->[0], $tabinfo->{$tab}->[-1], $mode;
}

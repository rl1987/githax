#!/usr/bin/perl -w
use warnings;
use strict;

# Post-process git log output and remove every entry that does not
# contain a diff.
#
# The intended use-case is for you're using a log mode that generates
# patches for nontrivial merges but not for trivial ones: you'll want
# to mail out the messages that contain diffs, but not the ones that
# don't.

my $copying = 0;
my $waiting_for_commit = 1;

my @pending_lines = ();

while (<>) {
    my $is_commit = /^commit [0-9a-f]+/;
    if ($copying) {
	if (! $is_commit) {
	    print;
	    next;
	}
	$copying = 0;
    }
    @pending_lines = () if ($is_commit);

    push @pending_lines, $_;
    if (/^diff/) {
	$copying = 1;

	print @pending_lines;
	@pending_lines = ();
    }
}

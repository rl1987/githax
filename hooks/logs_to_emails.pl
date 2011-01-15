#!/usr/bin/perl -w
use warnings;
use strict;

# Turns git log output into formail input. Call "git log"
# with appropriate options, then pipe that into this script.  This
# script takes a subject prefix as an argument.
#
#  Suggested arguments for "git log" include:
#    -p
#    --stat
#    one of: -c, -m, --cc
#    --reverse
#
# Note that if you're using this with remove_empty_merges.pl, you need
# to put it in the pipeline _AFTER_ remove_empty_merges, since
# remove_empty_merges consumes and produces git log output, whereas
# this script consumes logs and produces emails.

# Suggested use in a commit script:
my $suggested_use = q[
    git log --reverse -p --stat --cc "$oldrev..$newrev" |
     remove_empty_merges.pl |
     log_to_emails.pl "$projectname/${refname#refs/heads/}" |
       formail -I "To: $recipients" \
               -I "From: $GL_USER@torproject.org" \
               -s /usr/bin/sendmail -t
] ;

# Deficiencies:
#   Doesn't do 003/231 counting in the subject line like format-patch does

my $waiting_for_commit = 1;
my $prefix = shift @ARGV;
if ($prefix) {
    $prefix = "[$prefix] ";
} else {
    $prefix = "";
}
my @headerlines;
my $commitnum;
my %headervals;
my $firsttime = 1;

while (<>) {
    if ($waiting_for_commit) {
	if (! /^commit ([0-9a-f]+)/) {
	    print;
	    next;
	}
	@headerlines = ();
	%headervals = ();
	$waiting_for_commit = 0;
	$commitnum = $1;
    }
    if (/^\S/ or /^\s*$/) {
	# in header. Accumulate names and values.
	push @headerlines, $_;
	chomp;
	if (/^(\w+):\s+(.*)/) {
	    $headervals{$1} = $2;
	}
	next;
    }
    # Done with header.  Generate a mail header and a commit header, then just
    # echo till the next ^commit.
    my $subject = $_;
    $subject =~ s/^\s+//;     $subject =~ s/\s+$//;

    print "\n\n" unless ($firsttime);
    $firsttime = 0;
    print "From $commitnum Mon Sep 17 00:00:00 2001\n";
    print "Patch-Author: $headervals{Author}\n";
    print "Subject: $prefix$subject\n\n";

    print @headerlines;
    $waiting_for_commit = 1;
    print $_;
}


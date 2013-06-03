#!/usr/bin/perl -w
# Copyright 2011-2013 The Tor Project, Inc -- License at end of file.
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
    TOTAL_N_COMMITS=`git log --pretty=format:oneline "$oldrev..$newrev" | wc -l`
    export TOTAL_N_COMMITS

    git log --reverse -p --stat --cc "$oldrev..$newrev" |
     remove_empty_merges.pl |
     logs_to_emails.pl "$projectname/${refname#refs/heads/}" |
       formail -I "To: $recipients" \
               -I "From: $GL_USER@torproject.org" \
               -s /usr/bin/sendmail -t
] ;

# Set the environment variable TOTAL_N_COMMITS if you want to get a
# nice 001/123 header in your commits.
my $NUM_COMMITS = $ENV{TOTAL_N_COMMITS} || "";

my $waiting_for_commit = 1;
my $prefix = shift @ARGV;
my @headerlines;
my $commitnum;
my %headervals;
my $firsttime = 1;
my $commit_idx = 0;

sub getprefix {
    my $curnum = shift @_;
    my $extra;
    if ($NUM_COMMITS eq "") {
	$extra = "#$curnum";
    } else {
	$extra = sprintf("%03d/%03d", $curnum, $NUM_COMMITS);
    }
    if ($prefix) {
	return "[$prefix $extra]";
    } else {
	return "[$extra]";
    }
}

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
    ++$commit_idx;
    print "From $commitnum Mon Sep 17 00:00:00 2001\n";
    print "From: $headervals{Author}\n";
    print "Patch-Author: $headervals{Author}\n";
    my $thisprefix = getprefix($commit_idx);
    print "Subject: $thisprefix $subject\n\n";

    print @headerlines;
    $waiting_for_commit = 1;
    print $_;
}

=head1 LICENSE

Copyright 2011-2013 The Tor Project, Inc.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.

    * Neither the names of the copyright owners nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

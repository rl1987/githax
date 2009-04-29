#!/usr/bin/perl -w

$from = "";
$subject = "";
$date = "";
$commit = "";

while(<>) {
  print;
  chomp;
  if (/^From ([A-Fa-f0-9]+)/) { $commit = $1; }
  elsif (/^From: (.*)/) { $from = $1; }
  elsif (/^Subject: \[[^\]]*\] *(.*)/) { $subject = $1; }
  elsif (/^Date: (.*)/) { $date = $1; }
  elsif (/^$/) {
      print "Author: $from\nDate: $date\nSubject: $subject\n";
      print "Commit: $commit\n\n";
      last;
  }
}

while(<>)  { print; }

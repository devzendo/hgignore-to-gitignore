#!/usr/bin/env perl
#
# Converts .hgignore to .gitignore as best it can.
# .hgignore syntax: https://www.selenic.com/mercurial/hgignore.5.html#syntax
# .gitignore syntax: https://git-scm.com/docs/gitignore
#  uses globs: https://en.wikipedia.org/wiki/Glob_(programming)
#
# Matt Gumbley, Feb 2020
# matt.gumbley@gmail.com
# @mattgumbley
#
use warnings;
use strict;
no strict 'refs';

my $hi = '.hgignore';
my $gi = '.gitignore';
die "No $hi in the current directory\n" unless -f $hi;
die "$gi already exists in the current directory\n" if -f $gi;

open (my $hfh, "<", $hi) or die "Can't open $hi: $!\n";
open (my $gfh, ">", $gi) or die "Can't create $gi: $!\n";

my $lineno = 0;
my $syntax = 'regexp';
while (<$hfh>) {
  chomp;
  $lineno++;
  my $line = $_;
  #print "line [$line]\n";
  if ($line =~ /^\s*$/) {
    print $gfh "$_\n";
    next;
  }

  if ($line =~ /^syntax\s*:\s*(\S+)/) {
    $syntax = lc($1);
    die "Unknown syntax '$syntax' on line $lineno of $hi\n" if ($syntax !~ /(glob|regexp)/);
    next;
  }

  if ($line =~ /^((?:\S|\\#)+)(\s*#.*)?\s*$/) {
    my ($content, $comment) = ($1, $2);
    $comment ||= '';
    #print "$syntax [$content] comment [$comment]\n";
    my $handler = "handle_$syntax";
    &$handler($content, $comment);
    next;
  }

  print "Don't know how to handle line $lineno [$line]\n";
}

close $gfh;
close $hfh;

sub handle_regexp {
  my ($content, $comment) = (@_);
  # Of course regexps can be very complex, so just translate the basics into
  # what a glob can encompass..
  # What in a regexp can be transformed to the glob's * . ? [abc] [a-z] ?
  $content =~ s/[\^\$]//g;      # remove anchors
  $content =~ s/\.\*/*/g;       # .* -> *
  $content =~ s/\./?/g;         # .  -> ?
  $content =~ s/\\././g;        # \. -> .
  $content =~ s/(\[.+?\])/$1/g; # [abc] -> [abc]   or [a-z] -> [a-z]
  print $gfh "$content$comment\n";
}

sub handle_glob {
  my ($content, $comment) = (@_);
  # Pass it through - hg uses 'shell style' globs; git uses these with more
  # features, so hopefully the less funky hg globs will be handled just fine.
  print $gfh "$content$comment\n";
}

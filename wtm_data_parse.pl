#!/user/bin/perl -w
use strict;
use warnings;
use HTML::TableExtract;

package MyParser;
use base qw(HTML::Parser);

my $my_html = "wtm_out.html";
my $my_output = "index.html";

# package main;
# my $parser = MyParser->new;
# $parser->parse_file($my_html);

my $te = HTML::TableExtract->new( attribs => { class => "grid" } );
$te->parse_file($my_html);
foreach my $ts ($te->tables) {
#  print "Table named grid found at ", join(',', $ts->coords), ":\n";
# my $table_tree = $ts->tree;
  print "Net Sales1: " . $ts->cell(1,1) . "\n"; 
#  foreach my $row ($ts->rows) {
#     print "   ", join(',', @$row), "\n";
#  }
}


#!/user/bin/perl -w

use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;

# Get yesterday's date for the report. Fuckin' a!
use DateTime qw();
my $report_date = DateTime->now(time_zone => 'America/Los_Angeles');
$report_date = $report_date->subtract(days => 1);
$report_date = $report_date->strftime('%d-%m-%Y');
#print $report_date . "\n";

# my $outfile = "/home/gene/projects/perl/wtm/wtm_out.html";
my $outfile = "/home/gene/projects/perl/wtm/wtm_notify.html";

# Set user agent to avoid the dreaded lack-of-Flash bullshit. 
my $my_user_agent = 'Mozilla/5.0 (Linux; U; Android 2.2; de-de; HTC Desire HD 1.18.161.2 Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';

# URL for login.
my $url = "https://my.whentomanage.com/login.php";
# URL sets the Chico store.
my $url2 = "https://my.whentomanage.com/change_store_redirect.php?store_id=8574";

# URL for the actual report. Day,%20Mmm%20DD,%20YYYY. e.g. Sun,%20May%2022,%202016

# A date format of dd-mm-yyyy works!
my $url3 = "https://my.whentomanage.com/reports/report.php?id=162&user_params=true&loading=&use_dev_code=&basic_date_range%5Bstart%5D=" . $report_date . "&basic_date_range%5Bend%5D=" . $report_date . "&employee_id_or_all=all&runit=submit&output_as=grid&inline=&employee_id_or_all_textlabel=All+Employees&";

my $username = "geneh";
my $password = "gene22";
my $location = "Cheesesteak";
my $mech = WWW::Mechanize->new( agent => $my_user_agent );
$mech->cookie_jar(HTTP::Cookies->new());
$mech->get($url);
$mech->submit_form(
    form_number => 1,
    fields      => { 
        action   => "login",
        login    => $username,
        password => $password,
        locationid => $location,
        rememberme => "0"
    },
    );

$mech->get($url2);
$mech->get($url3);

# Get HTML content of report.
my $html_string = $mech->content();
#print $html_string;

# Open output file.
open(OUTFILE, ">$outfile");
#binmode(OUTFILE, ":utf8");
#print OUTFILE "$html_string";

# Begin parsing of HTML to retrieve TABLE DATA element.
use HTML::TableExtract;

# Define which table to locate. Parse.
my $te = HTML::TableExtract->new( attribs => { class => "grid" } );
$te->parse($html_string);

# Only 1 table, but whatever... 
foreach my $ts ($te->tables) {
#    print "Table named grid found at ", join(',', $ts->coords), ":\n";
#    print "Employee : " . $ts->cell(1,0) . "\n";
#    print "Hours    : " . $ts->cell(2,4) . "\n";
#    print "Employee : " . $ts->cell(4,0) . "\n";
#    print "Hours    : " . $ts->cell(5,4) . "\n";
#    print OUTFILE $ts->cell(1,1) . "     " . $ts->cell(2,1) . "     " . $ts->cell(3,2);

# Count rows in table. 
  my $num_rows = 0;
  foreach my $row ($ts->rows) {
#     print "   ", join(',', @$row), "\n";
    $num_rows++;
  }

# Hours data is every 3rd row. Want to go thru all rows minus the last 3
#   because it's the summary line.
  for (my $i=2; $i<$num_rows-3; $i+=3) {
#    print $ts->cell($i-1,0) . ": " . $ts->cell($i,4) . "\n";

    # Are the hours more than 8? If so, write it to file. 
    if($ts->cell($i,4) > 8) {
#      print "OT: " . $ts->cell($i-1,0) . " " . $ts->cell($i,4) . "\n";
      print OUTFILE "OT: " . $ts->cell($i-1,0) . " " . $ts->cell($i,4) . "\n";
    }


  }
}

close(OUTFILE);

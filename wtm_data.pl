#!/user/bin/perl -w

use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;

# Get today's date for the report.
use DateTime qw();
my $report_date = DateTime->now(time_zone => 'America/Los_Angeles');
$report_date = $report_date->strftime('%d-%m-%Y');

my $outfile = "/home/gene/projects/perl/wtm/wtm_data.html";

# Set user agent to avoid the dreaded lack-of-Flash bullshit. 
my $my_user_agent = 'Mozilla/5.0 (Linux; U; Android 2.2; de-de; HTC Desire HD 1.18.161.2 Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';

# URL for login.
my $url = "https://my.whentomanage.com/login.php";
# URL sets the Chico store.
my $url2 = "https://my.whentomanage.com/change_store_redirect.php?store_id=8574";
# URL for the actual report. Day,%20Mmm%20DD,%20YYYY. e.g. Sun,%20May%2022,%202016
# my $url3 = "https://my.whentomanage.com/reports/report.php?id=101276&output_as=grid&basic_date_range=&basic_date_range%5Bstart%5D=Sun,%20May%2022,%202016&basic_date_range%5Bend%5D=Sun,%20May%2022,%202016&";

# A date format of dd-mm-yyyy works!
my $url3 = "https://my.whentomanage.com/reports/report.php?id=101276&output_as=grid&basic_date_range=&basic_date_range%5Bstart%5D=" . $report_date . "&basic_date_range%5Bend%5D=" . $report_date . "&";

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
#print $output_page;

# Open output file.
open(OUTFILE, ">$outfile");
#binmode(OUTFILE, ":utf8");

# Begin parsing of HTML to retrieve TABLE DATA element.
use HTML::TableExtract;

# Define which table to locate. Parse.
my $te = HTML::TableExtract->new( attribs => { class => "grid" } );
$te->parse($html_string);

# Only 1 table, but whatever... 
foreach my $ts ($te->tables) {
#    print "Table named grid found at ", join(',', $ts->coords), ":\n";
#    print "Net Sales: " . $ts->cell(1,1) . "\n";
#    print "Labor    : " . $ts->cell(2,1) . "\n";
#    print "Discounts: " . $ts->cell(3,2) . "\n";
    print OUTFILE "S: " . $ts->cell(1,1) . "     L: " . $ts->cell(2,1) . "     D: " . $ts->cell(4,2) . "     O: " . $ts->cell(3,1) . "/" . $ts->cell(3,2);
}

#print OUTFILE "$output_page";
close(OUTFILE);

#!/user/bin/perl -w

use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;
use Date::Calc qw(Day_of_Week); # For DOW figuring

# Get today's date for the report.
use DateTime qw();
my $report_date = DateTime->now(time_zone => 'America/Los_Angeles');
my $report_time = $report_date->strftime('%I:%M%p');
$report_date = $report_date->strftime('%d-%m-%Y');
#$report_date = '12-07-2016';

# Define in/out files
my $html_outfile_hourly = "/home/gene/projects/perl/wtm/wtm_history.html";
my $outfile_hourly = "/home/gene/projects/perl/wtm/wtm_history.png";
my $tmpl_infile_hourly = "/home/gene/projects/perl/wtm/google_history_chart.tmpl";
my $html_chart = "files.asskick.com:8080/wtm_data/wtm_history.html";


# Set user agent to avoid the dreaded lack-of-Flash bullshit. 
my $my_user_agent = 'Mozilla/5.0 (Linux; U; Android 2.2; de-de; HTC Desire HD 1.18.161.2 Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';

# URL for login.
my $url = "https://my.whentomanage.com/login.php";
# URL sets the Chico store.
my $url2 = "https://my.whentomanage.com/change_store_redirect.php?store_id=8574";
# URL for the actual report. Day,%20Mmm%20DD,%20YYYY. e.g. Sun,%20May%2022,%202016
# my $url3 = "https://my.whentomanage.com/reports/report.php?id=101276&output_as=grid&basic_date_range=&basic_date_range%5Bstart%5D=Sun,%20May%2022,%202016&basic_date_range%5Bend%5D=Sun,%20May%2022,%202016&";

# A date format of dd-mm-yyyy works!
#my $url3 = "https://my.whentomanage.com/reports/report.php?id=101453&output_as=grid&basic_date_range=&basic_date_range%5Bstart%5D=" . $report_date . "&basic_date_range%5Bend%5D=" . $report_date . "&";

my $url3 = "https://my.whentomanage.com/reports/report.php?id=101516&user_params=true&loading=&use_dev_code=&start_date=" . $report_date . "&runit=submit&output_as=grid&inline=";

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

# Begin parsing of HTML to retrieve TABLE DATA element.
use HTML::TableExtract;

# Define which table to locate. Parse.
my $te = HTML::TableExtract->new( attribs => { class => "grid" } );
$te->parse($html_string);

# Output string for chart data
my $chart_data;

# Totals
my $chart_total_sales;
my $chart_total_labor;
my $chart_total_labor_percent;

# Number of days
my $num_days = 7;

# Only 1 table, but whatever... 
foreach my $ts ($te->tables) {
#    print "Table named grid found at ", join(',', $ts->coords), ":\n";
#    print "1st: " . $ts->cell(0,0) . "\n";
#    print "2nd: " . $ts->cell(0,1) . "\n";
#    print "3rd: " . $ts->cell(0,2) . "\n";
#    print "4th: " . $ts->cell(0,3) . "\n";
#    print "5th: " . $ts->cell(0,4) . "\n";
#    print "6th: " . $ts->cell(0,5) . "\n";
#    print "7th: " . $ts->cell(0,6) . "\n";
#    print OUTFILE "S: " . $ts->cell(1,1) . "     L: " . $ts->cell(2,1) . "     D: " . $ts->cell(3,2);

# Parse Float Function.
sub parseComma {
   my $str = shift;
   $str =~ s/,//g;
   return $str;
}

# For day of the week figuring
my @wdays = qw(S M T W Th F Sa Su);

for(my $i=0; $i<$num_days; $i++) {
  my @date_elements = split('/', $ts->cell(0,$i));
  # Figure out and add day of the week to date.
  my $dow = Day_of_Week($date_elements[2], $date_elements[0], $date_elements[1]);
  my $date_fixed = $wdays[$dow] . " " . $date_elements[0] . "/" . $date_elements[1];

  my $sales_dollars = parseComma($ts->cell(1,$i));

  $chart_total_sales += $sales_dollars;
  $chart_total_labor += $ts->cell(2,$i);
  $chart_total_labor_percent += $ts->cell(3,$i);

$chart_data = $chart_data . ",\n[\'" . $date_fixed . "\', " . $sales_dollars . ", " . $ts->cell(2,$i) . ", " . $ts->cell(3,$i) . "]"; 
} # End For

}

# Total sales string for chart
$chart_total_sales = sprintf "%.2f", $chart_total_sales/$num_days;
$chart_total_sales = "\$" . commify($chart_total_sales);
$chart_total_labor = sprintf "%.2f", $chart_total_labor/$num_days;
$chart_total_labor = "\$" . commify($chart_total_labor);
$chart_total_labor_percent = sprintf "%.2f", $chart_total_labor_percent/$num_days;
$chart_total_labor_percent = commify($chart_total_labor_percent) . "\%";

print $chart_data;
print $chart_total_sales . "\n";
print $chart_total_labor . "\n";
print $chart_total_labor_percent . "\n";

my $chart_totals = "Avg Sales: " . $chart_total_sales . ", " .
                   "Avg Labor: " . $chart_total_labor . ", " . 
                   "Avg Labor %: " . $chart_total_labor_percent;


# Open input template file.
open(FILE, "$tmpl_infile_hourly");

# Open output file.
open(OUTFILE, ">$html_outfile_hourly");
#binmode(OUTFILE, ":utf8");

select((select(OUTFILE), $|=1)[0]);

while(<FILE>) {
  $_ =~ s/<CHART_DATA>/$chart_data/;
  $_ =~ s/<CHART_TOTAL>/$chart_totals/;
  print OUTFILE $_;
}

# Close input and html output file handles;
close(FILE);
close(OUTFILE);

# Run WKHTMLTOIMAGE command to dump to PNG.
system("/usr/bin/xvfb-run /usr/bin/wkhtmltoimage --javascript-delay 15000 --width 800 --height 300 $html_chart $outfile_hourly");

# Function comma-ify numbers
sub commify {
  my $input = shift;
  $input = reverse $input;
  $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
  return reverse $input;
}


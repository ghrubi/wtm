#!/user/bin/perl -w

use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;

# Get today's date for the report.
use DateTime qw();
my $report_date = DateTime->now(time_zone => 'America/Los_Angeles');
my $report_time = $report_date->strftime('%I:%M%p');
$report_date = $report_date->strftime('%d-%m-%Y');
#$report_date = '12-07-2016';

# Define in/out files
my $html_outfile_hourly = "/home/gene/projects/perl/wtm/wtm_hourly.html";
my $outfile_hourly = "/home/gene/projects/perl/wtm/wtm_hourly.png";
my $tmpl_infile_hourly = "/home/gene/projects/perl/wtm/google_hourly_chart.tmpl";
my $html_chart = "files.asskick.com:8080/wtm_data/wtm_hourly.html";


# Set user agent to avoid the dreaded lack-of-Flash bullshit. 
my $my_user_agent = 'Mozilla/5.0 (Linux; U; Android 2.2; de-de; HTC Desire HD 1.18.161.2 Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';

# URL for login.
my $url = "https://my.whentomanage.com/login.php";
# URL sets the Chico store.
my $url2 = "https://my.whentomanage.com/change_store_redirect.php?store_id=8574";
# URL for the actual report. Day,%20Mmm%20DD,%20YYYY. e.g. Sun,%20May%2022,%202016
# my $url3 = "https://my.whentomanage.com/reports/report.php?id=101276&output_as=grid&basic_date_range=&basic_date_range%5Bstart%5D=Sun,%20May%2022,%202016&basic_date_range%5Bend%5D=Sun,%20May%2022,%202016&";

# A date format of dd-mm-yyyy works!
my $url3 = "https://my.whentomanage.com/reports/report.php?id=101453&output_as=grid&basic_date_range=&basic_date_range%5Bstart%5D=" . $report_date . "&basic_date_range%5Bend%5D=" . $report_date . "&";

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
#print $html_sting;

# Begin parsing of HTML to retrieve TABLE DATA element.
use HTML::TableExtract;

# Define which table to locate. Parse.
my $te = HTML::TableExtract->new( attribs => { class => "grid" } );
$te->parse($html_string);

# Output string for chart data
my $chart_data;

# Total sales
my $chart_total_sales;

# Only 1 table, but whatever... 
foreach my $ts ($te->tables) {
#    print "Table named grid found at ", join(',', $ts->coords), ":\n";
#    print "Net Sales: " . $ts->cell(1,1) . "\n";
#    print "Labor    : " . $ts->cell(2,1) . "\n";
#    print "Discounts: " . $ts->cell(3,2) . "\n";
##    print OUTFILE "S: " . $ts->cell(1,1) . "     L: " . $ts->cell(2,1) . "     D: " . $ts->cell(3,2);

# Strip A/PM and make 24 time
my @hours;
$hours[1] = substr($ts->cell(1,0), 0, -2);
$hours[2] = substr($ts->cell(2,0), 0, -2);
$hours[3] = substr($ts->cell(3,0), 0, -2);
$hours[4] = (substr($ts->cell(4,0), 0, -2) + 12);
$hours[5] = (substr($ts->cell(5,0), 0, -2) + 12);
$hours[6] = (substr($ts->cell(6,0), 0, -2) + 12);
$hours[7] = (substr($ts->cell(7,0), 0, -2) + 12);
$hours[8] = (substr($ts->cell(8,0), 0, -2) + 12);
$hours[9] = (substr($ts->cell(9,0), 0, -2) + 12);
$hours[10] = (substr($ts->cell(10,0), 0, -2) + 12);
$hours[11] = (substr($ts->cell(11,0), 0, -2) + 12);
$hours[12] = (substr($ts->cell(12,0), 0, -2) + 12);


for(my $i=1; $i<13; $i++) {
  $chart_total_sales += $ts->cell($i,2);
}

$chart_data = 
      "[[" . $hours[1] . ",00,00], " . $ts->cell(1,2) . ", null],\n" .
      "[[" . $hours[2] . ",00,00], " . $ts->cell(2,2) . ", null],\n" .
      "[[" . $hours[3] . ",00,00], " . $ts->cell(3,2) . ", null],\n" .
      "[[" . $hours[4] . ",00,00], " . $ts->cell(4,2) . ", null],\n" .
      "[[" . $hours[5] . ",00,00], " . $ts->cell(5,2) . ", null],\n" .
      "[[" . $hours[6] . ",00,00], " . $ts->cell(6,2) . ", null],\n" .
      "[[" . $hours[7] . ",00,00], " . $ts->cell(7,2) . ", null],\n" .
      "[[" . $hours[8] . ",00,00], " . $ts->cell(8,2) . ", null],\n" .
      "[[" . $hours[9] . ",00,00], " . $ts->cell(9,2) . ", null],\n" .
      "[[" . $hours[10] . ",00,00], " . $ts->cell(10,2) . ", null],\n" .
      "[[" . $hours[11] . ",00,00], " . $ts->cell(11,2) . ", null],\n" .
      "[[" . $hours[12] . ",00,00], " . $ts->cell(12,2) . ", null]\n"; 
}

# Total sales string for chart
$chart_total_sales = "\$" . commify($chart_total_sales) . " @ " . $report_time;

print $chart_data;
print $chart_total_sales . "\n";

# Open input template file.
open(FILE, "$tmpl_infile_hourly");

# Open output file.
open(OUTFILE, ">$html_outfile_hourly");
#binmode(OUTFILE, ":utf8");

select((select(OUTFILE), $|=1)[0]);

while(<FILE>) {
  $_ =~ s/<CHART_DATA>/$chart_data/;
  $_ =~ s/<CHART_TOTAL>/$chart_total_sales/;
  print OUTFILE $_;
}

# Close input and html output file handles;
close(FILE);
close(OUTFILE);

# Run WKHTMLTOIMAGE command to dump to PNG.
system("/usr/bin/xvfb-run --server-args=\"-screen 0, 1280x1200x24\" /usr/bin/wkhtmltoimage --javascript-delay 12000 --width 800 --height 300 $html_chart $outfile_hourly");

# Function comma-ify numbers
sub commify {
  my $input = shift;
  $input = reverse $input;
  $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
  return reverse $input;
}


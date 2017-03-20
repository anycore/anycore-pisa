#!/usr/local/bin/perl
use strict;
use POSIX;

use Cwd;
use Cwd qw(abs_path);
use Fcntl qw(:flock);

use UNIVERSAL 'can';

my $all_args = join("_",@ARGV);
$all_args = $all_args."_";

print "All args are $all_args\n";

use Getopt::Long;

my $help;
my $output = "reports.csv";
my $target_cycle_time = undef;
my $actual_cycle_time = undef;
my $combo_on = 0;
my $cumul_off = 0;
my $cumul_on = 1;
my $seq_on = 0;
my $all_on = 0;
my @designs;
my $energy = 0;
my $debug = undef;

if($#ARGV < -1){
  print "Syntax: generate_ppa_csv.pl --help for all options\n";
  exit 0;
}

GetOptions ("help"        =>  \$help,
            "o=s"         =>  \$output,
            "tct=s"       =>  \$target_cycle_time,
            "act=s"       =>  \$actual_cycle_time,
            "no_cumul"    =>  \$cumul_off,
            "combo"       =>  \$combo_on,
            "seq"         =>  \$seq_on,
            "all"         =>  \$all_on,
            "des=s{1,}"   =>  \@designs,
            "energy"      =>  \$energy,
            "debug=i"     =>  \$debug);


if($help){
  print "Syntax: collect_rama_report.pl [-des=[design1,design2,...] -o <processed csv report> --debug]\n";
  exit 0;
}

if($all_on){
  $cumul_on = 1;
  $seq_on = 1;
  $combo_on = 1;
}

if($cumul_off){
  $cumul_on = 0;
}

if($debug == 0){
  $debug = undef;
}

sub parse_power_report  {

  my $input   = shift @_ || die "Must provide input file";
  my $cycle_time = shift @_ || die "Must provide cycle time";
  my $output  = shift @_ || "temp.csv";
  my $energy_on = shift @_ || 0;
  my $dump_processed = shift @_ || 0;
  my $cumul_on  = shift @_ || 1;
  my $seq_on    = shift @_ || 0;
  my $combo_on  = shift @_ || 0;

  my %powerHash;

  my $record_cumulative =  0;
  my $record_sequential =  0;
  my $record_combo      =  0;
  my @instance_list = ();
  
  my $level       ;
  my $instance    ;
  my $module      ;
  my $int_power   ;
  my $swt_power   ;
  my $lek_power   ;
  my $tot_power   ;
  #my $percentage ;
  my $dyn_power;
  my $unique_key;

  my @hierarchy;

  print "Using Cycle Time $cycle_time ns\n";
  print "Trying to use $input as the input file\n";
  
  if(open (RAW_REPORT,"<",$input)){
    while (<RAW_REPORT>) {
      chomp;
      if((/==Begin Cumulative Data==/) and $cumul_on){
        $record_cumulative =  1;
        print "Recording on for cumulative data\n" if($debug);
      }
      if((/==End Cumulative Data==/) and $cumul_on){
        $record_cumulative =  0;
        print "Recording off for cumulative data\n" if($debug);
      }
      if((/==Begin Sequential Data==/) and $seq_on){
        $record_sequential =  1;
        print "Recording on for sequential data\n" if($debug);
      }
      if((/==End Sequential Data==/) and $seq_on){
        $record_sequential =  0;
        print "Recording off for sequential data\n" if($debug);
      }
      if((/==Begin Sequential Data==/) and $combo_on){
        $record_combo      =  1;
        print "Recording on for combo data\n" if($debug);
      }
      if((/==End Sequential Data==/) and $combo_on){
        $record_combo      =  0;
        print "Recording off for combo data\n" if($debug);
      }
  
      if($record_cumulative){
        # If the line read is in valid format
        #if(m/^(\s*)([a-zA-Z0-9_]+)\s+(\([a-zA-Z0-9_]+\))*\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)/){
        if(m/^(\s*)([a-zA-Z0-9_]+)\s+(\([a-zA-Z0-9_]+\))*\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+([0-9\.e-]+)\s+/){
          print $_."\n" if($debug);
          $level       = length($1)/2;
          $instance    = $2;
          $module      = $3;
          if($energy_on){
            print "Using energy instead of power\n";
            $int_power   = $4*$cycle_time;
            $swt_power   = $5*$cycle_time;
            $lek_power   = $6*$cycle_time;
            $tot_power   = $11*$cycle_time;
          } else {
            $int_power   = $4;
            $swt_power   = $5;
            $lek_power   = $6;
            $tot_power   = $11;
          }
          #$percentage  = $8;

          $dyn_power = $int_power + $swt_power;
  
          $hierarchy[$level] = $instance;

          $module =~ s/\(//;
          $module =~ s/\)//;

          $unique_key = $hierarchy[0];
          for(my $i = 1; $i <= $level; $i=$i+1){
            $unique_key = $unique_key."/".$hierarchy[$i];
          }
          
          # Push the unique key into the instance list.
          # This is used to print the hash contents in sorted order
          if(exists $powerHash{$unique_key}){
            my @existing_power_list = @{$powerHash{$unique_key}};
            my @new_power_list      = ($level,$instance,$module,$int_power,$swt_power,$dyn_power,$lek_power,$tot_power);
            print "$unique_key => ".join(", ",@new_power_list)."\n" if($debug == 2);
            for(my $i = 3;$i < 8;$i=$i+1){
              $existing_power_list[$i] = $existing_power_list[$i] + $new_power_list[$i];
            }
            $powerHash{$unique_key} = \@existing_power_list;
          } else {
            push(@instance_list,$unique_key);
            #print join("  ",($int_power,$swt_power,$lek_power,$tot_power))."\n";
            $powerHash{$unique_key} = [$level,$instance,$module,$int_power,$swt_power,$dyn_power,$lek_power,$tot_power];
            print "$unique_key => ".join(", ",(@{$powerHash{$unique_key}}))."\n" if($debug == 2);
          }
        }
      }
    } #while <RAW_REPORT>
    close RAW_REPORT;
  
    if($dump_processed){
      if(open (PROCESSED,">",$output)){ 
        print PROCESSED "Level,\t\tInstance,\t\tModule,\t\t\tInt,\t\t\t\tSwitch,\t\t\t\tDynamic,\t\t\t\tLeakage,\t\t\t\tTotal,\t\t\t\tPercentage\n";
  
        # Print Total Power in the file
        foreach my $key (@instance_list){
            if(exists $powerHash{$key}){
              print PROCESSED join(",",(@{$powerHash{$key}}))."\n"; #Push total power for the simpoint
            }
        }
      } else {
        print "Failed to open $output: $!\n";
      }
      close PROCESSED;
    }
  
  } else {
    print "$!\n";
  }

  return \%powerHash;
}

sub parse_timing_report(){
  my $input = shift @_;
  my $cycle_time = shift @_ || $target_cycle_time;
  return 0 unless($input);

  print "Trying to use $input as the input file\n" if($debug);

  my $IN_FILE; 
  open($IN_FILE,"<",$input) or die "Could not open $input $!\n";

  my $delay = 200000;
  while(my $line = <$IN_FILE>){
    next unless($line =~ /slack \((.*)\)/);
    if($1 eq "MET"){
      print("ERROR: FOUND ONE WHERE SLACK $1\n");
      $delay = $cycle_time;
      last;
    }
    $line =~ /slack .*\s+([\-0-9\.]+)/;
    $delay = $cycle_time-$1;
    last;
  }
  close $IN_FILE;
  return $delay;
}

sub parse_area_report(){
  my $input = shift @_;
  print "Trying to use $input as the input file\n" if($debug);
  unless($input =~ /rpt/){
    print "No input provided to parse_area_report()\n" if($debug);
    return 0;
  }
  my $area_line = `grep "Total cell area" $input`;
  $area_line =~ /Total cell area:\s*([0-9\.e\-]+)/;
  my $area = $1/1000000.0;
  return $area;
}

sub LOCK_SH() { 1 } ## shared lock
sub LOCK_EX() { 2 } ## exclusive lock
sub LOCK_NB() { 4 } ## non-blocking
sub LOCK_UN() { 8 } ## unlock

my $basedir = cwd();
my $path = ".";#abs_path($path);

foreach my $design (@designs){

  print "Analyzing reports for design: $design\n";

  my $OUT_FILE;
  open($OUT_FILE,">>",$output);
  flock(OUT_FILE,LOCK_EX);

  #my $area_report = `ls $design/reports/area_final* 2>/dev/null`;
  my $area_report = `ls $design/reports/area_final* 2>/dev/null`;
  chomp($area_report);
  print "Area report is $area_report\n" if($debug > 1);
  my $area = &parse_area_report($area_report);

  my $timing_report = `ls $design/reports/timing_max_typical_holdfixed* 2>/dev/null`;
  chomp($timing_report);
  print "Timing report is $timing_report\n" if($debug > 1);
  my $delay = &parse_timing_report($timing_report);

  #If a cycle time was passed as an argument, use that instead
  if($actual_cycle_time){
    print "Using given cycle time of $actual_cycle_time\n" if($debug);
    $delay = $actual_cycle_time;
  }

  my $power_report = `ls $design/reports/power_ptpx*`;
  chomp($power_report);
  print "Power report is $power_report\n" if($debug > 1);
  my %powerHash = %{parse_power_report($power_report,$delay,"temp.csv",$energy)};

  foreach my $key (keys %powerHash){
    # If not Level 0 instance, skip
    next unless($powerHash{$key}->[0] == 0);

    # If isolation power, skip
    next if($key =~ /isolation/);

    my $dynamic_power = 1000*$powerHash{$key}->[5];
    my $static_power = 1000*$powerHash{$key}->[6];
    #print $OUT_FILE "${conf}_$power_scenario,$delay,$area,$dynamic_power,$static_power\n"; 
    print $OUT_FILE "$design,$area,$dynamic_power,$static_power,$delay\n"; 
  
  }
  close $OUT_FILE;
  flock(OUT_FILE,LOCK_UN);

  chdir $basedir;
}

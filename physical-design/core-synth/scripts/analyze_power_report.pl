#!/usr/local/bin/perl
use POSIX;

use Cwd;
use Cwd qw(abs_path);

$all_args = join("_",@ARGV);
$all_args = $all_args."_";

print "All args are $all_args\n";

use Getopt::Long;

my $help;
my $output = "power.csv";
my $combo_on = 0;
my $cumul_off = 0;
my $cumul_on = 1;
my $seq_on = 0;
my $all_on = 0;
my @configs;
my @benchmarks;
my $vcd_based = 0;
my $run_id    = 1;
my $energy = 0;
my $batch_mode = 0;
my $diff_reports = 0;
my @diff_designs;
my @diff_cts;
my $ct = 10.0;

if($#ARGV < 0){
  print "Syntax: analyze_power_report --help for all options\n";
  exit 0;
}

GetOptions ("help"        =>  \$help,
            "p=s"         =>  \$path,
            "i=s"         =>  \$input,
            "o=s"         =>  \$output,
            "no_cumul"    =>  \$cumul_off,
            "combo"       =>  \$combo_on,
            "seq"         =>  \$seq_on,
            "all"         =>  \$all_on,
            "batch"       =>  \$batch_mode,
            "ct=s"        =>  \$ct,
            "vcd"         =>  \$vcd_based,
            "energy"      =>  \$energy,
            "run_id=i"    =>  \$run_id,
            "bench=s{1,}" =>  \@benchmarks,
            "diff"        =>  \$diff_reports,
            "des=s{1,}"   =>  \@diff_designs,
            "cts=s{1,}"   =>  \@diff_cts,
            "conf=i{1,}"  =>  \@configs);




if($help){
  print "Syntax: analyze_power_report -i <raw_power_report> [-o <processed power report>]\n";
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

if((scalar @configs) <= 0){
  @configs = (1,2,3,4,5,6);
}

if((scalar @benchmarks) <= 0){
  @benchmarks = ("none");
}

my @cycle_time = (0,0.56,0.55,0.57,0.56,0.59,0.58,0.59); #cycle_time[7]  -> Anycore's cycle time

sub parse_power_report  {

  my $input   = shift @_ || die "Must provide input file";
  my $cycle_time = shift @_ || die "Must provide cycle time";
  my $output  = shift @_ || die "Must provide output file";
  my $energy_on = shift @_ || 0;
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
            print "$unique_key => ".join("  ",@new_power_list)."\n" if($debug == 2);
            for(my $i = 3;$i < 8;$i=$i+1){
              $existing_power_list[$i] = $existing_power_list[$i] + $new_power_list[$i];
            }
            $powerHash{$unique_key} = \@existing_power_list;
          } else {
            push(@instance_list,$unique_key);
            #print join("  ",($int_power,$swt_power,$lek_power,$tot_power))."\n";
            $powerHash{$unique_key} = [$level,$instance,$module,$int_power,$swt_power,$dyn_power,$lek_power,$tot_power];
            print "$unique_key => ".join(" ",(@{$powerHash{$unique_key}}))."\n" if($debug == 2);
          }
        }
      }
    } #while <RAW_REPORT>
    close RAW_REPORT;
  
    if(open (PROCESSED,">",$output)){ 
      print PROCESSED "Level,\t\tInstance,\t\tModule,\t\t\tInt,\t\t\t\tSwitch,\t\t\t\tDynamic,\t\t\t\tLeakage,\t\t\t\tTotal,\t\t\t\tPercentage\n";
  
      # Print Total Power in the file
      foreach my $key (@instance_list){
          if(exists $powerHash{$key}){
            print PROCESSED join(",",(@{$powerHash{$key}}))."\n"; #Push total power for the simpoint
          }
      }
    } else {
      print "Failed to open $simpointfile: $!\n";
    }
    close PROCESSED;
  
  } else {
    print "$!\n";
  }

  return \%powerHash;
}

@structures = ();
push(@structures,"FABSCALAR/activeList/activeList");
push(@structures,"FABSCALAR/activeList/ctrlActiveList");
push(@structures,"FABSCALAR/activeList/executedActiveList");
push(@structures,"FABSCALAR/activeList/ldViolateVector");
push(@structures,"FABSCALAR/activeList/targetAddrActiveList");
push(@structures,"FABSCALAR/amt/AMT");
push(@structures,"FABSCALAR/dispatch/ldVioPred");
push(@structures,"FABSCALAR/fs1/bp");
push(@structures,"FABSCALAR/fs1/btb");
push(@structures,"FABSCALAR/instBuf/instBuffer");
push(@structures,"FABSCALAR/issueq/issueQfreelist/iqfreelist");
push(@structures,"FABSCALAR/issueq/payloadRAM");
push(@structures,"FABSCALAR/issueq/src1Cam");
push(@structures,"FABSCALAR/issueq/src2Cam");
push(@structures,"FABSCALAR/lsu/datapath/ldx_path");
push(@structures,"FABSCALAR/lsu/datapath/stx_path");
push(@structures,"FABSCALAR/registerfile/PhyRegFile_byte0");
push(@structures,"FABSCALAR/registerfile/PhyRegFile_byte1");
push(@structures,"FABSCALAR/registerfile/PhyRegFile_byte2");
push(@structures,"FABSCALAR/registerfile/PhyRegFile_byte3");
push(@structures,"FABSCALAR/rename/RMT/RenameMap");
push(@structures,"FABSCALAR/rename/specfreelist/freeList");

my $key_exepipe2 = "FABSCALAR/exePipe2";

my $basedir = cwd();
$path = abs_path($path);

print @benchmarks."\n";

if($diff_reports){
  
  my $input   = `ls $path/$diff_designs[0]/reports/power_ptpx*`;
  chomp($input);
  my $output  = "power_$diff_designs[0].csv";
  my $hashref = parse_power_report($input,$diff_cts[0],$output,$energy);
  my %statPowerHash = %{$hashref}; 
  
  my $input   = `ls $path/$diff_designs[1]/reports/power_ptpx*`;
  chomp($input);
  my $output  = "power_$diff_designs[1].csv";
  my $hashref = parse_power_report($input,$diff_cts[1],$output,$energy);
  my %anyPowerHash = %{$hashref}; 
  
  my $dyn_overhead;
  my $stat_overhead;
  my $total_overhead;
  my $percent_overhead;
  my $overall_overhead = 0;
  
  if(open (OVERHEAD,">","overhead_report.csv")){
  
    my @stat_power_data = @{$statPowerHash{$key_exepipe2}};
    my @any_power_data = @{$anyPowerHash{$key_exepipe2}};
    my $stat_exepipe2_dyn = $stat_power_data[5]; 
    my $stat_exepipe2_stat = $stat_power_data[6];
    my $any_exepipe2_dyn = $any_power_data[5];
    my $any_exepipe2_stat = $any_power_data[6];
  
    print OVERHEAD "Overall\n";
    print OVERHEAD "Type, Dynamic Power, Static Power, Total Power, Percent Overhead\n";
    foreach my $key (keys %statPowerHash){
      my @stat_power_data = @{$statPowerHash{$key}};
      # Print only for Level 0 hierarchy instance - FABSCALAR
      if($stat_power_data[0] == 0){
        if(exists $anyPowerHash{$key}){
          my @any_power_data = @{$anyPowerHash{$key}};
          print OVERHEAD "$stat_power_data[1]_stat, $stat_power_data[5], $stat_power_data[6], $stat_power_data[7]\n";
          print OVERHEAD "$any_power_data[1]_any, $any_power_data[5], $any_power_data[6], $any_power_data[7]\n";
          $dyn_overhead   = ($any_power_data[5] - $any_exepipe2_dyn) - ($stat_power_data[5] - $stat_exepipe2_dyn); 
          $stat_overhead  = ($any_power_data[6] - $any_exepipe2_stat) - ($stat_power_data[6] - $stat_exepipe2_stat); 
          $total_overhead = $dyn_overhead + $stat_overhead;
          $percent_overhead = $total_overhead/($stat_power_data[7] - $stat_exepipe2_dyn - $stat_exepipe2_stat);
          print OVERHEAD "$stat_power_data[1]_overhead, $dyn_overhead, $stat_overhead, $total_overhead,$percent_overhead\n";
          $overall_overhead = $total_overhead;
        }
      }
    }
  
    print OVERHEAD "\n\nInstances\n";
    print OVERHEAD "Instance, Dynamic Power, Static Power, Total Power, Percent Overhead\n";
    foreach my $key (keys %statPowerHash){
      next if($key =~ /exepipe2/i);
      my @stat_power_data = @{$statPowerHash{$key}};
      # Print only for Level 1 hierarchy instances
      if($stat_power_data[0] == 1){
        if(exists $anyPowerHash{$key}){
          my @any_power_data = @{$anyPowerHash{$key}};
          $dyn_overhead   = $any_power_data[5] - $stat_power_data[5]; 
          $stat_overhead  = $any_power_data[6] - $stat_power_data[6]; 
          $total_overhead = $dyn_overhead + $stat_overhead;
          $percent_overhead = $total_overhead/$overall_overhead;
          print OVERHEAD "$stat_power_data[1], $dyn_overhead, $stat_overhead, $total_overhead,$percent_overhead\n";
        }
      }
    }
  
    print OVERHEAD "\n\n\nStructures\n";
    print OVERHEAD "Instance, Dynamic Power, Static Power, Total Power, Percent Overhead\n";
    foreach my $key (@structures){
      print "Key = $key\n" if($debug);
      my @stat_power_data = @{$statPowerHash{$key}};
      if(exists $anyPowerHash{$key}){
        my @any_power_data = @{$anyPowerHash{$key}};
        $dyn_overhead   = $any_power_data[5] - $stat_power_data[5]; 
        $stat_overhead  = $any_power_data[6] - $stat_power_data[6]; 
        $total_overhead = $dyn_overhead + $stat_overhead;
        $percent_overhead = $total_overhead/$overall_overhead;
        print OVERHEAD "$stat_power_data[1], $dyn_overhead, $stat_overhead, $total_overhead,$percent_overhead\n" 
      }
    }
  
  } else {
    print "Failed to open overhead_$conf.csv\n";
  }
  
  
  chdir $basedir;

} elsif($batch_mode){

  foreach my $bench (@benchmarks){
  
    print "Analyzing power reports for benchmar: $bench\n";
  
    unless($bench =~ /none/){
      print "Creating directory $bench\n";
      mkdir $bench;
      chdir $bench;
      # If path is not absolute
      unless($path =~ /^\//){
        $path = "../".$path; 
      }
    }
  
    foreach my $conf (@configs){
      my $input   = $path."/StaticCore$conf/SYNTH/reports/power_ptpx_FABSCALAR_$run_id.rpt";
      if($vcd_based){ $input = $path."/StaticCore$conf/$bench/ANALYSIS/reports/power_ptpx_FABSCALAR_$run_id.rpt";}
  
      my $output  = "power_Static$conf.csv";
      my $hashref = parse_power_report($input,$cycle_time[$conf],$output,$energy);
      my %statPowerHash = %{$hashref}; 
    
      $input   = $path."/Dynamic$conf/ANALYSIS/reports/power_ptpx_FABSCALAR_$run_id.rpt";
      if($vcd_based){ $input = $path."/Dynamic$conf/$bench/ANALYSIS/reports/power_ptpx_FABSCALAR_$run_id.rpt";}
  
      $output  = "power_Dynamic$conf.csv";
      $hashref = parse_power_report($input,$cycle_time[7],$output,$energy);
      my %anyPowerHash = %{$hashref}; 
  
      my $dyn_overhead;
      my $stat_overhead;
      my $total_overhead;
      my $percent_overhead;
      my $overall_overhead = 0;
  
      if(open (OVERHEAD,">","overhead_$conf.csv")){
    
        my @stat_power_data = @{$statPowerHash{$key_exepipe2}};
        my @any_power_data = @{$anyPowerHash{$key_exepipe2}};
        my $stat_exepipe2_dyn = $stat_power_data[5]; 
        my $stat_exepipe2_stat = $stat_power_data[6];
        my $any_exepipe2_dyn = $any_power_data[5];
        my $any_exepipe2_stat = $any_power_data[6];
  
        print OVERHEAD "Overall\n";
        print OVERHEAD "Type, Dynamic Power, Static Power, Total Power, Percent Overhead\n";
        foreach my $key (keys %statPowerHash){
          my @stat_power_data = @{$statPowerHash{$key}};
          # Print only for Level 0 hierarchy instance - FABSCALAR
          if($stat_power_data[0] == 0){
            if(exists $anyPowerHash{$key}){
              my @any_power_data = @{$anyPowerHash{$key}};
              print OVERHEAD "$stat_power_data[1]_stat, $stat_power_data[5], $stat_power_data[6], $stat_power_data[7]\n";
              print OVERHEAD "$any_power_data[1]_any, $any_power_data[5], $any_power_data[6], $any_power_data[7]\n";
              $dyn_overhead   = ($any_power_data[5] - $any_exepipe2_dyn) - ($stat_power_data[5] - $stat_exepipe2_dyn); 
              $stat_overhead  = ($any_power_data[6] - $any_exepipe2_stat) - ($stat_power_data[6] - $stat_exepipe2_stat); 
              $total_overhead = $dyn_overhead + $stat_overhead;
              $percent_overhead = $total_overhead/($stat_power_data[7] - $stat_exepipe2_dyn - $stat_exepipe2_stat);
              print OVERHEAD "$stat_power_data[1]_overhead, $dyn_overhead, $stat_overhead, $total_overhead,$percent_overhead\n";
              $overall_overhead = $total_overhead;
            }
          }
        }
  
        print OVERHEAD "\n\nInstances\n";
        print OVERHEAD "Instance, Dynamic Power, Static Power, Total Power, Percent Overhead\n";
        foreach my $key (keys %statPowerHash){
          next if($key =~ /exepipe2/i);
          my @stat_power_data = @{$statPowerHash{$key}};
          # Print only for Level 1 hierarchy instances
          if($stat_power_data[0] == 1){
            if(exists $anyPowerHash{$key}){
              my @any_power_data = @{$anyPowerHash{$key}};
              $dyn_overhead   = $any_power_data[5] - $stat_power_data[5]; 
              $stat_overhead  = $any_power_data[6] - $stat_power_data[6]; 
              $total_overhead = $dyn_overhead + $stat_overhead;
              $percent_overhead = $total_overhead/$overall_overhead;
              print OVERHEAD "$stat_power_data[1], $dyn_overhead, $stat_overhead, $total_overhead,$percent_overhead\n";
            }
          }
        }
    
        print OVERHEAD "\n\n\nStructures\n";
        print OVERHEAD "Instance, Dynamic Power, Static Power, Total Power, Percent Overhead\n";
        foreach my $key (@structures){
          print "Key = $key\n" if($debug);
          my @stat_power_data = @{$statPowerHash{$key}};
          if(exists $anyPowerHash{$key}){
            my @any_power_data = @{$anyPowerHash{$key}};
            $dyn_overhead   = $any_power_data[5] - $stat_power_data[5]; 
            $stat_overhead  = $any_power_data[6] - $stat_power_data[6]; 
            $total_overhead = $dyn_overhead + $stat_overhead;
            $percent_overhead = $total_overhead/$overall_overhead;
            print OVERHEAD "$stat_power_data[1], $dyn_overhead, $stat_overhead, $total_overhead,$percent_overhead\n" 
          }
        }
    
      } else {
        print "Failed to open overhead_$conf.csv\n";
      }
    
    }
  
    chdir $basedir;
  }
} else {

  parse_power_report($input,$ct,$output,$energy);

}

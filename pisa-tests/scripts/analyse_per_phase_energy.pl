#!/usr/bin/env /usr/local/bin/perl

use strict;
use Getopt::Long;
use Cwd;
use File::Path qw(make_path remove_tree);

my $help;
my @benchmarks;
my $inDir = cwd();
my $outDir = "energy_result";
my $debug = undef;
my $nooverheads = undef;
my $prefix = "";
my $ppaPath = "/afs/unity.ncsu.edu/users/r/rbasuro/anycore-ppa";

if($#ARGV < -1){
  print "Syntax: analyze_per_phase_energy.pl --help for al options\n";
  exit 0;
}

$SIG{'INT'} = 'exit_gracefully';

sub exit_gracefully {
  print "Caught ^C \n";
  exit (1);
}

GetOptions ("help"        =>  \$help,
            "out=s"       =>  \$outDir,
            "in=s"        =>  \$inDir,
            "bmk=s{1,}"   =>  \@benchmarks,
            "debug=i"     =>  \$debug,
            "prefix=s"    =>  \$prefix,
            "nooverheads" =>  \$nooverheads,
            );

if($help){
  print "Syntax: analyze_per_phase_energy.pl [--bmk=<benchmarks> --in=<input_directory> --out=<output_directory> --prefix<output_prefix> --debug]\n";
  print "Output file will be stored in the output_directory and each CSV file will have the output_prefix prefixed to the name\n";
  exit 0;
}

#Add any lonely benchmark names to the list        
@benchmarks = (@benchmarks,@ARGV);

unless(join("",@benchmarks) =~ /\d+\.\w/){
  @benchmarks = split("\n",`ls $inDir|grep 4`);
}

# Check to make sure known benchmark
foreach my $bench (@benchmarks) {
  unless($bench =~ /perlbench|bzip2|bwaves|mcf|milc|leslie3d|namd|gobmk|dealII|povray|calculix|sjeng|libquantum|h264ref|lbm|omnetpp|astar|xalancbmk/){
    die "Unknown benchmark \"$bench\" specified\n";
  }
}

sub perPhaseEnergyForConfig(){
  my $phaseFile = shift @_;
  my $knobFile = shift @_;

  # Grep the phase IPCs from the stats file and put them
  # in an array.
  my $grepped_ipc = `grep -i "ipc_rate" $phaseFile`;
  $grepped_ipc =~ s/ipc_rate : //g;
  my @ipcArray = split("\n",$grepped_ipc);

  my $grepped_cycles = `grep -i "cycle_count" $phaseFile`;
  $grepped_cycles =~ s/cycle_count : //g;
  my @cyclesArray = split("\n",$grepped_cycles);

  my @energyArray;
  my @delayArray;

  ## Create on single knobs file that can 
  # be concateneted to every temporary per phase
  # stats file to be used by the anycore-ppa for energy
  # analysis.
  my $KNOB_FILE;
  my $TEMP_KNOB_FILE;
  open($KNOB_FILE,"<",$knobFile);
  open ($TEMP_KNOB_FILE,">","temp_knob.log");
  # Dump the knobs first
  while (my $line = <$KNOB_FILE>){
    last if($line =~ /stats/);
    print $TEMP_KNOB_FILE $line;
  }
  close $TEMP_KNOB_FILE;
  close $KNOB_FILE;

  my $PHASE_FILE;
  my $TEMP_PHASE_FILE;
  my $phaseStart = 0;
  my $phaseEnd = 0;
  my $currentPhase = 0;
  # Read the phase.log file for the configuration
  # and create a temporary per phase stats file
  # to be used by the ppa tool.
  open($PHASE_FILE,'<', $phaseFile);
  while(my $line = <$PHASE_FILE>){

    # Find the begining of a phase
    if($line =~ /Phase Counters Phase ID/){
      $phaseStart = 1;
      $phaseEnd = 0;
      # Put the knobs in the begining of the temporary stats file
      system("cp -f temp_knob.log temp_phase_stats.log");
      system("echo [stats] >> temp_phase_stats.log");
      open($TEMP_PHASE_FILE,'>>', "temp_phase_stats.log");
      next;
    }

    # Stop the phase just before the rates
    if($line =~ /Phase Rates Phase ID/){
      $phaseStart = 0;
      $phaseEnd = 1;

      close $TEMP_PHASE_FILE;

      print "Analyzing $phaseFile for Phase $currentPhase\n" if($debug);

      if($nooverheads){
        # Run the energy analysis on this phase
        print("python $ppaPath/bin/sim2ppa.py -t $ppaPath/templates/fabscalar_riscv_micro.yaml -s temp_phase_stats.log -o temp_phase.yaml\n") if($debug > 1);
        print("python $ppaPath/bin/run_ppa.py --power_db ./power.db -i temp_phase.yaml > temp_energy.out\n") if($debug > 1);

        system("rm -f temp_phase.yaml temp_energy.out");
        system("python $ppaPath/bin/sim2ppa.py -t $ppaPath/templates/fabscalar_riscv_micro.yaml -s temp_phase_stats.log -o temp_phase.yaml\n");
        system("python $ppaPath/bin/run_ppa.py --power_db ./power.db -i temp_phase.yaml > temp_energy.out\n");

      } else {
        # Run the energy analysis on this phase
        print("python $ppaPath/bin/sim2ppa.py -t $ppaPath/templates/anycore_riscv_micro.yaml -s temp_phase_stats.log -o temp_phase.yaml\n") if($debug > 1);
        print("python $ppaPath/bin/run_ppa.py --power_db ./power.db -i temp_phase.yaml > temp_energy.out\n") if($debug > 1);

        system("rm -f temp_phase.yaml temp_energy.out");
        system("python $ppaPath/bin/sim2ppa.py -t $ppaPath/templates/anycore_riscv_micro.yaml -s temp_phase_stats.log -o temp_phase.yaml\n");
        system("python $ppaPath/bin/run_ppa.py --power_db ./power.db -i temp_phase.yaml > temp_energy.out\n");

      }

      # Grep for total_energy in th efirst 7 lines of the results
      my $totalEnergy = `head -n7 temp_energy.out|grep -i \"total_energy\"`;

      # Extract the numerical value from the string
      $totalEnergy =~ s/\n//g;
      $totalEnergy =~ m/total_energy:\s([\d\.]+).*/;

      # Push to the energy array for this core configuration
      push(@energyArray,$1);  
      
      # Grep for the cycle_time in the first 7 lines of the results
      my $cycleTime = `head -n7 temp_energy.out|grep -i \"cycle_time\"`;

      # Extract the numerical value from the string
      $cycleTime =~ s/\n//g;
      $cycleTime =~ m/cycle_time:\s([\d\.]+).*/;
      $cycleTime = $1;

      ## Get the number of cycles required to execute this phase
      #my $cyclesInPhase = `grep \"cycle_count\" temp_phase_stats.log`;
      #$cyclesInPhase =~ m/.*(\d)+/
      #$cyclesInPhase = $1;

      print("Cycle Time Extracted: $cycleTime\n") if($debug);

      $delayArray[$currentPhase] = $cycleTime*$cyclesArray[$currentPhase];

      $currentPhase += 1;
    }

    # When in the region of interest of a phase,
    # Dump the stats to the temp file.
    if($phaseStart == 1 and $phaseEnd == 0){
      print $TEMP_PHASE_FILE $line;
    }

    #last if($currentPhase == 1000);  
    #last if($currentPhase == 1);  

  }

  return (\@ipcArray,\@energyArray,\@delayArray);

}



my %STATS_LOG;
my %maxConfigHash; # This is a global hash that contains list of configs for each bmark

# This hash contains the per phase IPCs for each config.
# The data is extracted in the folloing foreach loop.
my %ipcHash;
my %energyHash;
my %delayHash;

my $baseDir = cwd();
make_path($outDir);

foreach my $benchmark (@benchmarks){

  ## Skip benchmarks that do not have proper stats
  next if($benchmark =~ /perlbench|povray|leslie/);

  print "Running per phase analysis for benchmark $benchmark\n";

  my @configs = split("\n",`ls $inDir/$benchmark/`);
  #my @configs = ('Config2','Config3');
  print join(",",@configs)."\n" if($debug);

  my $numPhases = 0;

  my $runDir = "energy_run_$benchmark";
  make_path($runDir);
  chdir $runDir;

  # Copy the energy database here so that multiple
  # copies can be run in parallel.
  system("cp $ppaPath/power/power.db .");

  foreach my $conf (@configs){
    #next if($conf eq "Config10");
    print "Analyzing for Config $conf\n" if($debug);
    my $stats_file = "$inDir/$benchmark/$conf/phase.log";
    my $knobs_file = "$inDir/$benchmark/$conf/stats.log";
    my ($ipcArrayPtr,$energyArrayPtr,$delayArrayPtr) = &perPhaseEnergyForConfig($stats_file,$knobs_file);
    $ipcHash{$conf} = $ipcArrayPtr;
    $energyHash{$conf} = $energyArrayPtr;
    $delayHash{$conf} = $delayArrayPtr;

    $numPhases = scalar @$ipcArrayPtr;
  }


  # Dump the two hashes into per benchmark CSV files.
  # The energy values area dumped in earlier columns followed
  # by the IPC values.
  #
  chdir "$baseDir/$outDir";
  my $CSV_FILE;
  open ($CSV_FILE,">",$benchmark."_phase_energy.csv");

  #Print the heading first
  print $CSV_FILE "Phase,";
  foreach my $conf (sort @configs){
    print $CSV_FILE "IPC $conf, Energy $conf, Delay $conf";
  }
  print $CSV_FILE "\n";

  # Print the results
  foreach my $phaseID (0..$numPhases-1){
    print $CSV_FILE "$phaseID,";
    #foreach my $key (sort keys %energyHash){
    foreach my $key (sort @configs){
      # Print the energy and IPC value for the particular phase
      # of the particular configuration.
      print $CSV_FILE "${$ipcHash{$key}}[$phaseID],";
      print $CSV_FILE "${$energyHash{$key}}[$phaseID],";
      print $CSV_FILE "${$delayHash{$key}}[$phaseID],";
    }
    print $CSV_FILE "\n";

  }

  chdir $baseDir;

  close $CSV_FILE;
}


print "analyze_per_phase_energy.pl completed successfully\n";

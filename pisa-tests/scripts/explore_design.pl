use strict;
use warnings;
use Switch;

use Data::Dumper;
use Getopt::Long;
use Cwd;
use Cwd qw(abs_path);

$SIG{INT} = sub { die "Caught a sigint $!" };
$SIG{TERM} = sub { die "Caught a sigterm $!" };

my $all_args = join("_",@ARGV);
$all_args = $all_args."_";

print "All args are $all_args\n";

if($#ARGV < 0){
  print "Syntax: explore_design.pl --help for all options\n";
  exit 0;
}

my $help;
my $resultFile = "DSE_Result.log";
my $benchmark = "400.perlbench";
my $fullSweep;
my $checkpointDir = "/home/rbasuro/anycore_spec_chkpts";

GetOptions ("help"        =>  \$help,
            "o=s"         =>  \$resultFile,
            "bmk=s"       =>  \$benchmark,
            "sweep"       =>  \$fullSweep,
            "chkpt_dir=s" =>  \$checkpointDir);


if($help){
  print "Syntax: explore_design.pl [-o <Result File> -bmk <benchmark to run> -chkpt_dir <Base Directory for checkpoints>]\n";
  exit 0;
}

my $checkpointPath = $checkpointDir."/".$benchmark;
my $maxActiveList = 256;
my $maxIssueQueue = 64;
my $maxLSQ        = 64;
my $maxPRF        = $maxActiveList;
my $activeListGranularity = 16;
my $issueQueueGranularity = 8;
my $lsQueueGranularity = 8;
my $maxLanes = 4;
my $globalMaxIPC = 0.1;
my $globalMaxRunId = 0;
my $runId = 0;
my $RESULT_FILE;

my $AL = 1;
my $IQ = 2;
my $LSQ = 3;
my $FE =4;
my $BE =5;
my %resultHash;

my %possibleLaneMatrix;

## Ranked in order of decresing complexity/power
#$possibleLaneMatrix{"numFeLanes"}   = [4      ,4     ,4     ,4     ,4      ,4      ,4      ,4      ,4   ];
#$possibleLaneMatrix{"numBeLanes"}   = [5      ,4     ,4     ,4     ,3      ,3      ,3      ,2      ,2   ];
#$possibleLaneMatrix{"lsu"}          = ['0x11' ,'0x09','0x01','0x09','0x05' ,'0x01' ,'0x01' ,'0x01' ,'0x01'];
#$possibleLaneMatrix{"aluC"}         = ['0x02' ,'0x02','0x02','0x02','0x02' ,'0x02' ,'0x02' ,'0x02' ,'0x02'];
#$possibleLaneMatrix{"aluS"}         = ['0x0e' ,'0x06','0x0e','0x06','0x02' ,'0x06' ,'0x06' ,'0x02' ,'0x02'];
#$possibleLaneMatrix{"aluFP"}        = ['0x06' ,'0x06','0x06','0x02','0x02' ,'0x06' ,'0x02' ,'0x02' ,'0x02'];
$possibleLaneMatrix{"numFeLanes"}   = [4      ,4     ,4     ,4     ,4       ,4      ];
$possibleLaneMatrix{"numBeLanes"}   = [5      ,4     ,4     ,3     ,3       ,2      ];
$possibleLaneMatrix{"lsu"}          = ['0x11' ,'0x01','0x09','0x01','0x05'  ,'0x01' ];
$possibleLaneMatrix{"aluC"}         = ['0x02' ,'0x02','0x02','0x02','0x02'  ,'0x02' ];
$possibleLaneMatrix{"aluS"}         = ['0x0e' ,'0x0e','0x06','0x06','0x02'  ,'0x02' ];
$possibleLaneMatrix{"aluFP"}        = ['0x0e' ,'0x0e','0x06','0x06','0x02'  ,'0x02' ];

sub printHash(){
  my $FILE = shift @_;
  my %hash = %{shift @_};
  foreach my $key (keys %hash){
    print $FILE "$key->$hash{$key} : ";
  }
  print $FILE "\n";
}


sub printResultHash(){
  my $FILE = shift @_;
  my $id = shift @_;
  print $FILE $id." : ";
  foreach my $idx (0..4){
    print $FILE $resultHash{$id}->[$idx]." ";
  }
  &printHash($FILE,$resultHash{$id}->[5]);
}

sub exploreLanes(){
  my $localMaxIPC = shift @_;
  my $tuningParam = shift @_;
  my $alSize    = shift @_;
  my $iqSize    = shift @_;
  my $lsqSize   = shift @_;
  my $lnMatrix  = shift @_;

  my $localCurrentIPC = 0.00;

  my @returnArray = (0.1,0,0);

  my $laneIter = 0;


  while($laneIter < @{$possibleLaneMatrix{"numFeLanes"}}){

#    my $numFeLanes   = $possibleLaneMatrix{"numFeLanes"}->[$laneIter]; 
#    my $numBeLanes   = $possibleLaneMatrix{"numBeLanes"}->[$laneIter]; 
#    my $lsu          = $possibleLaneMatrix{"lsu"}->[$laneIter];       
#    my $aluS         = $possibleLaneMatrix{"aluS"}->[$laneIter];      
#    my $aluC         = $possibleLaneMatrix{"aluC"}->[$laneIter];      
#    my $aluFP        = $possibleLaneMatrix{"aluFP"}->[$laneIter];     

    $lnMatrix->{"numFeLanes"}   = $possibleLaneMatrix{"numFeLanes"}->[$laneIter]; 
    $lnMatrix->{"numBeLanes"}   = $possibleLaneMatrix{"numBeLanes"}->[$laneIter]; 
    $lnMatrix->{"lsu"}          = $possibleLaneMatrix{"lsu"}->[$laneIter];       
    $lnMatrix->{"aluS"}         = $possibleLaneMatrix{"aluS"}->[$laneIter];      
    $lnMatrix->{"aluC"}         = $possibleLaneMatrix{"aluC"}->[$laneIter];      
    $lnMatrix->{"aluFP"}        = $possibleLaneMatrix{"aluFP"}->[$laneIter];     

    #$activeListSize = $activeListSize - $activeListGranularity;
    my $configString = "--al ".$alSize." --iq ".$iqSize." --lsq ".$lsqSize;
    $configString = $configString." --fw ".$lnMatrix->{"numFeLanes"}." --dw ".$lnMatrix->{"numFeLanes"};
    $configString = $configString." --iw ".$lnMatrix->{"numBeLanes"}." --rw ".$lnMatrix->{"numFeLanes"};
    $configString = $configString." --lane 0x02:".$lnMatrix->{"lsu"}.":".$lnMatrix->{"aluS"}.":";
    $configString = $configString.$lnMatrix->{"aluC"}.":".$lnMatrix->{"lsu"}.":".$lnMatrix->{"aluFP"}.":0x02";
#    $configString = $configString." --fw $numFeLanes --dw $numFeLanes";
#    $configString = $configString." --iw $numBeLanes --rw $numFeLanes";
#    $configString = $configString." --lane 0x02:$lsu:$aluS:$aluC:$lsu:$aluFP:0x02";
  
    print ("make bmarks=\"$benchmark\" ConfigString=\"$configString\" CHKPT_DIR=\"$checkpointPath\"\n");
    system("make bmarks=\"$benchmark\" ConfigString=\"$configString\" CHKPT_DIR=\"$checkpointPath\"");
    #Parse the stats file for IPC
    my $ipcString = `grep -i ipc stats.log`;
    print $ipcString;
    $ipcString =~ m/ipc_rate\s*->\s*([0-9\.]*)/;
    my $localCurrentIPC = $1;
  
    # If a smaller config is within 2% of max IPC,
    # it becomes the new optimum config.
    if($localCurrentIPC > 0.90*$localMaxIPC){
      #Return the most optimum config
      #$lnMatrix->{"numFeLanes"}   = $possibleLaneMatrix{"numFeLanes"}->[$laneIter]; 
      #$lnMatrix->{"numBeLanes"}   = $possibleLaneMatrix{"numBeLanes"}->[$laneIter]; 
      #$lnMatrix->{"lsu"}          = $possibleLaneMatrix{"lsu"}->[$laneIter];       
      #$lnMatrix->{"aluS"}         = $possibleLaneMatrix{"aluS"}->[$laneIter];      
      #$lnMatrix->{"aluC"}         = $possibleLaneMatrix{"aluC"}->[$laneIter];      
      #$lnMatrix->{"aluFP"}        = $possibleLaneMatrix{"aluFP"}->[$laneIter];     
      my $newLnMatrix = {%{$lnMatrix}};
      @returnArray = ($localCurrentIPC,$runId,$newLnMatrix);
    }

    # If this configuration has higher IPC than the max,
    # this becomes the new max IPC
    if($localCurrentIPC > $localMaxIPC){
      $localMaxIPC = $localCurrentIPC;
    }
    if($localCurrentIPC > $globalMaxIPC){
      $globalMaxIPC = $localCurrentIPC;
      $globalMaxRunId = $runId;
    }
    print "Current IPC: $localCurrentIPC  Max IPC: $localMaxIPC Global Max IPC: $globalMaxIPC\n";
  
    my $newLnMatrix = {%{$lnMatrix}};
    $resultHash{$runId} = [$tuningParam,$localCurrentIPC,$alSize,$iqSize,$lsqSize,$newLnMatrix];
    &printResultHash($RESULT_FILE,$runId);
    $runId = $runId+1;
  
    $laneIter = $laneIter + 1;

 
  } 

  return @returnArray; 
}

sub exploreParam(){
  my $localMaxIPC = shift @_;
  my $tuningParam = shift @_;
  my $alSize    = shift @_;
  my $iqSize    = shift @_;
  my $lsqSize   = shift @_;
  my $lnMatrix  = shift @_;

  my $optAlSize = $alSize;
  my $optIqSize = $iqSize;
  my $optLsqSize= $lsqSize;
  my $optRunId  = $runId;
  my $optIPC    = 0.1;

  my $ipcDegradation = 0.00;
  my $localCurrentIPC = 0.00;

  my @returnArray = (0.1,0,0);

  my $numFeLanes  = $lnMatrix->{"numFeLanes"};

  while(1){
  
    #$activeListSize = $activeListSize - $activeListGranularity;
    my $configString = "--al ".$alSize." --iq ".$iqSize." --lsq ".$lsqSize;
    $configString = $configString." --fw ".$numFeLanes." --dw ".$numFeLanes;
    $configString = $configString." --iw ".$lnMatrix->{"numBeLanes"}." --rw ".$numFeLanes;
    $configString = $configString." --lane 0x02:".$lnMatrix->{"lsu"}.":".$lnMatrix->{"aluS"}.":";
    $configString = $configString.$lnMatrix->{"aluC"}.":".$lnMatrix->{"lsu"}.":".$lnMatrix->{"aluFP"}.":0x02";
  
    print ("make bmarks=\"$benchmark\" ConfigString=\"$configString\" CHKPT_DIR=\"$checkpointPath\"\n");
    exit;
    system("make bmarks=\"$benchmark\" ConfigString=\"$configString\" CHKPT_DIR=\"$checkpointPath\"");
    #Parse the stats file for IPC
    my $ipcString = `grep -i ipc stats.log`;
    print $ipcString;
    $ipcString =~ m/ipc_rate\s*->\s*([0-9\.]*)/;
    my $localCurrentIPC = $1;
  
    $ipcDegradation = (1-($localCurrentIPC/$localMaxIPC));

    if($localCurrentIPC >= $localMaxIPC){
      $localMaxIPC = $localCurrentIPC;
      # This ensures that only the configuration
      # with maximum IPC is returned for full sweep.
      if($fullSweep){
        $lnMatrix->{"numFeLanes"} = $numFeLanes;
        $optAlSize = $alSize;
        $optIqSize = $iqSize;
        $optLsqSize = $lsqSize;
        $optRunId = $runId;
        $optIPC   = $localCurrentIPC;
      }
    }
    if($localCurrentIPC > $globalMaxIPC){
      $globalMaxIPC = $localCurrentIPC;
      $globalMaxRunId = $runId;
    }
    print "Current IPC: $localCurrentIPC  Max IPC: $localMaxIPC Global Max IPC: $globalMaxIPC Degradation: $ipcDegradation\n";
  
    my $newLnMatrix = {%{$lnMatrix}};
    $newLnMatrix->{"numFeLanes"} = $numFeLanes;
    $resultHash{$runId} = [$tuningParam,$localCurrentIPC,$alSize,$iqSize,$lsqSize,$newLnMatrix];
    &printResultHash($RESULT_FILE,$runId);

    # If the IPC for this run is below the margin
    # break out of the loop without updating the return
    # array. This means that the function returns the
    # dimensions from the previous run and not the current run 
    # as the current run is a bad run.
    if(($ipcDegradation > 0.05) and (not $fullSweep)){
      last;
    }

    # End exploration for this parameter if at any time the current
    # IPC becomes 15% lower than the global maximum IPC.
    if(($localCurrentIPC < 0.85*$globalMaxIPC) and (not $fullSweep)){
      last;
    }

    if($tuningParam ==  $AL){
      # Optimum size for non full sweep is the energy balanced size
      unless($fullSweep){ 
        $optAlSize = $alSize;
        $optIPC = $localCurrentIPC;
      }
      @returnArray = ($optIPC,$runId,$optAlSize);
      $alSize = $alSize-$activeListGranularity;
      if($alSize <= 0){
        last;
      }
    } elsif($tuningParam ==  $IQ){
      # Optimum size for non full sweep is the energy balanced size
      unless($fullSweep){ 
        $optIqSize = $iqSize;
        $optIPC = $localCurrentIPC;
      }
      @returnArray = ($optIPC,$optRunId,$optIqSize);
      $iqSize = $iqSize-$issueQueueGranularity;
      if($iqSize <= 0){
        last;
      }
    } elsif($tuningParam ==  $LSQ){
      # Optimum size for non full sweep is the energy balanced size
      unless($fullSweep){ 
        $optLsqSize = $lsqSize;
        $optIPC = $localCurrentIPC;
      }
      @returnArray = ($optIPC,$optRunId,$optLsqSize);
      $lsqSize = $lsqSize-$lsQueueGranularity;
      if($lsqSize <= 0){
        last;
      }
    } elsif($tuningParam ==  $FE){
      # Optimum number of lanes for non full sweep is the energy balanced number
      unless($fullSweep){
        $lnMatrix->{"numFeLanes"} = $numFeLanes;
        $optIPC = $localCurrentIPC;
      }
      @returnArray = ($optIPC,$optRunId,$lnMatrix);
      $numFeLanes = $numFeLanes-1;
      if($numFeLanes <= 0){
        last;
      }
    }

    $runId = $runId+1;
    unless($fullSweep){$optRunId = $runId;}
  } 

  return @returnArray; 
}

my $activeListSize = $maxActiveList;
my $issueQueueSize = $maxIssueQueue;
my $lsQueueSize = $maxLSQ;
my $numLanes = $maxLanes;
my $currentIPC = 0.2;
my $optimumRunId = 0;
my $laneMatrix = {};

$laneMatrix->{"numFeLanes"}   = $maxLanes;
$laneMatrix->{"numBeLanes"}   = $maxLanes+1;
$laneMatrix->{"lsu"}          = 0x11;
$laneMatrix->{"aluS"}         = 0x0e;
$laneMatrix->{"aluC"}         = 0x0e;
$laneMatrix->{"aluFP"}        = 0x0e;


open($RESULT_FILE, ">", $resultFile) or die "Could not open $resultFile - $!\n";

($currentIPC,$optimumRunId,$laneMatrix)      = &exploreLanes($currentIPC,$BE,$activeListSize,$issueQueueSize,$lsQueueSize,$laneMatrix);
($currentIPC,$optimumRunId,$laneMatrix)      = &exploreParam($currentIPC,$FE,$activeListSize,$issueQueueSize,$lsQueueSize,$laneMatrix);
($currentIPC,$optimumRunId,$activeListSize)  = &exploreParam($currentIPC,$AL,$activeListSize,$issueQueueSize,$lsQueueSize,$laneMatrix);
#if($fullSweep){
#  $activeListSize = $maxActiveList;
#}
($currentIPC,$optimumRunId,$issueQueueSize)  = &exploreParam($currentIPC,$IQ,$activeListSize,$issueQueueSize,$lsQueueSize,$laneMatrix);
#if($fullSweep){
#  $issueQueueSize = $maxIssueQueue;
#}
($currentIPC,$optimumRunId,$lsQueueSize)     = &exploreParam($currentIPC,$LSQ,$activeListSize,$issueQueueSize,$lsQueueSize,$laneMatrix);
#if($fullSweep){
#  $lsQueueSize = $maxLSQ;
#}


print $RESULT_FILE "--Optimum Config--\n";
&printResultHash($RESULT_FILE,$optimumRunId);
print $RESULT_FILE "--Maximum Config--\n";
&printResultHash($RESULT_FILE,$globalMaxRunId);


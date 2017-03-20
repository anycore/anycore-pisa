use strict;
use warnings;

use Getopt::Long;
use Cwd;
use Cwd qw(abs_path);

$SIG{INT} = sub { die "Caught a sigint $!" };
$SIG{TERM} = sub { die "Caught a sigterm $!" };

my $all_args = join("_",@ARGV);
$all_args = $all_args."_";

print "All args are $all_args\n";

if($#ARGV < -1){
  print "Syntax: explore_design.pl --help for all options\n";
  exit 0;
}

my $help;
my $resultFile = "DSE_Data.csv";
my $benchmark = "400.perlbench";
my $fullSweep;
my $resultPath = "./";
my $optimumConfig;

GetOptions ("help"        =>  \$help,
            "o=s"         =>  \$resultFile,
            "bmk=s"       =>  \$benchmark,
            "path=s"      =>  \$resultPath,
            "optimum"     =>  \$optimumConfig);


if($help){
  print "Syntax: explore_design.pl [-o <Result File> -bmk <benchmark to run> -chkpt_dir <Base Directory for checkpoints>]\n";
  exit 0;
}

sub printHash(){
  my $FILE = shift @_;
  my %hash = %{shift @_};

  print $FILE "configs,".join(",\t",@{$hash{"configs"}})."\n";

  foreach my $key (sort keys %hash){
    if($key =~ /configs/i){next;}
    print $FILE "$key,\t\t".join(",\t",@{$hash{$key}})."\n";
  }
  print $FILE "\n";
}

sub countBits(){
  my $val = shift @_;
  my $count = 0;
  foreach my $bit (0..63){
    my $maskedVal = $val & (1 << $bit);
    unless($maskedVal == 0){
      $count = $count + 1;
    }
  }
  return $count;
}

# Each parameter has it's own hash. 
# Benchmarks are keys and they each have
# a result list of IPCs.
# The first entry of the hash is always
# a list of possible configurations for that
# parameter.

my %optimumHash   = ("configs" => ['runId','param','ipc','alSize','iqSize','lsqSize','beLanes','feLanes','aluS','lsu']);
my %maximumHash   = ("configs" => ['runId','param','ipc','alSize','iqSize','lsqSize','beLanes','feLanes','aluS','lsu']);
my %backEndHash   = ("configs" => [0,1,2,3,4,5,6]);
my %frontEndHash  = ("configs" => [4,3,2,1]);
my %alHash        = ("configs" => [256,240,224,208,192,176,160,144,128,112,96,80,64,48,32,16]);
my %iqHash        = ("configs" => [64,56,48,40,32,24,16,8]);
my %lsqHash       = ("configs" => [64,56,48,40,32,24,16,8]);


my $AL = 1;
my $IQ = 2;
my $LSQ = 3;
my $FE =4;
my $BE =5;


my $benchmarks = `ls $resultPath/`;
print $benchmarks;
my @bmks = split("\n",$benchmarks);


sub extractOptimum(){
  foreach my $bmk (@bmks){
    unless($bmk =~ /\d+\.\w/){next;}
    print "Extracting data for $bmk\n";
    my $INFILE;
    open ($INFILE,"<",$resultPath."/".$bmk."/DSE_Result.log") or die "Could not open file $bmk/DSE_Result.log - $!\n";
  
    my $parseOptimum = undef;
    my $parseMaximum = undef;
    my $line;
    while ($line = <$INFILE>){
      if($line =~ /Optimum/){$parseOptimum = 1; next;} #Turn flag on and skip this line
      if($line =~ /Maximum/){$parseOptimum = undef;$parseMaximum = 1; next;} #Turn flag on and skip this line
      unless($parseOptimum or $parseMaximum){next;} #If neither flag is set, we are not in the region yet
      $line =~ /(\d+)\s:\s(\d)\s([0-9\.]+)\s(\d+)\s(\d+)\s(\d+)\saluS.*/;
      my $runId  = $1;
      my $param  = $2;
      my $ipc    = $3;
      my $alSize = $4;
      my $iqSize = $5;
      my $lsqSize= $6;
      $line =~ /numBeLanes->(\d+)/;
      my $beLanes= $1;
      $line =~ /numFeLanes->(\d+)/;
      my $feLanes= $1;
      $line =~ /aluS->([x0-9abcdef]+)/;
      my $aluS = &countBits(hex $1);
      $line =~ /lsu->([x0-9abcdef]+)/;
      my $lsu = &countBits(hex $1);
      if($parseOptimum){
        $optimumHash{$bmk} = [$runId,$param,$ipc,$alSize,$iqSize,$lsqSize,$beLanes,$feLanes,$aluS,$lsu];
      } elsif($parseMaximum){
        $maximumHash{$bmk} = [$runId,$param,$ipc,$alSize,$iqSize,$lsqSize,$beLanes,$feLanes,$aluS,$lsu]; 
      }
    }
  
    close($INFILE);
  }
}

sub extractSweepResults(){
  foreach my $bmk (@bmks){
    unless($bmk =~ /\d+\.\w/){next;}
    print "Extracting data for $bmk\n";
    my $INFILE;
    open ($INFILE,"<",$resultPath."/".$bmk."/DSE_Result.log") or die "Could not open file $bmk/DSE_Result.log - $!\n";
  
    my $line;
    while ($line = <$INFILE>){
      if($line =~ /Optimum/){last;}
      $line =~ /(\d+)\s:\s(\d)\s([0-9\.]+)\s(\d+)\s(\d+)\s(\d+)\s.*numFeLanes->(\d)/;
      my $runId  = $1;
      my $param  = $2;
      my $ipc    = $3;
      my $alSize = $4;
      my $iqSize = $5;
      my $lsqSize= $6;
      my $feLanes= $7;
      if($param == $BE){
        push (@{$backEndHash{$bmk}},$ipc);
      } elsif($param == $FE){
        push (@{$frontEndHash{$bmk}},$ipc);
      } elsif($param == $AL){
        push (@{$alHash{$bmk}}, $ipc);
      } elsif($param == $IQ){
        push (@{$iqHash{$bmk}}, $ipc);
      } elsif($param == $LSQ){
        push (@{$lsqHash{$bmk}}, $ipc);
      }
    }
  
    close($INFILE);
  }
}

my $RESULT_FILE;

open($RESULT_FILE, ">", $resultFile) or die "Could not open $resultFile - $!\n";
if($optimumConfig){
  &extractOptimum();
  &printHash($RESULT_FILE,\%optimumHash);
  &printHash($RESULT_FILE,\%maximumHash);
} else {
  &extractSweepResults();
  &printHash($RESULT_FILE,\%backEndHash);
  &printHash($RESULT_FILE,\%frontEndHash);
  &printHash($RESULT_FILE,\%alHash);
  &printHash($RESULT_FILE,\%iqHash);
  &printHash($RESULT_FILE,\%lsqHash);
}


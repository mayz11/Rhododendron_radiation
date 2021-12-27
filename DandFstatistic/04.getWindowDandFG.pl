use strict;
use warnings;
use v5.10;

my($inDir,$inNum,$outDir)=@ARGV;
die("usage: inDir inNum outDir\n")unless($outDir);

my @inFile=sort glob("$inDir/*.gz");
my $inFileNum=@inFile;
print("Total $inFileNum gz files\n");
mkdir($outDir)unless(-e $outDir);
select(STDOUT);
$| = 1;
for(my $i=0;$i<$inFileNum;$i+=$inNum) {
  my $e=$i+$inNum-1;
  if($e > $inFileNum-1){
    $e=$inFileNum-1;
    last;
  }
  my %fallD;
  my %fallFG;
  for(my $j=$i;$j<=$e;$j++){
    print("Reading $j\r");
    print "$inFile[$j]\n";
    open(F,"gzip -dc $inFile[$j]|") or die("$!: $inFile[$j]\n");
    while(<F>){
      chomp;
      next if(/^\s*$/);
      next if(/^\s*#/);
      my($id,$indA,$indB,$indC,$indO,$numeratorD,$denominatorD,$numeratorFG,$denominatorFG)=split /\t/;
      $fallD{$indA}{$indB}{$indC}{$indO}[0]+=$numeratorD;
      $fallD{$indA}{$indB}{$indC}{$indO}[1]+=$denominatorD;
      $fallFG{$indA}{$indB}{$indC}{$indO}[0]+=$numeratorFG;
      $fallFG{$indA}{$indB}{$indC}{$indO}[1]+=$denominatorFG;
    }
    close(F);
  }
  my $outFile="$outDir/$i-$e.DvsFG";
open(Fo,"| gzip -2 > $outFile") or die("$!: $outFile\n");
  print Fo "indA\tindB\tindC\tOut\tD\tFG\n";
  foreach my $indA(sort keys %fallD){
    foreach my $indB(sort keys %{$fallD{$indA}}){
      foreach my $indC(sort keys %{$fallD{$indA}{$indB}}){
        foreach my $indO(sort keys %{$fallD{$indA}{$indB}{$indC}}){
          my $numeratorD=$fallD{$indA}{$indB}{$indC}{$indO}[0];
          my $denominatorD=$fallD{$indA}{$indB}{$indC}{$indO}[1];
          my $numeratorFG=$fallFG{$indA}{$indB}{$indC}{$indO}[0];
          my $denominatorFG=$fallFG{$indA}{$indB}{$indC}{$indO}[1];
          my $d='NA';
          my $fg='NA';
          if($denominatorD!=0){$d=$numeratorD/$denominatorD;}
          if($denominatorFG!=0){$fg=$numeratorFG/$denominatorFG;}
          print Fo join("\t",$indA,$indB,$indC,$indO,$d,$fg),"\n";
        }
      }
    }
  }
  close(Fo);
}
print("Done   \n");


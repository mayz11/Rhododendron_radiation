use strict;
use warnings;
use v5.10;

my($inFileValue,$outFile)=@ARGV;
die("usage: inFileValue outFile\n")unless($outFile);

my @pvalue;
my %hashValue;
my $idx=-1;
open(F,'<',$inFileValue) or die("$!: $inFileValue\n");
my $head=<F>;chomp($head);
my($nodeIDT,$groupAT,$groupBT,@name)=split /\t/,$head;
while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  my($nodeID,$groupA,$groupB,@indC)=split /\t/;
  for(my $i=0;$i<@indC;$i++) {
    my ($value,$zvalue,$pvalue)=split /_/,$indC[$i];
    if($pvalue ne 'NA'){
      $idx+=1;
      $pvalue[$idx]=$pvalue;
      $hashValue{$nodeID}{$groupA}{$groupB}{$i}=$idx;
    }
  }
}
close(F);

my $outFileTmp1="$outFile.1Pvalue.txt";
open(Fo,'>',$outFileTmp1) or die("$!: $outFileTmp1\n");
foreach my $pvalue (@pvalue) {
  print Fo "$pvalue\n";
}
close(Fo);

my $outFileR="$outFile.2HolmBonferroniFWER.R";
open(Fo,'>',$outFileR) or die("$!: $outFileR\n");
print Fo "
d=read.table('$outFileTmp1',header=FALSE)
newp=p.adjust(d\$V1, method = 'holm')
write.table(newp, file = '$outFile.3Pvalue.txt', append = FALSE, quote = FALSE, sep = '\t', row.names = FALSE, col.names = FALSE)
";
close(Fo);
system("/data/apps/R/3.5.1/bin/Rscript $outFileR");
my $inFileT="$outFile.3Pvalue.txt";
my @holmList;
open(F,'<',$inFileT) or die("$!: $inFileT\n");
while(<F>){
  chomp;
  push(@holmList,$_);
}
close(F);

open(Fo,"| gzip -2 > $outFile") or die("$!: $outFile\n");
open(F,"gzip -dc $inFileValue |") or die("$!: $inFileValue\n");
$head=<F>;
print Fo $head;
while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  my($nodeID,$groupA,$groupB,@indC)=split /\t/;
  for(my $i=0;$i<@indC;$i++) {
    my ($value,$zvalue,$pvalue)=split /_/,$indC[$i];
    if(exists $hashValue{$nodeID}{$groupA}{$groupB}{$i}){
      my $idx=$hashValue{$nodeID}{$groupA}{$groupB}{$i};
      my $newP=$holmList[$idx];
      $pvalue=$newP;
    }
    $indC[$i]=join("_",$value,$zvalue,$pvalue);
  }
  print Fo join("\t",$nodeID,$groupA,$groupB,@indC),"\n";
}
close(F);
close(Fo);

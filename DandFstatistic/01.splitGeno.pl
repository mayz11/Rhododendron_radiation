use strict;
use warnings;
use v5.10;

my($inFile,$inLineNum,$outDir)=@ARGV;
die("usage: inFile inLineNum outDir\n")unless($outDir);

mkdir($outDir)unless(-e $outDir);

open(F,"gzip -dc $inFile|") or die("$!: $inFile\n");
my $head=<F>;chomp($head);
my @lineList;
my $oid=-1;
while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  push(@lineList,$_);
  outLine() if(@lineList>=$inLineNum);
}
close(F);
outLine() if(@lineList>0);

sub outLine{
  $oid+=1;
  my $oids=sprintf("%05d",$oid);
  my $outFile="$outDir/$oids.gz";
  open(Fo,"| gzip -2 >$outFile") or die("$!: $outFile\n");
  print Fo $head,"\n";
  foreach my $line(@lineList){
    print Fo $line,"\n";
  }
  close(Fo);
  @lineList=();
}

#!/usr/bin/perl -w
use strict;
use warnings;
use v5.10;

my($inFile,$outFile)=@ARGV;
die("usage: inFile outFile\n")unless($outFile);

my $outFileR="$outFile.R";
open(Fo,'>',$outFileR) or die("$!: $outFileR\n");
print Fo "
d=read.table('$inFile',header=TRUE,sep = '\t')
newp=p.adjust(d\$p, method = 'holm')
write.table(newp, file = '$outFile.tmp', append = FALSE, quote = FALSE, sep = '\t', row.names = FALSE, col.names = FALSE)
";
close(Fo);

system("/data/apps/R/3.5.1/bin/Rscript $outFileR");
my $inFileT="$outFile.tmp";
my @holmList;
open(F,'<',$inFileT) or die("$!: $inFileT\n");
while(<F>){
  chomp;
  push(@holmList,$_);
}
close(F);

open(Fo,'>',$outFile) or die("$!: $outFile\n");
my $i=0;
open(F,'<',$inFile) or die("$!: $inFile\n");
my $head=<F>;chomp($head);
print Fo $head,"\tholm\n";
while(<F>){
  chomp;
  print Fo "$_\t",$holmList[$i],"\n";
  $i+=1;
}
close(F);
close(Fo);

use strict;
use warnings;
use v5.10;

my($inFile,$outFile)=@ARGV;
die("usage: inFileTsv outFileDmin\n")unless($outFile);

my %dh;
open(F,'<',$inFile) or die("$!: $inFile\n");
my $head=<F>;
while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  my($name1,$name2,$name3,$d,$z,@other)=split /\t/;
  my $namePermute=join("_",sort ($name1,$name2,$name3));
  my $absd=abs($d);
  if(!defined $dh{$namePermute} or $dh{$namePermute}[5] > $absd){
    $dh{$namePermute}=[$name1,$name2,$name3,$d,$z,$absd,@other];
  }
}
close(F);

open(Fo,'>',$outFile) or die("$!: $outFile\n");
print Fo $head;
foreach my $n(sort keys %dh){
  my($name1,$name2,$name3,$d,$z,$absd,@other)=@{$dh{$n}};
  print Fo join("\t",($name1,$name2,$name3,$d,$z,@other)),"\n";
}
close(Fo);

#!/usr/bin/perl -w
use strict;
use warnings;
use Statistics::Zed;
use v5.10;

my $zed=Statistics::Zed->new();

my($inDir,$outFile)=@ARGV;
die("usage: inDir outFile\n")unless($outFile);

my @inFile=glob("$inDir/*.gz");
my $inFileNum=@inFile;

select(STDOUT);
$| = 1;

my %Dhash;
for(my $i=0;$i<$inFileNum;$i++) {
  print("Read $i/$inFileNum\r");
  open(F,"gzip -dc $inFile[$i]|") or die("$!: $inFile[$i]\n");
  while(<F>){
    chomp;
    next if(/^\s*$/);
    next if(/^\s*#/);
    my($name1,$name2,$name3,$ou,$d,$fg)=split /\t/;
    my $D=$d;
    $Dhash{"$name1\t$name2\t$name3"}{$i}=$D;
  }
  close(F);
}
print("Read $inDir $inFileNum/$inFileNum done\n");
my @line;
my @lineP;
foreach my $name(sort keys %Dhash){
  my @ids=sort {$a<=>$b}keys %{$Dhash{$name}};
  my $n=@ids;
  if($n==1){
    print "$name n=1\n";
    next;
  }
  my %x;
  foreach my $i(@ids){
    my $sum=0;
    foreach my $j(@ids){
      next if($i==$j);
      $sum+=$Dhash{$name}{$j};
    }
    my $XiBar=$sum/($n-1);
    $x{$i}=$XiBar;
  }
  my $sum=0;
  foreach my $i(sort keys %x){
    $sum+=$x{$i};
  }
  my $XBar=$sum/$n;
  $sum=0;
  foreach my $i(sort keys %x){
    $sum+=($x{$i}-$XBar)*($x{$i}-$XBar);
  }
  my $varXBar=($n-1)*$sum/$n;
  my $standardError=sqrt($varXBar);
  
  my $sampleMean=0;
  foreach my $i(@ids){
    $sampleMean+=$Dhash{$name}{$i};
  }
  $sampleMean=$sampleMean/$n;
  
  my $z=($sampleMean-0)/$standardError;
  my $p = $zed->p_value($z);
  push(@line,[$name,$XBar,$varXBar,$standardError,$sampleMean,$z,$p]);
  push(@lineP,$p);
}
open(Fo,'>',$outFile) or die("$!: $outFile\n");
print Fo join("\t",qw(name1 name2 name3 xbar varxbar stderr samplemean z p)),"\n";
for(my $i=0;$i<@line;$i++){
  my ($name,$XBar,$varXBar,$standardError,$sampleMean,$z,$p)=@{$line[$i]};
  print Fo join("\t",$name,$XBar,$varXBar,$standardError,$sampleMean,$z,$p),"\n";
}
close(Fo);


use strict;
use warnings;
use v5.10;
use Algorithm::Permute;

my($inFile1,$inFile2,$inFile3,$indO,$outFile)=@ARGV;
die("usage: speInfo indFre speFre indO outFile\n")unless($outFile);

my $outFileL="$outFile.log";
open(FoL,'>',$outFileL) or die("$!: $outFileL\n");

my %speIndNum;
my %spe2ind;
open(F,'<',$inFile1) or die("$!: $inFile1\n");
while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  my($speId,$indId,$spe)=split /\t/;
  $speIndNum{$speId}++;
  push (@{$spe2ind{$speId}},$indId);
}
close(F);

open(F,"gzip -dc $inFile2 |") or die("$!: $inFile2\n");
my $nameLine0=<F>;chomp($nameLine0);
my ($chrT0,$posT0,@name0)=split /\t/,$nameLine0;
my $nameNum0=@name0;
print FoL "Total $nameNum0 Inds\n";
my %indname2Id;
for(my $i=0;$i<@name0;$i++){
  $indname2Id{$name0[$i]}=$i;
}
my %spe2PCx;
while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  my($CHROM0,$POS0,@PList0)=split /\t/;
  foreach my $speNum(keys %speIndNum){
    next if ($speIndNum{$speNum}==1);
    if ($speIndNum{$speNum}==2){
      $spe2PCx{$speNum}{$CHROM0}{$POS0}{c1}=$PList0[$indname2Id{$spe2ind{$speNum}[0]}];
      $spe2PCx{$speNum}{$CHROM0}{$POS0}{c2}=$PList0[$indname2Id{$spe2ind{$speNum}[1]}];
    }elsif($speIndNum{$speNum}==3){
      $spe2PCx{$speNum}{$CHROM0}{$POS0}{c1}=$PList0[$indname2Id{$spe2ind{$speNum}[0]}];
      my $tmp=($PList0[$indname2Id{$spe2ind{$speNum}[1]}]+$PList0[$indname2Id{$spe2ind{$speNum}[2]}])/2;
      $spe2PCx{$speNum}{$CHROM0}{$POS0}{c2}=$tmp;
    }else{
      print FoL "#####$speIndNum{$speNum}\t$speNum\n";
    }
  }
}
close(F);
print FoL "read Indfre Info done\n";

my $totalLine=0;
open(F,"gzip -dc $inFile3 |") or die("$!: $inFile3\n");
while(<F>){$totalLine+=1;}
close(F);
$totalLine-=1;
print FoL "Total $totalLine lines\n";

my ($numeratorFG,$denominatorFG,$numeratorD,$denominatorD);
open(F,"gzip -dc $inFile3 |") or die("$!: $inFile3\n");
my $nameLine=<F>;chomp($nameLine);
my ($chrT,$posT,@name)=split /\t/,$nameLine;
my $nameNum=@name;
print FoL "$nameLine\n";
print FoL "Total $nameNum spes\n";
my @idList;
my $idxO;
for(my $i=0;$i<$nameNum;$i++){
  if($name[$i] eq $indO){
    $idxO=$i;
    next;
  }
  push(@idList,$i);
}
print FoL "Outgroup index=$idxO\n";
my @namePermute;
my $p = Algorithm::Permute->new(\@idList, 3);
while (my @res = $p->next) {
  push(@namePermute,[@res]);
}
my $namePermuteNum=@namePermute;
print FoL "Permute number $namePermuteNum\n";
my %numeratorD;
my %denominatorD;
my %numeratorFG;
my %denominatorFG;

while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  my($CHROM,$POS,@PList)=split /\t/;
  for(my $i=0;$i<@namePermute;$i++) {
    my($idxA,$idxB,$idxC)=@{$namePermute[$i]};
    my $PA=$PList[$idxA];
    my $PB=$PList[$idxB];
    my $PC=$PList[$idxC];
    my $PO=$PList[$idxO];
    $numeratorD{$i}+=(1-$PA)*$PB*$PC*(1-$PO)-$PA*(1-$PB)*$PC*(1-$PO);
    $denominatorD{$i}+=(1-$PA)*$PB*$PC*(1-$PO)+$PA*(1-$PB)*$PC*(1-$PO);
    my ($PC1,$PC2);
    if ($speIndNum{$name[$idxC]}==1){
      next if ($PC==0.5);
      $PC1=$PC;
      $PC2=$PC;
      $numeratorFG{$i}+=(1-$PA)*$PB*$PC*(1-$PO)-$PA*(1-$PB)*$PC*(1-$PO);
      $denominatorFG{$i}+=(1-$PA)*$PC1*$PC2*(1-$PO)-$PA*(1-$PC1)*$PC2*(1-$PO);
    }else{
      $PC1=$spe2PCx{$name[$idxC]}{$CHROM}{$POS}{c1};
      $PC2=$spe2PCx{$name[$idxC]}{$CHROM}{$POS}{c2};
      $numeratorFG{$i}+=(1-$PA)*$PB*$PC*(1-$PO)-$PA*(1-$PB)*$PC*(1-$PO);
      $denominatorFG{$i}+=(1-$PA)*$PC1*$PC2*(1-$PO)-$PA*(1-$PC1)*$PC2*(1-$PO);
    }
  }
  print FoL "$inFile3  ".($.-1)."/$totalLine\n";
}
close(F);
close(FoL);

open(Fo,"| gzip -2 > $outFile") or die("$!: $outFile\n");
for(my $i=0;$i<@namePermute;$i++) {
  my($idxA,$idxB,$idxC)=@{$namePermute[$i]};
  my $indA=$name[$idxA];
  my $indB=$name[$idxB];
  my $indC=$name[$idxC];
  $numeratorD=$numeratorD{$i};
  $denominatorD=$denominatorD{$i};
  $numeratorFG=$numeratorFG{$i};
  $denominatorFG=$denominatorFG{$i};
  print Fo join("\t",($i,$indA,$indB,$indC,$indO,$numeratorD,$denominatorD,$numeratorFG,$denominatorFG)),"\n";
}
close(Fo);


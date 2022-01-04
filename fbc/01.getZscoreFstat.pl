use strict;
use warnings;
use Statistics::Zed;
use v5.10;
my $zed=Statistics::Zed->new();

my($inFile1,$outFile)=@ARGV;
die("usage: inFileFGjkDir outFile\n")unless($outFile);

my %fHashjk;
my $fileNum;
my @fg=glob("$inFile1/*.DvsFG");
for (my $i=0;$i<@fg;$i++){
  my $lineNum;
  my $trueNum;
  open(F,"gzip -dc $fg[$i]|") or die("$!: $fg[$i]\n");
  <F>;
  while(<F>){
    chomp;
    $lineNum++;
    my($indA,$indB,$indC,$indO,$d,$f)=split /\t/;
    next if ($f eq 'NA');
    $trueNum++;
    push (@{$fHashjk{$indA}{$indB}{$indC}},$f);
  }
  close(F);
  my $Anum1=keys %fHashjk;
  print "read $lineNum for fgJK file $fg[$i]; has $Anum1 Aind; $trueNum line have fgValue\n";
  $fileNum++;
}

my $Anum2=keys %fHashjk;
print "read $fileNum for fgJK file has $Anum2 Aind\n";

open(Fo,'>',$outFile) or die("$!: $outFile\n");
print Fo "indA\tindB\tindC\tmean\tz\tp\n";
foreach my $indA(sort {$a cmp $b} keys %fHashjk){
  foreach my $indB(sort {$a cmp $b} keys %{$fHashjk{$indA}}){
    foreach my $indC(sort {$a cmp $b} keys %{$fHashjk{$indA}{$indB}}){
      if (!defined $fHashjk{$indA}{$indB}{$indC}){
        print "for com $indA $indB $indC all f value is NA\n";
        print Fo "$indA\t$indB\t$indC\tNA\tNA\tNA\n";
        next;
      }
      my @samples=@{$fHashjk{$indA}{$indB}{$indC}};
      my $samNum=@samples;
      if ($samNum<3){
        print "for com $indA $indB $indC only have $samNum jk Samples\n";
        print Fo "$indA\t$indB\t$indC\tNA\tNA\tNA\n";
        next;
      }
      my ($mean,$z,$p)=ztest(@samples);
      print Fo "$indA\t$indB\t$indC\t$mean\t$z\t$p\n";
    }
  }
}
close(Fo);

sub ztest{
  my @winFg=@_;
  my $n=@winFg;
  my @x;
  for (my $i=0;$i<$n;$i++){
    my $sum=0;
    for (my $j=0;$j<$n;$j++){
      next if($i==$j);
      $sum+=$winFg[$j];
    }
    my $XiBar=$sum/($n-1);
    $x[$i]=$XiBar;
  }
  my $sum=0;
  for (my $i=0;$i<$n;$i++){
    $sum+=$x[$i];
  }
  my $XBar=$sum/$n;
  $sum=0;
  for (my $i=0;$i<$n;$i++){
    $sum+=($x[$i]-$XBar)*($x[$i]-$XBar);
  }
  my $varXBar=($n-1)*$sum/$n;
  my $standardError=sqrt($varXBar);
  my  $z=($XBar-0)/$standardError;
  my  $p = $zed->p_value($z);
  return ($XBar,$z,$p);
}

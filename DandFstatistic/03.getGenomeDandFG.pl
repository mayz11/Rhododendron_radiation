use strict;
use warnings;
use v5.10;

my($inDir,$outFile)=@ARGV;
die("usage: inDir outFile\n")unless($outFile);

my @inFile=glob("$inDir/*.gz");
my %fallFG;
my %fallD;
foreach my $inFile (@inFile) {
  open(F,"gzip -dc $inFile|") or die("$!: $inFile\n");
  print "$inFile\n";
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
        if($denominatorFG!=0){$fg=$numeratorFG/$denominatorFG;}
        if($denominatorD!=0){$d=$numeratorD/$denominatorD;}
        print Fo join("\t",$indA,$indB,$indC,$indO,$d,$fg),"\n";
      }
    }
  }
}
close(Fo);



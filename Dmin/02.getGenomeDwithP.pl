use strict;
use warnings;
use v5.10;

my($inFileD,$inFileZP,$outFile)=@ARGV;
die("usage: inFileD.gz inFileZP outFile\n")unless($outFile);


my %info;
open(F,"gzip -dc $inFileD |") or die("$!: $inFileD\n");
while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  my($name1,$name2,$name3,$name4,$d,$fg)=split /\t/;
  $info{"$name1\t$name2\t$name3"}{d}=$d;
}
close(F);

open(Fo,'>',$outFile) or die("$!: $outFile\n");
print Fo "name1\tname2\tname3\td\tz\tp\n";
open(F,'<',$inFileZP) or die("$!: $inFileZP\n");
while(<F>){
  chomp;
  next if(/^\s*$/);
  next if(/^\s*#/);
  my($name1,$name2,$name3,$xbar,$varxbar,$stderr,$samplemean,$z,$p)=split /\t/;
  my $name="$name1\t$name2\t$name3";
  print Fo join("\t",($name1,$name2,$name3,$info{$name}{d},$z,$p)),"\n" if(exists $info{$name}{d});
}
close(F);
close(Fo);


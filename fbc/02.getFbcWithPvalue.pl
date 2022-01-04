use strict;
use warnings;
use v5.10;

use Bio::TreeIO;
use IO::String;
use Bio::Tree::TreeFunctionsI;
use Statistics::Basic qw(median);
use Statistics::Zed;
my $zed=Statistics::Zed->new();
my($inFileTree,$inFilefGAll,$inFileJKzAll,$inOutgroupName,$outFile)=@ARGV;
die("usage: inFileTree fgAllSum inFileJKzAll inOutgroupName outFile\n")unless($outFile);


my %fHash;my $lineNum1;
open(F,"gzip -dc $inFilefGAll|") or die("$!: $inFilefGAll\n");
<F>;
while(<F>){
  chomp;
  my($indA,$indB,$indC,$indO,$d,$f)=split /\t/;
  $fHash{$indA}{$indB}{$indC}{$indO}=$f;
  $lineNum1++;
}
close(F);
my $Anum1=keys %fHash;
print "read $lineNum1 for allSum file; has $Anum1 Aind\n";

my %zHashjk;
my $lineNum2;
open(F,'<',$inFileJKzAll) or die("$!: $inFileJKzAll\n");
<F>;
while(<F>){
  chomp;
  my($indA,$indB,$indC,$mean,$z,$p)=split /\t/;
  $zHashjk{$indA}{$indB}{$indC}{out}=$z;
  $lineNum2++;
}
close(F);
my $Anum2=keys %zHashjk;
print "read $lineNum2 for allZfile; has $Anum2 Aind\n";


my $treeS;
open(F,'<',$inFileTree) or die("$!: $inFileTree\n");
{local $/;$treeS=<F>;chomp($treeS);}
close(F);

my $io = IO::String->new($treeS);
my $treeio = Bio::TreeIO->new(-fh => $io,-format => 'newick');

my $tree = $treeio->next_tree;
my $nodeRoot=$tree->get_root_node;
my @taxa = $tree->get_leaf_nodes;
my @nameC;
foreach my $taxa (@taxa) {
  push(@nameC,$taxa->id) if($taxa->id ne $inOutgroupName);
}

my($fbcMax,$fbcMin);

open(Fo,'>',$outFile) or die("$!: $outFile\n");
print Fo join("\t","nodeID","groupA","groupB",@nameC),"\n";

foreach my $subNode($nodeRoot->get_all_Descendents()){
  $subNode->id($subNode->_creation_id) if(! $subNode->is_Leaf);
  my %group;
  my %childID;
  for my $child ( $subNode->each_Descendent ) {
    if($child->is_Leaf){
      $childID{$child->_creation_id}=$child->id;
    }
    else{
      $childID{$child->_creation_id}=$child->_creation_id
    }
    if($child->is_Leaf){$group{$child->_creation_id}{$child->id}=1;}
    else{
      foreach my $subNodeT($child->get_all_Descendents()){
        $group{$child->_creation_id}{$subNodeT->id}=1 if( $subNodeT->is_Leaf );
      }
    }
  }
  my @groupId=keys %group;
  my $childNum=@groupId;
  if($childNum==0){
    next;
  }
  my @fbcAll1;
  my @fbcAll2;
  foreach my $nameC(@nameC){
    my ($fbc1,$a1)=getFbcCore($groupId[0],$groupId[1],\%group,$nameC);
    my $p1;
    if ($fbc1 ne "VT" and $fbc1 ne "ND" ){
      my $x=$a1+1;
      $x-=1;
      $p1=$zed->p_value($x);
      $p1=$p1/2.0;
      $p1=1 if ($a1<0);
      $fbcMax=$fbc1 if(!defined $fbcMax or $fbc1 > $fbcMax);
      $fbcMin=$fbc1 if(!defined $fbcMin or $fbc1 < $fbcMin);
    }else{
      $p1="NA";
    }
    push (@fbcAll1,"${fbc1}_${a1}_${p1}");
    my ($fbc2,$a2)=getFbcCore($groupId[1],$groupId[0],\%group,$nameC);
    my $p2;
    if ($fbc2 ne "VT" and $fbc2 ne "ND" ){
      
      my $x=$a2+1;
      $x-=1;
      $p2 = $zed->p_value($x);
      $p2=$p2/2.0;
      $p2=1 if ($a2<0);
      $fbcMax=$fbc2 if(!defined $fbcMax or $fbc2 > $fbcMax);
      $fbcMin=$fbc2 if(!defined $fbcMin or $fbc2 < $fbcMin);
    }else{
     $p2="NA"; 
    }
    push (@fbcAll2,"${fbc2}_${a2}_${p2}");
  }
  print Fo join("\t",$subNode->id,$childID{$groupId[0]},$childID{$groupId[1]},@fbcAll1),"\n";
  print Fo join("\t",$subNode->id,$childID{$groupId[1]},$childID{$groupId[0]},@fbcAll2),"\n";
}
close(Fo);

print("fbcMax=$fbcMax, fbcMin=$fbcMin\n");

my $newTree=$tree->as_text('newick');
my $outFileTree="$outFile.tree";
open(Fo,'>',$outFileTree) or die("$!: $outFileTree\n");
print Fo "$newTree\n";
close(Fo);

sub getFbcCore{
  my($groupA,$groupB,$group,$nameC)=@_;
  my @fA;my @zA;
  my $violateTree=0;
  foreach my $nameA(sort keys %{$$group{$groupA}}){
    if($nameA eq $nameC){
      $violateTree=1;
      last;
    }
    my @fB;my @zB;
    my @nameB=sort keys %{$$group{$groupB}};
    if(@nameB==0){
      $violateTree=1;
      last;
    }
    foreach my $nameB(@nameB){
      if($nameB eq $nameC){
        $violateTree=1;
        last;
      }
      if(!exists $fHash{$nameA}{$nameB}{$nameC}{$inOutgroupName}){print("for f File not exists $nameA $nameB $nameC  $inOutgroupName\n");}
      push(@fB,$fHash{$nameA}{$nameB}{$nameC}{$inOutgroupName});
      if(!exists $zHashjk{$nameA}{$nameB}{$nameC}{$inOutgroupName}){print("for z File not exists $nameA $nameB $nameC  $inOutgroupName\n");}
      push(@zB,$zHashjk{$nameA}{$nameB}{$nameC}{$inOutgroupName});
    }
    if($violateTree){
      last;
    }
    if(@fB==0){print "A=$nameA C=$nameC  $inOutgroupName fB count 0\n";}
    if(@zB==0){print "A=$nameA C=$nameC  $inOutgroupName zB count 0\n";}
    my $fmin;
    foreach my $f (@fB) {
      $fmin=$f if(!defined $fmin or $f < $fmin);
    }
    push(@fA,$fmin);
    my $zmin;
    foreach my $zScore (@zB) {
      $zmin=$zScore if(!defined $zmin or $zScore < $zmin);
    }
    push(@zA,$zmin);
  }
  my $fbc='-';my $zbc='-';
  if($violateTree){
    $fbc="VT";$zbc="VT";
  }
  elsif(@fA==0){
    $fbc="ND"; $zbc="ND";
      print "****@fA****@zA\n"
    }
  elsif(@zA==0){
    $fbc="ND"; $zbc="ND";
      print "****@fA****@zA\n"
    }  
  else{
    $fbc=median(@fA);
    $zbc=median(@zA);
  }
  return ($fbc,$zbc);
}

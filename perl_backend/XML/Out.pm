package XML::Out;
use strict;
use warnings;

use XML::LibXML;

sub write{
    my ($self,$pdb,$model,$bond) = @_;
    my $b = XML::LibXML::Element->new("BOND");
    my ($at1,$c1) = $bond->atom('1');
    my ($at2,$c2) = $bond->atom('2');
    my $atom1 = $pdb->atom($at1);
    my $atom2 = $pdb->atom($at2);

    $b->appendTextChild('model',$model);
    $b->appendTextChild('type',$bond->type);
    $b->appendTextChild('dist',$bond->getDist);

    my @atoms=($atom1,$atom2);
    my @res = (XML::LibXML::Element->new("RESIDUE"),
		XML::LibXML::Element->new("RESIDUE"));
    my @chains=($c1,$c2);

    for(my $i=0;$i<2;$i++){
	$res[$i]->setAttribute('index',$atoms[$i]->resNumber);
	$res[$i]->setAttribute('area',$atoms[$i]->Rarea);
	$res[$i]->setAttribute('pct',$atoms[$i]->Rpercent);
	$res[$i]->appendTextChild('name',$atoms[$i]->resName);
	$res[$i]->appendTextChild('chain',$chains[$i]);
	$res[$i]->appendTextChild('atom',$atoms[$i]->atomName);
	$res[$i]->appendTextChild('area',$atoms[$i]->area);
	$res[$i]->appendTextChild('percent',$atoms[$i]->percent);

	$b->addChild($res[$i]);
    }
    
    return $b->toString;
}

sub write2{
    my ($self,$bond, @models) = @_;
    my $b = XML::LibXML::Element->new("BOND");
    foreach my $model(@models){
	$b->appendTextChild('model',$model);
    }

    $bond =~ /([A-Z])(\d{1,4})([A-Z]{1,3})<-([A-Z]{6})->([A-Z])(\d{1,4})([A-Z]{1,3})/;
    my @chs = ($1,$5);
    my @res = ($2,$6);
    my @names = ($3,$7);
    my $type = $4;
    my @xRes = (XML::LibXML::Element->new("RESIDUE"),
		XML::LibXML::Element->new("RESIDUE"));
    $b->appendTextChild('type', $type);

    for(my $i=0;$i<2;$i++){
	$xRes[$i]->setAttribute('index',$res[$i]);
	$xRes[$i]->appendTextChild('name',$names[$i]);
	$xRes[$i]->appendTextChild('chain',$chs[$i]);

	$b->addChild($xRes[$i]);
    }
    return $b->toString;
}
1;

__DATA__
write:
<BOND index="1">
    <model>12</model>
    <type>HYDPHB</type>
    <distance>4.52</distance>
    <RESIDUE index="11">
      <name>GLU</name>
      <role>donor</role>
      <ch>A</ch>
      <atom>CA</atom>
      <area>3.88</area>
      <pct>0.27</pct>
    </RESIDUE>
    <RESIDUE index="18">
      <name>ARG</name>
      <role>acceptor</role>
      <ch>B</ch>
      <atom>CZ</atom>
      <area>1.97</area>
      <pct>0.15</pct>
    </RESIDUE>
  </BOND>
write2:
<BOND index="1">
 <model>6</model>
 <model>7</model>
 <model>10</model>
 <model>15</model>
 <model>16</model>
 <model>23</model>
 <model>25</model>
 <model>30</model>
 <type>HYDPHB</type>
 <RESIDUE index="8">
  <name>LYS</name>
  <chain>U</chain>
 </RESIDUE>
 <RESIDUE index="293">
  <name>MET</name>
  <chain>S</chain>
 </RESIDUE>
</BOND>

package Sheet;
use strict;
use warnings;

use Excel::Writer::XLSX;

sub generate_sheet{
    my $self=shift;
    my @files=@_;

    foreach my $file (@files){
	my $filestub=substr($file,0,rindex($file,'.'));
    
	my @lines=();
	my $header=2;
	my $max_cols=0;
	open(FH, "< $file") || die "Can't open $file\n";
	while(<FH>){
	    chomp;
	    if($header){$header--;next;}
	    my @temp=split(/\s+/);
	    @temp=@temp[1..$#temp];
	    $max_cols=$temp[7] if $temp[7]>$max_cols;
	    push(@lines,\@temp);
	}
	close(FH);
	
# Create a new Excel workbook
	my $workbook = Excel::Writer::XLSX->new( $filestub.'.xlsx' );
	my $worksheet = $workbook->add_worksheet();
	
	my $format_center = $workbook->add_format();
	$format_center->set_align( 'center' );
	
	my $format_yellow = $workbook->add_format();
	$format_yellow->set_align( 'center' );
	$format_yellow->set_bg_color( 'yellow' );
	
	my @sums=();
	for(my $col=0;$col<$max_cols;$col++){
	    $sums[$col]=0;
	}
	
	for(my $row=0;$row<scalar(@lines);$row++){
#    print $row,"\t",join("|",@{$lines[$row]}),"\n";
	    for(my $col=0;$col<8;$col++){
		$worksheet->write( $row, $col, $lines[$row][$col] );
	    }	
	    
	    my $format=$format_center;
	    #check to see if complete
	    if(scalar(@{$lines[$row]})==$max_cols+8){
		$format=$format_yellow;
	    }
	    
	    my $arr_pos=8;
	    my $she_pos=8;
	    for(my $col=1;$col<=$max_cols;$col++){
		if($arr_pos<scalar(@{$lines[$row]}) && $col == $lines[$row][$arr_pos]){
#	    print $col,"\t",$arr_pos,"\t",$she_pos,"\t",$lines[$row][$arr_pos],"\n" if $row==67;
		    $worksheet->write( $row, $she_pos, $lines[$row][$arr_pos], $format );
		    $arr_pos++;
		    $she_pos++;
		    $sums[$col-1]++;
		}else{
		    $worksheet->write( $row, $she_pos, ' ', $format );
#	    print $col,"\t",$arr_pos,"\t",$she_pos,"\t \n" if $row==67;
		    $she_pos++;
		}
	    }
	}
	for(my $col=0;$col<$max_cols;$col++){
#	$worksheet->write( scalar(@lines), $col+8, $sums[$col], $format_center );
	}
    }
}

1;

#!/usr/bin/perl
#
use strict;
use warnings;
my $opt={};
$opt->{infile}="../run_script/tmp.inp";
$opt->{fst}=1;
$opt->{end}=40;
#$opt->{end}=4;
@{$opt->{lines}}=();
&readinp($opt);
for (my $i = $opt->{fst};$i<=$opt->{end};$i++) {
	&output($i, $opt);
}

sub readinp {
	my ($opt)=@_;
	open(INFILE,$opt->{infile}) || die "Cannot open $opt->{infile}\n";
	my $in=0;
	my $out=0;
	while(<INFILE>){
		push(@{$opt->{lines}},$_);
	}
	close(INFILE);
}

sub output {
	my ($inum,$opt)=@_;
	my $outfile=sprintf("eq.%d.inp",$inum);
	open(OUTFILE,">".$outfile) || die "Cannot open $outfile\n";
	my $in=0;
	my $out=0;
	my $prev=$inum-1;
	for (my $i = 0;$i<scalar(@{$opt->{lines}});$i++) {
		my $str=$opt->{lines}->[$i];
		if ($out==1 && $str=~/^\[/) {
			$out=0;
		} elsif ($str=~/^\[OUTPUT/) {
			$in=0;
			$out=1;
		} elsif ($str=~/^\[INPUT/) {
			$in=1;
			$out=0;
		} elsif ($in==1 && $str=~/^rstfile = /) {
			$str=sprintf("rstfile = eq.%d.rst\n",$prev);
		} elsif ($out==1 && $str=~/^rstfile = /) {
			$str=sprintf("rstfile = eq.%d.rst\n",$inum);
		} elsif ($out==1 && $str=~/^dcdfile = /) {
			$str=sprintf("dcdfile = eq.%d.dcd\n",$inum);
		}
		printf OUTFILE "%s",$str;
	}
	close(OUTFILE);
}

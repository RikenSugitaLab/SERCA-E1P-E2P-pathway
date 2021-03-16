#!/usr/bin/perl
#
use strict;
use warnings;
my $opt={};
$opt->{inp}="./template_umb/temp.inp";
$opt->{sh}="./template_umb/temp.sh";
$opt->{next}=$ARGV[0];
$opt->{replicas}=64;
$opt->{hnam}="umb";
$opt->{dnam}="umb";
$opt->{inname}="rpath";
$opt->{hnam_eq}="pr";
$opt->{dnam_eq}="proc";
$opt->{eqlast}=30;

$opt->{header}=sprintf("%s%02d",$opt->{hnam},$opt->{next});
$opt->{dir}=sprintf("%s%02d",$opt->{dnam},$opt->{next});
if ($opt->{next} > 1) {
	$opt->{pheader}=sprintf("%s%02d",$opt->{hnam},$opt->{next}-1);
	$opt->{pdir}=sprintf("%s%02d",$opt->{dnam},$opt->{next}-1);
} else {
	$opt->{pheader}=sprintf("%s%02d",$opt->{hnam_eq},$opt->{eqlast});
	$opt->{pdir}=sprintf("%s%02d",$opt->{dnam_eq},$opt->{eqlast});
}

$opt->{inheader}=sprintf("%s_%drep",
		$opt->{header},$opt->{replicas});
$opt->{FC}=0.002;
# For equib
$opt->{fix_terminal}=1;
$opt->{rpath_period}=0;
# For product
#$opt->{rpath_period}=1000;
#$opt->{fix_terminal}=1;
#$opt->{fix_terminal}=0; #from 2
#$opt->{delta}=0.3;
#$opt->{smooth}=0.001;
$opt->{fc_line}=sprintf("constant1     = \\\n ");
$opt->{separator}=10;
for (my $i = 0 ;$i<$opt->{replicas};$i++) {
	if ($i > 0 && $i-int($i/$opt->{separator})*$opt->{separator} == 0) {
		$opt->{fc_line}=sprintf ("%s \\\n ",$opt->{fc_line});
	}
	$opt->{fc_line}=sprintf ("%s %s",$opt->{fc_line},$opt->{FC});
}
if ($opt->{replicas}-int($opt->{replicas}/$opt->{separator})*$opt->{separator}!= 0) {
	$opt->{fc_line}=sprintf ("%s\n",$opt->{fc_line});
}

my $stmp=sprintf("nreplica         = %d\n",$opt->{replicas});
$stmp=sprintf("%srpath_period      = %d\n",$stmp, $opt->{rpath_period});
$stmp=sprintf("%srest_function     = 1\n",$stmp);
if ($opt->{rpath_period} > 0) {
	if ($opt->{fix_terminal} == 1) {
		$stmp=sprintf("%sfix_terminal      = YES\n",$stmp);
		$stmp=sprintf("%savoid_shrinkage   = YES\n",$stmp);
	} else {
		$stmp=sprintf("%sfix_terminal      = NO\n",$stmp);
		$stmp=sprintf("%savoid_shrinkage   = YES\n",$stmp);
	}
	$stmp=sprintf("%sdelta     = %f\n",$stmp, $opt->{delta});
	$stmp=sprintf("%ssmooth    = %f\n",$stmp, $opt->{smooth});
}

$opt->{rpath_condition}=$stmp;

if (! -d $opt->{pdir}) {
	printf STDERR "Error: %s is not found\n", $opt->{pdir};
	exit;
}
if (! -d $opt->{dir}) {
	mkdir($opt->{dir});
}

&readinp($opt,"inp");
&output($opt,"inp");
&readinp($opt, "sh");
&output($opt,"sh");
my $command=sprintf("chmod a+x %s/%s.sh",$opt->{dir},$opt->{inheader});
system($command);

sub readinp {
	my ($opt,$name)=@_;
	@{$opt->{lines}->{$name}}=();
	open(INFILE,$opt->{$name}) || die "Cannot open $opt->{$name}\n";
	while(<INFILE>){
		push(@{$opt->{lines}->{$name}},$_);
	}
	close(INFILE);
}

sub output {
	my ($opt,$name)=@_;
	my $inum=$opt->{next};
	my $outfile=sprintf("%s/%s.%s",
			$opt->{dir},$opt->{inheader},$name);
	open(OUTFILE,">".$outfile) || die "Cannot open $outfile\n";
	my $in=0;
	my $out=0;
	my $prev=$inum-1;
	for (my $i = 0;$i<scalar(@{$opt->{lines}->{$name}});$i++) {
		my $str=$opt->{lines}->{$name}->[$i];
		if ($out==1 && $str=~/^\[/) {
			$out=0;
		} elsif ($str=~/^\[OUTPUT/) {
			$in=0;
			$out=1;
		} elsif ($str=~/^\[INPUT/) {
			$in=1;
			$out=0;
#		} elsif ($prev > 0 && $in==1 && $str=~/^rstfile/) {
		} elsif ( $in==1 && $str=~/^rstfile/) {
			$str=sprintf("rstfile = ../%s/%s.{}.rst\n",
					$opt->{pdir},$opt->{pheader});
		} elsif ($out==1 && $str=~/^rstfile/) {
			$str=sprintf("rstfile = %s.{}.rst\n",$opt->{header});
		} elsif ($out==1 && $str=~/^dcdfile/) {
			$str=sprintf("dcdfile = %s.{}.dcd\n",$opt->{header});
		} elsif ($out==1 && $str=~/^logfile/) {
			$str=sprintf("logfile = %s.{}.log\n",$opt->{header});
		} elsif ($out==1 && $str=~/^rpathfile/) {
			$str=sprintf("rpathfile = %s.{}.rpath\n",$opt->{header});
		} elsif ($out==1 && $str=~/^rpathlogfile/) {
			if ( $opt->{rpath_period} > 0) {
				$str=sprintf("rpathlogfile = %s.rpathlog\n",$opt->{header});
			} else {
				next;
			}
		}
		if ($str=~/^crdout_period/) {
			if ( $opt->{rpath_period} > 0) {
				$str=sprintf("crdout_period   = %d\n",$opt->{rpath_period});
			}
		}
		if ($str=~/^eneout_period/) {
			if ( $opt->{rpath_period} > 0) {
				$str=sprintf("eneout_period   = %d\n",$opt->{rpath_period});
			}
		}
		if ($str=~/^\<constant1\>/) {
			$str=$opt->{fc_line};
		}
		if ($str=~/^\<rpath_condition\>/) {
			$str=$opt->{rpath_condition};
		}
		if ($name eq "sh" && $str=~/^name=/) {
			$str=sprintf("name=%s\n",$opt->{inheader});
		}
		printf OUTFILE "%s",$str;
	}
	close(OUTFILE);
}

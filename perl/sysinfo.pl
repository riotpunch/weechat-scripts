#
# Copyright (c) 2002-2005 David Rudie
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Several additions and fixes to this script were contributed by Travis
# Morgan and therefore are Copyright (c) 2003-2006 Travis Morgan
#
# If you notice any bugs including spacing issues, wrong detection of hardware,
# obvious features missing, etc, we both want to hear about them.  If you make
# this script work on other operating systems and/or architectures please send
# either of us your patches.  My e-mail address is d.rudie@gmail.com and
# Travis Morgan's e-mail address is imbezol@criticaldamage.com
#
# The latest version can be obtained from either http://www.inexistent.com/ or
# http://imbezol.org/sysinfo/
#
# ported to weechat (http://www.weechat.org/) by Nils Görs. Copyright
# (c) 2011 Nils Görs
#
# 2011-09-27: 0.2 nils_2 <weechatter@arcor.de>
#           : recognition for linux kernel 3.x added
#           : option "channel" changed to "-channel"
# 2011-06-03: initial release
#           : ported to weechat by nils_2@freenode.#weechat
#           : based on sysinfo 2.81.16
#
# Development is currently hosted at
# https://github.com/weechatter/weechat-scripts

use POSIX qw(floor);
use strict;

my $PRGNAME     = "sysinfo";
my $VERSION     = "0.2";
my $DESCR       = "provides a system info command";

# Set up the arrays and variables first.
use vars qw(
	@arr
	@arr1
	@arr2
	$cpu
	@cpu
	@cpuinfo
	$data
	$distro
	$distrov
	@distros
	@data
	$df
	@dmesgboot
	@hinv
	@meminfo
	$mhz
	@mhz
	$model
	@netdev
	@netstat
	@nic
	@nicname
	$realdistro
	$smp
	@smp
	$stream
	$sysctl
	@uptime
	$var
	$vara
	$varb
	$varc
	$vard
	$varh
	$varm
	$varp
	$varx
	$vary
	$varz
	$col1
	$col2
);


# Specify your NIC interface name (eth0, rl0, fxp0, etc) and a name for it.
#
# Example:      @nic = ('eth0', 'eth1');
#               @nicname = ('External', 'Internal');
#
# NOTE: If you set one then you HAVE to set the other.
#@nic		= ('');
#@nicname	= ('');

# default values in setup file (~/.weechat/plugins.conf)
my %options = ( 'showhostname'          => 'on',
                'useshorthostname'      => 'on',
                'showdistro'            => 'on',
                'showos'                => 'on',
                'showusers'             => 'on',
                'showcpu'               => 'on',
                'showprocesses'         => 'on',
                'showuptime'            => 'on',
                'showloadaverage'       => 'on',
                'showbattery'           => 'off',# Requires APM and /proc/apm or /proc/acpi/battery/
                'showmemoryusage'       => 'on',
                'showdiskusage'         => 'on',
                'shownetworktraffic'    => 'off',
                'color'                 => 'default',
                'nic'                   => '',
                'nicname'               => '',
);

my $col1 = '';                                 # reset color
my $col2 = '';

###############################################
### Nothing below here should need changed. ###
###############################################

my $sysinfoVer	= '2.81.16';
my $sysinfoDate	= 'Jun 11, 2009, 11:09am MDT';

my $os		= `uname -s`; chomp($os);
my $osn		= `uname -n`; chomp($osn);
if ($options{useshorthostname} eq "on") {
	$osn	=~ s/([^\.]*).*/$1/;
}
my $osv		= `uname -r`; chomp($osv);
my $osm		= `uname -m`; chomp($osm);
my $uname	= "$os $osv/$osm";

my $darwin		= 1 if $os =~ /^Darwin$/;
my $freebsd		= 1 if $os =~ /^FreeBSD$/;
my $dragonfly	= 1 if $os =~ /^DragonFly$/;
my $linux		= 1 if $os =~ /^Linux$/;
my $netbsd		= 1 if $os =~ /^NetBSD$/;
my $openbsd		= 1 if $os =~ /^OpenBSD$/;
my $irix		= 1 if $os =~ /^IRIX$/;
my $irix64		= 1 if $os =~ /^IRIX64$/;
my $sun			= 1 if $os =~ /^SunOS$/;


my $alpha		= 1 if $osm =~ /^alpha$/;
my $armv4l		= 1 if $osm =~ /^armv4l$/;
my $armv5l		= 1 if $osm =~ /^armv5l$/;
my $i586		= 1 if $osm =~ /^i586$/;
my $i686		= 1 if $osm =~ /^i686$/;
my $ia64		= 1 if $osm =~ /^ia64$/;
my $mips		= 1 if $osm =~ /^mips$/;
my $parisc		= 1 if $osm =~ /^parisc$/;
my $parisc64	= 1 if $osm =~ /^parisc64$/;
my $ppc			= 1 if $osm =~ /^ppc$/;
my $ppc64		= 1 if $osm =~ /^ppc64$/;
my $x86_64		= 1 if $osm =~ /^x86_64$/;


my $d7		= 1 if $darwin && $osv =~ /^7\.\d+\.\d+/;
my $d8		= 1 if $darwin && $osv =~ /^8\.\d+\.\d+/;
my $d9		= 1 if $darwin && $osv =~ /^9\.\d+\.\d+/;
my $l26		= 1 if $linux && $osv =~ /^2\.6/;
my $l30         = 1 if $linux && $osv =~ /^3\../;
my $f_old	= 1 if $freebsd && $osv =~ /^4\.1-/ || $osv =~ /^4\.0-/ || $osv =~ /^3/ || $osv =~ /^2/;

my $progArgs = $ARGV[0];
if($progArgs) {
	if($progArgs eq '-v' || $progArgs eq '--version') {
		print "SysInfo v$sysinfoVer   $sysinfoDate\n";
		print "Written by David Rudie <d.rudie\@gmail.com> and Travis Morgan <imbezol\@criticaldamage.com>\n";
		exit -1;
	}
}

sub cmd_sysinfo {
    my ($data, $buffer, $args) = ($_[0], $_[1], $_[2]);
    my $i = 0;
    my $to_channel = 0;
    if ( $args eq "-channel" ){
      $args = "";
      $to_channel = 1;
    }

    if ( $args ne ""){                                                 # use user-command settings
      my @args_array=split(/ /,$args);
      $i = $args_array[0] if ( $args_array[0]  =~ /^\d*$/ );
        if (grep(m/^-channel$/, @args_array)){
          $to_channel = 1;
        }
        if (grep(m/^hostname$/, @args_array)){
          $options{showhostname} = "on";
        }else{
          $options{showhostname} = "off";
        }
        if (grep(m/^os$/, @args_array)){
          $options{showos} = "on";
        }else{
          $options{showos} = "off";
        }
        if (grep(m/^cpu$/, @args_array)){
          $options{showcpu} = "on";
        }else{
          $options{showcpu} = "off";
        }
        if (grep(m/^processes$/, @args_array)){
          $options{showprocesses} = "on";
        }else{
          $options{showprocesses} = "off";
        }
        if (grep(m/^uptime$/, @args_array)){
          $options{showuptime} = "on";
        }else{
          $options{showuptime} = "off";
        }
        if (grep(m/^loadaverage$/, @args_array)){
          $options{showloadaverage} = "on";
        }else{
          $options{showloadaverage} = "off";
        }
        if (grep(m/^battery$/, @args_array)){
          $options{showbattery} = "on";
        }else{
          $options{showbattery} = "off";
        }
        if (grep(m/^memory$/, @args_array)){
          $options{showmemoryusage} = "on";
        }else{
          $options{showmemoryusage} = "off";
        }
        if (grep(m/^disk$/, @args_array)){
          $options{showdiskusage} = "on";
        }else{
          $options{showdiskusage} = "off";
        }
        if (grep(m/^network$/, @args_array)){
          $options{shownetworktraffic} = "on";
        }else{
          $options{shownetworktraffic} = "off";
        }
        if (grep(m/^users$/, @args_array)){
          $options{showusers} = "on";
        }else{
          $options{showusers} = "off";
        }
        if (grep(m/^distro$/, @args_array)){
          $options{showdistro} = "on";
        }else{
          $options{showdistro} = "off";
        }
    }else{
      init_config();
    }

if($linux) {
	@cpuinfo		= &openfile("/proc/cpuinfo");
	@meminfo		= &openfile("/proc/meminfo");
	@netdev			= &openfile("/proc/net/dev");
	@uptime			= &openfile("/proc/uptime");

	$df			= 'df -lkP';

	if($options{showdistro} eq "on") {
		@distros = (
		"Gentoo",		"/etc/gentoo-release",
		"Fedora Core",	"/etc/fedora-release",
		"SuSE",			"/etc/SuSE-release",
		"Slackware",	"/etc/slackware-version",
		"Cobalt",		"/etc/cobalt-release",
		"Debian",		"/etc/debian_version",
		"Mandrake",		"/etc/mandrake-release",
		"Mandrake",		"/etc/mandrakelinux-release",
		"Yellow Dog",	"/etc/yellowdog-release",
		"OpenFiler",	"/etc/distro-release",
		"Red Hat",		"/etc/redhat-release"
		);
		$distro = "";
		$distrov = "";
		do {
			if (-e $distros[1]) {
				$distro = $distros[0];
				$distrov = `cat $distros[1] | head -n 1`;
				chomp($distrov);
				$distrov =~ s/[^0-9]*([0-9.]+)[^0-9.]{0,1}.*/$1/;
			}
			shift @distros;	shift @distros;
		} until (scalar @distros == 0) || (length $distro > 0);
		if ($distro eq "Debian") {
			if (-e "/etc/lsb-release") {
				$realdistro = `cat /etc/lsb-release | grep DISTRIB_DESCRIPTION`;
				if ($realdistro ne "") {
					chomp $realdistro;
					$realdistro	=~ s/DISTRIB_DESCRIPTION="//;
					$realdistro	=~ s/"$//;
					$distro		= $realdistro;
					$distrov	= $realdistro;
					$distro		=~ s/ [0-9.]*$//;
					$distrov	=~ s/.* ([0-9.]*)/$1/;
				}
			}
		}
		if ($distro eq "Red Hat") {
			$realdistro = `cat /etc/redhat-release`;
			if ($realdistro =~ "^CentOS") {
				$distro = "CentOS";
			}
		}
	}
} elsif($irix || $irix64) {
	@hinv			= `hinv`;
} else {
	@dmesgboot		= &openfile("/var/run/dmesg.boot");
	if($sun) {
		@netstat		= `netstat -in`;
	} else {
		@netstat		= `netstat -ibn`;
	}
	if($darwin) {
		$sysctl		= '/usr/sbin/sysctl';
	} else {
		$sysctl		= '/sbin/sysctl';
	}
	if($armv4l || $armv5l) {
		$df			= 'df -k';
	} elsif($f_old) {
		$df			= 'df -k';
	} else {
		$df			= 'df -lk';
	}

}

if($options{showcpu} eq "on") {
	if($freebsd || $dragonfly) {
		if($alpha) {
			@cpu		= grep(/^COMPAQ/, @dmesgboot);
			$cpu		= join("\n", $cpu[0]);
		} else {
			@cpu		= grep(/CPU: /, @dmesgboot);
			$cpu		= join("\n", @cpu);
			$cpu		=~ s/Warning:.*disabled//;
			@cpu		= split(/CPU: /, $cpu);
			$cpu		= $cpu[1];
			$cpu		=~ s/\s\d\.\d\dGHz//g;
			$cpu		=~ s/\s*[^\s]*-class CPU//gi;
			$cpu		=~ s/(\S*)-MHz/$1 MHz/gi;
			$cpu		=~ s/@\s+//;
			chomp($cpu);
			$smp		= `$sysctl -n hw.ncpu`;
	 		chomp($smp);
		if ( $smp eq 1 ) {
				$smp = "";
			}
		}
	}
	if($netbsd) {
		if($alpha) {
			@cpu		= grep(/^COMPAQ/, @dmesgboot);
			$cpu		= join("\n", $cpu[0]);
			@cpu		= split(/, /, $cpu);
			$cpu		= $cpu[0];
		} else {
			@cpu		= grep(/^v?cpu0.*MHz/, @dmesgboot);
			@cpu		= grep(!/apic/, @cpu);
			@cpu		= split(/: /,$cpu[0]);
			$cpu		= $cpu[1];
			$cpu		=~ s/, id.*//;
			$mhz		= $cpu;
			$mhz		=~ s/.* ([.0-9]+) *MHz.*$/$1/;
			$cpu		=~ s/,.*//;
			$cpu		= "$cpu ($mhz MHz)";
			$smp		= `$sysctl -n hw.ncpu`;
			chomp($smp);
			if ( $smp eq 1 ) {
				$smp = "";
			}
		}
	}
	if($openbsd) {
		@cpu		= grep(/cpu0: /, @dmesgboot);
		@cpu		= grep(/[M|G]Hz/, @cpu);
		$cpu		= join("\n", @cpu);
		@cpu		= split(/: /, $cpu);
		$cpu		= $cpu[1];
		$cpu		=~ s/, / /;
		$cpu		=~ s/([0-9.]* [MG]Hz)$/($1)/;
		$smp		= `$sysctl -n hw.ncpu`;
		chomp($smp);
		if ( $smp eq 1 ) {
			$smp = "";
		}
	}
	if($irix || $irix64) {
		@cpu		= grep(/CPU:/, @hinv);
		$cpu		= join("\n", @cpu);
		$cpu		=~ s/^.*(R[0-9]*) .*$/$1/;
		@mhz		= grep(/MHZ/, @hinv);
		$mhz		= join("\n", @mhz);
		$mhz		= $mhz[0];
		$mhz		=~ s/^.* ([0-9]*) MHZ.*$/$1/;
		@smp		= grep(/ IP/, @hinv);
		$smp		= $smp[0];
		$smp		=~ s/^([0-9]*) .*$/$1/;
		chomp($smp);
		chomp($cpu);
		chomp($mhz);
		$cpu		= "MIPS $cpu ($mhz MHz)";
	}
	if($linux) {
		if($alpha) {
			$cpu		= &cpuinfo("cpu\\s+: ");
			$model		= &cpuinfo("cpu model\\s+: ");
			$cpu		= "$cpu $model";
			$smp		= &cpuinfo("cpus detected\\s+: ");
		}
		if($armv4l || $armv5l) {
			$cpu		= &cpuinfo("Processor\\s+: ");
		}
		if($i686 || $i586 || $x86_64) {
			$cpu		= &cpuinfo("model name\\s+: ");
			$cpu		=~ s/(.+) CPU family\t+\d+MHz/$1/g;
			$cpu		=~ s/(.+) CPU .+GHz/$1/g;
			$mhz		= &cpuinfo("cpu MHz\\s+: ");
			$mhz		=~ s/^\s*//g;
			$cpu		= "$cpu ($mhz MHz)";
			@smp		= grep(/processor\s+: /, @cpuinfo);
			$smp		= scalar @smp;
		}
		if($ia64) {
			$cpu		= &cpuinfo("vendor\\s+: ");
			$model		= &cpuinfo("family\\s+: ");
			$mhz		= &cpuinfo("cpu MHz\\s+: ");
			$mhz		= sprintf("%.2f", $mhz);
			$cpu		= "$cpu $model ($mhz MHz)";
			@smp		= grep(/processor\s+: /, @cpuinfo);
			$smp		= scalar @smp;
		}
		if($mips) {
			$cpu		= &cpuinfo("cpu\\s+: ");
			$model		= &cpuinfo("cpu model\\s+: ");
			$cpu		= "$cpu $model";
		}
		if($parisc || $parisc64) {
			$cpu		= &cpuinfo("cpu\\s+: ");
			$model		= &cpuinfo("model name\\s+: ");
			$mhz		= &cpuinfo("cpu MHz\\s+: ");
			$mhz		= sprintf("%.2f", $mhz);
			$cpu		= "$model $cpu ($mhz MHz)";
		}
		if($ppc || $ppc64) {
			$cpu		= &cpuinfo("cpu\\s+: ");
			$mhz		= &cpuinfo("clock\\s+: ");
			$mhz		=~ s/^(\d+\.\d{3})\d*\s*MHz/$1 MHz/;
			$cpu		=~ s/, altivec supported//;
			if($cpu =~ /^(PPC)*9.+/) {
				$model		= "IBM PowerPC G5";
			} elsif($cpu =~ /^74.+/) {
				$model		= "Motorola PowerPC G4";
			} else {
				$model		= "IBM PowerPC G3";
			}
			$cpu		= "$model $cpu ($mhz)";
			$smp		= `/bin/grep -c -e '^processor\\s*:\\s*[0-9]\\+' /proc/cpuinfo`; chomp($smp);
		}
      } elsif($sun) {
			my $osp		= `uname -p`; chomp($osp);
			if($osv =~ /^5\.11/ || ($osv =~ /^5\.10/ && $osp =~ "i386")) {
				$cpu	= `/usr/sbin/psrinfo -vp | tail -1`; chomp($cpu);
				$mhz	= `/usr/sbin/psrinfo -vp | grep MHz | awk '{ print "(" \$(NF-1) " " \$NF}' | tail -1`; chomp($mhz);
				$cpu	= "$cpu $mhz";
				$smp	= `/usr/sbin/psrinfo -p`; chomp($smp);
				$cpu	=~	s/^\s*//;
			}
			if($osp =~ "sparc") {
				$cpu    = `/usr/platform/${osm}/sbin/prtdiag | head -1`; chomp($cpu);
				$cpu	=~ s/.*${osm} //;
				$smp	= `/usr/sbin/psrinfo | wc -l`;
			}
	} elsif($darwin) {
		$cpu		= `hostinfo | grep 'Processor type' | cut -f2 -d':'`; chomp($cpu);
		$cpu		=~ s/^\s*(.+)\s*$/$1/g;
		if($cpu =~ /^ppc7.+/) {
			$cpu	= "Motorola PowerPC G4";
		}
		if($cpu =~ /^ppc970/) {
			$cpu	= "Motorola PowerPC G5";
		}
		if ($cpu =~ /^i486/) {
			$cpu	= `sysctl -n machdep.cpu.brand_string`; chomp($cpu);
		}
		$mhz		= `$sysctl -n hw.cpufrequency`; chomp($mhz);
		$mhz		= sprintf("%.2f", $mhz / 1000000);
		$cpu		= "$cpu ($mhz MHz)";
		$smp		= `hostinfo | grep "physically available" | cut -f1 -d' '`; chomp($smp);
	}
	if($smp && $smp gt 1) {
		$cpu = "$smp x $cpu";
	}
	$cpu	=~ s/\s*@\s*\d*\.\d*\s*GHz//;
	$cpu	=~ s/^\s+//;
	$cpu	=~ s/\(R\)//gi;
	$cpu	=~ s/\(tm\)//gi;
	$cpu	=~ s/\([^(]*GenuineIntel[^)]*\)//;
	$cpu	=~ s/\s*processor//gi;
	$cpu	=~ s/\s*CPU//gi;
	$cpu	=~ s/ +/ /g;
}

my $output;

  if($options{showhostname} eq "on")             { $output  = $col1."Hostname".weechat::color($options{color}).": ".$col1.$osn.weechat::color($options{color})." - "; }
  if($options{showos} eq "on")                   { $output .= $col1."OS".weechat::color($options{color}).": ".$col1.$uname.weechat::color($options{color})." - "; }



if($linux && $options{showdistro} eq "on" && length $distro > 0 ) { 
        $output .= $col1."Distro".weechat::color($options{color}).": ".$col1.$distro;
        if (length $distrov > 0) {
                $output .= " ".$distrov;
        }
        $output .= weechat::color($options{color})." - ";
}

if($options{showcpu} eq "on")                   { $output .= $col1."CPU".weechat::color($options{color}).": ".$col1.$cpu.weechat::color($options{color})." - "; }
if($options{showprocesses} eq "on")             { $output .= $col1."Processes".weechat::color($options{color}).": ".$col1.&processes.weechat::color($options{color})." - "; }
if($options{showuptime} eq "on")                { $output .= $col1."Uptime".weechat::color($options{color}).": ".$col1.&uptime.weechat::color($options{color})." - "; }
if($options{showusers} eq "on")                 { $output .= $col1."Users".weechat::color($options{color}).": ".$col1.&users.weechat::color($options{color})." - "; }
if($options{showloadaverage} eq "on")           { $output .= $col1."Load Average".weechat::color($options{color}).": ".$col1.&loadaverage.weechat::color($options{color})." - "; }
if($options{showbattery} eq "on")               { $output .= $col1."Battery".weechat::color($options{color}).": ".$col1.&battery.weechat::color($options{color})." - "; }
if($options{showmemoryusage} eq "on")           { $output .= $col1."Memory Usage".weechat::color($options{color}).": ".$col1.&memoryusage.weechat::color($options{color})." - "; }
if($options{showdiskusage} eq "on")             { $output .= $col1."Disk Usage".weechat::color($options{color}).": ".$col1.&diskusage; }
if($options{shownetworktraffic} eq "on")        { $output .= &networktraffic; }
  return weechat::WEECHAT_RC_OK if ( not defined $output or $output eq "");
$output =~ s/ - $//g;


  if ( $to_channel == 1 ){
    $output = weechat::string_remove_color($output, "");
    weechat::command(weechat::current_buffer(),"/say " . $output);
  }elsif ( $to_channel == 0 ){
    weechat::print(weechat::current_buffer(),$output);
  }

  return weechat::WEECHAT_RC_OK;
}

sub batteryacpi {
	my $data = "";
	my ($bfull, $bcur, @dirs, $dir);

	if (opendir(DIR, '/proc/acpi/battery/')) {
		@dirs = grep { !/^\./ } readdir (DIR);
		closedir(DIR);
		foreach $dir (@dirs) {
			$bfull = "";
			$bcur = "";
			if(open(FD, '/proc/acpi/battery/'.$dir.'/info')) {
				while (<FD>) {
					if (/^last full capacity:\ +([0-9]+)/) {
						$bfull = $1;
					}
				}
				close(FD);
			}
			if(open(FD, '/proc/acpi/battery/'.$dir.'/state')) {
				while (<FD>) {
					if (/^remaining capacity:\ +([0-9]+)/) {
						$bcur = $1;
					}
				}
				close(FD);
			}
			if ($bfull ne "") {
				if ($data ne "") {
					$data = $data." ";
				}
				$data = $data.sprintf("%.0f",($bcur/$bfull*100)); 
				$data = $data."%";
			}
		}
	}
	return $data;
}

sub battery {
	$data = "";

	if ( -f '/proc/apm') {
		if(open(FD, '/proc/apm')) {
			while($stream = <FD>) {
				$data .= $stream;
				@data = split(/\n/, $data);
			}
			close(FD);
		}
		$data = $data[0];
		$data =~ s/.+\s(\d+%).+/$1/;
	} elsif ( -d '/proc/acpi/battery') {
		$data=&batteryacpi;
	}
	return $data;
}

sub cpuinfo {
	my $string = shift;
	@arr = grep(/$string/, @cpuinfo);
	$var = join("\n", $arr[0]);
	@arr = split(/: /, $var);
	$var = $arr[1];
	return $var;
}

sub diskusage {
	if($irix || $irix64) {
		$vara = `$df | grep dev | awk '{ sum+=\$3 / 1024 / 1024}; END { print sum }'`; chomp($vara);
		$vard = `$df | grep dev | awk '{ sum+=\$4 / 1024 / 1024}; END { print sum }'`; chomp($vard);
	} elsif($sun) {
		$vara = `$df | grep -v swap | grep -v libc | awk '{ sum+=\$2 / 1024 / 1024}; END { print sum }'`; chomp($vara);
		$vard = `$df | grep -v swap | grep -v libc | awk '{ sum+=\$3 / 1024 / 1024}; END { print sum }'`; chomp($vard);
	} else {
		$vara = `$df | grep dev | awk '{ sum+=\$2 / 1024 / 1024}; END { print sum }'`; chomp($vara);
		$vard = `$df | grep dev | awk '{ sum+=\$3 / 1024 / 1024}; END { print sum }'`; chomp($vard);
	}
	if ($vara eq "" or $vara == 0 ) {
		return "0GB/0GB (0%)";
	} else {
		$varp = sprintf("%.2f", $vard / $vara * 100);
		$vara = sprintf("%.2f", $vara);
		$vard = sprintf("%.2f", $vard);
		return $vard."GB/".$vara."GB ($varp%)";
	}
}

sub loadaverage {
	$var = `uptime`; chomp($var);
	if($irix || $irix64 || $linux || $sun) {
		@arr = split(/average: /, $var, 2);
	} else {
		@arr = split(/averages: /, $var, 2);
	}
	if($darwin) {
		@arr = split(/ +/, $arr[1], 2);
	} else {
		@arr = split(/, /, $arr[1], 2);
	}
	$var = $arr[0];
	return $var;
}

sub meminfo {
	my $string = shift;
	@arr = grep(/$string/, @meminfo);
	$var = join("\n", $arr[0]);
	@arr = split(/\s+/, $var);
	$var = $arr[1];
	return $var;
}

sub memoryusage {
	if($linux) {
		if($l26 or $l30) {
			$vara = &meminfo("MemTotal:") * 1024;
			$varb = &meminfo("Buffers:") * 1024;
			$varc = &meminfo("Cached:") * 1024;
			$vard = &meminfo("MemFree:") * 1024;
		} else {
			@arr = grep(/Mem:/, @meminfo);
			$var = join("\n", @arr);
			@arr = split(/\s+/, $var);
			$vara = $arr[1];
			$varb = $arr[5];
			$varc = $arr[6];
			$vard = $arr[3];
		}
		$vard = ($vara - $vard) - $varb - $varc;
	} elsif($darwin) {
		$vard = `vm_stat | grep 'Pages active' | awk '{print \$3}'` * 4096;
		$vara = `$sysctl -n hw.memsize`;
	} elsif($sun) {
		$vara = `/usr/sbin/prtconf | grep "Mem" | awk '{print \$3}'` * 1024 * 1024;
		$vard = `/bin/vmstat 1 2 | tail -1 | awk '{print \$5 * 1024}'`;
		$vard = $vara - $vard
	} elsif($irix || $irix64) {
		$var = `top -d1 | grep Memory`; chomp($var);
		$vara = $var;
		$vard = $var;
		$vara =~ s/^.* ([0-9]*)M max.*$/$1/;
		$vara *= 1024 * 1024;
		$vard =~ s/^.* ([0-9]*)M free,.*$/$1/;
		$vard = $vara - ($vard * 1024 * 1024);
	} elsif($netbsd) {
		$vard = `vmstat -t | tail -n 1 | awk '{print \$8}'`;
		$vard = $vard * 4096;
		$vara = `sysctl -n hw.physmem`;
	} else {
		$vard = `vmstat -s | grep 'pages active' | awk '{print \$1}'` * `vmstat -s | grep 'per page' | awk '{print \$1}'`;
		$vara = `$sysctl -n hw.physmem`;
	}
	$varp = sprintf("%.2f", $vard / $vara * 100);
	$vara = sprintf("%.2f", $vara / 1024 / 1024);
	$vard = sprintf("%.2f", $vard / 1024 / 1024);
	return $vard."MB/".$vara."MB ($varp%)";
}

sub networkinfobsd {
	$varc = shift;
	$vard = shift;
	@arr = grep(/$varc/, @netstat);
	@arr = grep(/Link/, @arr);
	$var = join("\n", @arr);
	@arr = split(/\s+/, $var);
	$var = $arr[$vard] / 1024 / 1024;
	$var = sprintf("%.2f", $var);
	return $var;
}

sub networkinfolinux {
	$varc = shift;
	$vard = shift;
	@arr = grep(/$varc/, @netdev);
	$var = join("\n", @arr);
	@arr = split(/:\s*/, $var);
	@arr = split(/\s+/, $arr[1]);
	$var = $arr[$vard] / 1024 / 1024;
	$var = sprintf("%.2f", $var);
	return $var;
}

sub networktraffic {
        $vara = 0;
        $varz = "";
        return $varz = "" if ( $options{nic} eq "" or $options{nicname} eq "");
        my @nic = split( /,/, $options{nic} );
        my @nicname = split( /,/, $options{nicname} );

	$varb = scalar @nic;
	if($nic[$vara] ne "") {
		while($vara lt $varb) {
			if($nic[$vara] ne "") {
				if ($varz eq "") {
					$varz = weechat::color($options{color})." - ".$col1;
				}
				if($darwin || $freebsd || $dragonfly) {
					$varx = &networkinfobsd($nic[$vara], 6);
					$vary = &networkinfobsd($nic[$vara], 9);
				}
				if($netbsd || $openbsd) {
					$varx = &networkinfobsd($nic[$vara], 4);
					$vary = &networkinfobsd($nic[$vara], 5);
				}
				if($sun) {
					$varx = &networkinfobsd($nic[$vara], 4);
					$vary = &networkinfobsd($nic[$vara], 6);
				}
				if($linux) {
					$varx = &networkinfolinux($nic[$vara], 0);
					$vary = &networkinfolinux($nic[$vara], 8);
				}
				$varz .= $nicname[$vara]." Traffic (".$nic[$vara].")".weechat::color($options{color}).": ".$col1.$varx."MB In/".$vary."MB Out - ";
			}
			$vara++;
		}
		return $varz;
	}
}

sub openfile {
	my $string = shift;
	$data = "";
	if(open(FD, $string)) {
		while($stream = <FD>) {
			$data .= $stream;
			@data = split(/\n/, $data);
		}
		close(FD);
	}
	return @data;
}

sub processes {
	if($irix || $irix64 || $sun) {
		$var = `ps -e | grep -v PID | wc -l`;
	} else {
		$var = `ps ax | grep -v PID | wc -l`;
	}
	chomp($var);
	$var = $var;
	$var =~ s/^\s+//;
	$var =~ s/\s+$//;
	return $var;
}

sub uptime {
	if($irix || $irix64 || $d9 || $sun) {
		$var = `uptime`; chomp($var);
		if($var =~ /day/) {
			$var =~ s/^.* ([0-9]*) day.* ([0-9]*):([0-9]*), .*$/$1d $2h $3m/;
		} elsif($var =~ /min/) {
			$var =~ s/^.* ([0-9]*) min.*$/0d 0h $1m/;
		} else {
			$var =~ s/^.* ([0-9]*):([0-9]*),.*$/0d $1h $2m/;
		}
		return $var;
	} else {
		if($freebsd || $dragonfly) {
			$var = `$sysctl -n kern.boottime | awk '{print \$4}'`;
		}
		if($netbsd || $openbsd || $darwin) {
			$var = `$sysctl -n kern.boottime`;
		}
		if($linux) {
			@arr = split(/ /, $uptime[0]);
			$varx = $arr[0];
		} else {
			chomp($var);
			$var =~ s/,//g;
			$vary = `date +%s`; chomp($vary);
			$varx = $vary - $var;
		}
		$varx = sprintf("%2d", $varx);
		$vard = floor($varx / 86400);
		$varx %= 86400;
		$varh = floor($varx / 3600);
		$varx %= 3600;
		$varm = floor($varx / 60);
		if($vard eq 0) { $vard = ''; } elsif($vard >= 1) { $vard = $vard.'d '; }
		if($varh eq 0) { $varh = ''; } elsif($varh >= 1) { $varh = $varh.'h '; }
		if($varm eq 0) { $varm = ''; } elsif($varm >= 1) { $varm = $varm.'m'; }
		return $vard.$varh.$varm;
	}
}

sub users {
	$var = `uptime`; chomp($var);
	$var =~ s/^.* +(.*) user.*$/$1/;
	return $var;
}


# -------------------------------[ weechat ]-------------------------------------
sub toggle_config_by_set
{
    my ($pointer, $name, $value) = @_;
    $name = substr($name, length("plugins.var.perl.".$PRGNAME."."), length($name));
    $options{$name} = $value;
    return weechat::WEECHAT_RC_OK;
}

sub init_config
{
    foreach my $option (keys %options)
    {
        if (!weechat::config_is_set_plugin($option))
        {
            weechat::config_set_plugin($option, $options{$option});
        }
        else
        {
            $options{$option} = weechat::config_get_plugin($option);
        }
    }
}

# -------------------------------[ init ]-------------------------------------
# first function called by a WeeChat-script.
weechat::register($PRGNAME, "Nils Görs <weechatter\@arcor.de>", $VERSION,
                  "GPL3", $DESCR, "", "");
init_config();
weechat::hook_command($PRGNAME, $DESCR, "hostname || os || cpu || processes || uptime || loadaverage || battery || memory || disk || network || users || distro || -channel",
                      "   hostname : show hostname\n".
                      "         os : show os\n".
                      "        cpu : show cpu\n".
                      "  processes : show amount of processes\n".
                      "     uptime : show uptime\n".
                      "loadaverage : show load average\n".
                      "    battery : show battery status\n".
                      "     memory : show memory usage\n".
                      "       disk : show disk usage\n".
                      "    network : show network traffic\n".
                      "      users : show number of users on the system\n".
                      "     distro : show distro\n".
                      "   -channel : print output to channel\n".
                      "\n".
                      "Options:\n".
                      "plugins.var.perl.$PRGNAME.nic    : comma separated list to specify your NIC interface name (wlan0,eth0,etc)\n".
                      "plugins.var.perl.$PRGNAME.nicname: comma separated list with name for interface (wireless,cable,etc)\n",
                      "hostname|os|cpu|processes|uptime|loadaverage|battery|memory|disk|network|users|distro|-channel%*", "cmd_sysinfo", "");

weechat::hook_config("plugins.var.perl.$PRGNAME.*", "toggle_config_by_set", "");
$col1 = weechat::color ("reset");
#!/usr/bin/perl -w
# Written by: Fekete Andras (Sept 21, 2014)
# This script is to make a server administrator's life easy with backups.
# The concept is that it makes hard links to past files, and you can run this script
# as often as you want, and it'll save the last $LEN backups.
use strict;
use File::Copy;
use File::Basename;
use File::Path qw(make_path remove_tree);

# Default arguments
my $SOURCE="/data/";
my $DEST="/backupData";
my $LEN=10;

### DO NOT EDIT BELOW HERE ###

if($#ARGV == 2) {
	$SOURCE=$ARGV[0];
	$DEST=$ARGV[1];
	$LEN=$ARGV[2];
} elsif($#ARGV != -1) {
	print "Usage: $0 <srcDir> <backupDir> <numBackups>\n";
	print "  Please use absolute paths.\n";
	exit;
}

if(!-d $SOURCE) { print "Source does not exist.\n"; exit; }
if(!($LEN =~ /^\d+?$/)) { print "'$LEN' is not an integer.\n"; exit; }

my $pidfile = "/tmp/".basename($0).".pid";
if(-e "$pidfile") {
	open(PIDFILE,"$pidfile") || die "Cannot create $pidfile";
	$_ = <PIDFILE>;
	$_ =~ s/\D*//g;
	if(kill 0,$_) {
		print "Process ($_) is already running.\n";
		exit;
	}
}

open(PIDFILE,">$pidfile") || die "Cannot create $pidfile";
print PIDFILE "$$";
close(PIDFILE);

&doRsync($SOURCE,$DEST,$LEN);

sub doRsync() {
	my $BACKUP_SOURCE=$_[0];
	my $BACKUP_ROOT=$_[1];
	my $BACKUP_LEN=$_[2];

	if(! -d "$BACKUP_ROOT" ) { make_path($BACKUP_ROOT) || die "Can't create backup directory"; }
# Shift backups down by one
	for ( my $i=$BACKUP_LEN; $i!=0; $i-- ) {
		if( -d "$BACKUP_ROOT/backup.".($i-1)) {
			move("$BACKUP_ROOT/backup.". ($i - 1), "$BACKUP_ROOT/backup.$i");
		}
	}
# Delete max oldest backup
	if(-d "$BACKUP_ROOT/backup.$BACKUP_LEN") { remove_tree("$BACKUP_ROOT/backup.$BACKUP_LEN"); }
# Make the backup
	if(-d "$BACKUP_ROOT/backup.1") {
		system "rsync -uaq --delete --partial --link-dest=\"$BACKUP_ROOT/backup.1\" \"$BACKUP_SOURCE\" \"$BACKUP_ROOT/backup.0\""
	} else {
		system "rsync -uaq --delete --partial \"$BACKUP_SOURCE\" \"$BACKUP_ROOT/backup.0\"";
	}
	system("touch \"$BACKUP_ROOT/backup.0\""); # Update timestamp
}


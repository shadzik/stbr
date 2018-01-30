#!/usr/bin/perl
#
# 2009 (c) Przemysław Iskra <sparky@pld-linux.org>
# It's GPL v2+!
#
use strict;
use warnings;
use WWW::Curl::Easy;
use Compress::Zlib ();
use Data::Dumper;
use DBI;

my $dbh = DBI->connect("dbi:SQLite2:dbname=unfilled.db","","");
my $sth = $dbh->prepare( "DELETE FROM unfilled WHERE line = ? and spec = ? and branch = ? and date < ?" );

my %queue_uri = (
	aidath => 'http://ep09.pld-linux.org/~builderaidath/queue.gz',
	ac => 'http://ep09.pld-linux.org/~buildsrc/queue.gz',
	th => 'http://ep09.pld-linux.org/~builderth/queue.gz',
	ti => 'http://kraz.tld-linux.org/~builderti/queue.gz',
);

sub get
{
	my $uri = shift;

	my $curl = new WWW::Curl::Easy;
	$curl->setopt( CURLOPT_URL, $uri );

	my $body;
	open my $body_f, ">", \$body;

	$curl->setopt( CURLOPT_WRITEDATA, $body_f );

	my $retcode = $curl->perform;

	if ( $retcode ) {
		die "$uri queue download error: " . $curl->strerror( $retcode ) . " ($retcode)\n";
	}
	return Compress::Zlib::memGunzip( $body );
}


my $removed = 0;

sub parse
{
	my $line = shift;
	my $xml = shift;
	$xml =~ s{</queue>.*}{}s;

	my @group = $xml =~ m{(<group.*?</group>)}gs;
	GROUP: foreach my $grp ( @group ) {
		my ($time) = $grp =~ m{<time>(\d+)</time>};
	
		next if $grp =~ m{<group.*?flags="test-build">};
	
		my @pkg = $grp =~ m{(<batch.*?</batch>)}gs;
		foreach my $p ( @pkg ) {
			my ($spec) = $p =~ m{<spec>(.*?)</spec>};
			next unless $spec;
	
			my ($branch) = $p =~ m{<branch>(.+?)</branch>};
	
			my $e = $sth->execute( $line, $spec, $branch, $time );
			print "$line: removed $spec @ $branch\n" if $e > 0;
			$removed += $e;
		}
	}
}

while ( my $line = shift @ARGV ) {
	$line = lc $line;

	my $uri = $queue_uri{ $line };
	unless ( $uri ) {
		warn "$line not supported\n";
		next;
	}

	my $xml = get( $uri );

	parse( $line, $xml );
}

if ( $removed ) {
	warn "Cleaning database\n";
	$dbh->do( "vacuum" );
}

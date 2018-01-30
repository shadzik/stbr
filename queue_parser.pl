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

my $data_dir = $ENV{PWD};

my $term = 0;
if ( $ARGV[0] eq "-t" ) {
	$term = 1;
	shift @ARGV;
}
my $line = shift @ARGV;
$line ||= "th";
$line = ucfirst lc $line;
$line = "AidaTh" if lc $line eq "aidath";

my %queue_uri = (
	AidaTh => 'http://ep09.pld-linux.org/~builderaidath/queue.gz',
	Ac => 'http://ep09.pld-linux.org/~buildsrc/queue.gz',
	Th => 'http://ep09.pld-linux.org/~builderth/queue.gz',
	Ti => 'http://kraz.tld-linux.org/~builderti/queue.gz',
	"Ti-dev" => 'http://kraz.tld-linux.org/~buildertidev/queue.gz',
);

my $uri = $queue_uri{ $line } || die "Line $line not supported\n";

my $data_file = "$data_dir/saved-vars-$line.pl";
my $data = do $data_file;
$data ||= { last_time => time - 60, printed => {} };
my %printed;


my %status_to_color = (
	'?' => "bold",
	OK => "green",
	FAIL => "red",
	SKIP => "blue",
	UNSUPP => "magenta",
);

my %color_to_code_irc = (
	red => 5,
	green => 3,
	yellow => 7,
	blue => 2,
	magenta => 6,
	cyan => 10,
	"" => 0,
);
sub color_irc
{
	my $color = shift;
	return "\017" unless $color;
	return "\002" if $color eq "bold";
	return "\003" . $color_to_code_irc{$color};
}
my %color_to_code_term = (
	red => 31,
	green => 32,
	yellow => 33,
	blue => 34,
	magenta => 35,
	cyan => 36,
	bold => 1,
	"" => 0,
);
sub color_term
{
	my $color = shift || "";
	return "\033[" . $color_to_code_term{$color} . "m";

}
*main::color = $term ? \&color_term : \&color_irc;

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
		die "$line queue download error: " . $curl->strerror( $retcode ) . " ($retcode)\n";
	}
	return Compress::Zlib::memGunzip( $body );
}


my $xml = get( $uri );
$xml =~ s{</queue>.*}{}s;

my $now = time;

my $color_e = color();
my $color_b = color( "bold" );
my $color_c = color( "cyan" );
my $printed_something = 0;
my $done_so_far = 1;
my @group = $xml =~ m{(<group.*?</group>)}gs;
GROUP: foreach my $grp ( @group ) {
	my ($time) = $grp =~ m{<time>(\d+)</time>};
	next if $time <= $data->{last_time};

	my $pre = "$color_b$line";
	if ( $grp =~ m{<group.*?flags="test-build">} ) {
		$pre .= " $color_e(test)$color_b";
	}
	$pre .= ":$color_e ";

	my ($requester) = $grp =~ m{<requester email='.*?'>(.*?)</requester>};
	$pre .= color( "green" ) . "$requester$color_e * ";

	my @pkg = $grp =~ m{(<batch.*?</batch>)}gs;
	foreach my $p ( @pkg ) {
		my ($id) = $p =~ m{<batch id='(.*?)'};

		if ( ( $data->{printed}->{$id} or "" ) eq "all" ) {
			$printed{$id} = "all";
			next;
		}

		my ($rpm) = $p =~ m{<src-rpm>(.*?)</src-rpm>};
		if ( $rpm ) {
			$rpm =~ s/\.src\.rpm$//;
			$rpm = $color_c . $1 . $color_e . $2 if $rpm =~ /^(.*)(-.*?-.*?)$/;
		} else {
			$p =~ m{<command flags="(.*?)">(.*?)</command>};
			$rpm = $1 ? "$color_c$2$color_e ($1)" : $2;
		}
		if ( $p =~ m{<branch>(.+?)</branch>} ) {
			my $branch = $1;
			$rpm .= " (" . color( "yellow" ) . "$branch$color_e)" if $branch ne "HEAD";
		}

		my $all_done = 1;
		my $some_done = 0;
		my @status;
		my @builders = $p =~ m{(<builder.*?</builder>)}g;
		foreach my $b ( @builders ) {
			my ( $status, $builder ) = $b =~ m{status='(.*?)'.*?>(.*?)</builder>};
			my $color = $status_to_color{ $status } || "red";
			push @status, "$builder: " . color($color) . "$status$color_e";
			if ( $status eq "?" ) {
				$all_done = 0;
			} else {
				$some_done = 1;
			}
		}

		if ( $all_done ) {
			# all done
			next if $printed_something > 4;
			$printed{$id} = "all";
		} else {
			$done_so_far = 0;
			next unless $some_done;

			# some done ?
			my $ftime = $data->{printed}->{$id};
			if ( $ftime and $ftime eq "some" ) {
				$printed{$id} = "some";
				next;
			}

			# nothing printed yet, first status info
			unless ( $ftime ) {
				$printed{$id} = $now;
				next;
			}
			$printed{$id} = $ftime;

			next unless $ftime =~ /^\d+$/; # bug
			next if $printed_something > 4;
			if ( $ftime + 15 * 60 < $now ) {
				$printed{$id} = "some";
			} else {
				next;
			}
		}

		print $pre
			. "$rpm$color_b:$color_e "
			. ( join ", ", @status )
			. "\n";
		$printed_something++ unless $term;
	}
	$data->{last_time} = $time if $done_so_far;
}

$data->{printed} = \%printed;
open F_OUT, ">", $data_file;
print F_OUT Dumper( $data );
close F_OUT;

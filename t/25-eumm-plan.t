#! perl

use strict;
use warnings;

use Test::More 0.89;

use File::Temp qw/tempdir/;
use Devel::FindPerl 'find_perl_interpreter';

my @perl = find_perl_interpreter();
system @perl, '-e0' and plan(skip_all => 'Can\'t find perl');

my $tempdir = tempdir();

chdir $tempdir;

open my $mfpl, '>', 'Makefile.PL';

print $mfpl <<'END';
use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Plan;
use ExtUtils::Builder::Node;
use ExtUtils::Builder::Action::Command;

my $action = ExtUtils::Builder::Action::Command->new(command => ['touch', 'very_unlikely_name']);
my $plan = ExtUtils::Builder::Node->new(actions => [ $action ], dependencies => [], target => 'foo');

WriteMakefile(
	NAME => 'FOO',
	VERSION => 0.001,
	postamble => {
		plans => [ $plan ],
		roots => [ 'foo' ],
	},
);

END

close $mfpl;

system @perl, 'Makefile.PL';

ok(-e 'Makefile', 'Makefile exists');

open my $mf, '<', 'Makefile' or die "Couldn't open Makefile: $!";
my $content = do { local $/; <$mf> };

like($content, qr/^\t touch .* very_unlikely_name/xm, 'Makefile contains very_unlikely_name');

if ($ENV{AUTHOR_TESTING}) {
	system 'make';
	ok(-e 'very_unlikely_name', "Unlikely file has been touched");
}

done_testing;

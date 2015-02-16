package ExtUtils::Builder::Action::Command;

use strict;
use warnings FATAL => 'all';

use parent 'ExtUtils::Builder::Role::Action::Primitive';

use IPC::System::Simple qw/systemx/;

sub _preference_map {
	return {
		command => 3,
		execute => 2,
		code    => 1,
		flatten => 0,
	};
}

sub new {
	my ($class, %args) = @_;
	return $class->SUPER::new(%args);
}

sub to_code {
	my $self = shift;
	require Data::Dumper;
	my $serialized = Data::Dumper->new([ $self->to_command ])->Terse(1)->Indent(0)->Dump;
	$serialized =~ s/ \A \[ (.*?) \] \z /$1/xms;
	return "sub { require IPC::System::Simple; IPC::System::Simple::systemx($serialized); }";
}

sub to_command {
	my $self = shift;
	return [ @{ $self->{command} } ];
}

my $quote = $^O eq 'MSWin32' ? do { require Win32::ShellQuote; \&Win32::ShellQuote::quote_system_list } : sub { @_ };
sub execute {
	my ($self, %opts) = @_;
	my @command = @{ $self->to_command };
	my $message = join ' ', map { my $arg = $_; $arg =~ s/ (?= ['#] ) /\\/gx ? "'$arg'" : $arg } @command;
	$opts{logger}->($message) if $opts{logger} and not $opts{quiet};
	systemx($quote->(@command)) if not $opts{dry_run};
	return;
}

1;

#ABSTRACT: An action object for external commands

=head1 SYNOPSIS

 my @cmd = qw/echo Hello World!/;
 my $action = ExtUtils::Builder::Action::Command->new(command => \@cmd);
 $action->execute;
 say "Executed: ", join ' ', @{$_} for $action->to_command;

=head1 DESCRIPTION

This is a primitive action object wrapping an external command. The easiest way to use it is to serialize it to command, though it doesn't mind being executed right away. For more information on actions, see L<ExtUtils::Builder::Role::Action|ExtUtils::Builder::Role::Action>.

=attr command

This is the command that should be run, represented as an array ref.

=method execute(%args)

This executes the command immediately.

=method to_command()

This returns the C<command> attribute.

=method to_code

This returns a piece of code that will run the command.

=method preference

This will prefer handling methods in the following order: command, execute, code, flatten

=method flatten

This returns the object.

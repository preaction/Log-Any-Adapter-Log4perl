use strict;
use warnings;

package Log::Any::Adapter::Log4perl;
# ABSTRACT: Log::Any adapter for Log::Log4perl

use Log::Log4perl 1.32; # bug-free wrapper_register available
use Log::Any::Adapter::Util 1.03 qw(make_method);
use base qw(Log::Any::Adapter::Base);

our $VERSION = '0.10';

# Ensure %F, %C, etc. skip Log::Any related packages
Log::Log4perl->wrapper_register(__PACKAGE__);
Log::Log4perl->wrapper_register("Log::Any::Proxy");

sub init {
    my ($self) = @_;

    $self->{logger} = Log::Log4perl->get_logger( $self->{category} );
}

foreach my $method ( Log::Any->logging_and_detection_methods() ) {
    my $log4perl_method = $method;

    # Map log levels down to log4perl levels where necessary
    #
    for ($log4perl_method) {
        s/notice/info/;
        s/warning/warn/;
        s/critical|alert|emergency/fatal/;
    }

    make_method(
        $method,
        sub {
            my $self = shift;
            return $self->{logger}->$log4perl_method(@_);
        }
    );
}

sub structured {
    my ($adapter, $level, $category, @parts) = @_;
    my $context = ref($parts[-1]) eq 'HASH'
        ? pop @parts
        : {};
    my $mdc = Log::Log4perl::MDC->get_context;
    local @{$mdc}{keys %{$context}} = values %{$context};
    $adapter->$level(@parts);
}

1;

__END__

=for Pod::Coverage init

=for Pod::Coverage structured

=head1 SYNOPSIS

    use Log::Log4perl;
    Log::Log4perl::init('/etc/log4perl.conf');

    Log::Any::Adapter->set('Log::Log4perl');

=head1 DESCRIPTION

This Log::Any adapter uses L<Log::Log4perl|Log::Log4perl> for logging. log4perl
must be initialized before calling I<set>. There are no parameters.

This adapter supports structured logging introduced in Log-Any v1.700.

=head1 LOG LEVEL TRANSLATION

Log levels are translated from Log::Any to Log4perl as follows:

    notice -> info
    warning -> warn
    critical -> fatal
    alert -> fatal
    emergency -> fatal

=head1 SEE ALSO

=for :list
* L<Log::Any>
* L<Log::Any::Adapter>
* L<Log::Log4perl>

=cut

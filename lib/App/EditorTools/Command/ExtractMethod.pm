package App::EditorTools::Command::ExtractMethod;

use strict;
use warnings;
use Path::Class;

use App::EditorTools -command;

our $VERSION = '0.17';

sub opt_spec {
    return ( 
        [ "name|n=s", "The name of the extracted method", ],
        [ "start|s=s",   "Line number of the start of code to extract", ],
        [ "end|e=s",   "Line number of the end of code to extract", ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    for (qw(name start end)) {
        $self->usage_error("Arg $_ is required") unless $opt->{$_};
    }
    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $doc_as_str = eval { local $/ = undef; <STDIN> };

    require PPIx::EditorTools::ExtractMethod;
    my $extract = PPIx::EditorTools::ExtractMethod->new(
        selected_range => [ $opt->{start}, $opt->{end} ]
    );
    $extract->code($doc_as_str);
    $extract->extract_method($opt->{name});
    print $extract->code;
    return;
}

1;

=head1 NAME

App::EditorTools::Command::ExtractMethod::Body - Generate body of extracted method

=head1 DESCRIPTION

See L<App::EditorTools> for documentation.

=head1 AUTHOR

Dagfinn Reiersøl

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.




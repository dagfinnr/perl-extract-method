package App::EditorTools::Command::ExtractMethod::Body;

use strict;
use warnings;
use Path::Class;

use App::EditorTools -command;

our $VERSION = '0.17';
sub command_names { 'extractmethod-body' }

sub opt_spec {
    return ( [ "name|n=s", "The name of the extracted metho", ] );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error("Name is required") unless $opt->{name};
    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $doc_as_str = eval { local $/ = undef; <STDIN> };

    require PPIx::EditorTools::ExtractMethod;
    my $extract = PPIx::EditorTools::ExtractMethod->new;
    $extract->code($doc_as_str);
    print $extract->method_body($opt->{name});
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

Copyright (C) 2010 by Mark Grimes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.




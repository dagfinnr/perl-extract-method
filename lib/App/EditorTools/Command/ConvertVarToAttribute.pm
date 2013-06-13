package App::EditorTools::Command::ConvertVarToAttribute;

use strict;
use warnings;
use Path::Class;

use App::EditorTools -command;

our $VERSION = '0.17';

sub opt_spec {
    return ( 
        [ "line|l=s",   "Line number of the start of variable to replace", ],
        [ "column|c=s", "Column number of the start of variable to replace", ],
        [ "name|n=s", "The name of the attribute", ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    for (qw(line column)) {
        $self->usage_error("Arg $_ is required") unless $opt->{$_};
    }
    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $doc_as_str = eval { local $/ = undef; <STDIN> };

    require PPIx::EditorTools::ConvertVarToAttribute;
    my $refactor = PPIx::EditorTools::ConvertVarToAttribute->new(
        current_location => [ $opt->{line}, $opt->{column} ],
        new_name => $opt->{name},
        ppi => PPI::Document->new(\$doc_as_str),
    );
    $refactor->replace;
    print $refactor->ppi->content;
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




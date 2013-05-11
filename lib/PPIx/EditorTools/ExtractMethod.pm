package PPIx::EditorTools::ExtractMethod;
use PPI::Document;
use PPIx::EditorTools;
use PPIx::EditorTools::KnownScopes;
use PPIx::EditorTools::ExtractMethod::Variable;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use Set::Scalar;
use Moose;

has 'code'   => ( is => 'rw', isa => 'Str' );

has 'code_with_sub'   => ( 
    is => 'rw', 
    isa => 'Str',
    lazy => 1,
    builder => '_build_code_with_sub',
);

has 'ppi'   => ( 
    is => 'rw', 
    isa => 'PPI::Document',
    lazy => 1,
    builder => '_build_ppi',
);

has 'known_scopes'   => ( 
    is => 'rw', 
    isa => 'PPIx::EditorTools::KnownScopes',
    lazy => 1,
    default => sub { PPIx::EditorTools::KnownScopes->new(
            ppi => $_[0]->ppi,
            start_selected => $_[0]->start_selected
        ) },
    handles => [ qw/ inserted enclosing_scope outside enclosing_scope_name enclosing_known_scope_name scopes scope_category /],
);

has 'start_selected'   => ( is => 'rw', isa => "Int" );
has 'end_selected'   => ( is => 'rw', isa => "Int" );

sub _build_code_with_sub {
    my $self = shift;
    my @lines = split("\n", $self->code);
    splice @lines, $self->end_selected, 0, '}';
    splice @lines, $self->start_selected - 1, 0, '   sub ppi_temp {';
    return join "\n", @lines;
}

sub _build_ppi {
    my $self = shift;
    my $code = $self->code_with_sub;
    return PPI::Document->new(\$code);
}

sub used_variables {
    my $self = shift;
    my $vars = {};
    foreach my $symbol ($self->symbols) {
        my $var = $symbol->content;
        my $name = substr( $var, 1 );
        if (! defined $vars->{ $name } ) {
            $vars->{ $name } = PPIx::EditorTools::ExtractMethod::Variable->new(name => $name);
        }
        if ($symbol->is_declaration) {
            $vars->{ $name }->declared_in_scope($self->scope_category($symbol));
        }
        else {
            $vars->{ $name }->used_in_scope($self->scope_category($symbol));
        }
    }
    return $vars;
}

sub symbols {
    my $self = shift;
    my $symbols = $self->ppi->find( 
        sub { $_[1]->isa('PPI::Token::Symbol') and $_[1]->content }
    );
    $symbols ||= [];
    return map { PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(ppi_symbol => $_) } @$symbols;
}

sub variable_declarations {
    my $self = shift;
    my $symbols = $self->ppi->find( 
        sub { $_[1]->isa('PPI::Statement::Variable') }
    );
    $symbols ||= [];
    return @$symbols;
}


1;

package PPIx::EditorTools::ExtractMethod::ScopeLocator;
use Moose;
use PPI::Document;
use PPIx::EditorTools;


has 'ppi'   => ( is => 'ro', isa => 'PPI::Document' );

sub enclosing_scope {
    my ($self, $element) = @_;
    return if !$element;
    $element = $element->parent;
    while (!$element->scope) {
        $element = $element->parent;
    }
    return $element;
}

sub scope_for_variable {
    my ($self, $token) = @_;
    my $decl = PPIx::EditorTools::find_variable_declaration($token);
    return $self->enclosing_scope($decl);
}

1;


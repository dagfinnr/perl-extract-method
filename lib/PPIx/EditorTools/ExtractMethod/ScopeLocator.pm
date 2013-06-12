package PPIx::EditorTools::ExtractMethod::ScopeLocator;
use Moose;
use PPI::Document;

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

1;


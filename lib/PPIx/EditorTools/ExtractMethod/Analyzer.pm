package PPIx::EditorTools::ExtractMethod::Analyzer;
use Moose;

use PPI::Document;
use PPIx::EditorTools;
use PPIx::EditorTools::ExtractMethod::Variable;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use PPIx::EditorTools::ExtractMethod::LineRange;
use PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory;
use Set::Scalar;

has 'code'   => ( is => 'rw', isa => 'Str' );

has 'ppi'   => ( 
    is => 'rw', 
    isa => 'PPI::Document',
    lazy => 1,
    builder => '_build_ppi',
);

has 'selected_range' => (
    is => 'rw',
    isa => 'PPIx::EditorTools::ExtractMethod::LineRange',
    coerce => 1,
);

sub variables_in_selected {
    my $self = shift;
    my @occurrences = $self->variable_occurrences_in_selected();
    my %vars;
    foreach my $occurrence ( @occurrences ) {
        if (! defined $vars{$occurrence->variable_id} ) {
            $vars{$occurrence->variable_id} = PPIx::EditorTools::ExtractMethod::Variable->new(
                id => $occurrence->variable_id,
                name => $occurrence->variable_name,
                type => $occurrence->variable_type,
            );
        }
        if ($occurrence->is_declaration) {
            $vars{$occurrence->variable_id}->declared_in_selection(1);
        }
    }
    return \%vars;
}

sub variable_occurrences_in_selected {
    my ($self) = @_;
    my $selected_region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        selected_range => $self->selected_range,
        ppi => $self->ppi,
    );
    return $selected_region->find_variable_occurrences;
    my $factory = PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory->new;
    my $symbols = $selected_region->find_symbols();
    my @occurrences = map { $factory->occurrence_from_symbol($_) } @$symbols;
    return @occurrences;
}

sub variables_after_selected {
    my $self = shift;
    my $inside_element =  PPIx::EditorTools::find_token_at_location(
        $self->ppi,
        [$self->selected_range->start, 1]);
    my $scope = $self->enclosing_scope($inside_element);
    my @occurrences = $self->variable_occurrences_after_selected($scope);

    my %vars;
    foreach my $occurrence ( @occurrences ) {
        if (! defined $vars{$occurrence->variable_id} ) {
            $vars{$occurrence->variable_id} = PPIx::EditorTools::ExtractMethod::Variable->new(
                id => $occurrence->variable_id,
                name => $occurrence->variable_name,
                type => $occurrence->variable_type,
                used_after => 1,
            );
        }
    }
    return \%vars;
}

sub variable_occurrences_after_selected {
    my ($self, $scope) = @_;

    my $selected_region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        selected_range => [$self->selected_range->end + 1, 9999999],
        scope => $scope,
        ppi => $self->ppi,
    );
    return $selected_region->find_variable_occurrences;
}

sub output_variables {
    my $self = shift;
    my $inside_vars = $self->variables_in_selected;
    my $after_vars = $self->variables_after_selected;
    foreach my $id ( keys %$inside_vars ) {
        if (defined $after_vars->{$id}) {
            $inside_vars->{$id}->used_after(1);
        }
    }
    return $inside_vars;
}

sub enclosing_scope {
    my ($self, $element) = @_;
    $element = $element->parent;
    while (!$element->scope) {
        $element = $element->parent;
    }
    return $element;
}

sub selected_code {
    my $self = shift;
    return $self->selected_range->cut_code($self->code);
}

sub _build_ppi {
    my $self = shift;
    my $code = $self->code;
    my $doc = PPI::Document->new(\$code);
    $doc->index_locations();
    return $doc;
}

1;

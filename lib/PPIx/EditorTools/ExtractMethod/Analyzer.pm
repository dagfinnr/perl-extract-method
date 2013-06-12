package PPIx::EditorTools::ExtractMethod::Analyzer;
use Moose;

use PPI::Document;
use PPIx::EditorTools;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use PPIx::EditorTools::ExtractMethod::LineRange;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory;
use aliased 'PPIx::EditorTools::ExtractMethod::Variable';
use aliased 'PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion';
use aliased 'PPIx::EditorTools::ExtractMethod::ScopeLocator';
use aliased 'PPIx::EditorTools::ExtractMethod::Analyzer::Result' => 'AnalyzerResult';
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

has 'selected_region'   => ( 
    is => 'ro', 
    isa => 'PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion',
    builder => '_build_selected_region',
    lazy => 1,
);

has 'scope_locator'   => ( 
    is => 'ro', 
    isa => 'PPIx::EditorTools::ExtractMethod::ScopeLocator',
    builder => '_build_scope_locator',
    lazy => 1,
    required => 1,
);

sub _build_scope_locator {
    my $self = shift;
    return ScopeLocator->new;
}
sub _build_selected_region {
    my $self = shift;
    return CodeRegion->new(
        selected_range => $self->selected_range,
        ppi => $self->ppi,
    );
}
sub result {
    my $self = shift ;
    my $inside_vars = $self->variables_in_selected;
    my $after_vars = $self->variables_after_selected;
    foreach my $id ( keys %$inside_vars ) {
        if (defined $after_vars->{$id}) {
            $inside_vars->{$id}->used_after(1);
        }
    }
    return AnalyzerResult->new(
        variables => $inside_vars,
        return_statement_at_end => $self->return_at_end
    );
}

sub variables_in_selected {
    my $self = shift;
    my @occurrences = $self->selected_region->find_variable_occurrences();
    my %vars;
    foreach my $occurrence ( @occurrences ) {
        if (! defined $vars{$occurrence->variable_id} ) {
            $vars{$occurrence->variable_id} = Variable->from_occurrence(
                $occurrence,
            );
        }
        if ($occurrence->is_declaration) {
            $vars{$occurrence->variable_id}->declared_in_selection(1);
        }
        if ($occurrence->is_changed) {
            $vars{$occurrence->variable_id}->is_changed_in_selection(1);
        }
    }
    return \%vars;
}

sub variable_occurrences_in_selected {
    my ($self) = @_;
    return $self->selected_region->find_variable_occurrences;
}

sub variables_after_selected {
    my $self = shift;
    my @occurrences = $self->selected_region->find_variable_occurrences;
    my %vars;
    foreach my $occurrence ( @occurrences ) {
        next if !$self->in_current_scope($occurrence)
        && !$self->in_variable_scope($occurrence);
        my $id = $occurrence->variable_id;
        if (! defined $vars{$id} ) {
            $vars{$id} = Variable->from_occurrence(
                $occurrence,
            );
            $vars{$id}->used_after(1);
        }
    }
    return \%vars;
}
sub in_current_scope {
    my ($self, $occurrence) = @_;
    my $inside_element =  PPIx::EditorTools::find_token_at_location(
        $self->ppi,
        [$self->selected_range->start, 1]);
    my $after_region = $self->create_region_from_current_scope($inside_element);

    return $after_region->has_variable($occurrence->variable_id)
}

sub create_region_from_current_scope {
    my ($self, $inside_element) = @_;
    my $after_region = CodeRegion->after_region($self->selected_region);
    $after_region->with_enclosing_scope($inside_element);
    return $after_region;
}

sub in_variable_scope {
    my ($self, $occurrence) = @_;
    my $symbols_inside = $self->selected_region->find(sub {
            $_[1]->content eq $occurrence->variable_id;
        });
    my ($after_region_for_var);
    $after_region_for_var = $self->create_region_from_variable_scope($symbols_inside);

    return $after_region_for_var->has_variable($occurrence->variable_id);
}

sub create_region_from_variable_scope {
    my ($self, $symbols_inside) = @_;
    my $after_region_for_var = CodeRegion->after_region($self->selected_region);
    $after_region_for_var->with_scope_for_variable($symbols_inside->[0]);
    return $after_region_for_var;
}

sub return_at_end {
    my $self = shift;
    my $breaks = $self->selected_region->find(sub { $_[1]->isa('PPI::Statement::Break')});
    my $last_break_statement = pop @$breaks;
    return 0 if !$last_break_statement;
    return 0 if !$last_break_statement->first_token->content eq 'return';
    return 0 if $last_break_statement->line_number != $self->selected_region->end;
    return 1;
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

package PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory;
use Moose;
use aliased 'PPIx::EditorTools::ExtractMethod::VariableOccurrence';

sub occurrence_from_symbol {
    my ($self, $symbol) = @_;
    return VariableOccurrence->new(
        ppi_symbol => $symbol,
        is_single_declaration => $self->is_single_declaration($symbol),
        is_list_declaration => $self->is_list_declaration($symbol),
        is_loop_variable_declaration => $self->is_loop_variable_declaration($symbol),
        variable_type => $self->variable_type($symbol),
        variable_name => $self->variable_name($symbol),
        is_changed => $self->is_changed($symbol),
        is_incremented => $self->is_incremented($symbol),
        is_decremented => $self->is_decremented($symbol),
        location => $symbol->location,
    );
}
sub is_changed {
    my ($self, $symbol) = @_;
    return 1 if $self->is_incremented($symbol);
    return 1 if $self->is_decremented($symbol);
    return 1 if $symbol->snext_sibling && $self->is_assignment_operator($symbol->snext_sibling->content);
    return 0;
}

sub is_assignment_operator {
    my ($self, $string) = @_;
    my %ops = map {$_ => 1} qw{= **= += *= &= <<= &&= -= /= |= >>= ||= .= %= ^= //= x=};
    return $ops{$string};
}

sub is_incremented {
    my ($self, $symbol) = @_;
    return 1 if $symbol->sprevious_sibling && $self->is_increment_operator($symbol->sprevious_sibling->content);
    return 1 if $symbol->snext_sibling && $self->is_increment_operator($symbol->snext_sibling->content);
    return 0;
}

sub is_decremented {
    my ($self, $symbol) = @_;
    return 1 if $symbol->sprevious_sibling && $self->is_decrement_operator($symbol->sprevious_sibling->content);
    return 1 if $symbol->snext_sibling && $self->is_decrement_operator($symbol->snext_sibling->content);
    return 0;
}

sub is_increment_or_decrement_operator {
    my ($self, $string) = @_;
    return $self->is_increment_operator($string) ||
    $self->is_decrement_operator($string);
}

sub is_increment_operator {
    return $_[1] eq '++';
}

sub is_decrement_operator {
    return $_[1] eq '--';
}

sub is_declaration {
    return $_[0]->is_single_declaration() ||
    $_[0]->is_loop_variable_declaration ||
    $_[0]->is_list_declaration();
}

sub is_single_declaration {
    my $symb = $_[1];
    return 0 if !$symb->parent;
    return $symb->parent->child(0)->content eq 'my'
    && $symb->parent->child(2) == $symb;
}

sub is_list_declaration {
    my $symb = $_[1];
    return 0 if !$symb->parent;
    if ( defined $symb->parent->parent && defined $symb->parent->parent->parent) {
        my $decl = $symb->parent->parent->parent;
        return 0 if !$decl->isa('PPI::Statement::Variable');
        return 1 if $decl->child(0)->content eq 'my'
        && $decl->child(2)->isa('PPI::Structure::List')
    }
    return 0;
}

sub is_loop_variable_declaration {
    my $symb = $_[1];
    return 0 if !$symb->parent;
    return $symb->parent->schild(0)->content =~ /^for(each)?$/
    && $symb->parent->schild(1)->content eq 'my'
    && $symb->parent->schild(2) == $symb;
}


sub variable_type {
    my ($self, $symbol) = @_;
    return '@' if ($self->is_array_element($symbol));
    return '%' if ($self->is_hash_element($symbol));
    return substr( $symbol->content, 0, 1);
}

sub variable_name {
    my ($self, $symbol) = @_;
    return substr( $symbol->content, 1);
}

sub variable_id {
    my $self = shift;
    return $self->variable_type . $self->variable_name;
}

sub is_array_element {
    my ($self, $symbol) = @_;
    return $self->_get_brace_for_subscript($symbol) eq '[';
}

sub is_hash_element {
    my ($self, $symbol) = @_;
    return $self->_get_brace_for_subscript($symbol) eq '{';
}

sub _get_brace_for_subscript {
    my ($self, $symbol) = @_;
    my $next = $symbol->next_sibling;
    return '' if ! $next;
    return '' if ! $next->isa('PPI::Structure::Subscript');
    return '' if ! $next->start;
    return $next->start->content;
}
1;

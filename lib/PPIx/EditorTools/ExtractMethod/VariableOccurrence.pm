package PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use Moose;
has 'ppi_symbol'   => ( 
    is => 'ro', 
    isa => 'PPI::Token::Symbol',
    required => 1,
    handles => [ qw / content parent / ],
);

sub is_declaration {
    return $_[0]->is_single_declaration() ||
    $_[0]->is_loop_variable_declaration ||
    $_[0]->is_list_declaration();
}

sub is_single_declaration {
    my $symb = $_[0]->ppi_symbol;
    return $symb->parent->child(0)->content eq 'my'
    && $symb->parent->child(2) == $symb;
}

sub is_list_declaration {
    my $symb = $_[0]->ppi_symbol;
    if ( defined $symb->parent->parent && defined $symb->parent->parent->parent) {
        my $decl = $symb->parent->parent->parent;
        return 0 if !$decl->isa('PPI::Statement::Variable');
        return 1 if $decl->child(0)->content eq 'my'
        && $decl->child(2)->isa('PPI::Structure::List')
    }
    return 0;
}

sub is_loop_variable_declaration {
    my $symb = $_[0]->ppi_symbol;
    return $symb->parent->schild(0)->content =~ /^for(each)?$/
    && $symb->parent->schild(1)->content eq 'my'
    && $symb->parent->schild(2) == $symb;
}


sub variable_type {
    my $symbol = $_[0]->ppi_symbol;
    # TODO: check whether this is an array or hash element
    return '@' if ($_[0]->is_array_element);
    return '%' if ($_[0]->is_hash_element);
    return substr( $symbol->content, 0, 1);
}

sub variable_name {
    my $self = shift;
    return substr( $self->ppi_symbol->content, 1);
}

sub variable_id {
    my $self = shift;
    return $self->variable_type . $self->variable_name;
}

sub is_array_element {
    return $_[0]->_get_brace_for_subscript eq '[';
}

sub is_hash_element {
    return $_[0]->_get_brace_for_subscript eq '{';
}

sub _get_brace_for_subscript {
    my $symbol = $_[0]->ppi_symbol;
    my $next = $symbol->next_sibling;
    return '' if ! $next;
    return '' if ! $next->isa('PPI::Structure::Subscript');
    return '' if ! $next->start;
    return $next->start->content;
}
1;

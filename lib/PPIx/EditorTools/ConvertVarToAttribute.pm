package PPIx::EditorTools::ConvertVarToAttribute;
use aliased 'PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion';
use Moose;

has 'current_location'   => ( is => 'rw', isa => 'ArrayRef' );

has 'current_name'   => ( 
    is => 'ro', 
    isa => 'Str',
    lazy => 1,
    builder => '_build_current_name',
);

has '_new_name'   => ( 
    is => 'rw', 
    isa => 'Str',
);

has 'ppi'   => ( 
    is => 'rw', 
    isa => 'PPI::Document',
);

sub _build_current_name {
    my $self = shift;
    my $symbol = PPIx::EditorTools::find_token_at_location($self->ppi, $self->current_location);
    return substr( $symbol->content, 1);
}

sub new_name {
    my ($self, $name) = @_;
    return $self->_new_name || $self->current_name if !$name;
    $self->_new_name($name);
}

sub replace {
    my $self = shift;
    $self->replace_vars;
    $self->add_moose_attribute;
}

sub add_moose_attribute {
    my $self = shift;
    my $insertion_point = $self->find_attribute_definitions->[0];
    if (!$insertion_point) {
        $insertion_point = $self->find_methods->[0];
    }
    my $attr = $self->moose_attribute;
    $insertion_point->insert_before($attr);
}

sub moose_attribute {
    my $self = shift;
    my $stmt = PPI::Statement->new;
    $stmt->add_element(PPI::Token->new('has'));
    $stmt->add_element(PPI::Token->new(' '));
    $stmt->add_element(PPI::Token->new("'" . $self->new_name . "'"));
    $stmt->add_element(PPI::Token->new(' '));
    $stmt->add_element(PPI::Token->new('=>'));
    $stmt->add_element(PPI::Token->new(' '));
    my $tmp_ppi = PPI::Document->new(\q!(is => 'rw')!);
    my $list = $tmp_ppi->find_first('PPI::Structure::List')->remove;
    $stmt->add_element($list);
    $stmt->add_element(PPI::Token->new(';'));
    $stmt->add_element(PPI::Token->new("\n"));
    return $stmt;
}

sub find_methods {
    my $self = shift ;
    return $self->ppi->find('PPI::Statement::Sub');
}

sub find_attribute_definitions {
    my $self = shift ;
    my $has = $self->ppi->find(sub {
            $_[1]->content eq 'has' &&
            $_[1]->parent->isa('PPI::Statement')
        });
    return [] if !$has;
    return [ map {$_->statement} @$has ];
}

sub replace_vars {
    my $self = shift ;
    my $symbol = PPIx::EditorTools::find_token_at_location($self->ppi, $self->current_location);
    my $region = CodeRegion->new->with_scope_for_variable($symbol);
    my @occurrences = $region->find_unquoted_variable_occurrences;
    foreach my $occurrence (@occurrences) {
        next if $occurrence->variable_name ne $self->current_name;
        if ($occurrence->is_declaration) {
            my $decl_statement = $occurrence->ppi_symbol;
            $decl_statement = $decl_statement->parent while ! $decl_statement->isa('PPI::Statement::Variable');
            my $replacement = $self->process_declaration($decl_statement,$occurrence);
        }
        else {
            my $stmt = $occurrence->ppi_symbol->statement;
            $self->parenthesize_rhs($occurrence);
            $occurrence->ppi_symbol->set_content('$self->' . $self->new_name);
            if ($occurrence->is_incremented) {
                $self->replace_incrementing($stmt);
            }
            elsif ($occurrence->is_decremented) {
                $self->replace_decrementing($stmt);
            }
        }
    }
    return $self->ppi->content;
}

sub replace_incrementing {
    my ($self, $stmt) = @_;
    $self->replace_increment_or_decrement($stmt, '+');
}

sub replace_decrementing {
    my ($self, $stmt) = @_;
    $self->replace_increment_or_decrement($stmt, '-');
}

sub replace_increment_or_decrement {
    my ($self, $stmt, $char) = @_;
    my $op = $stmt->find_first(sub{ $_[1]->content eq $char x 2 });
    $op->delete;
    $stmt->find_first(sub{ $_[1]->content eq ';' })->delete;
    my $rhs = $stmt->clone;
    $stmt->add_element(PPI::Token->new('('));
    $rhs->add_element(PPI::Token->new(' ' . $char. ' 1);'));
    $stmt->add_element($rhs);
}

sub parenthesize_rhs {
    my ($self, $occurrence) = @_;
    my $stmt = $occurrence->ppi_symbol->statement;
    my $eq = $stmt->find_first(sub { $_[1]->content eq '=' });
    return unless $eq;
    return unless $occurrence->is_lhs;
    $eq->set_content('(');
    $eq->next_token->remove while $eq->next_token->content =~ /^\s+/;
    $eq->previous_token->remove while $eq->previous_token->content =~ /^\s+/;
    my $end = $stmt->find_first(sub { $_[1]->content eq ';' });
    $end->insert_before(PPI::Token->new(')'));
}


sub process_declaration {
    my ($self, $stmt, $occurrence) = @_;
    if ($self->is_single_declaration_with_assignment($occurrence)) {
        $stmt->schild(0)->remove;
        $stmt->child(0)->remove if $stmt->child(0)->content =~ /^\s+/;
        $stmt->schild(0)->set_content('$self->' . $self->new_name);
        $self->parenthesize_rhs($occurrence);
        return $stmt;
    }
    if ($self->is_multi_declaration_without_assignment($occurrence)) {
        my $symbol = $stmt->find_first(sub { 
                $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '$' . $self->current_name
            });
        $symbol->next_token->remove; #comma
        $symbol->next_token->remove; #whitespace
        $symbol->remove;
        return $stmt;
    }
    if ($self->is_multi_declaration_with_assignment($occurrence)) {
        my $symbol = $stmt->find_first(sub { 
                $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '$' . $self->current_name
            });
        my $next_stmt = PPI::Statement->new;
        $next_stmt->add_element(PPI::Token::Symbol->new('$self'));
        $next_stmt->add_element(PPI::Token->new('->'));
        $next_stmt->add_element(PPI::Token->new($self->new_name));
        $next_stmt->add_element(PPI::Token->new('('));
        $next_stmt->add_element(PPI::Token::Symbol->new('$'.$self->new_name));
        $next_stmt->add_element(PPI::Token->new(')'));
        $stmt->add_element(PPI::Token->new("\n"));
        $stmt->add_element($next_stmt);
        $stmt->add_element(PPI::Token->new(";"));
        return $stmt;
    }
    # Single declaration without assignment
    $stmt->child(0)->delete while $stmt->children;
    return $stmt;
}

sub is_single_declaration_with_assignment {
    my ($self, $occurrence) = @_;
    my $stmt = $occurrence->parent;
    return 0 if $stmt->schild(0)->content ne 'my';
    return 0 if ! $stmt->schild(1)->isa('PPI::Token::Symbol');
    return 0 if $stmt->schild(2)->content ne '=';
    return 1;
}

sub is_multi_declaration_without_assignment {
    my ($self, $occurrence) = @_;
    return 0 if !$occurrence->is_multi_declaration;
    return 0 if $occurrence->is_in_assignment;
    return 1;
}

sub is_multi_declaration_with_assignment {
    my ($self, $occurrence) = @_;
    return 0 if !$occurrence->is_multi_declaration;
    return 0 if !$occurrence->is_in_assignment;
    return 1;
}

1;

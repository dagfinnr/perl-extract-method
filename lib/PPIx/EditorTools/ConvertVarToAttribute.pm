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
    my $attribute_statement = $self->find_attribute_definitions->[0];
    my $attr = $self->moose_attribute;
    $attribute_statement->insert_before($attr);
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

sub find_attribute_definitions {
    my $self = shift ;
    my $has = $self->ppi->find(sub {
            $_[1]->content eq 'has' &&
            $_[1]->parent->isa('PPI::Statement')
        });
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
            my $decl_statement = $occurrence->ppi_symbol->statement;
            my $replacement = $self->process_declaration($decl_statement);
            $decl_statement->insert_before($replacement);
            $decl_statement->delete;
        }
        else {
            $occurrence->ppi_symbol->set_content('$self->' . $self->new_name);
        }
    }
    return $self->ppi->content;
}


sub process_declaration {
    my ($self, $stmt) = @_;
    if ($self->is_single_declaration_with_assignment($stmt)) {
        $stmt->schild(0)->remove;
        $stmt->child(0)->remove if $stmt->child(0)->content =~ /^\s+/;
        $stmt->schild(0)->set_content('$self->' . $self->new_name);
        return $stmt;
    }
    if ($self->is_multi_declaration_without_assignment($stmt)) {
        my $symbol = $stmt->find_first(sub { 
                $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '$' . $self->current_name
            });
        $symbol->next_token->remove; #comma
        $symbol->next_token->remove; #whitespace
        $symbol->remove;
        return $stmt;
    }
    if ($self->is_multi_declaration_with_assignment($stmt)) {
        my $symbol = $stmt->find_first(sub { 
                $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '$' . $self->current_name
            });
        my $next_stmt = PPI::Statement->new;
        $next_stmt->add_element(PPI::Token::Symbol->new('$self'));
        $next_stmt->add_element(PPI::Token->new('->'));
        $next_stmt->add_element(PPI::Token->new($self->new_name));
        $next_stmt->add_element(PPI::Token->new(' '));
        $next_stmt->add_element(PPI::Token->new('='));
        $next_stmt->add_element(PPI::Token->new(' '));
        $next_stmt->add_element(PPI::Token::Symbol->new('$'.$self->new_name));
        my $both = PPI::Statement->new;
        $both->add_element($stmt);
        $both->add_element(PPI::Token->new("\n"));
        $both->add_element($next_stmt);
        $both->add_element(PPI::Token->new(";"));
        return $both;
    }
    return PPI::Statement::Variable->new;
}

sub is_single_declaration_with_assignment {
    my ($self, $stmt) = @_;
    return 0 if $stmt->schild(0)->content ne 'my';
    return 0 if ! $stmt->schild(1)->isa('PPI::Token::Symbol');
    return 0 if $stmt->schild(2)->content ne '=';
    return 1;
}

sub is_multi_declaration_without_assignment {
    my ($self, $stmt) = @_;
    return 0 if $stmt->schild(0)->content ne 'my';
    return 0 if ! $stmt->schild(1)->isa('PPI::Structure::List');
    return 0 if $stmt->schild(2)->content eq '=';
    return 1;
}

sub is_multi_declaration_with_assignment {
    my ($self, $stmt) = @_;
    return 0 if $stmt->schild(0)->content ne 'my';
    return 0 if ! $stmt->schild(1)->isa('PPI::Structure::List');
    return 0 if $stmt->schild(2)->content ne '=';
    return 1;
}

1;


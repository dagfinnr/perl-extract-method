package PPIx::EditorTools::ExtractMethod;
use PPI::Document;
use Set::Scalar;
use Moose;

sub Set::Scalar::as_list {
    my $self = shift;
    return '(' . join(', ', $self->elements) . ')';
}

sub PPI::Token::Symbol::is_hash { $_[0]->content =~ /^%/; }

sub PPI::Token::Symbol::is_array { $_[0]->content =~ /^@/; }

sub PPI::Token::Symbol::is_hash_or_array_element {
    my $self = shift;
    my $next = $self->next_sibling;
    return $next && $next->isa('PPI::Structure::Subscript');
}

has 'code'   => ( is => 'rw', isa => 'Str', trigger => \&parse );
has 'ppi'   => ( is => 'rw', isa => 'PPI::Document' );

sub method_body {
    my ($self, $method_name) = @_;
    return 'sub ' . $method_name . ' {' . "\n" .
    '    ' . $self->args_statement() . "\n" .
    $self->code . "\n" .
    'return ' . $self->used_scalars->as_list . ";\n" .
    '}';
}

sub call_statement {
    my ($self, $method_name) = @_;
    my $statement = '';
    if (!$self->declared_scalars->is_empty()) {
        $statement .= 'my ' . $self->declared_scalars->as_list . ";\n";
    }
    if (!$self->used_scalars->is_empty()) {
        $statement .= $self->used_scalars->as_list . ' = ';
    }
    $statement .= '$self->' . $method_name . 
    '(' . $self->undeclared_list . ');';
    return $statement;
}

sub args_statement {
    my $self = shift;
    return 'my $self = shift;' if $self->undeclared_scalars->is_empty();
    return 'my ($self, ' . $self->undeclared_list . ') = @_;';
}

sub undeclared_list {
    join(', ', $_[0]->undeclared_scalars->elements);
}

sub used_scalars {
    my $self = shift;
    my $scalars = Set::Scalar->new;
    foreach my $symbol ($self->symbols) {
        my $var = $symbol->content;
        next if $symbol->is_hash() || $symbol->is_array() || 
        $symbol->is_hash_or_array_element();
        $scalars->insert($var);
    }
    $scalars->delete('$self');
    return $scalars;
}

sub declared_scalars {
    my $self = shift;
    my $scalars = Set::Scalar->new;
    foreach my $node ($self->variable_declarations()) {
        my $symbol = $node->find_first('PPI::Token::Symbol');
        next if $symbol->is_array() || $symbol->is_hash();
        $scalars->insert($symbol->content);
    }
    return $scalars;
}

sub undeclared_scalars {
    my $self = shift;
    return $self->used_scalars - $self->declared_scalars;
}

sub parse {
    my $self = shift;
    $self->ppi(PPI::Document->new(\($self->code)));
}

sub symbols {
    my $self = shift;
    my $symbols = $self->ppi->find( 
        sub { $_[1]->isa('PPI::Token::Symbol') and $_[1]->content }
    );
    $symbols ||= [];
    return wantarray ? @$symbols : $symbols;
}

sub variable_declarations {
    my $self = shift;
    my $symbols = $self->ppi->find( 
        sub { $_[1]->isa('PPI::Statement::Variable') }
    );
    $symbols ||= [];
    return wantarray ? @$symbols : $symbols;
}

1;

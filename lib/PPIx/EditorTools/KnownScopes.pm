package PPIx::EditorTools::KnownScopes;
use Moose;

has 'ppi'   => ( 
    is => 'rw', 
    isa => 'PPI::Document',
    required => 1,
);

has 'start_selected'   => ( is => 'rw', isa => "Int", required => 1 );

has 'scopes'   => ( 
    is => 'rw', 
    isa => 'HashRef',
    lazy => 1,
    builder => '_build_scopes',
);

has 'inserted'   => ( 
    is => 'rw',
    builder => '_build_inserted_scope',
    lazy => 1,
);

has 'outside'   => ( 
    is => 'rw',
    builder => '_build_outside_scope',
    lazy => 1,
);

sub _build_scopes {
    my $self = shift;
    return { 
        inserted => $self->_build_inserted_scope,
        outside => $self->_build_outside_scope,
        document => $self->ppi,
    };
}

sub _build_inserted_scope {
    my $self = shift;
    my $token = PPIx::EditorTools::find_token_at_location(
        $self->ppi, 
        [$self->start_selected, 1]
    );
    return $token->snext_sibling->child(4);
}

sub _build_outside_scope {
    my $self = shift;
    return $self->enclosing_scope($self->inserted);
}

sub scope_category {
    my ($self, $symbol) = @_;
    my $scope_name = $self->enclosing_known_scope_name($symbol);
    if ($scope_name eq 'inserted' && 
        !$self->nearest_scope_is_known($symbol)) 
    {
        $scope_name = 'inside';
    }
    return $scope_name;
}

sub enclosing_scope {
    my ($self, $element) = @_;
    $element = $element->parent;
    while (!$element->scope) {
        $element = $element->parent;
    }
    return $element;
}

sub enclosing_known_scope {
    my ($self, $element) = @_;
    $element = $element->parent;
    while (!$self->is_known_scope($element)) {
        $element = $element->parent;
    }
    return $element;
}

sub is_known_scope {
    my ($self, $element) = @_;
    foreach my $name ( keys %{ $self->scopes } )
    {
        my $known_scope = $self->scopes->{ $name};
        return 1 if ($element == $known_scope);
    }
    return 0;
}

sub nearest_scope_is_known {
    my ($self, $element) = @_;
    return $self->enclosing_scope($element) == $self->enclosing_known_scope($element);
}

sub enclosing_scope_name {
    my ($self, $element) = @_;
    my $scope = $self->enclosing_scope($element);
    foreach my $name ( keys %{ $self->scopes } )
    {
        my $known_scope = $self->scopes->{ $name};
        return $name if ($scope == $known_scope);
    }
    return '';
}

sub enclosing_known_scope_name {
    my ($self, $element) = @_;
    my $scope = $self->enclosing_known_scope($element);
    foreach my $name ( keys %{ $self->scopes } )
    {
        my $known_scope = $self->scopes->{ $name};
        return $name if ($scope == $known_scope);
    }
    return '';
}
1;

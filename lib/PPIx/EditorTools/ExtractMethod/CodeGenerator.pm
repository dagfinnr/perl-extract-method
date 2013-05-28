package PPIx::EditorTools::ExtractMethod::CodeGenerator;
use PPIx::EditorTools::ExtractMethod::VariableSorter;
use Moose;

has 'sorter'   => ( is => 'ro', isa => 'PPIx::EditorTools::ExtractMethod::VariableSorter' );
has 'selected_code'   => ( is => 'ro', isa => 'Str' );

sub method_call {
    my ($self, $method_name) = @_;
    my $code = '$self->' . $method_name . 
    '(' . join(', ', $self->pass_list_external) . ');';
    $code = $self->returned_vars . ' = ' . $code if $self->return_vars;
    $code = $self->return_declarations . "\n" . $code if $self->return_by_ref_vars;
    $code .= "\n" . $self->return_dereference;
}

sub method_body {
    my ($self, $method_name) = @_;
    return "sub $method_name". ' {' ."\n" .
    $self->arg_list . "\n" .
    $self->arg_dereference . "\n" .
    $self->selected_code . "\n" .
    $self->return_statement . "\n" .
    '}';
}

sub arg_list {
    my $self = shift;
    return 'my (' . join(', ', '$self', $self->pass_list_internal) . ') = @_;';
}

sub arg_dereference {
    my $self = shift;
    return join "\n", map { 'my ' . join(' = ', @$_) . ';' } $self->dereference_list_internal;
}

sub return_statement {
    my $self = shift;
    return 'return (' . join(', ', $self->return_list_internal) . ');';
}

sub return_dereference {
    my $self = shift;
    return join "\n", map { join(' = ', @$_) . ';' } $self->dereference_list_external;
}

sub return_declarations {
    my $self = shift;
    return 'my (' . 
    join(', ', (map {'$' . $_->name } @{ $self->sorter->return_by_ref_bucket }), map { $_->id } @{ $self->sorter->return_by_ref_and_declare_bucket }) .
    ');';
}

sub returned_vars {
    my $self = shift;
    return '(' . join(', ', $self->return_list_external) . ')';
}

sub return_vars {
    my $self = shift;
    return scalar @{ $self->sorter->return_bucket } 
    + $self->return_by_ref_vars;
}

sub return_by_ref_vars {
    my $self = shift;
    return scalar @{ $self->sorter->return_by_ref_bucket };
}

sub pass_list_external {
    my $self = shift;
    my @list = map {$_->id} @{ $self->sorter->pass_bucket };
    foreach my $var ( @{ $self->sorter->pass_by_ref_bucket } ) {
        push @list, $var->make_reference;
    }
    return @list;
}

sub pass_list_internal {
    my $self = shift;
    my @list = map {$_->id} @{ $self->sorter->pass_bucket };
    foreach my $var ( @{ $self->sorter->pass_by_ref_bucket } ) {
        push @list, '$' . $var->name;
    }
    return @list;
}

sub dereference_list_external {
    my $self = shift;
    my @list;
    foreach my $var ( @{ $self->sorter->return_by_ref_bucket } ) {
        push @list, [$var->id,  $var->type . '$' . $var->name];
    }
    return @list;
}

sub dereference_list_internal {
    my $self = shift;
    my @list;
    foreach my $var ( @{ $self->sorter->pass_by_ref_bucket } ) {
        push @list, [$var->id,  $var->type . '$' . $var->name];
    }
    return @list;
}

sub return_list_internal {
    my $self = shift;
    my @list = map {$_->id} @{ $self->sorter->return_bucket };
    foreach my $var ( @{ $self->sorter->return_by_ref_bucket } ) {
        push @list, $var->make_reference;
    }
    return @list;
}

sub return_list_external {
    my $self = shift;
    my @list = map {$_->id} @{ $self->sorter->return_bucket };
    foreach my $var ( @{ $self->sorter->return_by_ref_bucket } ) {
        push @list, '$' . $var->name;
    }
    return @list;
}

1;

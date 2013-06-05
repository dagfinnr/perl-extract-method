package PPIx::EditorTools::ExtractMethod::Variable;
use Moose;
has 'name'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'type'   => ( is => 'ro', isa => 'Str', required => 1 );

has 'is_changed_in_selection' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'used_after' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'declared_in_selection' => ( is => 'rw', isa => 'Bool', default => 0 );

sub from_occurrence {
    my ($class, $occurrence) = @_;
    return __PACKAGE__->new(
        name => $occurrence->variable_name,
        type => $occurrence->variable_type,
    );
}

sub id {
    my $self = shift ;
    return $self->type . $self->name;
}

sub make_reference {
    return '\\' . $_[0]->id;
}

# I think there is actually a special PPI class for these
sub is_special_variable {
    return 1 if $_[0]->name eq '_';
    return 1 if $_[0]->name eq '/';
    return 1 if $_[0]->name eq '\\';
    return 1 if $_[0]->name eq '#';
    return 1 if $_[0]->name =~ /^\d$/;
    return 0;
}

1;

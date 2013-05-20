package PPIx::EditorTools::ExtractMethod::Variable;
use Moose;
has 'name'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'id'   => ( is => 'ro', isa => 'Str' );
has 'type'   => ( is => 'ro', isa => 'Str', required => 1 );

has 'used_after' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'declared_in_selection' => ( is => 'rw', isa => 'Bool', default => 0 );

sub make_reference {
    return '\\' . $_[0]->id;
}

1;

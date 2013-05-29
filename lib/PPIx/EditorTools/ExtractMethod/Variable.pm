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

sub is_special_variable {
    return 1 if $_[0]->name eq '_';
    return 1 if $_[0]->name eq '/';
    return 1 if $_[0]->name eq '\\';
    return 1 if $_[0]->name eq '#';
    return 1 if $_[0]->name =~ /^\d$/;
    return 0;
}

1;

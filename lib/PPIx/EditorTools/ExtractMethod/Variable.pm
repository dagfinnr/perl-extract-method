package PPIx::EditorTools::ExtractMethod::Variable;
use Moose;
has 'name'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'id'   => ( is => 'ro', isa => 'Str' );
has 'type'   => ( is => 'ro', isa => 'Str', required => 1 );

has 'used_after' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'declared_in_scope'   => ( 
    is => 'rw',
    isa => 'Str',
);

sub used_in_scope {
    my ($self, $scope) = @_;
    return if ! $scope;
    $self->used_in_scopes->insert($scope);
}
1;

package PPIx::EditorTools::ExtractMethod::Variable;
use Set::Scalar;
use Moose;
has 'name'   => ( is => 'ro', isa => 'Str' );
has 'id'   => ( is => 'ro', isa => 'Str' );

has 'used_in_scopes'   => ( 
    is => 'rw',
    isa => 'Set::Scalar',
    default => sub { Set::Scalar->new },
);

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

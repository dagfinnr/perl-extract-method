use Test::More;
use PPIx::EditorTools::ExtractMethod;
use Data::Dumper;

{
    package StubElement;
    use Moose;
    has 'parent'   => ( is => 'rw', isa => 'StubElement' );
    has 'scope'   => ( is => 'rw', isa => 'Bool', default => 0 );
}

my $scopes;

sub setup {
    my $code = shift || q!if ($condition) {
        sub ppi_temp {
        #somewhat random code, this
        my $foo; my $bar = $baz + $qux + $quux;
        }
        return $quux;
    }!;
    $scopes = PPIx::EditorTools::KnownScopes->new(
        ppi => PPI::Document->new(\$code),
        start_selected => 2,
    );
}

sub trim_code {
    my $code = shift;
    $code =~ s/^\s+//gm;
    return $code;
}

subtest 'can locate inserted sub in PPI document' => sub  {
    setup();
    isa_ok($scopes->inserted, 'PPI::Structure::Block');
    ok($scopes->inserted->scope);
    isa_ok($scopes->inserted->parent, 'PPI::Statement::Sub');
};

subtest 'can locate outside scope' => sub  {
    setup();
    isa_ok($scopes->outside, 'PPI::Structure::Block');
    isa_ok($scopes->outside->parent, 'PPI::Statement::Compound');
};

subtest 'can identify enclosing scope for element' => sub {
    my $scope = StubElement->new(scope => 1);
    my $e1 = StubElement->new(parent => $scope);
    my $e2 = StubElement->new(parent => $e1);
    is( $scopes->enclosing_scope($e2), $scope );
};

subtest 'can identify enclosing known scope for element' => sub {
    my $scope1 = StubElement->new(scope => 1);
    my $e1 = StubElement->new(parent => $scope1);
    my $scope2 = StubElement->new(parent => $e1, scope => 1);
    my $e2 = StubElement->new(parent => $scope2);
    $scopes->scopes({'test' => $scope1});
    is( $scopes->enclosing_scope($e2), $scope2 );
    is( $scopes->enclosing_known_scope($e2), $scope1 );
};

subtest 'can identify enclosing known scope name for element' => sub {
    my $scope1 = StubElement->new(scope => 1);
    my $e1 = StubElement->new(parent => $scope1);
    my $scope2 = StubElement->new(parent => $e1, scope => 1);
    my $e2 = StubElement->new(parent => $scope2);
    $scopes->scopes({'test' => $scope1});
    is( $scopes->enclosing_scope($e2), $scope2 );
    is( $scopes->enclosing_known_scope_name($e2), 'test' );
};

subtest 'can tell when known scope is not nearest' => sub {
    my $scope1 = StubElement->new(scope => 1);
    my $e1 = StubElement->new(parent => $scope1);
    my $scope2 = StubElement->new(parent => $e1, scope => 1);
    my $e2 = StubElement->new(parent => $scope2);
    $scopes->scopes({'test' => $scope1});
    ok( !$scopes->nearest_scope_is_known($e2) );
};

done_testing();

use Test::More;
use aliased PPIx::EditorTools::ExtractMethod::ScopeLocator;

subtest 'can find enclosing scope for element' => sub  {
    $code = q!sub {
    my $foo;
    if (1) {
        ($bar, $qux);
    }!;
    my $doc = PPI::Document->new(\$code);
    my $foo = $doc->find_first( sub { $_[1]->content eq '$foo' } );
    my $bar = $doc->find_first( sub { $_[1]->content eq '$bar' } );
    $locator = ScopeLocator->new(ppi => $doc);
    my $scope = $locator->enclosing_scope($bar);
    is ($scope->parent->child(0)->content, "if");
    $scope = $locator->enclosing_scope($foo);
    is ($scope->parent->child(0)->content, "sub");


};

done_testing();

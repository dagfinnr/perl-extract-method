use Test::More;
use PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion;

my ($region);

#sub setup {
#    $region = PPIx::EditorTools::ExtractMethod::CodeRegion->new();
#    my $code = shift || q!
#    if ($condition) {
#        my $inside = 42;
#        my $bar = $baz + $qux + $inside;
#        $bar = $corge;
#        return $quux;
#    }
#    $foo = 1;
#    $grault = 2!;
#    $analyzer->code($code);
#    $analyzer->selected_range([3,4]);
#}

subtest 'can search whole document' => sub  {
    $region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        ppi => PPI::Document->new(\'my $foo = $bar;')
    );
    @names = map { $_->content } @{ $region->find_symbols };
    is($names[0], '$foo');
    is($names[1], '$bar');
};

subtest 'can search line range with start and end' => sub  {
    $region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        ppi => PPI::Document->new(\q!my $foo = $bar;
        my $quux;
        my @baz = %qux;
        my $grault;
        !),
        selected_range => [2,3],
    );
    @names = map { $_->content } @{ $region->find_symbols };
    is($names[0], '$quux');
    is($names[1], '@baz');
    is($names[2], '%qux');
};

subtest 'can search line range with start but no end' => sub  {
    $region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        ppi => PPI::Document->new(\q!my $foo = $bar;
        my $quux;
        my @baz = %qux;
        my $grault;
        !),
        selected_range => [3,99999999],
    );
    @names = map { $_->content } @{ $region->find_symbols };
    is($names[0], '@baz');
    is($names[1], '%qux');
    is($names[2], '$grault');
};

subtest 'can search line range within scope' => sub  {
    my $doc = PPI::Document->new(\q!my $foo = $bar;
    {
    my $quux;
    my @baz = %qux;
    my $grault;
    }
    $fred;
    !);
    my $scope = $doc->find_first('PPI::Structure::Block');

    $region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        ppi => $doc,
        scope => $scope,
        selected_range => [4,99999999],
    );
    @names = map { $_->content } @{ $region->find_symbols };
    is (scalar @names, 3);
    is($names[0], '@baz');
    is($names[1], '%qux');
    is($names[2], '$grault');
};
done_testing();

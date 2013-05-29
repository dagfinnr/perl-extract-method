use Test::More;
use PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion;

my ($region);

subtest 'can find quote tokens' => sub  {
    $region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        ppi => PPI::Document->new(\q!"$qux";
        "$foo/$bar";
        s/$foo/$bar/'
        "$quux";
        !
    ),
        selected_range => [2,3],
    );
    $tokens = $region->find_quote_tokens;
    isa_ok($tokens->[0], 'PPI::Token::Quote::Double');
    isa_ok($tokens->[1], 'PPI::Token::Regexp::Substitute');
};

subtest 'can find quoted variable occurrences' => sub  {
    $region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        ppi => PPI::Document->new(\'"$foo/$bar"; s/$foo/$bar/'),
        selected_range => [1,9999],
    );
    @names = map { $_->variable_id } $region->find_quoted_variable_occurrences;
    is($names[0], '$foo');
    is($names[1], '$bar');
    is($names[2], '$foo');
    is($names[3], '$bar');
};

subtest 'can search whole document' => sub  {
    $region = PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion->new(
        ppi => PPI::Document->new(\'my $foo = $bar;')
    );
    @names = map { $_->variable_id } $region->find_variable_occurrences;
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
    @names = map { $_->variable_id } $region->find_variable_occurrences;
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
    @names = map { $_->variable_id } $region->find_variable_occurrences;
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
    @names = map { $_->variable_id } $region->find_variable_occurrences;
    is (scalar @names, 3);
    is($names[0], '@baz');
    is($names[1], '%qux');
    is($names[2], '$grault');
};
done_testing();

use Test::More;
use PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter;
1;
subtest 'can eliminate double quotes' => sub  {
    my $doc = PPI::Document->new(\'"$foo/$bar"');
    my $expected = PPI::Document->new(\'$foo/$bar');
    my $token = $doc->first_token;
    is_deeply(
        (PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter->to_ppi($token))[0],
        $expected); 
};

subtest 'can eliminate backticks' => sub  {
    my $doc = PPI::Document->new(\'`$foo/$bar`');
    my $expected = PPI::Document->new(\'$foo/$bar');
    my $token = $doc->first_token;
    is_deeply(
        (PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter->to_ppi($token))[0],
        $expected); 
};

subtest 'can eliminate qq token' => sub  {
    my $doc = PPI::Document->new(\'qq!$foo/$bar!');
    my $expected = PPI::Document->new(\'$foo/$bar');
    my $token = $doc->first_token;
    my @docs = PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter->to_ppi($token); 
    is_deeply($docs[0], $expected);
};

subtest 'can get code from s///' => sub  {
    my $doc = PPI::Document->new(\'s/$foo/$bar/');
    my $expected0 = PPI::Document->new(\'$foo');
    my $expected1 = PPI::Document->new(\'$bar');
    my $token = $doc->first_token;
    my @docs = PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter->to_ppi($token); 
    is_deeply($docs[0], $expected0);
    is_deeply($docs[1], $expected1);
};

subtest 'does not eliminate single quotes' => sub  {
    my $doc = PPI::Document->new(\q{q!$foo/$bar!});
    my $expected = PPI::Document->new(\'$foo/$bar');
    my $token = $doc->first_token;
    my @docs = PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter->to_ppi($token); 
    is(scalar @docs, 0);
};


done_testing();

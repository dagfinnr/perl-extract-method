use Test::More;
use PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter;
1;
sub process {
    my $code = shift;
    my $doc = PPI::Document->new(\$code);
    my $token = $doc->first_token;
    PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter->to_ppi($token); 
}

subtest 'can eliminate double quotes' => sub  {
    my @docs = process('"$foo/$bar"');
    is("$docs[0]", '$foo/$bar');
};

subtest 'can eliminate backticks' => sub  {
    my @docs = process('`$foo/$bar`');
    is("$docs[0]", '$foo/$bar');
};

subtest 'can eliminate qq token' => sub  {
    my @docs = process('qq!$foo/$bar!');
    is("$docs[0]", '$foo/$bar');
};

subtest 'can get code from s///' => sub  {
    my @docs = process('s/$foo/$bar/');
    is("$docs[0]", '$foo');
    is("$docs[1]", '$bar');
};

subtest 'does not eliminate single quotes' => sub  {
    my @docs = process(q{q!$foo/$bar!});
    is(scalar @docs, 0);
};


done_testing();

use Test::More;
use PPIx::EditorTools::ExtractMethod::Analyzer;
use Data::Dumper;

sub trim_code {
    my $code = shift;
    $code =~ s/^\s+//gm;
    return $code;
}

my $analyzer;

sub setup {
    $analyzer = PPIx::EditorTools::ExtractMethod::Analyzer->new();
    my $code = shift || q!my $qux; my $grault;
    if ($condition) {
        my $inside = 42;
        my $foo; my $bar = $baz + $qux + $inside;
        $bar = $corge;
        return $quux;
    }
    $foo = 1;
    $grault = 2!;
    $analyzer->code($code);
    $analyzer->start_selected(3);
    $analyzer->end_selected(4);
}

subtest 'can identify variables within selected region' => sub  {
    setup();
    my $vars = $analyzer->found_variables;
    is_deeply( [ sort keys %{$vars} ], [ qw / $bar $baz $foo $inside $qux / ]);
};

subtest 'can identify variables in current scope after selected region' => sub  {
    setup();
    my $vars = $analyzer->variables_after_selected;
    is_deeply( [ sort keys %{$vars} ], [ qw / $bar $corge $quux / ]);
};

subtest 'identified variables are variable objects' => sub  {
    setup();
    my $vars = $analyzer->found_variables;
    my $baz = $vars->{'$baz'};
    isa_ok($baz, 'PPIx::EditorTools::ExtractMethod::Variable');
    is($baz->name, 'baz');
    is($baz->id, '$baz');
};

subtest 'can identify variable declared inside selected region' => sub  {
    my $vars = $analyzer->found_variables;
    my $foo = $vars->{'$foo'};
    is($foo->declared_in_scope, 'selected');
};

subtest 'can identify variable declared outside selected region' => sub  {
    my $vars = $analyzer->found_variables;
    my $foo = $vars->{'$qux'};
    is($foo->declared_in_scope, 'before');
};

subtest 'can know variable is used after selected region' => sub {
    setup();
    my $vars = $analyzer->relevant_variables;
    ok ($vars->{ '$bar' }->used_after);
    ok (!$vars->{ '$inside' }->used_after);
    ok (!$vars->{ '$foo' }->used_after);
};

subtest 'ignores variables completely outside' => sub {
    setup();
    my $vars = $analyzer->relevant_variables;
    ok (! defined $vars->{ '$grault' });
};

done_testing();

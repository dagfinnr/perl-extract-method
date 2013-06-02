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
    $analyzer->selected_range([3,4]);
}

subtest 'knows if there is a return statement at the end of the selected region' => sub  {
    setup(q!
        
        my $qux;
        return $qux;!
    );
    ok($analyzer->return_at_end);
    setup(q!
        my $qux;
        return $qux;
        $qux = 1;!
    );
    ok(!$analyzer->return_at_end);
};
subtest 'can identify variables within selected region' => sub  {
    setup();
    my $vars = $analyzer->variables_in_selected;
    is_deeply( [ sort keys %{$vars} ], [ qw / $bar $baz $foo $inside $qux / ]);
};

subtest 'can identify variables in current scope after selected region' => sub  {
    setup();
    my $vars = $analyzer->variables_after_selected;
    is_deeply( [ sort keys %{$vars} ], [ qw / $bar / ]);
};

subtest 'can identify variable declared before and used after in current scope' => sub  {
    setup(q!
        my $qux;
        $qux;
        $qux;
        $qux;
        !);
    my $vars = $analyzer->variables_after_selected;
    is_deeply( [ sort keys %{$vars} ], [ qw / $qux / ]);
};

subtest 'can identify variable declared and used after in larger scope' => sub  {
    setup(q!  my $qux;
        if ($x) {
            $qux;
            $qux;
            $bar;
        }
        $qux;
        !);
    my $vars = $analyzer->variables_after_selected;
    is_deeply( [ sort keys %{$vars} ], [ qw / $qux / ]);
};

subtest 'can find scope for variable declaration' => sub  {
    setup(q!  sub { my $qux;
        if ($x) {
            $qux;
            $qux;
            $bar;
        }
        $qux; }
        !);
    my $symbols = $analyzer->ppi->find(sub { $_[1]->content eq '$qux' });
    my $expected = $analyzer->ppi->find_first('PPI::Structure::Block');
    my $scope = $analyzer->find_scope_for_variable($symbols->[1]);
    is($scope, $expected);
};

subtest 'identified variables are variable objects' => sub  {
    setup();
    my $vars = $analyzer->variables_in_selected;
    my $baz = $vars->{'$baz'};
    isa_ok($baz, 'PPIx::EditorTools::ExtractMethod::Variable');
    is($baz->name, 'baz');
    is($baz->id, '$baz');
};

subtest 'can identify variable declared inside selected region' => sub  {
    my $vars = $analyzer->variables_in_selected;
    my $foo = $vars->{'$foo'};
    ok($foo->declared_in_selection);
};

subtest 'can identify variable declared outside selected region' => sub  {
    my $vars = $analyzer->variables_in_selected;
    my $foo = $vars->{'$qux'};
    ok(!$foo->declared_in_selection);
};

subtest 'can know variable is used after selected region' => sub {
    setup();
    my $vars = $analyzer->result->variables;
    ok ($vars->{ '$bar' }->used_after);
    ok (!$vars->{ '$inside' }->used_after);
    ok (!$vars->{ '$foo' }->used_after);
};

subtest 'ignores variables completely outside' => sub {
    setup();
    my $vars = $analyzer->result->variables;
    ok (! defined $vars->{ '$grault' });
};

subtest 'can return selected code as string' => sub  {
    my $expected = trim_code(q!my $inside = 42;
        my $foo; my $bar = $baz + $qux + $inside;!);
    is(trim_code($analyzer->selected_code),
        $expected);
};

#The following two behaviors are in place, but not tested:
#
#subtest 'can handle no variables inside selected region' => sub  {
#};

#subtest 'can handle no variables after selected region' => sub  {
#};

done_testing();

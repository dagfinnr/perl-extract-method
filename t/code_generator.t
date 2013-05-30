use Test::More;
use PPIx::EditorTools::ExtractMethod::CodeGenerator;
use PPIx::EditorTools::ExtractMethod::Analyzer;
use PPIx::EditorTools::ExtractMethod::VariableSorter;
my ($generator, $analyzer);

sub setup {
    $analyzer = PPIx::EditorTools::ExtractMethod::Analyzer->new();
    my $code = shift || q!my $qux; my $grault;
    if ($condition) {
        my %to_return = 42; $inside_array[0] = 43;
        my $foo; my $bar = $baz + $qux;
        $bar = $corge;
        return ($quux, %to_return);
    }
    $foo = 1;
    $grault = 2!;
    $analyzer->code($code);
    $analyzer->selected_range([3,4]);
    my $sorter = PPIx::EditorTools::ExtractMethod::VariableSorter->new(
        input => $analyzer->output_variables,
    );
    $sorter->process_input;
    $generator = PPIx::EditorTools::ExtractMethod::CodeGenerator->new(
        sorter => $sorter,
        selected_code => $analyzer->selected_code,
    );
}

sub trim_code {
    my $code = shift;
    $code =~ s/^\s+//gm;
    return $code;
}

subtest 'omits return list when nothing to return' => sub  {
    setup( q!sub foo{
        # one
        $qux = 42;
        # two
        }!
    ); 
    is(
        $generator->method_call('new_method'),
        '$self->new_method($qux);' . "\n"
    );
};

subtest 'can generate list of variables to pass' => sub  {
    setup();
    is(join(',', $generator->pass_list_external), '$qux,$baz,\@inside_array');
};

subtest 'can generate list of passed variables' => sub  {
    setup();
    is(join(',', $generator->pass_list_internal), '$qux,$baz,$inside_array');
};

subtest 'can generate list of variables to dereference when passing' => sub  {
    setup();
    is_deeply([$generator->dereference_list_internal], [[qw/@inside_array @$inside_array/]]);
};

subtest 'can generate list of variables to dereference after returning' => sub  {
    setup();
    is_deeply([$generator->dereference_list_external], [[qw/%to_return %$to_return/], [qw/@inside_array @$inside_array/] ]);
};

subtest 'can generate list of variables to return' => sub  {
    setup();
    is(join(',', $generator->return_list_internal), '$bar,\%to_return,\@inside_array');
};

subtest 'can generate list of returned variables' => sub  {
    setup();
    is(join(',', $generator->return_list_external), '$bar,$to_return,$inside_array');
};

subtest 'can generate argument list' => sub  {
    setup();
    is($generator->arg_list, 'my ($self, $qux, $baz, $inside_array) = @_;');
};

subtest 'can generate argument dereferencing' => sub  {
    setup();
    is($generator->arg_dereference, 'my @inside_array = @$inside_array;');
};

subtest 'can generate return statement' => sub  {
    setup();
    is($generator->return_statement, 'return ($bar, \%to_return, \@inside_array);');
};

subtest 'can generate simplifed return statement if only one var' => sub  {
    setup(q!
        my $foo;
        $bar = 1;
        $foo;
    }
    $bar;
    !);
    $analyzer->selected_range([3,4]);
    is($generator->return_statement, 'return $bar;');
};

subtest 'can generate dereferencing after return' => sub  {
    setup();
    is($generator->return_dereference, '%to_return = %$to_return;' . "\n" . '@inside_array = @$inside_array;');
};

subtest 'can generate declarations of returned variables and references' => sub  {
    setup();
    is($generator->return_declarations, 'my ($to_return, $inside_array, %to_return, $bar);');
};


subtest 'can generate list of returned vars' => sub  {
    setup();
    is($generator->returned_vars, '($bar, $to_return, $inside_array)');
};

subtest 'can generate simplifed list of returned vars if only one var' => sub  {
    setup(q!
        my $foo;
        $bar = 1;
        $foo;
    }
    $bar;
    !);
    is($generator->returned_vars, '$bar');
};
subtest 'can generate call to method' => sub  {
    setup(); 
    is(
        $generator->method_call('new_method'),
        'my ($to_return, $inside_array, %to_return, $bar);' . "\n" .
        '($bar, $to_return, $inside_array) = $self->new_method($qux, $baz, \@inside_array);' . "\n" .
        '%to_return = %$to_return;' . "\n" .
        '@inside_array = @$inside_array;'
    );
};

subtest 'can generate method body' => sub  {
    setup(); 
    my $expected = q!sub new_method {
        my ($self, $qux, $baz, $inside_array) = @_;
        my @inside_array = @$inside_array;
        my %to_return = 42; $inside_array[0] = 43;
        my $foo; my $bar = $baz + $qux;
        return ($bar, \%to_return, \@inside_array);
    }!;
    is(
        trim_code($generator->method_body('new_method')),
        trim_code($expected)
    );
};
done_testing();

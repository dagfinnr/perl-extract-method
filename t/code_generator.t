use Test::More;
use Test::More::Hooks;
use aliased 'PPIx::EditorTools::ExtractMethod::CodeGenerator';
use aliased 'PPIx::EditorTools::ExtractMethod::Analyzer';
use aliased 'PPIx::EditorTools::ExtractMethod::VariableSorter';

my ($generator, $analyzer);

# The setup process is a bit clumsy since it sometimes runs twice.
# Once from the before block and once by explicit call if it needs
# arguments.
#
sub setup {
    $analyzer = Analyzer->new();
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
    my $sorter = VariableSorter->new(
        analyzer_result => $analyzer->result,
    );
    $sorter->process_input;
    $generator = CodeGenerator->new(
        sorter => $sorter,
        selected_code => $analyzer->selected_code,
    );
}

sub trim_code {
    my $code = shift;
    $code =~ s/^\s+//gm;
    return $code;
}

before {
    setup();
};

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

subtest 'omits return list and adds return statement when selected code has return statement at end' => sub  {
    setup( q!sub foo{
        # one
        $qux = 42;
        # two
        }!
    ); 
    $generator->sorter->return_statement_at_end(1);
    is(
        $generator->method_call('new_method'),
        'return $self->new_method($qux);'
    );
};

subtest 'can generate list of variables to pass' => sub  {
    is(join(',', $generator->pass_list_external), '$baz,$qux,\@inside_array');
};


subtest 'can generate list of passed variables' => sub  {
    is(join(',', sort $generator->pass_list_internal), '$baz,$inside_array,$qux');
};

subtest 'can generate list of variables to dereference when passing' => sub  {
    is_deeply([$generator->dereference_list_internal], [[qw/@inside_array @$inside_array/]]);
};

subtest 'can generate list of variables to dereference after returning' => sub  {
    is_deeply([$generator->dereference_list_external], [[qw/%to_return %$to_return/],[qw/@inside_array @$inside_array/]]);
};

subtest 'can generate list of variables to return' => sub  {
    is(join(',', $generator->return_list_internal), '$bar,\%to_return,\@inside_array');
};

subtest 'can generate list of returned variables' => sub  {
    is(join(',', $generator->return_list_external), '$bar,$to_return,$inside_array');
};

subtest 'can generate argument list' => sub  {
    (my $arg_list = $generator->arg_list) =~ s/(\$qux),(\s*)(\$baz)/$3,$2$1/;
    is($arg_list, 'my ($self, $baz, $qux, $inside_array) = @_;');
};

subtest 'can generate argument dereferencing' => sub  {
    is($generator->arg_dereference, 'my @inside_array = @$inside_array;');
};

subtest 'can generate return statement' => sub  {
    (my $stmt = $generator->return_statement) =~ s/(..to_return),(\s*)(..inside_array)/$3,$2$1/;
    is($stmt, 'return ($bar, \@inside_array, \%to_return);');
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
    is($generator->return_dereference, '%to_return = %$to_return;' . "\n" . '@inside_array = @$inside_array;');
};

#my $re = '([@$%]\w+,\s*){3}([@$%]\w+,\s*)';
subtest 'can generate declarations of returned variables and references' => sub  {
    is($generator->return_declarations, 'my ($bar, $inside_array, $to_return, %to_return);');
};


subtest 'can generate list of returned vars' => sub  {
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
    is(
        $generator->method_call('new_method'),
        'my ($bar, $inside_array, $to_return, %to_return);' . "\n" .
        '($bar, $to_return, $inside_array) = $self->new_method($baz, $qux, \@inside_array);' . "\n" .
        '%to_return = %$to_return;' . "\n" .
        '@inside_array = @$inside_array;'
    );
};

subtest 'can generate method body' => sub  {
    my $expected = q!sub new_method {
        my ($self, $baz, $qux, $inside_array) = @_;
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

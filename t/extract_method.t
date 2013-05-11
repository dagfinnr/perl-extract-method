use Test::More;
use PPIx::EditorTools::ExtractMethod;
use Data::Dumper;

my $extract;

sub setup {
    $extract = PPIx::EditorTools::ExtractMethod->new();
    my $code = shift || q!if ($condition) {
        #somewhat random code, this
        my $foo; my $bar = $baz + $qux + $quux;
        return $quux;
    }!;
    $extract->code($code);
    $extract->start_selected(2);
    $extract->end_selected(3);
}

sub trim_code {
    my $code = shift;
    $code =~ s/^\s+//gm;
    return $code;
}

#TODO: {
#    local $TODO = 'deal with interpolated variables';
#    subtest 'can deal with interpolated variables' => sub  {
#        setup('my $foo = "$bar"');
#        is_deeply( [ $extract->undeclared_scalars->elements ], [ '$bar' ]);
#    };
#};

subtest 'can identify variable in inserted scope' => sub  {
    setup();
    my $qux = $extract->used_variables->{qux};
    is_deeply([ $qux->used_in_scopes->elements ], [ qw( inserted ) ]);
};

subtest 'can add sub around selected code' => sub  {
    setup();
    my $expected = q!if ($condition) {
        sub ppi_temp {
        #somewhat random code, this
        my $foo; my $bar = $baz + $qux + $quux;
        }
        return $quux;
    }!;
    is(trim_code($extract->code_with_sub), trim_code($expected));
};

subtest 'can find used variables' => sub  {
    setup();
    is($extract->used_variables->{bar}->name, 'bar');
    is($extract->used_variables->{baz}->name, 'baz');
    is($extract->used_variables->{quux}->name, 'quux');
    is($extract->used_variables->{qux}->name, 'qux');
};


subtest 'can locate inserted sub in PPI document' => sub  {
    setup();
    isa_ok($extract->inserted, 'PPI::Structure::Block');
    ok($extract->inserted->scope);
    isa_ok($extract->inserted->parent, 'PPI::Statement::Sub');
};

subtest 'can locate outside scope' => sub  {
    setup();
    isa_ok($extract->outside, 'PPI::Structure::Block');
    isa_ok($extract->outside->parent, 'PPI::Statement::Compound');
};

subtest 'can identify variable in two scopes' => sub  {
    setup();
    my $quux = $extract->used_variables->{quux};
    is_deeply([ $quux->used_in_scopes->elements ], [ qw( inserted outside ) ]);
};

subtest 'can identify variable in inside scope' => sub  {
    setup(q!if ($condition) {
        #somewhat random code, this
        if ($other_condition) {
            $corge = 1;
        }
        my $foo; my $bar = $baz + $qux + $quux;
        return $quux;
    }!);
    $extract->end_selected(5);
    my $corge = $extract->used_variables->{corge};
    is($corge->name, 'corge');
    is_deeply([ $corge->used_in_scopes->elements ], [ qw( inside ) ]);
};

subtest 'can tell variable is declared in inserted scope' => sub  {
    setup();
    my $foo = $extract->used_variables->{foo};
    is ($foo->declared_in_scope, 'inserted');
};

subtest 'can tell whether a symbol is part of a declaration' => sub  {
    my $code = 'my $foo = $bar';
    my $ppi = PPI::Document->new( \$code );
    my $declared = $ppi->find( sub { $_[1]->content eq '$foo' } )->[0];
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $declared);
    ok ($occurrence->is_declaration);
    my $used = $ppi->find( sub { $_[1]->content eq '$bar' } )->[0];
    $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $used);
    ok (!$occurrence->is_declaration);
};

subtest 'can generate variable name and id' => sub  {
    my $code = 'my $foo = $bar';
    my $ppi = PPI::Document->new( \$code );
    my $used = $ppi->find( sub { $_[1]->content eq '$bar' } )->[0];
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $used);
    is($occurrence->variable_name, 'bar');

};
done_testing();

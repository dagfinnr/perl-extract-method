use Test::More;
use PPI::Document;
use aliased 'PPIx::EditorTools::ConvertVarToAttribute';

my $refactoring;

sub setup {
    $refactoring = ConvertVarToAttribute->new(current_name => 'foo');
}

sub process {
    my $doc = PPI::Document->new(\$_[0]);
    my $statement = $doc->find_first('PPI::Statement')->remove;
    return $refactoring->process_declaration($statement)->content;
}

subtest 'can remove from single declaration without assignment' => sub  {
    setup();
    is(process('my $foo;'), "")
};

subtest 'can replace with new name' => sub  {
    setup();
    $refactoring->new_name('qux');
    is(process('my $foo = $bar;'), '$self->qux($bar);')
};

subtest 'can replace in single declaration with assignment' => sub  {
    setup();
    is(process('my $foo = $bar;'), '$self->foo($bar);')
};

subtest 'can remove from multi-declaration without assignment' => sub  {
    setup();
    is(process('my ($bar, $foo, $qux);'), 'my ($bar, $qux);')
};

subtest 'can adjust multi-declaration with assignment' => sub  {
    setup();
    is(
        process('my ($bar, $foo, $qux) = $self->quux;'),
        'my ($bar, $foo, $qux) = $self->quux;' . "\n" .
        '$self->foo($foo);'
    );
    $refactoring = ConvertVarToAttribute->new(current_name => 'c');
    is(
        process('my ( $self, $c ) = @_;'),
        'my ( $self, $c ) = @_;' . "\n" .
        '$self->c($c);'
    );
    
};

subtest 'can generate Moose attribute' => sub {
    setup();
    my $expected = q!has 'foo' => (is => 'rw');! . "\n";
    is($refactoring->moose_attribute->content, $expected);
};

subtest 'can find location of Moose attributes' => sub  {
    setup();
    my $doc = PPI::Document->new('t/data/input/Analyzer_error.pm');
    $refactoring->ppi($doc);
    my $statements = $refactoring->find_attribute_definitions;
    is($statements->[0]->line_number, 13);
};

subtest 'can replace all uses of a variable' => sub  {
    setup();
    my $code = q!my $foo;
    $foo = $bar + 1;
    print $foo;
    #$bar = "$foo" #let's not do this yet;
    !;
    my $doc = PPI::Document->new(\$code);
    $refactoring->ppi($doc);
    $refactoring->current_location([2,5]);
    my $expected = q!
    $self->foo($bar + 1);
    print $self->foo;
    #$bar = "$foo" #let's not do this yet;
    !;
    is($refactoring->replace_vars, $expected);
};

subtest 'can replace incremented variable' => sub  {
    setup();
    my $code = q!my $foo;
    $foo++;
    $foo--;
    ++$foo;
    --$foo;
    !;
    my $doc = PPI::Document->new(\$code);
    $refactoring->ppi($doc);
    $refactoring->current_location([2,5]);
    my $expected = q!
    $self->foo($self->foo + 1);
    $self->foo($self->foo - 1);
    $self->foo($self->foo + 1);
    $self->foo($self->foo - 1);
    !;
    is($refactoring->replace_vars, $expected);
};

subtest 'can add Moose attribute to document' => sub {
    setup();
    my $doc = PPI::Document->new('t/data/input/Analyzer_error.pm');
    unlike($doc->content, qr/has 'foo'/);
    $refactoring->ppi($doc);
    $refactoring->add_moose_attribute();
    like($doc->content, qr/has 'foo'/);
};

subtest 'can get current name from variable at current_location' => sub  {
    setup();
    my $code = q!my $foo;
    $foo = $bar;
    !;
    my $doc = PPI::Document->new(\$code);
    $refactoring = ConvertVarToAttribute->new;
    $refactoring->ppi($doc);
    $refactoring->current_location([2,13]);
    is($refactoring->current_name, 'bar');
};
done_testing();

use Test::More;
use PPIx::EditorTools::ExtractMethod;
use Data::Dumper;

my $extract = PPIx::EditorTools::ExtractMethod->new();

sub setup {
    my $code = shift || 'my $foo; my $bar = $baz + $qux;';
    $extract->code($code);
}

sub trim_code {
    my $code = shift;
    $code =~ s/^\s+//gm;
    return $code;
}

subtest 'can find all used scalar variables' => sub  {
    setup(q(
        if ($width && $height && $width < $height) {
            my $ratio = $maxwidth/$width;
            $newwidth = $maxwidth;
            $newheight = $height * $ratio;
        }
    ));
    ok(
        Set::Scalar->new(qw($height $maxwidth $newheight $newwidth $ratio $width ))
        == $extract->used_scalars
    );
};

subtest 'can identify single scalar variable declaration' => sub  {
    setup();
    ok( Set::Scalar->new(qw( $foo $bar )) == $extract->declared_scalars);
};

subtest 'can identify undeclared scalars' => sub  {
    setup();
    ok( Set::Scalar->new(qw( $baz $qux )) == $extract->undeclared_scalars);
};

subtest 'can generate arguments initialization statement' => sub  {
    setup();
    is($extract->args_statement(), 'my ($self, $qux, $baz) = @_;')
};

subtest 'can generate arguments initialization statement with no variables' => sub  {
    setup('# only a comment');
    is($extract->args_statement(), 'my $self = shift;')
};

subtest 'can generate call to extracted method' => sub  {
    setup();
    is(
        $extract->call_statement('new_method'), 
        'my ($foo, $bar);' . "\n" .
        '($qux, $foo, $baz, $bar) = $self->new_method($qux, $baz);'
    )
};

subtest 'can generate call to extracted method with no variables' => sub  {
    setup('# only a comment');
    is($extract->call_statement('new_method'), '$self->new_method();')
};

subtest 'can generate extracted method' => sub  {
    setup();
    my $method = q(
    sub new_method {
        my ($self, $qux, $baz) = @_;
        my $foo; my $bar = $baz + $qux;
        return ($qux, $foo, $baz, $bar);
    });
    is(trim_code($extract->method_body('new_method')), trim_code($method));
};

subtest 'does not register arrays as scalars' => sub  {
    setup('my $foo = $bar[0], @bar, $baz;');
    is_deeply( [ $extract->undeclared_scalars->elements ], [ '$baz' ]);
};

subtest 'does not register array declarations as scalar declarations' => sub  {
    setup('my @foo = ($baz);');
    ok($extract->declared_scalars->is_empty());
};

subtest 'does not register hashes as scalars' => sub  {
    setup('my $foo = $bar{qux}, %bar, $baz;');
    is_deeply( [ $extract->undeclared_scalars->elements ], [ '$baz' ]);
};

subtest 'does not duplicate $self' => sub  {
    setup('$self->foo(42);');
    is($extract->args_statement(), 'my $self = shift;');
    setup('$self->foo(42);my $foo; my $bar = $baz + $qux;');
    is($extract->args_statement(), 'my ($self, $qux, $baz) = @_;')
};

#TODO: {
#    local $TODO = 'deal with interpolated variables';
    subtest 'can deal with interpolated variables' => sub  {
        setup('my $foo = "$bar"');
        is_deeply( [ $extract->undeclared_scalars->elements ], [ '$bar' ]);
    };
#};

done_testing();

use Test::More;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory;
use PPI::Document;

my $factory = PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory->new;

sub occurrence {
    my $symbol = shift;
    $factory->occurrence_from_symbol($symbol);
}

subtest 'can set location' => sub  {
    my $ppi = PPI::Document->new( \'my $foo = $bar' );
    my $symbol = $ppi->find('PPI::Token::Symbol')->[1];
    my $occurrence = occurrence($symbol);
    is(join(';', @{$occurrence->location}), '1;11;11;1;');
};

subtest 'can generate variable name and id' => sub  {
    my $ppi = PPI::Document->new( \'my $foo = $bar' );
    my $symbol = $ppi->find('PPI::Token::Symbol')->[1];
    my $occurrence = occurrence($symbol);
    is($occurrence->variable_name, 'bar');
    is($occurrence->variable_id, '$bar');
};

subtest 'can parse single variable declaration' => sub  {
    my $ppi = PPI::Document->new( \'my $foo = $bar' );
    my $declared_symbol = $ppi->find('PPI::Token::Symbol')->[0];
    my $occurrence = occurrence($declared_symbol);
    ok ($occurrence->is_declaration);
    my $used_symbol = $ppi->find('PPI::Token::Symbol')->[1];
    ok (!occurrence($used_symbol)->is_declaration);
};

subtest 'can parse loop variable declaration' => sub  {
    my $ppi = PPI::Document->new(\'foreach my $foo ( @bar ) { }');
    my $declared_symbol = $ppi->find('PPI::Token::Symbol')->[0];
    my $occurrence = occurrence($declared_symbol);
    ok ($occurrence->is_declaration);
    my $used_symbol = $ppi->find('PPI::Token::Symbol')->[1];
    ok (!occurrence($used_symbol)->is_declaration);
};

subtest 'can parse multi-variable declaration' => sub  {
    my $ppi = PPI::Document->new(\'my ($foo, $qux) = $bar');
    my $declared_symbol = $ppi->find('PPI::Token::Symbol')->[0];
    my $occurrence = occurrence($declared_symbol);
    ok ($occurrence->is_declaration);
    my $declared_symbol = $ppi->find('PPI::Token::Symbol')->[1];
    $occurrence = occurrence($declared_symbol);
    ok ($occurrence->is_declaration);
    my $used_symbol = $ppi->find('PPI::Token::Symbol')->[2];
    ok (!occurrence($used_symbol)->is_declaration);
};

subtest 'can identify type of simple variables' => sub {
    my $symbol = PPI::Token::Symbol->new;
    $symbol->set_content('$var');
    my $occurrence = occurrence($symbol);
    is($occurrence->variable_type, '$');
    $symbol->set_content('%var');
    $occurrence = occurrence($symbol);
    is($occurrence->variable_type, '%');
    $symbol->set_content('@var');
    $occurrence = occurrence($symbol);
    is($occurrence->variable_type, '@');
};

subtest 'can identify type of hash or array element' => sub {
    my $ppi = PPI::Document->new(\'$var[0]');
    my $symbol = $ppi->find( sub { $_[1]->content eq '$var' } )->[0];
    my $occurrence = occurrence($symbol);
    is($occurrence->variable_id, '@var');
    my $ppi = PPI::Document->new(\'$var{a}');
    my $symbol = $ppi->find( sub { $_[1]->content eq '$var' } )->[0];
    $occurrence = occurrence($symbol);
    is($occurrence->variable_id, '%var');
};

subtest 'can detect assignment' => sub  {
    my $ppi = PPI::Document->new(\'$bar = $foo');
    my $symbol = $ppi->first_token;
    my $occurrence = occurrence($symbol);
    ok($occurrence->is_changed);
    $symbol = $ppi->find( sub { $_[1]->content eq '$foo' } )->[0];
    my $occurrence = occurrence($symbol);
    ok(!$occurrence->is_changed);
};

subtest 'can detect incrementing' => sub  {
    my $ppi = PPI::Document->new(\'++$bar');
    my $symbol = $ppi->find_first('PPI::Token::Symbol');
    my $occurrence = occurrence($symbol);
    ok($occurrence->is_changed);
    $ppi = PPI::Document->new(\'$bar--');
    $symbol = $ppi->find_first('PPI::Token::Symbol');
    $occurrence = occurrence($symbol);
};
done_testing();
__END__
Some variable declaration examples:

open my $fh, "<", $filename
while (my $line = <$fh>) {
(my $path = $file) =~ s/$class$//;
foreach my $cfgfile (@{$loaded_cfg}) {
for my $method (qw(want_som)) {
if ( my $hit = ${ $self->struct->{channel}->{item} }[$self->current_count]) {
foreach my $f (@fields){



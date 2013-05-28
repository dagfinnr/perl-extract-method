use Test::More;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence;
use PPI::Document;

my $extract;


subtest 'can generate variable name and id' => sub  {
    my $code = 'my $foo = $bar';
    my $ppi = PPI::Document->new( \$code );
    my $used = $ppi->find( sub { $_[1]->content eq '$bar' } )->[0];
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $used);
    is($occurrence->variable_name, 'bar');

};

subtest 'can parse single variable declaration' => sub  {
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

subtest 'can parse loop variable declaration' => sub  {
    my $code = 'foreach my $foo ( @bar ) { }';
    my $ppi = PPI::Document->new( \$code );
    my $declared = $ppi->find( sub { $_[1]->content eq '$foo' } )->[0];
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $declared);
    ok ($occurrence->is_declaration);
#    my $used = $ppi->find( sub { $_[1]->content eq '@bar' } )->[0];
#    $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
#        ppi_symbol => $used);
#    ok (!$occurrence->is_declaration);
};

subtest 'can parse multi-variable declaration' => sub  {
    my $code = 'my ($foo, $qux) = $bar';
    my $ppi = PPI::Document->new( \$code );
    my $declared = $ppi->find( sub { $_[1]->content eq '$foo' } )->[0];
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $declared);
    ok ($occurrence->is_declaration);
    $declared = $ppi->find( sub { $_[1]->content eq '$qux' } )->[0];
    $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $declared);
    ok ($occurrence->is_declaration);
    $declared = $ppi->find( sub { $_[1]->content eq '$bar' } )->[0];
    $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $declared);
    ok (!$occurrence->is_declaration);
};

subtest 'can identify type of simple variables' => sub {
    my $symbol = PPI::Token::Symbol->new;
    $symbol->set_content('$var');
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $symbol
    );
    is($occurrence->variable_type, '$');
    $symbol->set_content('%var');
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $symbol
    );
    is($occurrence->variable_type, '%');
    $symbol->set_content('@var');
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $symbol
    );
    is($occurrence->variable_type, '@');
};

subtest 'can identify type of hash or array element' => sub {
    my $code = '$var[0]';
    my $ppi = PPI::Document->new( \$code );
    my $symbol = $ppi->find( sub { $_[1]->content eq '$var' } )->[0];
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $symbol
    );
    is($occurrence->variable_id, '@var');
    my $code = '$var{a}';
    my $ppi = PPI::Document->new( \$code );
    my $symbol = $ppi->find( sub { $_[1]->content eq '$var' } )->[0];
    my $occurrence = PPIx::EditorTools::ExtractMethod::VariableOccurrence->new(
        ppi_symbol => $symbol
    );
    is($occurrence->variable_id, '%var');
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

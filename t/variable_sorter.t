use Test::More;
use PPIx::EditorTools::ExtractMethod::VariableSorter;
my $sorter;

subtest 'variable declared in inserted scope and used in outside scope' => sub  {
$sorter = PPIx::EditorTools::ExtractMethod::VariableSorter->new;
    my $var = PPIx::EditorTools::ExtractMethod::Variable->new(
        name => 'foo',
        used_in_scopes => Set::Scalar->new('outside'),
        declared_in_scope => 'inserted'
    );
    $sorter->input({foo => $var});
    $sorter->process_input();
    is_deeply( $sorter->return_bucket, [ $var ] );
};

subtest 'variable declared in outside scope and used in inserted scope' => sub  {
$sorter = PPIx::EditorTools::ExtractMethod::VariableSorter->new;
    my $var = PPIx::EditorTools::ExtractMethod::Variable->new(
        name => 'foo',
        used_in_scopes => Set::Scalar->new('inserted'),
        declared_in_scope => 'outside'
    );
    $sorter->input({foo => $var});
    $sorter->process_input();
    is_deeply( $sorter->pass_and_return_bucket, [ $var ] );
};

subtest 'variable undeclared and used in inserted scope' => sub  {
$sorter = PPIx::EditorTools::ExtractMethod::VariableSorter->new;
    my $var = PPIx::EditorTools::ExtractMethod::Variable->new(
        name => 'foo',
        used_in_scopes => Set::Scalar->new('inserted'),
        declared_in_scope => '',
    );
    $sorter->input({foo => $var});
    $sorter->process_input();
    is_deeply( $sorter->pass_and_return_bucket, [ $var ] );
};

done_testing();

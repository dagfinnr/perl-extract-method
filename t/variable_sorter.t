use Test::More;
use PPIx::EditorTools::ExtractMethod::VariableSorter;
my ($sorter, $var);

sub setup {
    my $options = shift;
    $sorter = PPIx::EditorTools::ExtractMethod::VariableSorter->new;
    $var = PPIx::EditorTools::ExtractMethod::Variable->new(
        name => 'foo',
        type => $options->{type} || '$',
        declared_in_selection => $options->{declared_in_selection},
        used_after => $options->{used_after},
        is_changed_in_selection => $options->{is_changed_in_selection} || 0,
    );
    $sorter->input({'$foo' => $var});
    $sorter->process_input();
}

subtest 'scalar declared before and used inside' => sub  {
    setup({declared_in_selection => 0, used_after => 0});
    is_deeply( $sorter->pass_bucket, [ $var ] );
    is_deeply( $sorter->return_bucket, [ ] );
};

subtest 'scalar declared inside and used inside' => sub  {
    setup({declared_in_selection => 1, used_after => 0});
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ ] );
};

subtest 'scalar declared inside and used after' => sub  {
    setup({declared_in_selection => 1, used_after => 1});
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ $var ] );
    is_deeply( $sorter->return_and_declare_bucket, [ $var ] );
};

subtest 'scalar declared before and used both inside and after, changed_inside' => sub  {
    setup({declared_in_selection => 0, used_after => 1, is_changed_in_selection => 1});
    is_deeply( $sorter->pass_bucket, [ $var ] );
    is_deeply( $sorter->return_bucket, [ $var ] );
};

subtest 'scalar declared before and used after, unchanged inside' => sub  {
    setup({declared_in_selection => 0, used_after => 1, is_changed_in_selection => 0});
    is_deeply( $sorter->pass_bucket, [ $var ] );
    is_deeply( $sorter->return_bucket, [ ] );
};

subtest 'hash declared before and used inside' => sub  {
    setup({declared_in_selection => 0, used_after => 0, type => '%'});
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ ] );
    is_deeply( $sorter->pass_by_ref_bucket, [ $var ] );
    is_deeply( $sorter->return_by_ref_bucket, [ $var ] );
};

subtest 'hash declared inside and used inside' => sub  {
    setup({declared_in_selection => 1, used_after => 0, type => '%'});
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ ] );
    is_deeply( $sorter->pass_by_ref_bucket, [ ] );
    is_deeply( $sorter->return_by_ref_bucket, [ ] );
};

subtest 'hash declared inside and used after' => sub  {
    setup({declared_in_selection => 1, used_after => 1, type => '%'});
    is_deeply( $sorter->pass_by_ref_bucket, [ ] );
    is_deeply( $sorter->return_by_ref_bucket, [ $var ] );
    is_deeply( $sorter->return_and_declare_bucket, [ $var ] );
};

subtest 'hash declared before and used both inside and after' => sub  {
    setup({declared_in_selection => 0, used_after => 1, type => '%'});
    is_deeply( $sorter->pass_by_ref_bucket, [ $var ] );
    is_deeply( $sorter->return_by_ref_bucket, [ $var ] );
};

subtest 'eliminates $self' => sub  {
    $sorter = PPIx::EditorTools::ExtractMethod::VariableSorter->new;
    $var = PPIx::EditorTools::ExtractMethod::Variable->new(
        name => 'self',
        type => '$',
        declared_in_selection => 0,
        used_after => 0,
    );
    $sorter->input({'$self' => $var});
    $sorter->process_input();
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ ] );
    is_deeply( $sorter->pass_by_ref_bucket, [ ] );
    is_deeply( $sorter->return_by_ref_bucket, [ ] );
};

subtest 'eliminates special variables' => sub  {
    $sorter = PPIx::EditorTools::ExtractMethod::VariableSorter->new;
    $var = PPIx::EditorTools::ExtractMethod::Variable->new(
        name => '_',
        type => '$',
        declared_in_selection => 0,
        used_after => 0,
    );
    $sorter->input({'$self' => $var});
    $sorter->process_input();
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ ] );
    is_deeply( $sorter->pass_by_ref_bucket, [ ] );
    is_deeply( $sorter->return_by_ref_bucket, [ ] );
};

done_testing();

use Test::More;
use PPIx::EditorTools::ExtractMethod::VariableSorter;
my ($sorter, $var);

sub setup {
    my $options = shift;
    $sorter = PPIx::EditorTools::ExtractMethod::VariableSorter->new;
    $var = PPIx::EditorTools::ExtractMethod::Variable->new(
        name => 'foo',
        type => $options->{type} || '$',
        declared_in_scope => $options->{declared_in_scope},
        used_after => $options->{used_after},
    );
    $sorter->input({$foo => $var});
    $sorter->process_input();
}

subtest 'scalar declared before and used inside' => sub  {
    setup({declared_in_scope => 'before', used_after => 0});
    is_deeply( $sorter->pass_bucket, [ $var ] );
    is_deeply( $sorter->return_bucket, [ ] );
};

subtest 'scalar declared inside and used inside' => sub  {
    setup({declared_in_scope => 'inside', used_after => 0});
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ ] );
};

subtest 'scalar declared inside and used outside' => sub  {
    setup({declared_in_scope => 'inside', used_after => 1});
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ $var ] );
};

subtest 'scalar declared inside and used both inside and outside' => sub  {
    setup({declared_in_scope => 'before', used_after => 1});
    is_deeply( $sorter->pass_bucket, [ $var ] );
    is_deeply( $sorter->return_bucket, [ $var ] );
};

subtest 'hash declared before and used inside' => sub  {
    setup({declared_in_scope => 'before', used_after => 0, type => '%'});
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ ] );
    is_deeply( $sorter->pass_by_ref_bucket, [ $var ] );
    is_deeply( $sorter->return_by_ref_bucket, [ ] );
};

subtest 'hash declared inside and used inside' => sub  {
    setup({declared_in_scope => 'inside', used_after => 0, type => '%'});
    is_deeply( $sorter->pass_bucket, [ ] );
    is_deeply( $sorter->return_bucket, [ ] );
    is_deeply( $sorter->pass_by_ref_bucket, [ ] );
    is_deeply( $sorter->return_by_ref_bucket, [ ] );
};

subtest 'hash declared inside and used outside' => sub  {
    setup({declared_in_scope => 'inside', used_after => 1, type => '%'});
    is_deeply( $sorter->pass_by_ref_bucket, [ ] );
    is_deeply( $sorter->return_by_ref_bucket, [ $var ] );
};

subtest 'hash declared inside and used both inside and outside' => sub  {
    setup({declared_in_scope => 'before', used_after => 1, type => '%'});
    is_deeply( $sorter->pass_by_ref_bucket, [ $var ] );
    is_deeply( $sorter->return_by_ref_bucket, [ $var ] );
};
done_testing();
__END__


subtest 'hash declared inside and used both inside and outside' => sub  {
    setup({declared_in_scope => 'before', used_after => 1, type => '%'});
    is_deeply( $sorter->pass_by_ref_bucket, [ $var ] );
    is_deeply( $sorter->return_by_ref_bucket, [ $var ] );
};

done_testing();

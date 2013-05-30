use Test::More;
use PPIx::EditorTools::ExtractMethod;
use File::Slurp;
use FindBin;

my $extractor;

subtest 'integration test' => sub  {
    ok(1);
    my $code = read_file($FindBin::Bin . '/data/input/RenameVariable.pm');
    my $expected = read_file($FindBin::Bin . '/data/output/RenameVariable.pm');
    my $extractor = PPIx::EditorTools::ExtractMethod->new(
        code => $code,
        selected_range => [122,150],
    );

    $extractor->extract_method('symbol_patterns');
    write_file('/tmp/RenameVariable.pm', $extractor->code);
    is($extractor->code . "\n", $expected);
};

subtest 'extract method from extract method' => sub  {
    my $code = read_file($FindBin::Bin . '/data/input/extract_method.pl');
    my $extractor = PPIx::EditorTools::ExtractMethod->new(
        code => $code,
        selected_range => [6,10],
    );
    $extractor->extract_method('foo');
    like($extractor->code,
        qr/my \(\$editor\).*\$editor = \$self->foo\(\$name\);/s
    );
};
done_testing();

use Test::More;
use PPIx::EditorTools::ExtractMethod::CodeEditor;

my $editor;

sub setup {
    my $code = shift || q!1;
    1;
    sub foo {
        my $self = shift;
        # extract
        # these
        # lines
        return $bar;
    }

    sub bar {
    !;

    my $replacement = q!# these
    # instead!;
    $editor = PPIx::EditorTools::ExtractMethod::CodeEditor->new(
        code => $code,
        replacement => $replacement,
        selected_range => [5, 7],
    );
}

sub trim_code {
    my $code = shift;
    $code =~ s/^\s+//gm;
    return $code;
}

subtest 'can replace selected code with given code' => sub  {
    setup();
    $editor->replace_selected_lines();
    like( $editor->code, qr/shift;\s*# these\s*# instead\s*return/s );
};

subtest 'can find the end of current sub' => sub  {
    setup();
    is($editor->end_of_sub,9);

}; 

subtest 'can insert code after end of current sub' => sub  {
    setup();
    $editor->insert_after(
        $editor->end_of_sub,
        "#one\n#two"
    );
    like( $editor->code, qr/\}\s*#one\s*#two\s*sub bar/s );
};

done_testing();

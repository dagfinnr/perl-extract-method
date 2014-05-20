sub extract_method {
    my ($self, $name) = @_;
    my $vars = $self->analyzer->output_variables();
    $self->sorter->input($vars);
    $self->sorter->process_input;
    my $editor = PPIx::EditorTools::ExtractMethod::CodeEditor->new(
        code => $self->code,
        replacement => $self->generator->method_call($name)
    );
    $editor->selected_range($self->selected_range);
    $editor->replace_selected_lines();
    $editor->insert_after(
        $editor->end_of_sub,
        $self->generator->method_body($name)
    );
    $self->code($editor->code);
}

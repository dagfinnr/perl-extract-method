package PPIx::EditorTools::ExtractMethod;

use Moose;

use PPI::Document;
use PPIx::EditorTools;
use PPIx::EditorTools::ExtractMethod::LineRange;
use PPIx::EditorTools::ExtractMethod::Analyzer;
use PPIx::EditorTools::ExtractMethod::VariableSorter;
use PPIx::EditorTools::ExtractMethod::CodeGenerator;
use PPIx::EditorTools::ExtractMethod::CodeEditor;

has 'code'   => ( is => 'rw', isa => 'Str' );

has 'selected_range' => (
    is => 'rw',
    isa => 'PPIx::EditorTools::ExtractMethod::LineRange',
    coerce => 1,
);

has 'analyzer'   => ( 
    is => 'ro', 
    isa => 'PPIx::EditorTools::ExtractMethod::Analyzer',
    builder => '_build_analyzer',
    lazy => 1,
);
has 'sorter'   => ( 
    is => 'ro', 
    isa => 'PPIx::EditorTools::ExtractMethod::VariableSorter',
    builder => '_build_sorter',
    lazy => 1,
);
has 'generator'   => ( 
    is => 'ro', 
    isa => 'PPIx::EditorTools::ExtractMethod::CodeGenerator',
    builder => '_build_generator',
    lazy => 1,
    required => 1,
);

sub _build_generator {
    my $self = shift;
    return PPIx::EditorTools::ExtractMethod::CodeGenerator->new(
        sorter => $self->sorter,
        selected_range => $self->selected_range,
        selected_code => $self->analyzer->selected_code,
    );
}

sub _build_sorter {
    my $self = shift;
    return PPIx::EditorTools::ExtractMethod::VariableSorter->new;
}
sub _build_analyzer {
    my $self = shift;
    my $analyzer = PPIx::EditorTools::ExtractMethod::Analyzer->new();
    $analyzer->code($self->code);
    $analyzer->selected_range($self->selected_range);
    return $analyzer;
}

#TODO Make sure we're not dependent on the correct sequence of end_of_sub vs
#replace_selected_lines
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
1;

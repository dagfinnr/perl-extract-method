package PPIx::EditorTools::ExtractMethod::CodeEditor;

use Moose;

use PPI::Document;
use PPIx::EditorTools;
use PPIx::EditorTools::ExtractMethod::LineRange;

has 'code'   => ( is => 'rw', isa => 'Str' );
has 'replacement'   => ( is => 'ro', isa => 'Str' );

has 'selected_range' => (
    is => 'rw',
    isa => 'PPIx::EditorTools::ExtractMethod::LineRange',
    coerce => 1,
);

sub replace_selected_lines {
    my $self = shift;
    my @lines = split "\n", $self->code;
    splice(
        @lines,
        $self->selected_range->start - 1,
        $self->selected_range->length,
        $self->replacement
    );
    $self->code(join "\n", @lines);
}

sub end_of_sub {
    my $self = shift;
    my $code = $self->code;
    my $doc = PPI::Document->new(\$code);
    $doc->index_locations();
    my $element = PPIx::EditorTools::find_token_at_location(
        $doc, [$self->selected_range->start, 1]);
    while (!$element->isa('PPI::Document') && !$element->isa('PPI::Statement::Sub'))
    {
        $element = $element->parent;
    }
    die 'No enclosing sub found' if $element->isa('PPI::Document');
    return $element->find_first('PPI::Structure::Block')->finish->line_number;
}

sub insert_after {
    my ($self, $line, $code) = @_;
    my @lines = split "\n", $self->code;
    splice( @lines, $line, 0, $code);
    $self->code(join "\n", @lines);
}
1;

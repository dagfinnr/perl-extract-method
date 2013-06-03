# Need handling for hashes and arrays that are declared inside the
# selected region and used after. These must be declared on the outside as
# well.
package PPIx::EditorTools::ExtractMethod::VariableSorter;
use Moose;

use PPIx::EditorTools::ExtractMethod::Variable;
use PPIx::EditorTools::ExtractMethod::Analyzer::Result;
has 'input'   => ( is => 'rw', isa => 'HashRef' );

has 'return_statement_at_end'   => ( is => 'rw', isa => 'Bool', default => 0);

has 'analyzer_result'   => (
    is => 'rw',
    isa => 'PPIx::EditorTools::ExtractMethod::Analyzer::Result' 
);

has 'return_bucket' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[PPIx::EditorTools::ExtractMethod::Variable]',
    default => sub { [] },
    handles => {
        add_to_return_bucket  => 'push',
    },
);

has 'pass_bucket' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[PPIx::EditorTools::ExtractMethod::Variable]',
    default => sub { [] },
    handles => {
        add_to_pass_bucket  => 'push',
    },
);

has 'return_and_declare_bucket' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[PPIx::EditorTools::ExtractMethod::Variable]',
    default => sub { [] },
    handles => {
        add_to_return_and_declare_bucket  => 'push',
    },
);

has 'return_by_ref_bucket' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[PPIx::EditorTools::ExtractMethod::Variable]',
    default => sub { [] },
    handles => {
        add_to_return_by_ref_bucket  => 'push',
    },
);

has 'pass_by_ref_bucket' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[PPIx::EditorTools::ExtractMethod::Variable]',
    default => sub { [] },
    handles => {
        add_to_pass_by_ref_bucket  => 'push',
    },
);

sub to_pass {
    my ($self, $var) = @_;
    if ($var->type eq '$') {
        $self->add_to_pass_bucket($var);
    }
    else {
        $self->add_to_pass_by_ref_bucket($var);
    }
}

sub to_return {
    my ($self, $var) = @_;
    if ($var->type eq '$') {
        $self->add_to_return_bucket($var);
    }
    else {
        $self->add_to_return_by_ref_bucket($var);
    }
}

sub process_input {
    my $self = shift;
    $self->return_statement_at_end($self->analyzer_result->return_statement_at_end);
    foreach my $var (values %{$self->analyzer_result->variables}) {
        next if ($var->name eq 'self');
        next if ($var->is_special_variable);
        if (!$var->declared_in_selection && !$var->used_after)
        {
            $self->to_pass($var);
            $self->to_return($var) if $var->type ne '$';
        }
        if ($var->declared_in_selection && $var->used_after)
        {
            $self->to_return($var);
            $self->add_to_return_and_declare_bucket($var);
        }
        if (!$var->declared_in_selection && $var->used_after)
        {
            $self->to_pass($var);
            $self->to_return($var) unless ($var->type eq '$' && !$var->is_changed_in_selection);
        }
    }
}
1;

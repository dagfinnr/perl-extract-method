package PPIx::EditorTools::ExtractMethod::VariableSorter;
use PPIx::EditorTools::ExtractMethod::Variable;
use Moose;

has 'input'   => ( is => 'rw', isa => 'HashRef' );

has 'return_bucket' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[PPIx::EditorTools::ExtractMethod::Variable]',
    default => sub { [] },
    handles => {
        add_to_return_bucket  => 'push',
    },
);

has 'pass_and_return_bucket' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[PPIx::EditorTools::ExtractMethod::Variable]',
    default => sub { [] },
    handles => {
        add_to_pass_and_return_bucket  => 'push',
    },
);

sub process_input {
    my $self = shift;
    foreach my $var (values %{$self->input}) {
        if ($var->declared_in_scope eq 'inserted' && $var->used_in_scopes->has('outside'))
        {
            $self->add_to_return_bucket($var);
        }
        if ($var->declared_in_scope eq 'document' && $var->used_in_scopes->has('inserted'))
        {
            $self->add_to_pass_and_return_bucket($var);
        }
        if ($var->declared_in_scope eq 'outside' && $var->used_in_scopes->has('inserted'))
        {
            $self->add_to_pass_and_return_bucket($var);
        }
        if (!$var->declared_in_scope && $var->used_in_scopes->has('inserted'))
        {
            $self->add_to_pass_and_return_bucket($var);
        }
    }
}
1;

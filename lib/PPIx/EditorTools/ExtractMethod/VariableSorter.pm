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

has 'pass_bucket' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[PPIx::EditorTools::ExtractMethod::Variable]',
    default => sub { [] },
    handles => {
        add_to_pass_bucket  => 'push',
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
    foreach my $var (values %{$self->input}) {
        next if ($var->name eq 'self');
        if (!$var->declared_in_selection && !$var->used_after)
        {
            $self->to_pass($var);
        }
        if ($var->declared_in_selection && $var->used_after)
        {
            $self->to_return($var);
        }
        if (!$var->declared_in_selection && $var->used_after)
        {
            $self->to_pass($var);
            $self->to_return($var);
        }
    }
}
1;

package PPIx::EditorTools::ExtractMethod::Analyzer::Result;
use Moose;

has 'variables'   => ( is => 'ro', isa => 'HashRef', default => sub { {} });
has 'return_statement_at_end'   => ( is => 'ro', isa => 'Bool', default => 0 );

1;


package PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion;
use Moose;
use PPI::Document;
use PPIx::EditorTools;
use PPIx::EditorTools::ExtractMethod::LineRange;
use aliased 'PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter';
use aliased 'PPIx::EditorTools::ExtractMethod::Variable';
use aliased 'PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory' => 'VariableOccurrenceFactory';

has 'ppi'   => ( is => 'ro', isa => 'Object' );

has 'selected_range' => (
    is => 'rw',
    isa => 'PPIx::EditorTools::ExtractMethod::LineRange',
    coerce => 1,
    default => sub { 
        PPIx::EditorTools::ExtractMethod::LineRange->all;
    },
    handles => [ qw / start end / ],
);

has 'scope' => ( is => 'ro', isa => 'Maybe[PPI::Element]' );

sub find_variable_at_location {
    my ($self, $location) = @_;
    my $token = PPIx::EditorTools::find_token_at_location($self->ppi, $location);
    my $occurrence = VariableOccurrenceFactory->occurrence_from_symbol($token);
    return Variable->from_occurrence($occurrence);

}

sub find_variable_occurrences {
    my $self = shift ;
    my @result = ();
    @result = (@result, $self->find_unquoted_variable_occurrences);
    @result = (@result, $self->find_quoted_variable_occurrences);
    return @result;
}

sub find_quoted_variable_occurrences {
    my $self = shift ;
    my $tokens = $self->find_quote_tokens;
    my $result = [];
    foreach my $token (@$tokens) {
        my @docs = Unquoter->to_ppi($token);
        foreach my $doc (@docs) {
            my $region = __PACKAGE__->new(ppi => $doc);
            @$result = (@$result, $region->find_unquoted_variable_occurrences);
        }
    }
    return @$result;
}

sub find_unquoted_variable_occurrences {
    my $self = shift ;
    my $symbols = $self->find_symbols();
    my $factory = VariableOccurrenceFactory->new;
    return map { $factory->occurrence_from_symbol($_) } @$symbols;
}


sub find_quote_tokens {
    my $self = shift ;
    my $finder = sub { 
        my @excluded_classes = qw(
            PPI::Token::Quote::Single
            PPI::Token::Quote::Literal
        );
        foreach my $ppi_class (@excluded_classes) {
            return 0 if $_[1]->isa($ppi_class);
        }
        my @included_classes = qw(
            PPI::Token::Quote
            PPI::Token::QuoteLike
            PPI::Token::Regexp
        );
        foreach my $ppi_class (@included_classes) {
            return 1 if $_[1]->isa($ppi_class);
        }
        return 0;
    };
    return $self->find($finder); 
}

sub has_variable {
    my ($self, $var_id) = @_;
    my @occurrences = $self->find_variable_occurrences;
    my %set = map { $_ => 1 } map { $_->variable_id } @occurrences;
    return $set{$var_id};
}

sub find_symbols {
    my ($self) = @_;
    my $finder = sub {
        return $_[1]->isa('PPI::Token::Symbol')
    };
    return $self->find($finder);
}
sub find {
    my ($self, $finder) = @_;
    die "CodeRegion->find() accepts only callbacks" if !(ref $finder eq 'CODE');
    my $find_in_range = sub { 
        return 0 if !$self->selected_range->contains_line($_[1]->location->[0]);
        &$finder;
    };
    if ($self->scope) {
        return $self->scope->find($find_in_range) || [];
    }
    return $self->ppi->find($find_in_range) || [];
}


1;

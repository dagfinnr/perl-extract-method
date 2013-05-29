package PPIx::EditorTools::ExtractMethod::Analyzer::CodeRegion;
use Moose;
use PPI::Document;
use PPIx::EditorTools::ExtractMethod::LineRange;
use PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter;
use PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory;

has 'ppi'   => ( is => 'ro', isa => 'Object' );

has 'selected_range' => (
    is => 'rw',
    isa => 'PPIx::EditorTools::ExtractMethod::LineRange',
    coerce => 1,
    default => sub { 
        PPIx::EditorTools::ExtractMethod::LineRange->all;
    }
);

has 'scope' => ( is => 'ro', isa => 'PPI::Element' );

sub find_symbols {
    my $self = shift ;
    my $result = [];
    @$result = (@$result, @{$self->find_unquoted_symbols});
    return $result;
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
        my @docs = PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter->to_ppi($token);
        foreach my $doc (@docs) {
            my $region = __PACKAGE__->new(ppi => $doc);
            @$result = (@$result, $region->find_unquoted_variable_occurrences);
        }
    }
    return @$result;
}

sub find_unquoted_variable_occurrences {
    my $self = shift ;
    my $finder = sub {
        return $_[1]->isa('PPI::Token::Symbol')
        && $self->selected_range->contains_line($_[1]->location->[0]);
    };
    my $symbols = $self->find($finder);
    my $factory = PPIx::EditorTools::ExtractMethod::VariableOccurrence::Factory->new;
    return map { $factory->occurrence_from_symbol($_) } @$symbols;
}

sub find_unquoted_symbols {
    my $self = shift ;
    my $finder = sub {
        return $_[1]->isa('PPI::Token::Symbol')
        && $self->selected_range->contains_line($_[1]->location->[0]);
    };
    return $self->find($finder);
}

sub find_quote_tokens {
    my $self = shift ;
    my $finder = sub { 
        return 0 if !$self->selected_range->contains_line($_[1]->location->[0]);
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

sub find {
    my ($self, $finder) = @_;
    return $self->scope->find($finder) || [] if $self->scope;
    return $self->ppi->find($finder) || [];
}


1;

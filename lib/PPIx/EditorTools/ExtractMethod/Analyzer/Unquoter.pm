package PPIx::EditorTools::ExtractMethod::Analyzer::Unquoter;
use Moose;
use PPI::Document;
use PPIx::EditorTools::ExtractMethod::LineRange;

sub to_ppi {
    my ($class, $token) = @_;
    my @simple_classes = qw(
        PPI::Token::Quote::Double
        PPI::Token::QuoteLike::Backtick
    );
    my @excluded_classes = qw(
        PPI::Token::Quote::Single
        PPI::Token::Quote::Literal
    );
    foreach my $ppi_class (@excluded_classes) {
        return () if $token->isa($ppi_class);
    }
    foreach my $ppi_class (@simple_classes) {
        return $class->from_simple_quoted($token) if $token->isa($ppi_class);
    }
    # All other classes in PPI::Token::QuoteLike and PPI::Token::Regexp:
    return $class->from_complex_quoted($token);
}

sub from_simple_quoted {
    my ($class, $token) = @_;
    my $code = $token->content;
    my $q = $token->{separator};
    $code =~ s/^$q(.*)$q$/$1/s;
    return (PPI::Document->new(\$code));
}

sub from_complex_quoted {
    my ($class, $token) = @_;
    my $code = $token->content;
    my @docs;
    foreach my $section (@{$token->{sections}}) {
        my $string = substr(
            $code,
            $section->{position},
            $section->{size}
        );
        push @docs, PPI::Document->new(\$string);
    }
    return @docs;
}
1;

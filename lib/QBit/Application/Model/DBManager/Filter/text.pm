package QBit::Application::Model::DBManager::Filter::text;

use qbit;

use base qw(QBit::Application::Model::DBManager::Filter);

sub need_tokens {return [qw(STRING NOT LIKE IN)]}

sub nonterminals {
    return {
        strings     => "STRING { [\$_[1]] }\n        |   STRING ',' strings { [\$_[1], \@{\$_[3]}] }\n        ;",
        string_list => "'[' strings ']' { \$_[2] }\n        ;"
    };
}

sub expressions {
    my ($self, $field_name) = @_;

    my $uc_field_name = uc($field_name);

    return [
        "$uc_field_name '='      STRING      { [$field_name => '='        => \$_[3]] }",
        "$uc_field_name '<>'     STRING      { [$field_name => '<>'       => \$_[3]] }",
        "$uc_field_name LIKE     STRING      { [$field_name => 'LIKE'     => \$_[3]] }",
        "$uc_field_name NOT LIKE STRING      { [$field_name => 'NOT LIKE' => \$_[4]] }",
        "$uc_field_name '='      string_list { [$field_name => '='        => \$_[3]] }",
        "$uc_field_name '<>'     string_list { [$field_name => '<>'       => \$_[3]] }",
        "$uc_field_name IN       string_list { [$field_name => 'IN'       => \$_[3]] }",
        "$uc_field_name NOT IN   string_list { [$field_name => 'NOT IN'   => \$_[4]] }",
    ];
}

sub check {
    throw gettext('Bad data') unless !ref($_[1]->[2]) || ref($_[1]->[2]) eq 'ARRAY';
    throw gettext('Bad operation "%s"', $_[1]->[1])
      unless in_array($_[1]->[1], [qw(= <> LIKE IN), 'NOT LIKE', 'NOT IN']);
}

sub as_text {
    my $string;
    if (ref($_[1]->[2]) eq 'ARRAY') {
        $string = '[' . join(', ', map {s/'/\\'/g; "'$_'"} @{$_[1]->[2]}) . ']';
    } else {
        $string = $_[1]->[2];
        $string =~ s/'/\\'/g;
        $string = "'$string'";
    }
    "$_[1]->[0] $_[1]->[1] $string";
}

sub as_filter {
    [
        defined($_[2]->{'db_expr'})
        ? $_[2]->{'db_expr'}
        : $_[1]->[0] => $_[1]->[1] => \($_[1]->[1] =~ /LIKE/ ? __like_str($_[1]->[2]) : $_[1]->[2])
    ];
}

sub __like_str {
    my ($text) = @_;

    $text =~ s/%/\\%/g;
    $text =~ s/_/\\_/g;

    $text =~ s/\*/%/g;
    $text =~ s/\?/_/g;

    return "%$text%";
}

TRUE;

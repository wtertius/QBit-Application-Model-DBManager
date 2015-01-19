package QBit::Application::Model::DBManager::_Utils::Fields;

use qbit;

use base qw(QBit::Class);

__PACKAGE__->mk_ro_accessors('model');

sub new {
    my ($class, $opt, $fields, $model) = @_;

    _init_field_deps($fields, $_) foreach keys(%$fields);
    my $weighted = {};
    $weighted->{$_} = _init_field_sort($weighted, $fields, $_, 0) foreach keys(%$fields);

    my %res_fields;
    $opt = [grep {$fields->{$_}{'default'}} keys(%$fields)] unless defined($opt);
    $opt = [$opt] if ref($opt) ne 'ARRAY';

    foreach (values(%$fields)) {
        $_->{'check_rights'} = [$_->{'check_rights'}]
          if defined($_->{'check_rights'}) && ref($_->{'check_rights'}) ne 'ARRAY';
    }

    foreach my $field (@$opt) {
        next unless exists($fields->{$field});
        next if $fields->{$field}{'check_rights'} && !$model->check_rights(@{$fields->{$field}{'check_rights'}});
        # Skipping field unless it's all depends are available
        next
          if $fields->{$field}{'depends_on'}
              && @{$fields->{$field}{'depends_on'}} !=
              grep {!$fields->{$_}{'check_rights'} || $model->check_rights(@{$fields->{$_}{'check_rights'}})}
              @{$fields->{$field}{'depends_on'}};

        $res_fields{$field} = clone($fields->{$field});
    }

    foreach my $field (keys(%res_fields)) {
        if (exists($fields->{$field}{'depends_on'}) || exists($fields->{$field}{'forced_depends_on'})) {
            foreach
              my $dep_field (@{$fields->{$field}{'depends_on'} || []}, @{$fields->{$field}{'forced_depends_on'} || []})
            {
                unless (exists($res_fields{$dep_field})) {
                    $res_fields{$dep_field} = clone($fields->{$dep_field});
                    $res_fields{$dep_field}->{'need_delete'} = TRUE;
                }
            }
        }
    }

    my $fields_sorted = [sort {($weighted->{$a} || 0) <=> ($weighted->{$b} || 0) || $a cmp $b} keys(%res_fields)];

    return $class->SUPER::new(__FIELDS__ => \%res_fields, __FIELD_NAMES__ => $fields_sorted, model => $model);
}

sub get_fields {
    my ($self) = @_;

    return clone(\%{$self->{'__FIELDS__'}});
}

sub get_db_fields {
    my ($self, $table, %opts) = @_;

    my %res    = ();
    my $fields = $self->get_fields();

    foreach my $field_name (
        grep {
                 (!defined($table) && $fields->{$_}{'db'})
              || (defined($table) && ($fields->{$_}{'db'} || '') eq ($table || ''))
        } keys(%$fields)
      )
    {
        $res{$field_name} = defined($fields->{$field_name}{'db_expr'}) ? $fields->{$field_name}{'db_expr'} : '';
    }

    return \%res;
}

sub process_data {
    my ($self, $data) = @_;

    my @fields = @{$self->{'__FIELD_NAMES__'}};

    my @res;
    foreach my $rec (@$data) {
        my %new_rec;
        foreach my $field (@fields) {
            my $val;
            if (exists($rec->{$field})) {
                $val = $rec->{$field};
            } elsif (exists($self->{'__FIELDS__'}{$field}{'get'})) {
                $val = $rec->{$field} = $self->{'__FIELDS__'}{$field}{'get'}($self, $rec);
            } elsif ($self->{'__FIELDS__'}{$field}{'i18n'}) {
                $val = {map {$_ => $rec->{"${field}_${_}"}} keys(%{$self->model->get_option('locales', {})})};
            } else {
                throw gettext('Cannot get field "%s"', $field);
            }
            # store and skip implicit fields
            $new_rec{$field} = $val unless ($self->{'__FIELDS__'}{$field}{'need_delete'});
        }
        push(@res, \%new_rec);
    }
    return \@res;
}

sub need {
    my ($self, $name) = @_;

    return exists($self->{'__FIELDS__'}{$name});
}

sub _init_field_deps {
    my ($fields, $name) = @_;

    throw gettext('Field "%s" does not exists', $name) unless exists($fields->{$name});

    my %deps;
    foreach (qw(depends_on forced_depends_on)) {
        $deps{$_} = $fields->{$name}{$_} || [];
        $deps{$_} = [$deps{$_}] if ref($deps{$_}) ne 'ARRAY';
    }

    if (map {@$_} values(%deps)) {
        foreach my $dep (map {_init_field_deps($fields, $_)} @{$deps{'depends_on'}}) {
            push(@{$deps{$_}}, @{$dep->{$_}}) foreach qw(depends_on forced_depends_on);
        }
        foreach my $dep (map {_init_field_deps($fields, $_)} @{$deps{'forced_depends_on'}}) {
            push(@{$deps{'forced_depends_on'}}, @{$dep->{$_}}) foreach qw(depends_on forced_depends_on);
        }

        foreach (qw(depends_on forced_depends_on)) {
            $fields->{$name}{$_} = array_uniq($deps{$_}) if $deps{$_};
        }
    }

    return \%deps;
}

sub _init_field_sort {
    my ($weighted, $fields, $name, $level) = @_;

    return $weighted->{$name} + $level if exists($weighted->{$name});

    my @foreign_fields = (@{$fields->{$name}{'depends_on'} || []}, @{$fields->{$name}{'forced_depends_on'} || []});

    return @foreign_fields
      ? array_max(map {_init_field_sort($weighted, $fields, $_, $level + 1)} @foreign_fields)
      : $level;
}

TRUE;

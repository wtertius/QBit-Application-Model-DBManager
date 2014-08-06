package TestAppDBManager::Model::User;

use qbit;

use base qw(QBit::Application::Model::DBManager);

__PACKAGE__->model_accessors(db => 'TestAppDBManager::Model::DB',);

__PACKAGE__->model_fields(
    id       => {db => 1, default => 1, pk => 1},
    name     => {db => 1},
    lastname => {db => 1},
    habitat  => {db => 1},
    fullname => {
        default    => 1,
        depends_on => [qw(name lastname)],
        get        => sub {"$_[1]->{'name'} $_[1]->{'lastname'}"},
    },
    hidden_field => {
        check_rights => 'view_hidden_field',
        get          => sub {10}
    },
    forced_depends_on_field => {
        forced_depends_on => [qw(hidden_field)],
        get               => sub {
            $_[1]->{'hidden_field'} ^ 1234567;
          }
    }
);

__PACKAGE__->model_filter(
    db_accessor => 'db',
    fields      => {
        id       => {type => 'number', label => d_gettext('ID')},
        name     => {type => 'text',   label => d_gettext('Name')},
        lastname => {type => 'text',   label => d_gettext('Lastname')},
    }
);

sub query {
    my ($self, %opts) = @_;

    return $self->db->query->select(
        table  => $self->db->user,
        fields => $opts{'fields'}->get_db_fields(),
        filter => $opts{'filter'}
    );
}

1;

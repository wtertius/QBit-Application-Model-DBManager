package TestAppDBManager::Model::Bookshelf;

use qbit;

use base qw(QBit::Application::Model::DBManager);

__PACKAGE__->model_accessors(
    db   => 'TestAppDBManager::Model::DB',
    user => 'TestAppDBManager::Model::User',
    book => 'TestAppDBManager::Model::Book',
);

__PACKAGE__->model_fields(
    id          => {db => 1, pk      => 1, default => 1},
    title       => {db => 1, default => 1},
    description => {db => 1},
    owner_id    => {db => 1},
    owner       => {
        depends_on => ['owner_id'],
        get        => sub {$_[0]->{'owners'}{$_[1]->{'owner_id'}}->{'fullname'}},
    }
);

__PACKAGE__->model_filter(
    db_accessor => 'db',
    fields      => {
        id    => {type => 'number',  label => d_gettext('ID')},
        title => {type => 'text',    label => d_gettext('Title')},
        vault => {type => 'boolean', label => d_gettext('Vault')},
        book  => {
            type           => 'subfilter',
            label          => d_gettext('Book'),
            model_accessor => 'book',
            field          => 'id',
            fk_field       => 'bookshelf_id'
        },
        owner => {type => 'subfilter', label => d_gettext('Owner'), model_accessor => 'user', field => 'owner_id'}
    },
);

sub query {
    my ($self, %opts) = @_;

    return $self->db->query->select(
        table  => $self->db->bookshelf,
        fields => $opts{'fields'}->get_db_fields(),
        filter => $opts{'filter'}
    );
}

sub pre_process_fields {
    my ($self, $fields, $data) = @_;

    $fields->{'owners'} =
      {map {$_->{'id'} => $_} @{$self->user->get_all(filter => {id => [map {$_->{'owner_id'}} @$data]})}}
      if $fields->need('owner');
}

1;

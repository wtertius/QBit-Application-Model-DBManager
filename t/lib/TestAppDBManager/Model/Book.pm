package TestAppDBManager::Model::Book;

use qbit;

use base qw(QBit::Application::Model::Multistate QBit::Application::Model::DBManager);

__PACKAGE__->model_accessors(db => 'TestAppDBManager::Model::DB', bookshelf => 'TestAppDBManager::Model::Bookshelf');

__PACKAGE__->multistates_graph(
    multistates =>
      [[available => 'Can get'], [hired => 'Hired'], [expired => 'Expired'], [dirty => 'Dirty', private => 1]],

    actions => {
        accept  => 'Accept',
        get     => 'Get',
        return  => 'Return',
        expired => 'Expired',
        dirty   => 'Dirty'
    },

    multistate_actions => [
        {
            action    => 'accept',
            from      => '__EMPTY__',
            set_flags => ['available'],
        },
        {
            action      => 'get',
            from        => 'available',
            set_flags   => ['hired'],
            reset_flags => ['available'],
        },
        {
            action      => 'return',
            from        => 'hired',
            set_flags   => ['available'],
            reset_flags => ['hired', 'expired'],
        },
        {
            action    => 'expired',
            from      => 'hired',
            set_flags => ['expired'],
        },
        {
            action    => 'dirty',
            from      => 'available',
            set_flags => ['dirty'],
        },
    ]
);

__PACKAGE__->model_fields(
    id           => {db => 1, pk => 1, default => 1},
    title        => {db => 1},
    bookshelf_id => {db => 1},
);

__PACKAGE__->model_filter(
    db_accessor => 'db',
    fields      => {
        id         => {type => 'number',     label => d_gettext('ID')},
        title      => {type => 'text',       label => d_gettext('Title')},
        multistate => {type => 'multistate', label => d_gettext('Status')},
        genre      => {
            type   => 'dictionary',
            label  => d_gettext('Genre'),
            values => sub {shift->get_genres()}
        },
        bookshelf => {
            type           => 'subfilter',
            label          => d_gettext('Bookshelf'),
            model_accessor => 'bookshelf',
            field          => 'bookshelf_id'
        }
    }
);

sub query {
    my ($self, %opts) = @_;

    return $self->db->query->select(
        table  => $self->db->book,
        fields => $opts{'fields'}->get_db_fields(),
        filter => $opts{'filter'}
    );
}

sub get_genres {
    my ($self) = @_;

    return [
        {id => 0, key => 'novel',   label => gettext('Novel')},
        {id => 1, key => 'fantasy', label => gettext('Fantasy')},
        {id => 2, key => 'comics',  label => gettext('Comics')},
        {id => 3, key => 'tale',    label => gettext('Tale')},
    ];
}

1;

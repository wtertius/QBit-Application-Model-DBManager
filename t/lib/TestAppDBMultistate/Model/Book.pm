package TestAppDBMultistate::Model::Book;

use qbit;

use base qw(QBit::Application::Model::Multistate::DB QBit::Application::Model::DBManager);

__PACKAGE__->model_accessors(db => 'TestAppDBMultistate::Model::MultistateDB');

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
    id    => {db => 1, pk => 1, default => 1},
    title => {db => 1},
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
    }
);

sub _multistate_db_table {$_[0]->db->book}
sub _action_log_db_table {$_[0]->db->book_action_log}

1;

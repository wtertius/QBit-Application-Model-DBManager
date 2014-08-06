package TestAppDBMultistate::Model::MultistateDB;

use qbit;

use base qw(QBit::Application::Model::DB::mysql);

__PACKAGE__->meta(
    tables => {
        users => {
            fields => [
                {name => 'id',       type => 'INT',     not_null => 1, autoincrement => 1},
                {name => 'name',     type => 'VARCHAR', length   => 100},
                {name => 'lastname', type => 'VARCHAR', length   => 100},
            ],
            primary_key => ['id']
        },
        book => {
            fields => [
                {name => 'id',     type => 'INT',     not_null => 1, autoincrement => 1},
                {name => 'title',  type => 'VARCHAR', length   => 100},
                {name => 'author', type => 'VARCHAR', length   => 100},
                {name => 'multistate', type => 'BIGINT', unsigned => 1, not_null => 1, default => 0},
            ],
            primary_key => ['id'],
        },

        book_action_log => {
            type          => 'MultistateActionLog',
            elem_table    => 'book',
            elem_table_pk => ['id'],
        }
    }
);

1;

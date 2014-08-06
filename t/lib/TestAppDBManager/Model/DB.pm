package TestAppDBManager::Model::DB;

use qbit;

use base qw(QBit::Application::Model::DB::mysql);

__PACKAGE__->meta(
    tables => {
        user => {
            fields => [
                {name => 'id',       type => 'INT',     not_null => 1, autoincrement => 1},
                {name => 'name',     type => 'VARCHAR', length   => 100},
                {name => 'lastname', type => 'VARCHAR', length   => 100},
                {name => 'habitat',  type => 'VARCHAR', length   => 100},
            ],
            primary_key => ['id']
        },

        bookshelf => {
            fields => [
                {name => 'id',          type => 'INT',     not_null => 1, autoincrement => 1},
                {name => 'title',       type => 'VARCHAR', length   => 100},
                {name => 'description', type => 'VARCHAR', length   => 255},
                {name => 'owner_id'},
            ],
            primary_key  => ['id'],
            foreign_keys => [[['owner_id'] => user => ['id']]]
        },

        book => {
            fields => [
                {name => 'id',     type => 'INT',     not_null => 1, autoincrement => 1},
                {name => 'title',  type => 'VARCHAR', length   => 100},
                {name => 'author', type => 'VARCHAR', length   => 100},
                {name => 'bookshelf_id'},
            ],
            primary_key  => ['id'],
            foreign_keys => [[['bookshelf_id'] => bookshelf => ['id']]]
        }
    }
);

1;

package TestDBMysql::Model::DB;

use qbit;

use base qw(QBit::Application::Model::DB::mysql);

__PACKAGE__->meta(
    tables => {
        table1 => {
            fields => [
                {
                    name          => 'field1',
                    type          => 'INT',
                    unsigned      => 1,
                    autoincrement => 1,
                    not_null      => 1,
                    length        => 10,
                    zerofill      => 1
                },
                {name => 'field2', type => 'INT'},
                {
                    name     => 'field3',
                    type     => 'FLOAT',
                    unsigned => 1,
                    not_null => 1,
                    length   => 10,
                    decimals => 5,
                    zerofill => 1
                },
                {name => 'field4', type => 'FLOAT'},
                {name => 'field5', type => 'BINARY', length => 10, not_null => 1},
                {name => 'field6', type => 'BINARY'},
                {
                    name      => 'field7',
                    type      => 'VARCHAR',
                    length    => 200,
                    charset   => 'utf8',
                    collation => 'utf8_general_ci',
                    not_null  => 1
                },
                {name => 'field8', type => 'VARCHAR'},
                {
                    name      => 'field9',
                    type      => 'TEXT',
                    charset   => 'utf8',
                    collation => 'utf8_general_ci',
                    not_null  => 1
                },
                {name => 'field10', type => 'TEXT'},
            ],
            primary_key => ['field1'],
            indexes     => [{fields => ['field2']}]
        },

        table2 => {
            fields => [
                {name => 'field1', type => 'INT',      unsigned => 1, autoincrement => 1, not_null => 1},
                {name => 'field2', type => 'DATETIME', not_null => 1},
                {name => 't1_f2'},
                {name => 'ml_field', type => 'VARCHAR', length => 100, i18n => 1}
            ],
            primary_key  => [qw(field1 field2)],
            foreign_keys => [[['t1_f2'] => table1 => ['field2']]]
        },

        qtable1 => {
            fields => [
                {name => 'id',       type => 'INT'},
                {name => 'field',    type => 'CHAR'},
                {name => 'value',    type => 'INT'},
                {name => 'ml_field', type => 'VARCHAR', length => 100, i18n => 1}
            ],
            primary_key => [qw(id)],
        },

        qtable2 => {
            fields       => [{name          => 'parent_id'}, {name => 'field', type => 'CHAR'}],
            foreign_keys => [[['parent_id'] => qtable1       => ['id']]]
        }
    }
);

1;

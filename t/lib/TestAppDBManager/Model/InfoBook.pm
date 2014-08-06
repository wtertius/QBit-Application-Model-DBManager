package TestAppDBManager::Model::InfoBook;

use qbit;

use base qw(QBit::Application::Model::DBManager);

__PACKAGE__->model_accessors(
    db   => 'TestAppDBManager::Model::DB',
    book => 'TestAppDBManager::Model::Book',
);

__PACKAGE__->model_filter(
    db_accessor => 'db',
    fields      => {
        book_id => {
            type    => 'number',
            label   => d_gettext('ID book'),
            db_expr => {id => 'book'}
        },
        book_title => {
            type    => 'text',
            label   => d_gettext('Title book'),
            db_expr => {title => 'book'}
        },
        book_rarity => {
            type    => 'boolean',
            label   => d_gettext('Rarity book'),
            db_expr => {is_rarity => 'book'}
        },
        book_genre => {
            db_expr => {genre => 'book'},
            type    => 'dictionary',
            label   => d_gettext('Genre'),
            values  => sub    {shift->book->get_genres()}
        },
    },
);

1;

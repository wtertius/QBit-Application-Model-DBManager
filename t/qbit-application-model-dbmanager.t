#!/usr/bin/perl

use qbit;
use FindBin qw($Bin);
use lib "t/lib";
use lib "$Bin/../lib";
use Test::More tests => 109;

use TestAppDBManager;

my $app = TestAppDBManager->new();

$app->pre_run();

$app->set_option('db' => {user => 'root'});

my $db_name = "qbit_test_$$";

$app->db->_connect();
$app->db->_do("CREATE DATABASE $db_name");
$app->db->_do("USE $db_name");

$app->db->init_db();

$app->db->user->add_multi(
    [
        {name => 'Vasiliy', lastname => 'Pupkin',  habitat => 'Real life'},
        {name => 'Ivan',    lastname => 'Petrov',  habitat => 'Real life'},
        {name => 'Jhon',    lastname => 'Dorian',  habitat => 'Series'},
        {name => 'Homer',   lastname => 'Simpson', habitat => 'Animation'},
    ]
);

$app->db->bookshelf->add_multi(
    [
        {title => 'Technical', description => 'Bookshelf with technical literature', owner_id => 2},
        {title => 'Medical',   description => 'Bookshelf with medical literature',   owner_id => 3},
    ]
);

$app->db->book->add_multi(
    [
        {title => 'Windows 7 for Dummies',           author => 'Andy Rathbone',  bookshelf_id => 1},
        {title => 'Electronic Amplifier Circuits',   author => 'Joseph Petit',   bookshelf_id => 1},
        {title => 'The Art of Computer Programming', author => 'Donald Knuth',   bookshelf_id => 1},
        {title => 'Surreal Numbers',                 author => 'Donald Knuth',   bookshelf_id => 1},
        {title => 'Anesthesia Secrets',              author => 'James Duke',     bookshelf_id => 2},
        {title => ' Drugs for the Heart',            author => 'Lionel H. Opie', bookshelf_id => 2},
        {title => 'Biomedical instrumentation',      author => 'Ilyasov L.V.',   bookshelf_id => 1},
        {title => 'Biomedical instrumentation',      author => 'Ilyasov L.V.',   bookshelf_id => 2},
    ]
);

END {
    $app->db->_do("DROP DATABASE $db_name");
    $app->post_run();
}

#======== get_pk_fields ========
is_deeply($app->book->get_pk_fields(), ['id'], 'Check get_pk_fields');

#======== get_db_filter_fields ========
is_deeply(
    $app->bookshelf()->get_db_filter_fields(),
    {
        owner => {
            subfields => {
                name     => {type => 'text',   label => 'Name'},
                lastname => {type => 'text',   label => 'Lastname'},
                id       => {type => 'number', label => 'ID'}
            },
            label => 'Owner',
            type  => 'subfilter'
        },
        vault => {type => 'boolean', label => 'Vault'},
        book  => {
            subfields => {
                title      => {type => 'text',   label => 'Title'},
                id         => {type => 'number', label => 'ID'},
                multistate => {
                    values => {
                        hired     => 'Hired',
                        expired   => 'Expired',
                        available => 'Can get'
                    },
                    label => 'Status',
                    type  => 'multistate'
                },
                genre => {type => 'dictionary', label => 'Genre', values => $app->book->get_genres()},
            },
            label => 'Book',
            type  => 'subfilter'
        },
        title => {type => 'text',   label => 'Title'},
        id    => {type => 'number', label => 'ID'},
    },
    'Check get_db_filter_fields'
);

is_deeply(
    $app->bookshelf()->get_db_filter_simple_fields(),
    [{name => 'vault', label => 'Vault'}, {name => 'title', label => 'Title'}, {name => 'id', label => 'ID'}],
    'Check get_db_filter_fields'
);

#======== Filters ========
# NUMBER
foreach my $op (qw(= <> > < >= <=)) {
    is_deeply(
        $app->bookshelf->get_db_filter("id $op 100"),
        $app->db->filter([id => $op => \100]),
        "Check text filter: number $op"
    );
    is_deeply($app->bookshelf->get_db_filter("id $op 100", type => 'text'),
        "id $op 100", "Check text filter: number $op (as text)");
    is_deeply(
        $app->info_book->get_db_filter("book_id $op 100"),
        $app->db->filter([{id => 'book'} => $op => \100]),
        "Check text filter(field from join table): number $op"
    );
}

foreach my $op (qw(= <> IN), 'NOT IN') {
    is_deeply(
        $app->bookshelf->get_db_filter("id $op [1, 2, 3]"),
        $app->db->filter([id => $op => \[1, 2, 3]]),
        "Check text filter: number $op array"
    );
    is_deeply(
        $app->bookshelf->get_db_filter("id $op [1, 2, 3]", type => 'text'),
        "id $op [1, 2, 3]",
        "Check text filter: number $op array (as text)"
    );
    is_deeply(
        $app->info_book->get_db_filter("book_id $op [1, 2, 3]"),
        $app->db->filter([{id => 'book'} => $op => \[1, 2, 3]]),
        "Check text filter(field from join table): number $op array"
    );
}

# TEXT
foreach my $op ('=', '<>') {
    is_deeply(
        $app->bookshelf->get_db_filter("title $op 'example'"),
        $app->db->filter([title => $op => \'example']),
        "Check text filter: text $op"
    );
    is_deeply(
        $app->bookshelf->get_db_filter("title $op 'example'", type => 'text'),
        "title $op 'example'",
        "Check text filter: text $op (as text)"
    );
    is_deeply(
        $app->info_book->get_db_filter("book_title $op 'example'"),
        $app->db->filter([{title => 'book'} => $op => \'example']),
        "Check text filter(field from join table): text $op"
    );
}

foreach my $op ('LIKE', 'NOT LIKE') {
    is_deeply(
        $app->bookshelf->get_db_filter("title $op 'e?xamp*le'"),
        $app->db->filter([title => $op => \'%e_xamp%le%']),
        "Check text filter: text $op"
    );
    is_deeply(
        $app->bookshelf->get_db_filter("title $op 'e?xamp*le'", type => 'text'),
        "title $op 'e?xamp*le'",
        "Check text filter: text $op (as text)"
    );
    is_deeply(
        $app->info_book->get_db_filter("book_title $op 'e?xamp*le'"),
        $app->db->filter([{title => 'book'} => $op => \'%e_xamp%le%']),
        "Check text filter(field from join table): text $op"
    );
}

foreach my $op ('IN', 'NOT IN', '=', '<>') {
    is_deeply(
        $app->bookshelf->get_db_filter("title $op ['example1', 'example2']"),
        $app->db->filter([title => $op => \['example1', 'example2']]),
        "Check text filter: text $op"
    );
    is_deeply(
        $app->bookshelf->get_db_filter("title $op ['example1', 'example2']", type => 'text'),
        "title $op ['example1', 'example2']",
        "Check text filter: text $op (as text)"
    );
    is_deeply(
        $app->info_book->get_db_filter("book_title $op ['example1', 'example2']"),
        $app->db->filter([{title => 'book'} => $op => \['example1', 'example2']]),
        "Check text filter(field from join table): text $op"
    );
}

# BOOLEAN
is_deeply($app->bookshelf->get_db_filter("vault"), $app->db->filter('vault'), 'Check text filter: boolean');

is_deeply(
    $app->bookshelf->get_db_filter("not vault"),
    $app->db->filter([AND => [{NOT => ['vault']}]]),
    'Check text filter: boolean NOT'
);

is_deeply($app->bookshelf->get_db_filter("vault", type => 'text'), 'vault', 'Check text filter: boolean (as text)');

is_deeply($app->bookshelf->get_db_filter("not vault", type => 'text'),
    'NOT vault', 'Check text filter: boolean NOT (as text)');

is_deeply(
    $app->info_book->get_db_filter("book_rarity"),
    $app->db->filter({is_rarity => 'book'}),
    'Check text filter(field from join table): boolean'
);

is_deeply(
    $app->info_book->get_db_filter("not book_rarity"),
    $app->db->filter([AND => [{NOT => [{is_rarity => 'book'}]}]]),
    'Check text filter(field from join table): boolean NOT'
);

# DICTIONARY
foreach my $op ('=', '<>') {
    is_deeply(
        $app->book->get_db_filter("genre $op novel"),
        $app->db->filter([genre => $op => \0]),
        "Check text filter: dictionary $op"
    );

    is_deeply(
        $app->book->get_db_filter("genre $op [novel, comics]"),
        $app->db->filter([genre => $op => \[0, 2]]),
        "Check text filter: dictionary $op array"
    );

    is_deeply(
        $app->book->get_db_filter("genre $op novel", type => 'text'),
        "genre $op novel",
        "Check text filter: dictionary $op (as text)"
    );

    is_deeply(
        $app->book->get_db_filter("genre $op [novel, comics]", type => 'text'),
        "genre $op [novel, comics]",
        "Check text filter: dictionary $op (as text)"
    );

    is_deeply(
        $app->info_book->get_db_filter("book_genre $op novel"),
        $app->db->filter([{genre => 'book'} => $op => \0]),
        "Check text filter(field from join table): dictionary $op"
    );

    is_deeply(
        $app->info_book->get_db_filter("book_genre $op [novel, comics]"),
        $app->db->filter([{genre => 'book'} => $op => \[0, 2]]),
        "Check text filter(field from join table): dictionary $op array"
    );
}

# MULTISTATE
foreach my $op ('=', '<>') {
    is_deeply(
        $app->book->get_db_filter("multistate $op expired"),
        $app->db->filter([multistate => $op => \$app->book->get_multistates_by_filter('expired')]),
        "Check text filter: multistate $op"
    );

    is_deeply(
        $app->book->get_db_filter("multistate $op expired", type => 'text'),
        "multistate $op expired",
        "Check text filter: multistate $op (as text)"
    );
}

# SUBFILTER
is_deeply(
    $app->book->get_db_filter("bookshelf match {owner not match {id > 100}}"),
    $app->db->filter(
        [
            bookshelf_id => '= ANY' => $app->db->query->select(
                table  => $app->db->bookshelf,
                fields => ['id'],
                filter => $app->db->filter(
                    [
                        owner_id => '<> ALL' => $app->db->query->select(
                            table  => $app->db->user,
                            fields => ['id'],
                            filter => $app->db->filter([id => '>' => \100])
                        )
                    ]
                )
            )
        ]
    ),
    'Check text filter: subfilter MATCH'
);

is_deeply(
    $app->book->get_db_filter("bookshelf match {owner not match {id > 100}}", type => 'text'),
    'bookshelf MATCH {owner NOT MATCH {id > 100}}',
    'Check text filter: subfilter MATCH (as text)'
);

# EXPRESSION
is_deeply(
    $app->book->get_db_filter("id = 1 or id > 200 and id < 300 or (id = 5)", type => 'text'),
    '(id = 1 OR (id > 200 AND id < 300) OR id = 5)',
    'Check text filter: expression (as text)'
);

is_deeply(
    $app->book->get_db_filter({id => 100, title => 'test'}, type => 'text'),
    '(title = \'test\' AND id = 100)',
    'Check hash filter: expression (as text)'
);

#======== get_all ========
is_deeply(
    $app->user->get_all(fields => [qw(id name forced_depends_on_field)], filter => {id => 2}),
    [
        {
            id                      => 2,
            name                    => 'Ivan',
            forced_depends_on_field => 1234573
        }
    ],
    'Check get_all'
);

is_deeply(
    [sort keys($app->user->{'__LAST_FIELDS__'})],
    [qw(forced_depends_on_field id name)],
    'Check __LAST_FIELDS__ with hidden field'
);

#======== get_all + order_by, limit, distinct ========#

is_deeply(
    $app->user->get_all(fields => [qw(habitat)], distinct => TRUE),
    [{'habitat' => 'Real life',}, {'habitat' => 'Series',}, {'habitat' => 'Animation',}],
    'Check get_all + distinct'
);

is_deeply(
    $app->user->get_all(fields => [qw(id name)], offset => 2, limit => 2),
    [
        {
            'name' => 'Jhon',
            'id'   => '3'
        },
        {
            'name' => 'Homer',
            'id'   => '4'
        }
    ],
    'Check get_all + limit'
);

is_deeply(
    $app->user->get_all(fields => [qw(id name)], order_by => ['name']),
    [
        {
            'name' => 'Homer',
            'id'   => '4'
        },
        {
            'name' => 'Ivan',
            'id'   => '2'
        },
        {
            'name' => 'Jhon',
            'id'   => '3'
        },
        {
            'name' => 'Vasiliy',
            'id'   => '1'
        }
    ],
    'Check get_all + order_by'
);

#======== get ========
is_deeply($app->book->get(5, fields => ['id']), {'id' => '5'}, 'Check get with scalar PK');

#======== Filters on the field from join table ========
# NUMBER
foreach my $op (qw(= <> > < >= <=)) {
    is_deeply(
        $app->info_book->get_db_filter("book_id $op 100"),
        $app->db->filter([{id => 'book'} => $op => \100]),
        "Check text filter(field from join table): number $op"
    );
}

foreach my $op (qw(= <> IN), 'NOT IN') {
    is_deeply(
        $app->info_book->get_db_filter("book_id $op [1, 2, 3]"),
        $app->db->filter([{id => 'book'} => $op => \[1, 2, 3]]),
        "Check text filter(field from join table): number $op array"
    );
}

# TEXT
foreach my $op ('=', '<>') {
    is_deeply(
        $app->info_book->get_db_filter("book_title $op 'example'"),
        $app->db->filter([{title => 'book'} => $op => \'example']),
        "Check text filter(field from join table): text $op"
    );
}

foreach my $op ('LIKE', 'NOT LIKE') {
    is_deeply(
        $app->info_book->get_db_filter("book_title $op 'e?xamp*le'"),
        $app->db->filter([{title => 'book'} => $op => \'%e_xamp%le%']),
        "Check text filter(field from join table): text $op"
    );
}

# BOOLEAN
is_deeply(
    $app->info_book->get_db_filter("book_rarity"),
    $app->db->filter({is_rarity => 'book'}),
    'Check text filter(field from join table): boolean'
);

is_deeply(
    $app->info_book->get_db_filter("not book_rarity"),
    $app->db->filter([AND => [{NOT => [{is_rarity => 'book'}]}]]),
    'Check text filter(field from join table): boolean NOT'
);

# DICTIONARY
foreach my $op ('=', '<>') {
    is_deeply(
        $app->info_book->get_db_filter("book_genre $op novel"),
        $app->db->filter([{genre => 'book'} => $op => \0]),
        "Check text filter(field from join table): dictionary $op"
    );

    is_deeply(
        $app->info_book->get_db_filter("book_genre $op [novel, comics]"),
        $app->db->filter([{genre => 'book'} => $op => \[0, 2]]),
        "Check text filter(field from join table): dictionary $op array"
    );
}

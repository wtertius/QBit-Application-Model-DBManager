package TestAppDBManager;

use qbit;

use base qw(QBit::Application);

use TestAppDBManager::Model::DB accessor => 'db';

use TestAppDBManager::Model::User accessor      => 'user';
use TestAppDBManager::Model::Bookshelf accessor => 'bookshelf';
use TestAppDBManager::Model::Book accessor      => 'book';
use TestAppDBManager::Model::InfoBook accessor  => 'info_book';

1;

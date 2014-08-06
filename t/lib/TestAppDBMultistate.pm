package TestAppDBMultistate;

use qbit;

use base qw(QBit::Application);

use TestAppDBMultistate::Model::MultistateDB accessor => 'db';

use TestAppDBMultistate::Model::Book accessor => 'book';

1;

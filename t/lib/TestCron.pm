package TestCron;

use qbit;

use base qw(QBit::Application QBit::Cron);

use TestCron::Methods1 path => 'm1';

1;

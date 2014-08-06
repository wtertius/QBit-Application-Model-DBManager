package TestCron::Methods1;

use qbit;

use base qw(QBit::Cron::Methods);

sub method1 : CRON('* * * * *') {
    return 'method 1';
}

sub method2 : CRON('*/2 * * * *') : LOCK {
    return 'method 2';
}

sub method3 : CRON('*/5 * * * *') : LOCK('lockname') {
    return 'method 3';
}

1;

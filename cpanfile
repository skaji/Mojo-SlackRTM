requires 'perl', '5.010001';

requires 'IO::Socket::SSL';
requires 'Mojolicious';

on test => sub {
    requires 'Test::More', '0.98';
};

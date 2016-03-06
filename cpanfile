requires 'perl', '5.008005';

requires 'IO::Socket::SSL';
requires 'Mojolicious';

on test => sub {
    requires 'Test::More', '0.98';
};

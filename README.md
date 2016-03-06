[![Build Status](https://travis-ci.org/skaji/Mojo-SlackRTM.svg?branch=master)](https://travis-ci.org/skaji/Mojo-SlackRTM)

# NAME

Mojo::SlackRTM - SlackRTM client using Mojo::IOLoop

# SYNOPSIS

    use Mojo::SlackRTM;

    my $slack = Mojo::SlackRTM->new(token => "your_token");
    $slack->on(message => sub {
      my ($slack, $message) = @_;
      my $channel = $message->{channel};
      my $user    = $message->{user};
      my $text    = $message->{text};
      $slack->send_message($channel => "hello $user!");
    });
    $slack->start;

# DESCRIPTION

Mojo::SlackRTM is a SlackRTM client using [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop).

# DEBUGGING

Set `MOJO_SLACKRTM_DEBUG=1`.

# SEE ALSO

[AnyEvent::SlackRTM](https://metacpan.org/pod/AnyEvent::SlackRTM)

[AnySan::Provider::Slack](https://metacpan.org/pod/AnySan::Provider::Slack)

[http://perladvent.org/2015/2015-12-23.html](http://perladvent.org/2015/2015-12-23.html)

# AUTHOR

Shoichi Kaji &lt;skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji &lt;skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

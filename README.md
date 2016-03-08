[![Build Status](https://travis-ci.org/skaji/Mojo-SlackRTM.svg?branch=master)](https://travis-ci.org/skaji/Mojo-SlackRTM)

# NAME

Mojo::SlackRTM - SlackRTM client using Mojo::IOLoop

# SYNOPSIS

    use Mojo::SlackRTM;

    my $slack = Mojo::SlackRTM->new(token => "your_token");
    $slack->on(message => sub {
      my ($slack, $event) = @_;
      my $channel_id = $event->{channel};
      my $user_id    = $event->{user};
      my $user_name  = $slack->find_user_name($user_id);
      my $text       = $event->{text};
      $slack->send_message($channel_id => "hello $user_name!");
    });
    $slack->start;

# DESCRIPTION

Mojo::SlackRTM is a SlackRTM client using [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop).

This class inherits all events, methods, attributes from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo::EventEmitter).

# EVENTS

There are a lot of events, eg, **hello**, **message**, **user\_typing**, **channel\_marked**, ....

See [https://api.slack.com/rtm](https://api.slack.com/rtm) for details.

    $slack->on(reaction_added => sub {
      my ($slack, $event) = @_;
      my $reaction  = $event->{reaction};
      my $user_id   = $event->{user};
      my $user_name = $slack->find_user_name($user_id);
      $slack->log->info("$user_name reacted with $reaction");
    });

# METHODS

## call\_api

    $slack->call_api($method);
    $slack->call_api($method, $param);
    $slack->call_api($method, $param, $cb);

Call slack api. See [https://api.slack.com/methods](https://api.slack.com/methods) for details.

    $slack->call_api("channels.list", {exclude_archived => 1}, sub {
      my ($slack, $tx) = @_;
      if ($tx->success and $tx->res->json("/ok")) {
        my $channels = $tx->res->json("/channels");
        $slack->log->info($_->{name}) for @$channels;
        return;
      }
      my $error = $tx->success ? $tx->res->json("/error") : $tx->error->{message};
      $slack->log->error($error);
    });

## connect

    $slack->connect;

## find\_channel\_id

    my $id = $slack->find_channel_id($name);

## find\_channel\_name

    my $name = $slack->find_channel_name($id);

## find\_user\_id

    my $id = $slack->find_user_id($name);

## find\_user\_name

    my $name = $slack->find_user_name($id);

## finish

    $slack->finish;

## next\_id

    my $id = $slack->next_id;

## ping

    $slack->ping;

## reconnect

    $slack->reconnect;

## send\_message

    $slack->send_message($channel => $text);

Send `$text` to slack `$channel` via the websocket transaction.

## start

    $slack->start;

This is a convenient method. In fact it is equivalent to:

    $slack->connect;
    $slack->ioloop->start unless $slack->ioloop->is_running;

# ATTRIBUTES

## auto\_reconnect

Automatically reconnect to slack

## ioloop

[Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop) singleton

## log

[Mojo::Log](https://metacpan.org/pod/Mojo::Log) instance

## metadata

The response of rtm.start. See [https://api.slack.com/methods/rtm.start](https://api.slack.com/methods/rtm.start) for details.

## token

slack access token

## ua

[Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) instance

## ws

Websocket transaction

# DEBUGGING

Set `MOJO_SLACKRTM_DEBUG=1`.

# SEE ALSO

[AnyEvent::SlackRTM](https://metacpan.org/pod/AnyEvent::SlackRTM)

[AnySan::Provider::Slack](https://metacpan.org/pod/AnySan::Provider::Slack)

[http://perladvent.org/2015/2015-12-23.html](http://perladvent.org/2015/2015-12-23.html)

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

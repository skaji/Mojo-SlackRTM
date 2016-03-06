package Mojo::SlackRTM;
use Mojo::Base 'Mojo::EventEmitter';

use IO::Socket::SSL;
use Mojo::IOLoop;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Log;
use Mojo::UserAgent;

use constant DEBUG => $ENV{MOJO_SLACKRTM_DEBUG};

our $VERSION = '0.01';

has ioloop => sub { Mojo::IOLoop->singleton };
has ua => sub { Mojo::UserAgent->new };
has log => sub { Mojo::Log->new };
has "token";
has "pinger";
has 'ws';
has 'auto_reconnect' => 1;

our $START_URL = "https://slack.com/api/rtm.start";

sub _dump {
    shift;
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    my $dump = Data::Dumper::Dumper(@_);
    warn "  \e[33m$_\e[m\n" for split /\n/, $dump;
}

sub metadata {
    my $self = shift;
    return $self->{_metadata} unless @_;
    my $metadata = shift;
    $self->{_metadata} = $metadata;
    unless ($metadata) {
        $self->{$_} = undef for qw(_users _channels);
        return;
    }
    $self->{_users}    = [
        +{ map { ($_->{id}, $_->{name}) } @{$metadata->{users}} },
        +{ map { ($_->{name}, $_->{id}) } @{$metadata->{users}} },
    ];
    $self->{_channels} = [
        +{ map { ($_->{id}, $_->{name}) } @{$metadata->{channels}} },
        +{ map { ($_->{name}, $_->{id}) } @{$metadata->{channels}} },
    ];
    $metadata;
}
sub next_id {
    my $self = shift;
    $self->{_id} //= 0;
    ++$self->{_id};
}

sub start {
    my $self = shift;
    $self->connect;
    $self->ioloop->start unless $self->ioloop->is_running;
}

sub connect {
    my $self = shift;
    my $token = $self->token or die "Missing token";
    my $tx = $self->ua->get("$START_URL?token=$token");
    unless ($tx->success) {
        my $e = $tx->error;
        my $msg = sprintf "failed to get %s?token=XXXXX: %s",
            $START_URL, $e->{code} ? "$e->{code} $e->{message}" : $e->{message};
        $self->log->fatal($msg);
        return;
    }
    my $metadata = $tx->res->json;
    $self->metadata($metadata);
    my $url = $metadata->{url};
    $self->ua->websocket($url => sub {
        my ($ua, $ws) = @_;
        unless ($ws->is_websocket) {
            $self->log->fatal("$url does not return websocket connection");
            return;
        }
        $self->ws($ws);
        $self->pinger( $self->ioloop->recurring(10 => sub { $self->ping }) );
        $self->ws->on(json => sub {
            my ($ws, $event) = @_;
            $self->_handle_event($event);
        });
        $self->ws->on(finish => sub {
            my ($ws, $event) = @_;
            $self->log->warn("detect 'finish' event");
            $ws->finish;
            $self->_clear;
            $self->connect if $self->auto_reconnect;
        });
    });
}

sub reconnect {
    my $self = shift;
    $self->ws->finish if $self->ws;
    $self->_clear;
    $self->connect;
}

sub _clear {
    my $self = shift;
    if (my $pinger = $self->pinger) {
        $self->ioloop->remove($pinger);
        $self->pinger(undef);
    }
    $self->ws(undef);
    $self->metadata(undef);
    $self->{_id} = 0;
}

sub _handle_event {
    my ($self, $event) = @_;
    if (my $type = delete $event->{type}) {
        if ($type eq "hello") {
            DEBUG and $self->log->debug("===> skip 'hello' event");
            return;
        }
        if ($type eq "message" and defined(my $reply_to = $event->{reply_to})) {
            DEBUG and $self->log->debug("===> skip 'message' event with reply_to $reply_to");
            DEBUG and $self->_dump($event);
            return;
        }
        DEBUG and $self->log->debug("===> emit '$type' event");
        DEBUG and $self->_dump($event);
        $self->emit($type, $event);
    } else {
        DEBUG and $self->log->debug("===> got event without 'type'");
        DEBUG and $self->_dump($event);
    }
}

sub ping {
    my $self = shift;
    my $hash = {id => $self->next_id, type => "ping"};
    DEBUG and $self->log->debug("===> emit 'ping' event");
    DEBUG and $self->_dump($hash);
    $self->ws->send({json => $hash});
}

sub find_channel_id {
    my ($self, $name) = @_;
    $self->{_channels}[1]{$name};
}
sub find_channel_name {
    my ($self, $id) = @_;
    $self->{_channels}[0]{$id};
}
sub find_user_id {
    my ($self, $name) = @_;
    $self->{_users}[1]{$name};
}
sub find_user_name {
    my ($self, $id) = @_;
    $self->{_users}[0]{$id};
}

sub send_message {
    my ($self, $channel, $text, %option) = @_;
    # $option{as_user} = 1 unless exists $option{as_user};
    # $option{as_user} = $option{as_user} ? Mojo::JSON->true : Mojo::JSON->false;
    my $hash = {
        id => $self->next_id,
        type => "message",
        channel => $channel,
        text => $text,
        %option,
    };
    DEBUG and $self->log->debug("===> send message");
    DEBUG and $self->_dump($hash);
    $self->ws->send({json => $hash});
}

sub call_api {
    my ($self, $method, $param) = (shift, shift, shift);
    my $url = "https://slack.com/api/$method";
    my $cb = shift || sub {
        my ($ua, $tx) = @_;
        return if $tx->success;
        my $e = $tx->error;
        $self->log->warn("$url: " . ($e->{code} ? "$e->{code} $e->{message}" : $e->{message}));
    };
    $self->ua->post($url => json => $param => $cb);
}

1;
__END__

=for stopwords SlackRTM

=encoding utf-8

=head1 NAME

Mojo::SlackRTM - SlackRTM client using Mojo::IOLoop

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Mojo::SlackRTM is a SlackRTM client using L<Mojo::IOLoop>.

=head1 DEBUGGING

Set C<MOJO_SLACKRTM_DEBUG=1>.

=head1 SEE ALSO

L<AnyEvent::SlackRTM>

L<AnySan::Provider::Slack>

L<http://perladvent.org/2015/2015-12-23.html|http://perladvent.org/2015/2015-12-23.html>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

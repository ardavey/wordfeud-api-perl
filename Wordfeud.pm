package Wordfeud;

# Class for interacting with the Wordfeud server
# Based on https://github.com/fstream/PHP-Wordfeud-API/blob/master/Wordfeud.php

use strict;
use warnings;

use Digest::SHA qw( sha1_hex );
use JSON qw( encode_json decode_json );
use LWP;
use Log::Log4perl qw( get_logger );
use Data::Dumper;

Log::Log4perl->init( '/home/ardavey/log4perl/wf.conf' );
$Log::Log4perl::DateFormat::GMTIME = 1;

our $log = get_logger();

# This might be subject to change... unsure!
my $base_url = 'http://game03.wordfeud.com/wf/';

sub new {
  my ( $class ) = @_;
  my $self = {};
  Log::Log4perl::MDC->put('session', 'NOSESSION' );
  bless( $self, $class );  
  return $self;
}

sub get_log {
  my ( $self ) = @_;
  return $log;
}

sub get_session_id {
  my ( $self ) = @_;
  if ( $self->{session_id} ) {
    return $self->{session_id};
  }
  return undef;
}

sub get_distribution {
  my ( $self, $game ) = @_;
  
  my $dist = {
    # US
    0 => [ qw(
      ? ? A A A A A A A A A A B B C C D D D D D E E E E E E E E E
      E E E F F G G G H H H I I I I I I I I I J K L L L L M M N N
      N N N N O O O O O O O P P Q R R R R R R S S S S S T T T T T
      T T U U U U V V W W X Y Y Z
    ) ],
    # Norwegian
    1 => [ qw(
      A A A A A A A B B B C D D D D D E E E E E E E E E F F F F G
      G G G H H H I I I I I I J J K K K K L L L L L M M M N N N N
      N N O O O O P P R R R R R R R S S S S S S S T T T T T T T U
      U U V V V W Y Æ Ø Ø Å Å 
    ) ],
    # Dutch
    2 => [ qw(
      A A A A A A A B B C C D D D D D E E E E E E E E E E E E E E
      E E E E F F G G G H H I I I I J J K K K L L L M M M N N N N
      N N N N N N N O O O O O O P P Q R R R R R S S S S S T T T T
      T U U U V V W W X Y Z Z 
    ) ],
    # Danish
    3 => [ qw(
      A A A A A A A B B B B C C D D D D D E E E E E E E E E F F F
      G G G H H I I I I J J K K K K L L L L L M M M N N N N N N N
      O O O O O P P R R R R R R R S S S S S S T T T T T T U U U V
      V V X Y Y Z Æ Æ Ø Ø Å Å 
    ) ],
    # Swedish
    4 => [ qw(
      A A A A A A A A A B B C D D D D D E E E E E E E E F F G G G
      H H I I I I I J K K K L L L L L M M M N N N N N N O O O O O
      O P P R R R R R R R R S S S S S S S S T T T T T T T T T U U
      U V V X Y Z Ä Ä Ö Ö Å Å 
    ) ],
    # English
    5 => [ qw(
      ? ? A A A A A A A A A A B B C C D D D D D E E E E E E E E E
      E E E F F G G G H H H I I I I I I I I I J K L L L L M M N N
      N N N N O O O O O O O P P Q R R R R R R S S S S S T T T T T
      T T U U U U V V W W X Y Y Z
    ) ],
    # Spanish
    6 => [ qw(
      A A A A A A A A A A A A A B B C C C C CH D D D D D E E E E E
      E E E E E E E E F G G H H I I I I I I J L L L L L L M M N N
      N N N N Ñ O O O O O O O O O P P Q R R R R R R R S S S S S S
      S T T T T U U U U U V X Y Z
    ) ],
    # French
    7 => [ qw(
      A A A A A A A A A A B B C C D D D E E E E E E E E E E E E E
      E F F G G G H H I I I I I I I I I J K L L L L L M M M N N N
      N N N O O O O O O P P Q R R R R R R S S S S S S T T T T T T
      U U U U U U V V W X Y Z 
    ) ],
  };
  
  return $dist->{$game->{ruleset}};
}

sub set_session_id {
  my ( $self, $session_id ) = @_;
  $self->{session_id} = $session_id;
  if ( !defined $session_id ) {
    $session_id = 'NOSESSION';
  }
  Log::Log4perl::MDC->put('session', $session_id );
}

sub login_by_email {
  my ( $self, $email, $password ) = @_;
  my $action = 'user/login/email/';
  my $params = {
    email => $email,
    password => sha1_hex( $password.'JarJarBinks9' ),  # I shit you not
  };
  if ( $self->request( $action, $params ) ) {
    return $self->get_session_id();
  }
  $log->info( "Attempting non-seeded login for user '$email'" );
  $params->{password} = sha1_hex( $password );
  if ( $self->request( $action, $params ) ) {
    return $self->get_session_id();
  }  
  return 0;
}

sub login_by_id {
  my ( $self, $id, $password ) = @_;
  my $action = 'user/login/id/';
  my $params = {
    id => $id,
    password => sha1_hex( $password.'JarJarBinks9' ),  # I shit you not
  };
  if ( $self->request( $action, $params ) ) {
    return $self->get_session_id();
  }
  return 0;
}

sub search_user {
  my ( $self, $query ) = @_;
  my $action = 'user/search/';

  my $params = {
    username_or_email => $query,
  };

  my $res = $self->request( $action, $params );

  if ( $res ) {
    return $res->{result};
  }
}

sub create_account {  
  my ( $self, $username, $email, $password ) = @_;
  my $action = 'user/create/';
  my $params = {
    username => $username,
    email => $email,
    password => sha1( $password ),
  };
  
  my $res = $self->request( $action, $params );
  
  if ( $res ) {
    return $res->{id};
  }
  
  return undef;
}

sub get_avatar_url {
  my ( $self, $id, $size ) = @_;
  # Sizes '40', '60' and 'full' are known to work
  return "http://avatars.wordfeud.com/$size/$id";
}

sub get_friends {
  my ( $self ) = @_;
  my $action = 'user/relationships/';

  my $res = $self->request( $action );

  if ( $res ) {
    return $res->{relationships};
  }
  
  return undef;
}

sub add_friend {
  my ( $self, $user_id ) = @_;
  my $action = 'relationship/create/';
  
  my $params = {
    id => $user_id,
    type => 0,
  };

  my $res = $self->request( $action, $params );
  
  if ( $res ) {
    return $res;
  }
  return undef;
}

sub delete_friend {}

sub get_chat_messages {
  my ( $self, $game_id ) = @_;
  my $action = "game/$game_id/chat/";
  
  my $res = $self->request( $action );

  if ( $res ) {
    return $res->{messages};
  }
  return undef;
}

sub send_chat_message {
  my ( $self, $game_id, $message ) = @_ ;
  my $action = "game/$game_id/chat/send/";

  my $params = {
    message => $message,
  };

  my $res = $self->request( $action, $params );

  if ( $res ) {
    return $res;
  }
  return undef;
}

sub get_games {
  my ( $self ) = @_;
  my $action = 'user/games/';

  my $res = $self->request( $action );

  if ( $res ) {
    return $res->{games};
  }
  return undef;
}

sub get_game {
  my ( $self, $game_id ) = @_;
  my $action = "game/$game_id/";

  my $res = $self->request( $action );

  if ( $res ) {
    return $res->{game};
  }
  return undef;
}

sub get_board {}

sub place_tiles {}

sub pass {}

sub resign {}

sub invite {}

sub accept_invite {}

sub reject_invite {}

sub change_password {}

sub log_out {
  my ( $self ) = @_;
  $self->set_session_id( undef );
}

sub request {
  my ( $self, $action, $params ) = @_;
  
  my $ua = LWP::UserAgent->new();

  my $headers = {
    'Accept' => 'application/json',
    'Content-Type' => 'application/json',
    'User-Agent' => 'Perl Wordfeud API',
  };
  if ( $self->get_session_id() ) {
    $headers->{'Cookie'} = 'sessionid='.$self->get_session_id();
  }
  
  my $res;
  if ( $params ) {
    $res = $ua->post( $base_url.$action, %$headers, Content => encode_json( $params ) );
  }
  else {
    $res = $ua->post( $base_url.$action, %$headers );
  }

  $log->debug( Dumper( $res ) );

  if ( $res->{_rc} == 200 ) {
    my $cookie = $res->{_headers}->{'set-cookie'};
    my $session_id = '';
    if ( $cookie ) {
      ( $session_id ) = $cookie =~ m/sessionid=(\w+);/;
    }
    my $content = decode_json( $res->{_content} );
    
    if ( length $session_id && ! get_session_id() ) {
      $self->set_session_id( $session_id );
    }
    
    if ( $content->{status} eq 'success' ) {
      return $content->{content};
    }
    else {
      return undef;
      $log->error( 'Error sending request!' );
    }
  }
  else {
    $log->error_die( "Unexpected HTTP response: $res->{_rc}" );
  }

}

1;

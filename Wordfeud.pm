package Wordfeud;

# Class for interacting with the Wordfeud server
# Based on https://github.com/fstream/PHP-Wordfeud-API/blob/master/Wordfeud.php

use strict;
use warnings;

use utf8;

use Digest::SHA qw( sha1_hex );
use JSON qw( encode_json decode_json );
use LWP;
use Data::Dumper;

# This might be subject to change... unsure!
my $base_url = 'http://game03.wordfeud.com/wf/';

sub new {
  my ( $class ) = @_;
  my $self = {};
  bless( $self, $class );  
  return $self;
}

sub get_session_id {
  my ( $self ) = @_;
  if ( $self->{session_id} ) {
    return $self->{session_id};
  }
  return undef;
}

sub set_distribution {
  my ( $self, $game ) = @_;
  
  my $dist = {
    0 => {
           name => 'US English',
           tileset => [ qw( ? ? A A A A A A A A A A B B C C D D D D D E E E E E E E E E
                            E E E F F G G G H H H I I I I I I I I I J K L L L L M M N N
                            N N N N O O O O O O O P P Q R R R R R R S S S S S T T T T T
                            T T U U U U V V W W X Y Y Z ) ],
           points => {
                      'A' => 1,  'N' => 1,
                      'B' => 4,  'O' => 1,
                      'C' => 4,  'P' => 4,
                      'D' => 2,  'Q' => 10,
                      'E' => 1,  'R' => 1,
                      'F' => 4,  'S' => 1,
                      'G' => 3,  'T' => 1,
                      'H' => 4,  'U' => 2,
                      'I' => 1,  'V' => 4,
                      'J' => 10, 'W' => 4,
                      'K' => 5,  'X' => 8,
                      'L' => 1,  'Y' => 4,
                      'M' => 3,  'Z' => 10,
                      '?' => 0,
                      },
         },
    1 => {
           name => 'Norwegian',
           tileset => [ qw( ? ? A A A A A A A B B B C D D D D D E E E E E E E E E F F F
                            F G G G G H H H I I I I I I J J K K K K L L L L L M M M N N
                            N N N N O O O O P P R R R R R R R S S S S S S S T T T T T T
                            T U U U V V V W Y Æ Ø Ø Å Å ) ],
           points => {
                      'A' => 1,  'N' => 1,
                      'B' => 4,  'O' => 3,
                      'C' => 10, 'P' => 4,
                      'D' => 1,  'R' => 1,
                      'E' => 1,  'S' => 1,
                      'F' => 2,  'T' => 1,
                      'G' => 4,  'U' => 4,
                      'H' => 3,  'V' => 5,
                      'I' => 2,  'W' => 10,
                      'J' => 4,  'Y' => 8,
                      'K' => 3,  'Æ' => 8,
                      'L' => 2,  'Ø' => 4,
                      'M' => 2,  'Å' => 4,
                      '?' => 0,
                      },
         },
    2 => {
           name => 'Dutch',
           tileset => [ qw( ? ? A A A A A A A B B C C D D D D D E E E E E E E E E E E E
                            E E E E E E F F G G G H H I I I I J J K K K L L L M M M N N
                            N N N N N N N N N O O O O O O P P Q R R R R R S S S S S T T
                            T T T U U U V V W W X Y Z Z ) ],
           points => {
                      'A' => 1,  'N' => 1,
                      'B' => 4,  'O' => 1,
                      'C' => 5,  'P' => 4,
                      'D' => 2,  'Q' => 10,
                      'E' => 1,  'R' => 2,
                      'F' => 4,  'S' => 2,
                      'G' => 3,  'T' => 2,
                      'H' => 4,  'U' => 2,
                      'I' => 2,  'V' => 4,
                      'J' => 4,  'W' => 5,
                      'K' => 3,  'X' => 8,
                      'L' => 3,  'Y' => 8,
                      'M' => 3,  'Z' => 5,
                      '?' => 0,
                      },
         },
    3 => {
           name => 'Danish',
           tileset => [ qw( ? ? A A A A A A A B B B B C C D D D D D E E E E E E E E E F
                            F F G G G H H I I I I J J K K K K L L L L L M M M N N N N N
                            N N O O O O O P P R R R R R R R S S S S S S T T T T T T U U
                            U V V V X Y Y Z Æ Æ Ø Ø Å Å ) ],
           points => {
                      'A' => 1,  'O' => 2,
                      'B' => 3,  'P' => 4,
                      'C' => 8,  'R' => 1,
                      'D' => 2,  'S' => 2,
                      'E' => 1,  'T' => 2,
                      'F' => 3,  'U' => 3,
                      'G' => 3,  'V' => 4,
                      'H' => 4,  'X' => 8,
                      'I' => 3,  'Y' => 4,
                      'J' => 4,  'Z' => 9,
                      'K' => 3,  'Æ' => 4,
                      'L' => 2,  'Ø' => 4,
                      'M' => 4,  'Å' => 4,
                      'N' => 1,  '?' => 0,
                      },
         },
    4 => {
           name => 'Swedish',
           tileset => [ qw( ? ? A A A A A A A A A B B C D D D D D E E E E E E E E F F G
                            G G H H I I I I I J K K K L L L L L M M M N N N N N N O O O
                            O O O P P R R R R R R R R S S S S S S S S T T T T T T T T T
                            U U U V V X Y Z Ä Ä Ö Ö Å Å ) ],
           points => {
                      'A' => 1,  'O' => 2,
                      'B' => 3,  'P' => 4,
                      'C' => 8,  'R' => 1,
                      'D' => 1,  'S' => 1,
                      'E' => 1,  'T' => 1,
                      'F' => 3,  'U' => 4,
                      'G' => 2,  'V' => 3,
                      'H' => 3,  'X' => 8,
                      'I' => 1,  'Y' => 7,
                      'J' => 7,  'Z' => 8,
                      'K' => 3,  'Ä' => 4,
                      'L' => 2,  'Ö' => 4,
                      'M' => 3,  'Å' => 4,
                      'N' => 1,  '?' => 0,
                      },
         },
    5 => {
           name => 'International English',
           tileset => [ qw( ? ? A A A A A A A A A A B B C C D D D D D E E E E E E E E E
                            E E E F F G G G H H H I I I I I I I I I J K L L L L M M N N
                            N N N N O O O O O O O P P Q R R R R R R S S S S S T T T T T
                            T T U U U U V V W W X Y Y Z ) ],
           points => {
                      'A' => 1,  'N' => 1,
                      'B' => 4,  'O' => 1,
                      'C' => 4,  'P' => 4,
                      'D' => 2,  'Q' => 10,
                      'E' => 1,  'R' => 1,
                      'F' => 4,  'S' => 1,
                      'G' => 3,  'T' => 1,
                      'H' => 4,  'U' => 2,
                      'I' => 1,  'V' => 4,
                      'J' => 10, 'W' => 4,
                      'K' => 5,  'X' => 8,
                      'L' => 1,  'Y' => 4,
                      'M' => 3,  'Z' => 10,
                      '?' => 0,
                      },
         },
    6 => {
           name => 'Spanish',
           tileset => [ qw( ? ? A A A A A A A A A A A A A B B C C C C CH D D D D D E E E
                            E E E E E E E E E E F G G H H I I I I I I J L L L L L L M M
                            N N N N N N Ñ O O O O O O O O O P P Q R R R R R R R S S S S
                            S S S T T T T U U U U U V X Y Z ) ],
           points => {
                      'A' => 1,  'N' => 1,
                      'B' => 3,  'Ñ' => 8,
                      'C' => 3,  'O' => 1,
                      'CH' => 5, 'P' => 3,
                      'D' => 2,  'Q' => 5,
                      'E' => 1,  'R' => 1,
                      'F' => 4,  'RR' => 8,
                      'G' => 3,  'S' => 1,
                      'H' => 4,  'T' => 2,
                      'I' => 1,  'U' => 1,
                      'J' => 8,  'V' => 4,
                      'L' => 1,  'X' => 8,
                      'LL' => 8, 'Y' => 5,
                      'M' => 3,  'Z' => 10,
                      '?' => 0,
                      },
         },
    7 => {
           name => 'French',
           tileset => [ qw( ? ? A A A A A A A A A A B B C C D D D E E E E E E E E E E E
                            E E E F F G G G H H I I I I I I I I I J K L L L L L M M M N
                            N N N N N O O O O O O P P Q R R R R R R S S S S S S T T T T
                            T T U U U U U U V V W X Y Z ) ],
           points => {
                      'A' => 1,  'N' => 1,
                      'B' => 3,  'O' => 1,
                      'C' => 3,  'P' => 3,
                      'D' => 2,  'Q' => 8,
                      'E' => 1,  'R' => 1,
                      'F' => 4,  'S' => 1,
                      'G' => 2,  'T' => 1,
                      'H' => 4,  'U' => 1,
                      'I' => 1,  'V' => 5,
                      'J' => 8,  'W' => 10,
                      'K' => 10, 'X' => 10,
                      'L' => 2,  'Y' => 10,
                      'M' => 2,  'Z' => 10,
                      '?' => 0,
                      },
         },
  };
  
  $self->{dist} = $dist->{$game->{ruleset}};
}

sub set_session_id {
  my ( $self, $session_id ) = @_;
  $self->{session_id} = $session_id;
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
  
  if ( $res->{_rc} == 200 ) {
    my $cookie = $res->{_headers}->{'set-cookie'};
    my $session_id = '';
    if ( $cookie ) {
      ( $session_id ) = $cookie =~ m/sessionid=(\w+);/;
    }
    my $content = decode_json( $res->{_content} );
    $self->{res} = $content->{content};
    
    if ( length $session_id && ! get_session_id() ) {
      $self->set_session_id( $session_id );
    }
    
    if ( $content->{status} eq 'success' ) {
      return $content->{content};
    }
    else {
      return undef;
    }
  }
  else {
    return undef;
  }

}

1;

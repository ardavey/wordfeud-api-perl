#!/usr/bin/perl -w
use strict;

use Data::Dumper;

use CGI::Pretty;
use Wordfeud;

my $q = new CGI;
my $wf = new Wordfeud;

print $q->header();
print $q->start_html( -title => 'Wordfeud stats' );
  
my $action = $q->param( "action" ) || 'login_form';

if ( $action eq 'login_form' ) {
  print $q->p( 'Please enter your Wordfeud credentials.  These are only used to talk to the game server, and are NOT stored anywhere.' );
  print $q->start_form(
    -name => 'login_form',
    -method => 'POST',
  );
  print $q->p( 'Email address: '
    . $q->textfield(
      -name => 'email',
      -value => '',
      -size => 30,
    )
  );
  print $q->p( 'Password: '
	  . $q->password_field(
      -name => 'password',
      -size => 30,
    )
  );
  print $q->hidden(
    -name => 'action',
    -default => 'get_game_list',
  );
  print $q->p( $q->submit(
      -name => 'submit_form',
      -value => 'Log in',
    )
  );
  print $q->end_form;

}
elsif ( $action eq 'get_game_list' ) {
  if ( $wf->set_session_id( $wf->login_by_email( $q->param( 'email' ), $q->param( 'password' ) ) ) ) {
    print $q->p( 'Logged in successfully ('.$wf->get_session_id().')' );
  }
  else {
    print $q->p( 'Failed to log in - go back and try again.' );
    exit 1;
  }
  
  print $q->p( 'Getting list of games...' );
  my $games = $wf->get_games();
  
  my @running = ();
  my @complete = ();
  
  foreach my $game ( @$games ) {
    if ( $game->{is_running} ) {
      push @running, $game;
    }
    else {
      push @complete, $game;
    }
  }
  
  print $q->hr();
  print $q->h3( 'Running Games' );
  
  print $q->start_ul();
  foreach my $game ( @running ) {
    my $id = $game->{id};
    print $q->li( '<a href="?session='.$wf->get_session_id().'&action=show_game&id='.$id.'">Game '.$id.'</a>: '
                 . ${$game->{players}}[0]->{username}.' ('.${$game->{players}}[0]->{score}.') vs '
                 . ${$game->{players}}[1]->{username}.' ('.${$game->{players}}[1]->{score}.')' );
  }
  print $q->end_ul();
  
  print $q->hr();
  print $q->h3( 'Completed Games' );

  print $q->start_ul();
  foreach my $game ( @complete ) {
    my $id = $game->{id};
    print $q->li( '<a href="?session='.$wf->get_session_id().'&action=show_game&id='.$id.'">Game '.$id.'</a>: '
                 . ${$game->{players}}[0]->{username}.' ('.${$game->{players}}[0]->{score}.') vs '
                 . ${$game->{players}}[1]->{username}.' ('.${$game->{players}}[1]->{score}.')' );
  }
  print $q->end_ul();
  
}
elsif ( $action eq 'show_game' ) {
  my $id = $q->param( 'id' );
  $wf->set_session_id( $q->param( 'session' ) );
  
  my $game = $wf->get_game( $id );
  
  print $q->h3( "Game $id: ".${$game->{players}}[0]->{username}.' ('.${$game->{players}}[0]->{score}.') vs '
                 . ${$game->{players}}[1]->{username}.' ('.${$game->{players}}[1]->{score}.')' );
  
  #print $q->pre( Dumper($game) );

  my @seen_tiles = ();
  my @board = ();
  my @rack = ();
  
  # create an empty board
  foreach my $r ( 0..14 ) {
    $board[$r] = [qw( 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 )];
  }
  my @players = ();
  
  foreach my $player ( @{$game->{players}} ) {
    if ( exists $player->{rack} ) {
      @rack = @{$player->{rack}};
      @rack = map { $_ = ( length $_ ) ? $_ : '?' } @rack;
      push @seen_tiles, @rack;
    }
  }
  
  foreach my $tile ( @{$game->{tiles}} ) {
    if ( @$tile[3] ) {
      @board[@$tile[1]]->[@$tile[0]] = lc( @$tile[2] );
      push @seen_tiles, '?';
    }
    else { 
      @board[@$tile[1]]->[@$tile[0]] = @$tile[2];
      push @seen_tiles, @$tile[2];
    }
  }

  my $avail = {};
  
  foreach my $l ( split( //, $Wordfeud::distribution ) ) {
    if ( $avail->{$l} ) {
      $avail->{$l}++;
    }
    else {
      $avail->{$l} = 1;
    }
  }
  
  foreach my $l ( @seen_tiles ) {
    $avail->{$l}--;
    if ( $avail->{$l} == 0 ) {
      delete $avail->{$l};
    }
  }
  
  my $remaining = '';
  foreach my $l ( sort keys %$avail ) {
    $remaining .= $l x $avail->{$l};
  }
  
  print $q->p( 'Your rack:<br>[<code> ' .join( ' ', @rack )." </code>]\n" );
  print $q->p( 'Remaining tiles:<br>[<code> '. join( ' ', split( //, $remaining ) ) ." </code>]\n" );
  print $q->p( 'Board:' );
  print $q->pre( printable_board( \@board ) );

}

print $q->end_html();


sub printable_board {
  my ( $board_ref ) = @_;
  my @board = @$board_ref;
  my $printable_board = '';
  foreach my $r ( @board ) {
    $printable_board .= '+' . '---+' x 15 . "\n";
    my @row = map { $_ ||= ' ' } @$r;
    $printable_board .= '| ' . join( ' | ', @row ) . " |\n";
  }
  $printable_board .= '+' . '---+' x 15 . "\n";
  return $printable_board;
}  


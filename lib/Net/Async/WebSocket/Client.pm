#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2014 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Client;

use strict;
use warnings;
use base qw( Net::Async::WebSocket::Protocol );

use Carp;

our $VERSION = '0.08';

use Protocol::WebSocket::Handshake::Client;

=head1 NAME

C<Net::Async::WebSocket::Client> - connect to a WebSocket server using
C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::WebSocket::Client;

 my $client = Net::Async::WebSocket::Client->new(
    on_frame => sub {
       my ( $self, $frame ) = @_;
       print $frame;
    },
 );

 my $loop = IO::Async::Loop->new;
 $loop->add( $client );
 
 $client->connect(
    host => $HOST,
    service => $PORT,
    url => "ws://$HOST:$PORT/",

    on_connected => sub {
       $client->send_frame( "Hello, world!\n" );
    },

    on_connect_error => sub { die "Cannot connect - $_[-1]" },
    on_resolve_error => sub { die "Cannot resolve - $_[-1]" },
 );

 $loop->loop_forever;

=head1 DESCRIPTION

This subclass of L<Net::Async::WebSocket::Protocol> connects to a WebSocket
server to establish a WebSocket connection for passing frames.

=cut

=head1 METHODS

=cut

sub _do_handshake
{
   my $self = shift;
   my %params = @_;

   my $hs = Protocol::WebSocket::Handshake::Client->new(
      url => $params{url},
   );

   $self->debug_printf( "HANDSHAKE start" );
   $self->write( $hs->to_string );

   my $f = $self->loop->new_future;
   $self->SUPER::configure( on_read => sub {
      my ( undef, $buffref, $closed ) = @_;

      $hs->parse( $$buffref ); # modifies $$buffref

      if( $hs->is_done ) {
         $self->debug_printf( "HANDSHAKE done" );
         $self->SUPER::configure( on_read => undef );

         $f->done( $self );
      }

      return 0;
   } );

   return $f;
}

=head2 $self->connect( %params ) ==> ( $self )

Connect to a WebSocket server. Takes the following named parameters:

=over 8

=item url => STRING

URL to provide to WebSocket handshake

=back

=head2 $self->connect( %params )

When not returning a C<Future>, the following additional parameters provide
continuations:

=over 8

=item on_connected => CODE

CODE reference to invoke when the handshaking is complete.

=back

=cut

sub connect
{
   my $self = shift;
   my %params = @_;

   my $f = $self->SUPER::connect( %params )->then( sub {
      my ( $self ) = @_;

      $self->_do_handshake( %params );
   });

   $f->on_done( $params{on_connected} ) if $params{on_connected};

   return $f if defined wantarray;

   $f->on_ready( sub { undef $f } ); # intentional cycle
}

=head2 $client->connect_handle( $handle, %params ) ==> ( $self )

Sets the read and write handles to the IO reference given, then performs the
initial handshake using the parameters given. These are as for C<connect>.

=cut

sub connect_handle
{
   my $self = shift;
   my ( $handle, %params ) = @_;

   $self->set_handle( $handle );

   $self->_do_handshake( %params );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

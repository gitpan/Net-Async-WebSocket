#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Client;

use strict;
use warnings;
use base qw( Net::Async::WebSocket::Protocol );

use Carp;

our $VERSION = '0.06';

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

=head2 $self->connect( %params )

Connect to a WebSocket server. Takes the following named parameters:

=over 8

=item transport => IO::Async::Stream

The underlying transport to use for this connection.

=item url => STRING

URL to provide to WebSocket handshake

=item on_connected => CODE

CODE reference to invoke when the handshaking is complete.

=back

=cut

sub connect
{
   my $self = shift;
   my %params = @_;

   my $on_connected = delete $params{on_connected} or croak "Expected 'on_connected' as a CODE ref";

   my $hs = Protocol::WebSocket::Handshake::Client->new(
      url => $params{url},
   );

   $self->SUPER::connect(
      %params,

      on_connected => sub {
         $self->write( $hs->to_string );

         $self->SUPER::configure( on_read => sub {
            my ( undef, $buffref, $closed ) = @_;

            $hs->parse( $$buffref ); # modifies $$buffref

            if( $hs->is_done ) {
               $self->SUPER::configure( on_read => undef );

               $on_connected->( $self );
            }

            return 0;
         } );
      },
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

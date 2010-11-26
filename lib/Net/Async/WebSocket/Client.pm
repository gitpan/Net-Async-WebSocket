#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Client;

use strict;
use warnings;
use base qw( Net::Async::WebSocket::Protocol );

use Carp;

our $VERSION = '0.01';

use Protocol::WebSocket::Handshake::Client;

=head1 NAME

C<Net::Async::WebSocket::Client> - connect to a WebSocket server using
C<IO::Async>

=head1 SYNOPSIS

 TODO

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

   unless( $params{transport} ) {
      # TODO: Protocol->connect
      $self->get_loop->connect(
         %params,
         on_stream => sub {
            my ( $stream ) = @_;

            $self->connect(
               %params,
               transport => $stream,
               on_connected => $on_connected,
            );
         },
      );

      return;
   }

   my $transport = delete $params{transport};
   
   $self->configure( transport => $transport );

   my $hs = Protocol::WebSocket::Handshake::Client->new(
      url => $params{url},
   );

   $self->write( $hs->to_string );

   $self->SUPER::configure( on_read => sub {
      my ( undef, $buffref, $closed ) = @_;

      $hs->parse( $$buffref );
      $$buffref = "";

      if( $hs->is_done ) {
         $self->SUPER::configure( on_read => undef );

         $on_connected->( $self );
      }

      return 0;
   } );
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

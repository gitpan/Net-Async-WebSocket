#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2013 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Protocol;

use strict;
use warnings;
use base qw( IO::Async::Protocol::Stream );

use Carp;

our $VERSION = '0.06';

use Protocol::WebSocket::Frame;

=head1 NAME

C<Net::Async::WebSocket::Protocol> - send and receive WebSocket frames

=head1 DESCRIPTION

This subclass of L<IO::Async::Protocol::Stream> implements an established
WebSocket connection, that has already completed its setup handshaking and is
ready to pass frames.

Objects of this type would not normally be constructed directly. For WebSocket
clients, see L<Net::Async::WebSocket::Client>, which is a subclass of this.
For WebSocket servers, see L<Net::Async::WebSocket::Server>, which constructs
objects in this class when it accepts a new connection and passes it to its
event handler.

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init;

   $self->{framebuffer} = Protocol::WebSocket::Frame->new;
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item on_frame => CODE

A CODE reference for when a frame is received

 $on_frame->( $self, $frame )

=back

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_frame )) {
      $self->{$_} = delete $params{$_} if exists $params{on_frame};
   }

   $self->SUPER::configure( %params );
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $closed ) = @_;

   my $framebuffer = $self->{framebuffer};

   $framebuffer->append( $$buffref ); # modifies $$buffref

   while( my $frame = $framebuffer->next ) {
      $self->invoke_event( on_frame => $frame );
   }

   return 0;
}

=head1 METHODS

=cut

=head2 $self->send_frame( @args )

Sends a frame to the peer containing containing the given string. The
arguments are passed to L<Protocol::WebSocket::Frame>'s C<new> method.

=cut

sub send_frame
{
   my $self = shift;

   $self->write( Protocol::WebSocket::Frame->new( @_ )->to_bytes );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

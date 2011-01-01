#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Server;

use strict;
use warnings;
use base qw( IO::Async::Listener );

use Carp;

our $VERSION = '0.03';

use Net::Async::WebSocket::Protocol;

use Protocol::WebSocket::Handshake::Server;

=head1 NAME

C<Net::Async::WebSocket::Server> - serve WebSocket clients using C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::WebSocket::Server;
 
 my $server = Net::Async::WebSocket::Server->new(
    on_client => sub {
       my ( undef, $client ) = @_;
 
       $client->configure(
          on_frame => sub {
             my ( $self, $frame ) = @_;
             $self->send_frame( $frame );
          },
       );
    }
 );
 
 my $loop = IO::Async::Loop->new;
 $loop->add( $server );
 
 $server->listen(
    service => 3000,
 
    on_listen_error => sub { die "Cannot listen - $_[-1]" },
    on_resolve_error => sub { die "Cannot resolve - $_[-1]" },
 );
 
 $loop->loop_forever;

=head1 DESCRIPTION

This subclass of L<IO::Async::Listener> accepts WebSocket connections. When a
new connection arrives it will perform an initial handshake, and then pass the
connection on to the continuation callback or method.

=cut

sub new
{
   my $class = shift;
   return $class->SUPER::new(
      @_,
      # TODO: IO::Async::Listener -> on_stream method
      on_stream => sub {
         my ( $self, $stream ) = @_;

         my $hs = Protocol::WebSocket::Handshake::Server->new;

         $stream->configure(
            on_read => sub {
               my ( $stream, $buffref, $closed ) = @_;

               $hs->parse( $$buffref ); # modifies $$buffref

               if( $hs->is_done ) {
                  $stream->write( $hs->to_string );

                  $self->remove_child( $stream );

                  my $client = $self->new_client( $stream );

                  my $on_client = $self->{on_client} ||
                                  $self->can( "on_client" );

                  $on_client->( $self, $client );

                  $self->add_child( $client );
               }

               return 0;
            },
         );

         $self->add_child( $stream );
      },
   );
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item on_client => CODE

A callback that is invoked whenever a new client connects and completes its
inital handshake.

 $on_client->( $self, $client )

It will be passed a new instance of a L<Net::Async::WebSocket::Protocol>
object, wrapping the client connection.

=back

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_client )) {
      $self->{$_} = delete $params{$_};
   }

   $self->SUPER::configure( %params );
}

sub new_client
{
   my $self = shift;
   my ( $stream ) = @_;

   return Net::Async::WebSocket::Protocol->new( transport => $stream );
}

sub listen
{
   my $self = shift;
   my %params = @_;

   $self->SUPER::listen(
      socktype => 'stream',
      %params,
   );
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

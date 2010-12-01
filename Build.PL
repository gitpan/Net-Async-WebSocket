use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::WebSocket',
   requires => {
      'IO::Async::Listener' => '0.30',
      'Protocol::WebSocket' => '0.0003',
      'Protocol::WebSocket::Frame' => 0,
      'Protocol::WebSocket::Handshake::Client' => 0,
      'Protocol::WebSocket::Handshake::Server' => 0,
   },
   build_requires => {
      'Test::More' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);
  
$build->create_build_script;

package IOMCore::Include;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = qw( Include );
@EXPORT_OK   = qw( Include );
%EXPORT_TAGS = ( );

##########################################################################

use IOMCore::FichLog;


sub Include($);


sub Include($)
{ my $fichero=shift;
  my (@lineas,$resul);
  local *HANDIN;

  open(HANDIN,$fichero) || do
  { printLOG(%FLvoid,"IOMCore::Include: No pude abrir fichero $fichero: $!");
    return undef;
  };

  @lineas=<HANDIN>;
  $resul=join
  close(HANDIN);

  return join("",@lineas);
};

1;
  

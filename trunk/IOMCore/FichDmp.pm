package IOMCore::FichDmp;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = qw( GrabaDump CargaDump );
@EXPORT_OK   = qw( GrabaDump CargaDump );
%EXPORT_TAGS = ( );

##########################################################################

use Data::Dumper;

=pod
  Uso:

  use IOMCore::FichDmp;

  Cargar 
  %VarGrabada=%{CargaDump("FichDmp")};
  @VarGrabada=@{CargaDump("FichDmp")};

  Grabar
  GrabaDump("FicheroDmp",\%VarAGarbar);
  GrabaDump("FicheroDmp",\@VarAGarbar);

=cut

#GrabaDump(fichero,refadatos)
sub GrabaDump($$)
{ my $fichero=shift;
  my $datos=shift;
  local *HANDOUT;
  my $cadenaGZ;
  
  $cadenaGZ=($fichero=~ m#\.gz#)?"| gzip -9 > $fichero ":"$fichero";

  open(HANDOUT,"$cadenaGZ > $fichero") || do
  { print STDERR "No pude grabar el fichero $fichero: $!\n";
    return 1;
  };
  print HANDOUT Dumper($datos) || return 1;
  close(HANDOUT) && return 0;
  return 1;
};

#CargaDump(fichero)
sub CargaDump($)
{ my $fichero=shift;
  my ($datos,$VAR1);
  local *HANDOUT;
  my $cadenaGZ;

  $cadenaGZ=($fichero=~ m/\.gz/)?"gzip -cd  $fichero |":"$fichero";

  $VAR1={};

  open(HANDIN,"$cadenaGZ") || do
  { printLOG("Error al abrir el fichero $fichero: $!\n");
  };
  eval(join(" ",<HANDIN>));
  close(HANDIN);
  if ($@)
  { printLOG("Error al evaluar el contenido del fichero $fichero: $@\n");
  } else
  { $datos=$VAR1;
  };
  return $datos;
};

1;

package IOMCore::FichDmp;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
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

  $cadenaGZ=($fichero=~ m#\.gz$#)?"| gzip -9 > $fichero ":">$fichero";

  open(HANDOUT,"$cadenaGZ") || do
  { print STDERR "No pude grabar el fichero $fichero: $!\n";
    return 0;
  };
  print HANDOUT Dumper($datos) || return 0;
  close(HANDOUT) && return 1;
  return 0;
};

#CargaDump(fichero)
sub CargaDump($)
{ my $fichero=shift;
  my ($datos,$VAR1);
  local *HANDOUT;
  my $cadenaGZ;

  $cadenaGZ=($fichero=~ m/\.gz$/)?"gzip -cd  $fichero |":"$fichero";

  $VAR1={};

  open(HANDIN,"$cadenaGZ") || do
  { print STDERR "Error al abrir el fichero $fichero: $!\n";
    return $VAR1;
  };
  eval(join(" ",<HANDIN>));
  if ($@)
  { print STDERR "Error al evaluar el contenido del fichero $fichero: $@\n";
  } else
  { $datos=$VAR1;
  };
  close(HANDIN);
  return $datos;
};

1;

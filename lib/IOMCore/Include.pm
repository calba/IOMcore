package IOMCore::Include;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = @EXPORT_OK = qw( Include IncludeC Append AppendC );
%EXPORT_TAGS = ( );

##########################################################################

use IOMCore::FichLog;


sub Include($);
sub IncludeC(\%$);

sub Include($)
{ return IncludeC(%FLvoid,$_[0]);
};

sub IncludeC(\%$)
{ my $CONFIG=shift;
  my $fichero=shift;
  my (@lineas);
  local *HANDIN;

  open(HANDIN,$fichero) || do
  { printLOG(%$CONFIG,"IOMCore::Include: No pude abrir fichero $fichero: $!");
    return undef;
  };

  @lineas=<HANDIN>;
  close(HANDIN);

  return join("",@lineas);
};

sub AppendC(\%$$)
{ my $CONFIG=shift;
  my $fichero=shift;
  my $linea=shift;

  local *HANDOUT;

  open(HANDOUT, ">> $fichero") || do
  { printLOG(%{$CONFIG},"AppendC: Problemas al abrir: $fichero: $!");
    return -1;
  };
  print HANDOUT $linea;
  close HANDOUT;
  return 0;
};

sub Append($$)
{ my $fichero=shift;
  my $linea=shift;

  return AppendC(%FLvoid,$fichero,$linea);
};

1;
  
=head1 NAME

IOMCore::Include - Lee un fichero completo y lo almacena en una cadena

=head1 SYNOPSIS

    use IOMCore::Include;

    $mifichero=Include("Fichero");

=head1 DESCRIPCION

Este modulo carga un fichero y lo almacena en memoria. No se hace ningun tipo de procesado.

=head1 Version

$Id: Include.pm,v 1.7 2008-05-06 22:48:33 calba Exp $

=head1 Cambios

$Log: not supported by cvs2svn $
Revision 1.6  2005/01/25 17:03:57  calba
- A√±adidas las funciones Append y AppendC para a√±adir contenido a ficheros

Revision 1.5  2004/12/28 08:45:43  calba
- Corregida una linea del cambio anterior que provocaba un warning

Revision 1.4  2004/12/26 19:39:07  calba
- Modificado error en Include por el que se pasaba mal el nombre del fichero a incluir.

Revision 1.3  2003/12/26 20:52:24  calba
- AÒadido IncludeC para que las trazas las ponga en el fichero de log y no por la salida de error

Revision 1.2  2003/01/30 11:01:56  calba
AÒadida documentacion en POD


=cut

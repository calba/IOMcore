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
  
=head1 NAME

IOMCore::Include - Lee un fichero completo y lo almacena en una cadena

=head1 SYNOPSIS

    use IOMCore::Include;

    $mifichero=Include("Fichero");

=head1 DESCRIPCION

Este modulo carga un fichero y lo almacena en memoria. No se hace ningun tipo de procesado.

=head1 Version

$Id: Include.pm,v 1.2 2003-01-30 11:01:56 calba Exp $

=head1 Cambios

$Log: not supported by cvs2svn $

=cut




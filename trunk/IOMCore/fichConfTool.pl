#!/usr/bin/perl -w

#$Id: fichConfTool.pl,v 1.4 2003-03-18 17:43:46 calba Exp $

use strict;
use diagnostics;

use FindBin;
use lib "$FindBin::Bin/..";

use Getopt::Long;
use Data::Dumper;

use IOMCore::FichConf;

sub Ayuda($$);
sub CargaModulo($$);
sub VuelcaHash($$\%);
sub VuelcaModulo($$$\%);

my (%CONFIG,%ConfParser,%ConfDatos,$fichconf);

%CONFIG= ( 'SEPARADOR'=>" ",);

my @Opciones=( 'PARSERCONF|cf=s',
               'PARSERMOD|cm=s',
               'FICHSAL|o=s',
               'GCONFIPARSERPM|pp=s',
               'GCONFIPARSERST|ps=s',
               'GCONFIDATOSPM|xp=s',
               'GCONFIDATOSST|xs=s',
               'ENTORNO|e!',
               'SEPARADOR|s=s',
               'h|?' => \&Ayuda
              );

GetOptions(\%CONFIG,@Opciones);

#Carga la configuracion del parser
if (defined($CONFIG{'PARSERCONF'}))
{ do
  { die "ORROR: Problemas al leer el fichero de configuracion: $CONFIG{'PARSERCONF'}\n";
  } unless (%ConfParser=LeeFichConfParser($CONFIG{'PARSERCONF'}))
} elsif (defined($CONFIG{'PARSERMOD'}))
{ my ($modauxi);
  $modauxi=$CONFIG{'PARSERMOD'};
  $modauxi =~ s/\.pm$//;
  CargaModulo("NADA",$CONFIG{'PARSERMOD'});
  eval("%ConfParser = %$modauxi"."::ConfParser");
} else
{ print STDERR "ORROR: Falta la sintaxis del parser (opcion -cf o -cm)\n";
  Ayuda("","");
};

if (defined($CONFIG{'GCONFIPARSERST'}))
{ my $fichname;

  if (defined($CONFIG{'FICHSAL'}))
  { $fichname=$CONFIG{'FICHSAL'};
    if ($fichname !~ m#\.pl$#)
    { $fichname .= ".pl";
    };
  } else
  { $fichname = "";
  };

  VuelcaHash($fichname,$CONFIG{'GCONFIPARSERST'},%ConfParser);
  exit 0;
} 

if (defined($CONFIG{'GCONFIPARSERPM'}))
{ my $fichname;

  if (defined($CONFIG{'FICHSAL'}))
  { $fichname=$CONFIG{'FICHSAL'};
    if ($fichname !~ m#\.pm$#)
    { $fichname .= ".pm";
    };
  } else
  { $fichname = "";
  };

  VuelcaModulo($fichname,$CONFIG{'GCONFIPARSERPM'},"ConfParser",%ConfParser);
  exit 0;
} 


do
{ print STDERR "ORROR: No se han especificado ficheros de configuracion\n";
  Ayuda("","");
} unless (@ARGV);

foreach $fichconf (@ARGV)
{ LeeFichConf(%ConfDatos,%ConfParser,$fichconf);
};

if (defined($CONFIG{'ENTORNO'}))
{ my ($clave,@claves);

  @claves=grep { !(ref($ConfDatos{$_})) || 
                  (ref($ConfDatos{$_}) eq "ARRAY"); } (keys %ConfDatos);

  if (@claves)
  { map { if (ref($ConfDatos{$_}))
          { print "$_=\"".join($CONFIG{'SEPARADOR'},@{$ConfDatos{$_}})."\"\n";
          } else
          { print "$_=\"$ConfDatos{$_}\"\n"; 
          }
        } (@claves);
    print "export ","@claves ","\n";
  };
  exit (0);
} elsif (defined($CONFIG{'GCONFIDATOSST'}))
{ my $fichname;

  if (defined($CONFIG{'FICHSAL'}))
  { $fichname=$CONFIG{'FICHSAL'};
    if ($fichname !~ m#\.pl$#)
    { $fichname .= ".pl";
    };
  } else
  { $fichname = "";
  };

  VuelcaHash($fichname,$CONFIG{'GCONFIDATOSST'},%ConfDatos);
  exit 0;
} elsif (defined($CONFIG{'GCONFIDATOSPM'}))
{ my $fichname;

  if (defined($CONFIG{'FICHSAL'}))
  { $fichname=$CONFIG{'FICHSAL'};
    if ($fichname !~ m#\.pm$#)
    { $fichname .= ".pm";
    };
  } else
  { $fichname = "";
  };

  VuelcaModulo($fichname,$CONFIG{'GCONFIDATOSPM'},"CONFIG",%ConfDatos);
  exit 0;
} else
{ print STDERR "ORROR: No se ha indicado que hacer con el/los fichero(s) de configuracion leido(s) (opciones -e o -xp o -xs)\n";
  Ayuda("","");
};

##########################################################################
##########################################################################
##########################################################################
##########################################################################

sub Ayuda($$)
{ print STDERR <<FIN;

fichConfTool.pl: Herramienta auxiliar para manejo de ficheros de configuracion

Uso: 
fichConfTool.pl [-h][-?] {-cf sintaxis.cfg | -cm sintaxis.pm} { -pp modulossint.pm | -ps modulosint.pl | -xp datosconf.pm | -xs datosconf.pl | -e [-s sep]} [-o fichsalida] ficheroconf.cfg ...

-h Esta pantalla
-? Esta pantalla
-cf sintaxis.cfg Sintaxis del fichero de configuracion 
-cm sintaxis.pm Modulo perl que contiene la sintaxis del fichero de conf.
-pp modulossint.pm Genera un modulo perl susceptible de ser importado por cm
-ps nombrehash Genera un fichero con un hash susceptible de require o C&P
-xp datosconf.pm Genera un modulo perl con los datos de configuracion real
-xs nombrehash Genera un fichero perl para require o C&P con la configuracion
-e             Saca las variables base escalares y arrays por salida estandar
               como variables de entorno. Ideal para hacer 'eval'.
-s separador Separador de los campos que formarn los arrays que salen con -e
            Por defecto: espacio
-o fichsalida Nombre del fichero de salida. Por defecto: salida estándar.

FIN
  exit 1;
};

sub CargaModulo($$)
{ my $modulocarga;
  (undef,$modulocarga)=@_;
  require $modulocarga;
};

sub VuelcaModulo($$$\%)
{ my $fichero=shift;
  my $modname=shift;
  my $varname=shift;
  my $datos=shift;
  my ($flag);
  local *HANDOUT;

  *HANDOUT = *STDOUT;
  if ($fichero)
  { $flag=1;
    open(HANDOUT,">".$fichero) || do
    { *HANDOUT = *STDOUT;
      $flag=0;
    };
  };

  print HANDOUT <<FIN;
package $modname;
use strict;
use vars qw(\@ISA \@EXPORT \@EXPORT_OK \%EXPORT_TAGS \$VERSION);

use Exporter;
\$VERSION = 1.00;
\@ISA = qw(Exporter);

\@EXPORT_OK   = qw( \%$varname );       # Symbols to export on request

use vars qw( \%$varname );

FIN

  print HANDOUT "\%$varname = %{ my ",Dumper($datos),"};\n\n1;\n";

  close HANDOUT if ($flag);
};

sub VuelcaHash($$\%)
{ my $fichero=shift;
  my $varname=shift;
  my $datos=shift;
  my ($flag);
  local *HANDOUT;

  *HANDOUT = *STDOUT;
  if ($fichero)
  { $flag=1;
    open(HANDOUT,">".$fichero) || do
    { *HANDOUT = *STDOUT;
      $flag=0;
    };
  };

  print HANDOUT "\%$varname= \%{  my ",Dumper($datos),"};\n\n\n1\n;";
  close HANDOUT if ($flag);
};


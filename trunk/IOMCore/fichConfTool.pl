#!/usr/bin/perl -w

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

my @Opciones=( 'PARSERCONF|cf=s',
               'PARSERMOD|cm=s',
               'FICHSAL|o=s',
               'GCONFIPARSERPM|pp=s',
               'GCONFIPARSERST|ps=s',
               'GCONFIDATOSPM|xp=s',
               'GCONFIDATOSST|xs=s',
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

if (defined($CONFIG{'GCONFIDATOSST'}))
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
{ print STDERR "ORROR: No se ha indicado que hacer con el/los fichero(s) de configuracion leido(s) (opcion -xp o -xs)\n";
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
fichConfTool.pl [-h][-?] {-cf sintaxis.cfg | -cm sintaxis.pm} { -pp modulossint.pm | -ps modulosint.pl | -xp datosconf.pm | -xs datosconf.pl [-o fichsalida] ficheroconf.cfg ...

-h Esta pantalla
-? Esta pantalla
-cf sintaxis.cfg Sintaxis del fichero de configuracion 
-cm sintaxis.pm Sintaxis del 
-pp modulossint.pm | 
-ps modulosint.pl | 
-xp datosconf.pm | 
-xs datosconf.pl [
-o fichsalida] ficheroconf.cfg ...
 
 'PARSERCONF|cf=s',
 'PARSERMOD|cm=s',
 'FICHSAL|o=s',
 'GCONFIPARSERPM|pp=s',
 'GCONFIPARSERST|ps=s',
 'GCONFIDATOSPM|xp=s',
 'GCONFIDATOSST|xs=s',

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


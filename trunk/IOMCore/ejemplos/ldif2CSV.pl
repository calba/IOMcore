#!/usr/bin/perl -w

use strict;
use diagnostics;

use Getopt::Long;

#LOCALIZACION de IOMCore
if (defined($ENV{'LIBCORE'}))
{ use lib $ENV{'LIBCORE'};
  use IOMCore::LeeLDIF;
} else
{ die "ORROR: No se ha fijado la variable LIBCORE. Consulte con el administrador";
  #TOD: Error mas digno
};

my (%LDAP,%CONFIG,@salida,$fichname);

my @Opciones=( 'SALIDA|o=s',
               'h|?' => \&Ayuda,
             );

GetOptions(\%CONFIG,@Opciones);

if (@ARGV)
{ %LDAP=ldif2hash($ARGV[0]);
} else
{  %LDAP=ldif2hash("-");
};

foreach (keys %LDAP)
{ my %dato;

  %dato=%{$LDAP{$_}};

  push @salida,join("|",$dato{'uid'},$dato{'mail'});
};

$fichname=defined($CONFIG{'SALIDA'})?$CONFIG{'SALIDA'}:"-";
$fichname=$CONFIG{'SALIDA'}||"-";

if ($fichname eq "-")
{ *HANDOUT=*STDOUT;
} else
{ open(HANDOUT,">$fichname") 
    || die "ORROR: ldif2hash no pudo abrir $fichname: $!";
};

map { print HANDOUT "$_\n"; } @salida;

if ($fichname ne "-")
{ close HANDOUT;
};


sub Ayuda($$)
{
  print <<FIN;
ldif2CSV.pl: Lee datos en formato LDIF y devuelve un fichero formato CSV 
             separado por "|" con el UID y el campo mail
Uso:
  ldif2CSV.pl [-oficherosalida][-?][-h] [ficheroLDIF]

Opciones:
 -h Esta pantalla
 -? Esta pantalla
 -o fichero Nombre del fichero de salida. Por defecto: Salida estándar

FIN

  exit (1);
};


package IOMCore::FichConf;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line,for MakeMaker
@ISA = qw(Exporter);

@EXPORT_OK = @EXPORT = qw(LeeFichConf ParseFich GenConfParser ConfParser
                          LeeFichConfParser Lista2Hash DumpConfig);

##########################################################################

use strict;
use diagnostics;

use Data::Dumper;

use IOMCore::FichLog;

sub LeeFichConfParser($);
sub GenConfParser(\%);
sub EliminaDuplisArray(\@);
sub HazLimpieza(\%);
sub LeeFichConf(\%\%$);
sub ConfParser(\%$);

sub do_untaint($);
my @emptyArray;

sub LeeFichConf(\%\%$)
{ my $CONFIG=shift;
  my $ConfParser=shift;
  my $fichconf=do_untaint(shift);

  local *HANDIN;
  my ($clave,%PARSECONF,$linea,$MODO,$VALMODO,%CONFAUX);

  %PARSECONF=GenConfParser(%{$ConfParser});

  open(HANDIN,$fichconf) || do
  { printLOG(%FLvoid,"Error al abrir: $fichconf: $!");
    return;
  };

  while(defined($linea=<HANDIN>))
  { my ($clave,$valor);

    chomp $linea;
    $linea =~ s/\cM//g;
    $linea =~ s/^\s*//g;
    $linea =~ s/\s*$//g;

    next if (($linea =~ m/^\s*$/) || ($linea =~ m/^\s*#/));

    ($clave,$valor)=split(/\s+/,$linea,2);
    $clave=uc($clave);


    LOO: {
     if ($clave =~ m/^FIN$/)
     { $MODO="";
       $VALMODO="";
       next LOO;
     };
     next LOO unless (defined($valor));

     if (defined($PARSECONF{'CLAVES'}{$clave}))
     { $MODO=$clave;
       $VALMODO=$valor;
       next LOO;
     };
     if ($MODO &&
         ($VALMODO ne "") &&
         defined($PARSECONF{'SUBBASES'}{$MODO}{$clave})
        )
     { if ($PARSECONF{'SUBBASES'}{$MODO}{$clave}{'TIPO'} eq "\$")
       { $CONFIG->{$MODO}{$VALMODO}{$clave}=$valor;
       } else
       { push (@{$CONFIG->{$MODO}{$VALMODO}{$clave}},$valor);
       };
       next LOO;
     };
     if(defined($PARSECONF{'BASES'}{$clave}))
     { if ($PARSECONF{'BASES'}{$clave}{'TIPO'} eq "\$")
       { $CONFIG->{$clave}=$valor;
       } else
       { push (@{$CONFIG->{$clave}},$valor);
       };
       next LOO;
     };
     printLOG(%FLvoid,"CONF: ($fichconf:$.) Clave: $clave desconocida en ",
                      "$linea");
    }; # LOO
  };
  close HANDIN;

  HazLimpieza(%{$CONFIG});
};

sub GenConfParser(\%)
{ my $ConfBase=shift;
  my (%RESUL);

  if (defined($ConfBase->{'BASE'}))
  { my $clave;

    foreach $clave (@{$ConfBase->{'BASE'}})
    { my ($tipo,$nombre);

      next unless ($clave);

      $clave =~ m#^(\$|@)?(.+)$# ;
      $tipo=$1;
      $nombre=uc($2);

      if ($nombre =~ m#^(FIN)$# )
      { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Configuracion de parser ",
                         "contiene FIN en BASE");
        next;
      };

      $RESUL{'BASES'}{$nombre}{'TIPO'}=$tipo || '$';
    };
  };

  if (defined($ConfBase->{'CLAVEPRI'}))
  { my $clave;

    foreach $clave (keys %{$ConfBase->{'CLAVEPRI'}})
    { my ($subclave);

      next unless ($clave);

      if ($clave =~ m#^(FIN)$# )
      { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Configuracion de parser",
                         " contiene una SUBCLAVE llamada FIN");
        next;
      };

      if (defined($RESUL{'BASES'}{$clave}))
      { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Intenta definir una ",
                        "subclave igual que una clave base ($clave). Omitida.");
        next;
      };

      foreach $subclave (@{$ConfBase->{'CLAVEPRI'}{$clave}{'CLAVESEC'}})
      { my ($tipo,$nombre);
        next unless ($subclave);

        $subclave =~ m#^(\$|@)?(.+)$# ;
        $tipo=$1;
        $nombre=uc($2);

        if ($nombre =~ m#^(FIN)$# )
        { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Configuracion de parser",
                           " contiene FIN como SUBCLAVE de $clave. Omitida.");
          next;
        };

        if (defined($RESUL{'CLAVES'}{$nombre}))
        { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Intenta definir una ",
                           " subclave igual que una clave base ($nombre).",
                           " Omitida.");
          next;
        };

        $RESUL{'SUBBASES'}{$clave}{$nombre}{'TIPO'}=$tipo || '$';
      };
      $RESUL{'CLAVES'}{$clave}++;
    };
  };
  return %RESUL;

};

sub EliminaDuplisArray(\@)
{ my $array=shift;
  my (%hashaux,@auxi);

  map { $hashaux{$_}++; } (@{$array});
  @{$array}=grep { $hashaux{$_}<2 }(@$array);
};

sub HazLimpieza(\%)
{ my $CONFIG=shift;
  my ($clave,%RESUL);

  foreach $clave (keys %{$CONFIG})
  { my ($tipo);

    $tipo=ref($CONFIG->{$clave});

    $_=$tipo;
    LOO1:
    { /SCALAR/ && next LOO1;
      /ARRAY/ && do
      { EliminaDuplisArray(@{$CONFIG->{$clave}});
        next LOO1;
      };
      /HASH/ && do
      { HazLimpieza(%{$CONFIG->{$clave}});
        next LOO1;
      };
    };
  };
};

#Lee el fichero de descripción de la gramática del fichero (que es un fichero de
#configuración en sí mismo) y devuelve la variable que permite la interpretación
#del fichero de configuración
sub LeeFichConfParser($)
{ my $fichero=shift;
  my %RESUL=();

  my %ConfFichParser= ( 'BASE' => [ '@BASE' ],
                        'CLAVEPRI' => { 'CLAVEPRI' => { 'CLAVESEC' => [ '@CLAVESEC' ] }}
                      );
  LeeFichConf(%RESUL,%ConfFichParser,$fichero);

  return %RESUL;
};

sub Lista2Hash(\%$$)
{ my $CONFIG=shift;
  my $claveLista=shift;
  my $claveHash=shift;

  do
  { printLOG(%$CONFIG,"Variable $claveLista no definida o es del tipo escalar");
    return;
  } unless (defined($CONFIG->{$claveLista}) &&
                                      (ref($CONFIG->{$claveLista}) eq "ARRAY"));

  do
  { printLOG(%$CONFIG,"Variable $claveHash ya en uso");
    return;
  } if (defined($CONFIG->{$claveHash}));

  map { $CONFIG->{$claveHash}{$_}++; } (@{$CONFIG->{$claveLista}});
};


#Devuelve con una closure de una función de lectura de fichero de configuración
#susceptible de ser usada como callback por GetOptions.
#Uso:
#Como opción en GetOptions:
#  my @OPTIONS = ( ...
#                  'c=s' => ConfParser(%CONFIG,$gramBASE),
#                  ...
#              );
#...
#GetOptions(\%CONFIG,@OPTIONS);
#grambase es la ubicación del fichero que contiene la descripción YA ADAPTADA
#del fichero de configuración
#CONFIG es la variable que va a almacenar la configuración leída del fichero
sub ConfParser(\%$)
{ my $CONFIG=shift;
  my $gramaBase=shift;

  my $resul=sub
  { my ($nada,$fichconf)=@_;
    our %ConfParser;

    #Carga de la gramática
    require $gramaBase;

    #Lectura de fichero de configuración
    LeeFichConf(%$CONFIG,%ConfParser,$fichconf);
  };

  return $resul;
}

#Returns the Dumper of the CONFIG hash with the values of certain keys hidden
sub DumpConfig(\%;$@)
{
  my $CONFIG = shift;
  my $extraSTR = shift || "";
  my @keys2embezzle = @_;

  my @lines = split( /\n/, Dumper($CONFIG) );

  foreach my $key (@keys2embezzle)
  {
    #my $regex=qr("^(\s*'$key' =>)\s*'[^']*',");
    my $regex = qr#^(\s*'$key'\s+=>\s+)'.*',#;
    map { s/$regex/$1 '*************'/ } @lines;
    #map { ( $_ =~ m/$regex/ ) and print "---- $_\n" } @lines;
  }

  return "$extraSTR" . join( "\n", @lines );
}

sub do_untaint($)
{
  my $arg = shift;

  unless ( $arg =~ m#^(((([\w_.]|-)*)/)*(([\w_.]|-)+))$# )
  {    #allow filename to be [a-zA-Z0-9_]
    die("Tainted");
  }
  return $1;
};

1;

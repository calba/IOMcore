package IOMCore::FichConf;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = qw(LeeFichConf ParseFich GenConfParser LeeFichConfParser);
@EXPORT_OK   = qw(LeeFichConf ParseFich GenConfParser LeeFichConfParser);

##########################################################################

use strict;
use diagnostics;
use FindBin qw($Bin);
use lib "$Bin/..";

use Data::Dumper;

use IOMCore::FichLog;

sub LeeFichConfParser($);
sub GenConfParser(\%);
sub EliminaDuplisArray(\@);
sub HazLimpieza(\%);
sub LeeFichConf(\%\%$);

sub LeeFichConf(\%\%$)
{ my $CONFIG=shift;
  my $ConfParser=shift;
  my $fichconf=shift;

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

    next unless (defined($valor));

    LOO: {
     if(defined($PARSECONF{'BASES'}{$clave}))
     { if ($PARSECONF{'BASES'}{$clave}{'TIPO'} eq "\$")
       { $CONFIG->{$clave}=$valor;
       } else
       { push (@{$CONFIG->{$clave}},$valor);
       };
       next LOO;
     };
     if (defined($PARSECONF{'CLAVES'}{$clave}))
     { $MODO=$clave;
       $VALMODO=$valor;
       next LOO;
     };
     if ($MODO && ($VALMODO ne "") && defined($PARSECONF{'SUBBASES'}{$MODO}{$clave}))
     { if ($PARSECONF{'SUBBASES'}{$MODO}{$clave}{'TIPO'} eq "\$")
       { $CONFIG->{$MODO}{$VALMODO}{$clave}=$valor;
       } else
       { push (@{$CONFIG->{$MODO}{$VALMODO}{$clave}},$valor);
       };
       next LOO;
     };
     if ($clave =~ m/^FIN$/)
     { $MODO="";
       $VALMODO="";
       next LOO;
     };
     printLOG(%FLvoid,"CONF: ($fichconf:$.) Clave: $clave desconocida en $linea");
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
      { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Configuracion de parser contiene FIN en BASE");
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
      { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Configuracion de parser contiene una SUBCLAVE llamada FIN");
        next;
      };

      if (defined($RESUL{'BASES'}{$clave}))
      { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Intenta definir una subclave igual que una clave base ($clave)");
        next;
      };

      foreach $subclave (@{$ConfBase->{'CLAVEPRI'}{$clave}{'CLAVESEC'}})
      { my ($tipo,$nombre);
        next unless ($subclave);

        $subclave =~ m#^(\$|@)?(.+)$# ;
        $tipo=$1;
        $nombre=uc($2);

        if ($nombre =~ m#^(FIN)$# )
        { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Configuracion de parser contiene FIN como SUBCLAVE de $clave");
          next;
        };

        if (defined($RESUL{'BASES'}{$nombre}))
        { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Intenta definir una subclave igual que una clave base ($nombre)");
          next;
        };

        if (defined($RESUL{'CLAVES'}{$nombre}))
        { printLOG(%FLvoid,"IOMCore::FichConf: ORROR: Intenta definir una subclave igual que una clave base ($nombre)");
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
  @{$array}=(sort (keys %hashaux));
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

sub LeeFichConfParser($)
{ my $fichero=shift;
  my %RESUL=();

  my %ConfFichParser= ( 'BASE' => [ '@BASE' ],
                        'CLAVEPRI' => { 'CLAVEPRI' => { 'CLAVESEC' => [ '@CLAVESEC' ] }}
                      );
  LeeFichConf(%RESUL,%ConfFichParser,$fichero);

  return %RESUL;
};
  
1;

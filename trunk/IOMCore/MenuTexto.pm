package IOMCore::MenuTexto;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line,for MakeMaker
@ISA = qw(Exporter);

@EXPORT_OK = @EXPORT = qw( CreaModo AddOpcion CreaOpcion VuelcaMenu
                           OrdenOpciones
                         );

##########################################################################

use strict;
use diagnostics;
use FindBin qw($Bin);
use lib "$Bin/..";
use Data::Dumper;

use IOMCore::FichLog;

sub CreaMenu(\%$;\%);
sub AddOpcion(\%$$\%);
sub CreaOpcion($$;$$$);
sub VuelcaMenu(\%$$;$$$);


sub OrdenOpciones(\%$$$);

sub CreaModo(\%$;\%)
{ my $CONFIG=shift;
  my $MODO=shift;
  my $MENU=shift;
  
  if (defined($CONFIG->{'_MENUSES'}{$MODO}))
  { printLOG(%$CONFIG,"IOMCore::MenuTexto: el modo $MODO ya existía. Saliendo");
    return;
  };
  
  if ($MENU)
  { %{$CONFIG->{'_MENUSES'}{$MODO}}=[%$MENU];
  } else
  { %{$CONFIG->{'_MENUSES'}{$MODO}}=();
  };
};

sub AddOpcion(\%$$\%)
{ my $CONFIG=shift;
  my $MODO=shift;
  my $tecla=shift;
  my $accion=shift;

  if (defined($CONFIG->{'_MENUSES'}{$MODO}{$tecla}))
  { printLOG(%$CONFIG,"IOMCore::MenuTexto: tecla $tecla en el modo $MODO ya ".
                      "existía. Saliendo");
    return;
  };
  
  %{$CONFIG->{'_MENUSES'}{$MODO}{$tecla}}=%$accion;
};

sub VuelcaMenu(\%$$;$$$)
{ my $CONFIG=shift;
  my $MODO=shift;
  my $COLUMNAS=shift;
  my $accAntes=shift;
  my $accDespues=shift;
  my $accSalto=shift;
  
  my ($o,%menu,$longAcum);
   
  do
  { printLOG(%$CONFIG,"IOMCore::MenuTexto: el modo $MODO no existe. Saliendo");
    return;
  } unless (defined($CONFIG->{'_MENUSES'}{$MODO}));
  
  %menu=%{$CONFIG->{'_MENUSES'}{$MODO}};
  
  $longAcum=0;
  &$accAntes($longAcum,$COLUMNAS) if defined($accAntes);
  
  foreach $o (sort { OrdenOpciones(%$CONFIG,$MODO,$a,$b) } keys %menu)
  { my ($longi);
    
    $longi=$menu{$o}{'longi'}||length(sprintf("%s - %s. ",$o,$menu{$o}{'texto'}));
    if ($longAcum+$longi > $COLUMNAS)
    { if (defined($accSalto))
      { &$accSalto()
      } else
      { print "\n\r";
      };  
      $longAcum=0;
    };
    
    if (defined($menu{$o}{'mostrar'}))
    { &{$menu{$o}{'mostrar'}}();
    } else
    { printf("%s - %s ",$o,$menu{$o}{'texto'});      
    };
    
    $longAcum+=$longi;
  };
  &$accDespues($longAcum,$COLUMNAS) if defined($accDespues);
};

sub CreaOpcion($$;$$$)
{ my $tecla=shift;
  my $texto=shift;
  my $longi=shift||length(sprintf("%s - %s ",$tecla,$texto));
  my $mostrar=shift||printf("%s - %s ",$tecla,$texto);
  my $orden=shift||0;
  
  my %resul;
  
  $resul{'tecla'}=$tecla;
  $resul{'texto'}=$texto;
  $resul{'longi'}=$longi;
  $resul{'mostrar'}=$mostrar;
  $resul{'orden'}=$orden;
  
  return \%resul;
};

sub OrdenOpciones(\%$$$)
{ my $CONFIG=shift;
  my $MODO=shift;
  my $a=shift;
  my $b=shift;
  
  printLOG(%$CONFIG,Dumper($CONFIG->{'_MENUSES'},$CONFIG->{'_MENUSES'}{$MODO}{$a},$CONFIG->{'_MENUSES'}{$MODO}{$b}));
  return ($CONFIG->{'_MENUSES'}{$MODO}{$a}{'orden'}||0) <=> 
                         ($CONFIG->{'_MENUSES'}{$MODO}{$b}{'orden'}||0);
}

##########################################################################

1;
 
package IOMCore::ConsultaBD;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = @EXPORT_OK= qw(EjecutaConsultaBD ConectarBD 
                              PreparaSentenciaBD EjecutaSentenciaBD
                              EjecutaSentenciaPrep EjecutaConsultaPrep );
%EXPORT_TAGS = ( );

##########################################################################

use DBI;
use IOMCore::FichLog;

sub ConectarBD(\%;$);
sub PreparaSentenciaBD(\%$);
sub EjecutaSentenciaBD(\%$;@);
sub EjecutaSentenciaPrep(\%$;@);
sub EjecutaConsultaBD(\%$;@);
sub EjecutaConsultaPrep(\%$;@);


sub ConectarBD(\%;$)
{ my $CONFIG=shift;
  my $autocommit=shift||0;
  #Conexión a la base de datos con autocommit
  $CONFIG->{'DBH'} = DBI->connect($CONFIG->{'BD_DSN'},
                                  $CONFIG->{'BD_USER'},
                                  $CONFIG->{'BD_PASSWORD'},
                                  { RaiseError => 0,
                                    PrintError => 1,
                                    AutoCommit => $autocommit,
                                  });
  if (!$CONFIG->{'DBH'})
  { return "Error connecting: ".$DBI::errstr;
  };
  return 0;
} # ConectarBDD()

#PreparaSentenciaBD(%CONFIG $sentSQL )
#Prepara una sentencia (comprueba que es correcta) y devuelve el handle de la
#sentencia o undef si hubo problemas.
#Si hubo problemas deja el mensaje en el LOG.
#La ventaja es que es una ejecución controlada
#Se pasa una sentencia SQL (se admiten placeholders)
#Se ejecuta contra el Handle de BD que está en $CONFIG{'DBH'}

sub PreparaSentenciaBD(\%$)
{ my $CONFIG=shift;
  my $sentSQL=shift;

  my ($sql,$resul);

  eval
  { $CONFIG->{'DBH'}->{RaiseError}=1;
    $sql=$CONFIG->{'DBH'}->prepare($sentSQL);

  };
  if ($@)
  { printLOG(%{$CONFIG},"EjecutaConsulta: Fallo en prepare. Sent:\"$sentSQL\"",
                " Error: $@");
    return undef;
  } else
  { return $sql;
  };
};

#EjecutaSentenciaBD(%CONFIG $sentSQL @params)
#Ejecuta una sentencia (la prepara y la ejecuta) y devuelve el resultado de la
#sentencia o undef si hubo problemas.
#Si hubo problemas deja el mensaje en el LOG.
#La ventaja es que es una ejecución controlada
#Se pasa una sentencia SQL (se admiten placeholders)
#Se pasan los parametros que ocupan los "placeholders"
#Se ejecuta contra el Handle de BD que está en $CONFIG{'DBH'}

sub EjecutaSentenciaBD(\%$;@)
{ my $CONFIG=shift;
  my $sentSQL=shift;
  my @resto=@_;

  my ($sentprep,$sql,$resul);

  $sentprep=PreparaSentenciaBD(%$CONFIG,$sql);

  return undef unless defined($sentprep);

  return EjecutaSentenciaPrep(%$CONFIG,$sentprep,@resto);

};

#EjecutaSentenciaPrep(%CONFIG $sentSQL @params)
#Ejecuta una sentencia que ya se ha pasado por el prepare 
#y devuelve el resultado de la
#sentencia o undef si hubo problemas.
#Si hubo problemas deja el mensaje en el LOG.
#La ventaja es que es una ejecución controlada
#Se pasa una sentencia SQL (se admiten placeholders)
#Se pasan los parametros que ocupan los "placeholders"
#Se ejecuta contra el Handle de BD que está en $CONFIG{'DBH'}
sub EjecutaSentenciaPrep(\%$;@)
{ my $CONFIG=shift;
  my $sentprep=shift;
  my @resto=@_;

  my ($resul);

  eval
  { $CONFIG->{'DBH'}->{RaiseError}=1;
    $resul=$sentprep->execute(@resto);
  };
  if ($@)
  { printLOG(%{$CONFIG},"EjecutaSentenciaPrep: Fallo en execute. Sent:\"",
             $sentprep,"\" Param:\"", join("|",@resto)," Error: $@");
    return undef;
  };

  return $resul;
};

#EjecutaConsultaBD(%CONFIG $sentSQL @parametros)
#Ejecución controlada de una sentencia select .
#Se pasa una sentencia SQL (se admiten placeholders)
#Se pasan los parametros que ocupan los "placeholders"
#Se ejecuta contra el Handle de BD que está en $CONFIG{'DBH'}
#La sentencia se ejecuta con selectall_arrayref y devuelve un array de hashes
#Cuyas claves son los campos del select
sub EjecutaConsultaBD(\%$;@)
{ my $CONFIG=shift;
  my $sentSQL=shift;
  my @resto=@_;

  my ($sentprep,$sql,$resul);

  $sentprep=PreparaSentenciaBD(%$CONFIG,$sentSQL);

  return undef unless defined($sentprep);

  return EjecutaConsultaPrep(%$CONFIG,$sentprep,@resto);

};

#EjecutaConsultaPrep(%CONFIG $sentSQL @parametros)
#Ejecución controlada de una sentencia select ya preparada.
#Se pasa una sentencia SQL (se admiten placeholders)
#Se pasan los parametros que ocupan los "placeholders"
#Se ejecuta contra el Handle de BD que está en $CONFIG{'DBH'}
#La sentencia se ejecuta con selectall_arrayref y devuelve un array de hashes
#Cuyas claves son los campos del select
sub EjecutaConsultaPrep(\%$;@)
{ my $CONFIG=shift;
  my $sentprep=shift;
  my @resto=@_;

  my ($resul);

  eval
  { $CONFIG->{'DBH'}->{RaiseError}=1;
    $resul=$CONFIG->{'DBH'}->selectall_arrayref($sentprep,
                                                { Columns=>{} },
                                                  @resto);
  };
  if ($@)
  { printLOG(%{$CONFIG},"EjecutaConsulta: Fallo en selectall_arrayref. ",
                        "Sent:\"$sentprep\" Param:\"",
                        join("|",@resto)," Error: $@");
    return undef;
  };

  return $resul;
};

1;

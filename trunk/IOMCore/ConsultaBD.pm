package IOMCore::ConsultaBD;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = @EXPORT_OK= qw(EjecutaConsultaBD);
%EXPORT_TAGS = ( );

##########################################################################

use DBI;
use IOMCore::FichLog;

sub EjecutaConsultaBD(\%$;@);

#EjecutaConsulta(%CONFIG $sentSQL @parametros)
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

  my ($sql,$resul);

  eval
  { $CONFIG->{'DBH'}->{RaiseError}=1;
    $sql=$CONFIG->{'DBH'}->prepare($sentSQL);

  };
  if ($@)
  { printLOG(%{$CONFIG},"EjecutaConsulta: Fallo en prepare. Sent:\"$sentSQL\"",
                " Error: $@");
    return undef;
  };
  eval
  { $CONFIG->{'DBH'}->{RaiseError}=1;
    $resul=$CONFIG->{'DBH'}->selectall_arrayref($sql,
                                                { Columns=>{} },
                                                  @resto);
  };
  if ($@)
  { printLOG(%{$CONFIG},"EjecutaConsulta: Fallo en selectall_arrayref. Sent:\"$sentSQL\" Param:\"",
                join("|",@resto)," Error: $@");
    return undef;
  };

  return $resul;
};

1;


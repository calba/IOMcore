package IOMCore::DataFacts;

use strict;
use warnings;

BEGIN
{
  use Exporter ();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK );

  # if using RCS/CVS, this may be preferred
  $VERSION = do { my @r = ( q$Revision: 1.3 $ =~ /\d+/g ); sprintf "%d." . "%02d" x $#r, @r }; # must be all one line, for MakeMaker
  @ISA = qw(Exporter);
  @EXPORT_OK = @EXPORT = qw( OpenFacts CloseFacts );

# ReopenFacts GetOpenFacts GetLatestClosedFacts
# as well as any optionally exported functions

}

use IOMCore::ConsultaBD;
use IOMCore::FichLog;
use IOMCore::AuxPerl;

sub OpenFact(\%$$$$$$);
sub OpenFacts(\%$$\%$;$);

sub CloseFacts(\%$$$$;$);
sub CloseFactByID(\%$$$);

sub GetWholeOpenFacts(\%$$);
sub GetOpenFacts(\%$$);

=pod
sub ReopenFacts(\%$$\%$;$);
sub GetOpenFact(\%$$$);
sub GetFacts(\%$$);
sub GetLatestClosedFacts(\%$$);
=cut

##############################################################################
##############################################################################
##############################################################################

#Abre un hecho de clave indicada a un objeto.
sub OpenFact(\%$$$$$$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;
  my $clave   = shift;
  my $valor   = shift;
  my $ruser   = shift;
  my $tini    = shift || time();

  my ( %fact, $resul );
  my $sentCreaFact = qq/
                  insert into DATAFACTS (TIPOOBJ,OBJ_id,CLAVE,VALOR,TINI,IDUSR)
                                 values (?,?,?,?,FROM_UNIXTIME(?),?)
                      /;

  if ( NotEmpty($valor) )
  {
    EjecutaSentenciaBD( %$CONFIG, $sentCreaFact, $tipoOBJ, $objID, $clave,
                                    $valor, $tini, $ruser )
      || do
    {
      printLOG(
        %$CONFIG,
        "OpenFact. Error al crear hecho: ",
        "($tipoOBJ,$objID,$clave,$valor, $tini). "
      );
      return 0;
    };
  }

  return 1;
}

#Compara los hechos que se pasan como parámetro con los hechos abiertos del
#objeto. Cierra los que hayan cambiado y abre los nuevos. Cierra los que hayan
#desaparecido
sub OpenFacts(\%$$\%$;$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;
  my $DATOS   = shift;
  my $ruser   = shift;
  my $tevent  = shift || time();

  my (%CURFACTS,@resul);
  @resul=();

  %CURFACTS = GetWholeOpenFacts( %$CONFIG, $tipoOBJ, $objID );

  #Compara los hechos abiertos ya existentes
  foreach my $clave ( keys %$DATOS )
  {
    if ( defined( $CURFACTS{$clave} ) )
    {
      if ( $CURFACTS{$clave}{'VALOR'} eq $DATOS->{$clave} )
      {
        delete $CURFACTS{$clave};
        next;
      }
      else
      {
        my $idfact = $CURFACTS{$clave}{'ID'};
        CloseFactByID( %$CONFIG, $idfact, $ruser, $tevent ) || do
        {
          printLOG( %$CONFIG, "Problemas al cerrar el hecho (ID:$idfact)" );
          return 0;
        };
        delete $CURFACTS{$clave};
      }
    }
    OpenFact( %$CONFIG, $tipoOBJ, $objID, $clave, $DATOS->{$clave}, $ruser,
      $tevent ) || do
    { printLOG( %$CONFIG, "Problemas al abrir el hecho ",
                              "($tipoOBJ,$objID)->{$clave}=$DATOS->{$clave}" );
      return 0;
    };
    push @resul,$clave;
  }
  #Cierra los que ya no estén
  foreach my $clave ( keys %CURFACTS )
  {
    my $idfact = $CURFACTS{$clave}{'ID'};
    CloseFactByID( %$CONFIG, $idfact, $ruser, $tevent ) || do
    {
      printLOG( %$CONFIG, "Problemas al cerrar el hecho (ID:$idfact)" );
      return 0;
    };
    delete $CURFACTS{$clave};
    push @resul,$clave;
  };
  return @resul;
}

#Cierra un hecho identificado por su número de hecho
sub CloseFactByID(\%$$$)
{
  my $CONFIG = shift;
  my $factid = shift;
  my $ruser  = shift;
  my $tfin   = shift || time();

  my ($sentSQL);

  $sentSQL = qq/
                update DATAFACTS set TFIN=FROM_UNIXTIME(?),IDUSR=?,TIMESET=NOW()
                  where ID=?
               /;

  EjecutaSentenciaBD( %$CONFIG, $sentSQL, $tfin, $ruser, $factid ) || do
  {
    printLOG( %$CONFIG, "Error al cerrar hecho: '$factid'. " );
    return 0;
  };

  return 1;
}

#Cierra todos los hechos abiertos de un objeto
sub CloseFacts(\%$$$$;$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;
  my $ruser   = shift;
  my $tfin    = shift || time();

  my ($sentSQL);

  $sentSQL = qq/
                update DATAFACTS set TFIN=FROM_UNIXTIME(?),
                                     IDUSR=?,
                                     TIMESET=NOW()
                                 where TIPOOBJ=?
                                   and OBJ_id=?
                                   and TFIN is NULL
               /;

  EjecutaSentenciaBD( %$CONFIG, $sentSQL, $tfin, $ruser, $tipoOBJ, $objID )
    || do
  {
    printLOG( %$CONFIG,
      "Error al cerrar hechos para objeto ($tipoOBJ,$objID)." );
    return 0;
  };
  return 1;
}

#Devuelve los hechos abiertos de un OBJETO. Devuelve registros completos
sub GetWholeOpenFacts(\%$$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;

  my ( %RESUL, $aux );

  my $sentSQL = qq/
                  select * from DATAFACTS where TIPOOBJ=?
                                            and OBJ_id=?
                                            and TFIN is NULL
                /;
  %RESUL = ();

  #El UID ya ha existido, se buscan los hechos abiertos existentes
  $aux = EjecutaConsultaBD( %$CONFIG, $sentSQL, $tipoOBJ, $objID );

  foreach my $i (@$aux)
  {
    $RESUL{ $i->{'CLAVE'} } = $i;
  }
  return %RESUL;
}

#Devuelve los hechos abiertos de un OBJETO. Devuelve sólo valores
sub GetOpenFacts(\%$$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;

  my ( %RESUL, %aux );

  %RESUL = ();

  %aux = GetWholeOpenFacts( %$CONFIG, $tipoOBJ, $objID );

  foreach my $clave ( keys %aux )
  {
    $RESUL{$clave} = $aux{$clave}{'VALOR'};
  }
  return %RESUL;
}

=pod
sub ReopenFacts(\%$$\%$;$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;
  my $DATOS   = shift;
  my $ruser   = shift;
  my $tevent  = shift || time();

  my ( %tempfacts, %lastclosed );

  %lastclosed = %{ GetLatestClosedFacts( %$CONFIG, $tipoOBJ, $objID ) };

  foreach my $clave ( keys %lastclosed )
  {
    $tempfacts{$clave} = $lastclosed{$clave}{'VALOR'};
  }
  foreach my $clave ( keys %$DATOS )
  {
    $tempfacts{$clave} = $DATOS->{$clave};
  }
  foreach my $clave ( keys %tempfacts )
  {
    OpenFact( %$CONFIG, $tipoOBJ, $objID, $clave, $tempfacts{$clave}, $ruser,
      $tevent );
  }
}


#Devuelve el hecho abierto 'clave' de una persona 'persid'
sub GetOpenFact(\%$$$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;
  my $clave   = shift;

  my ( %RESUL, $aux );

  my $sentSQL = qq/
                  select * from DATAFACTS where TIPOOBJ=?
                                            and OBJ_id=?
                                            and CLAVE=?
                                            and TFIN is NULL
                /;

  $aux = EjecutaConsultaBD( %$CONFIG, $sentSQL, $tipoOBJ, $objID, $clave );

  %RESUL = ();

  if (@$aux)
  {
    %RESUL = %{ $aux->[0] };
  }

  return %RESUL;
}

#Devuelve todos los hechos, abiertos y cerrados, de un objeto
sub GetFacts(\%$$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;

  my ( %RESUL, $aux );

  my $sentSQL = qq/
                    select * from DATAFACTS where TIPOOBJ=?
                                              and OBJ_id=?
                  /;

  $aux = EjecutaConsultaBD( %$CONFIG, $sentSQL, $tipoOBJ, $objID );

  %RESUL = ();

  if (@$aux)
  {
    %RESUL = %{ $aux->[0] };
  }

  return %RESUL;
}

sub GetLatestClosedFacts(\%$$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $objID   = shift;

  my ( %RESUL, $aux, $ultclave );

  my $sentSQL = qq/
                    select * from DATAFACTS where TIPOOBJ=?
                                              and OBJ_id=?
                  /;

  $aux = EjecutaConsultaBD( %$CONFIG, $sentSQL, $tipoOBJ, $objID );

  %RESUL = ();

  if (@$aux)
  {
    my ( %auxfacts, $tmax, $open );
    $open = 0;
    $tmax = 0;
    foreach my $fact (@$aux)
    {
      my ($tfact);
      if ( defined( $tfact = $fact->{'TFIN'} ) )
      {
        ( $tmax = $tfact ) if ( $tfact > $tmax );
      }
      else
      {
        $open = 1;
      }

      push @{ $auxfacts{ $fact->{'TFIN'} || -1 } }, $fact;
    }

    $tmax = -1 if ($open);

    foreach my $fact ( @{ $auxfacts{$tmax} } )
    {
      %{ $RESUL{ $fact->{'CLAVE'} } } = %$fact;
    }
  }
  return \%RESUL;
}

sub GetOpenFactsByClave(\%$$)
{
  my $CONFIG  = shift;
  my $tipoOBJ = shift;
  my $clave   = shift;
  my ( $aux, %RESUL );

  my $sentSQL = qq/
                    select * from DATAFACTS where TIPOOBJ=?
                                              and CLAVE=?
                                              and TFIN is NULL
                  /;

  $aux = EjecutaConsultaBD( %$CONFIG, $sentSQL, $tipoOBJ, $clave );

  %RESUL = ();

  if (@$aux)
  {
    my ( %auxfacts, $tmax, $open );
    $open = 0;
    $tmax = 0;
    foreach my $fact (@$aux)
    {
      my ($tfact);
      if ( defined( $tfact = $fact->{'TFIN'} ) )
      {
        ( $tmax = $tfact ) if ( $tfact > $tmax );
      }
      else
      {
        $open = 1;
      }

      push @{ $auxfacts{ $fact->{'TFIN'} || -1 } }, $fact;
    }

    $tmax = -1 if ($open);

    foreach my $fact ( @{ $auxfacts{$tmax} } )
    {
      %{ $RESUL{ $fact->{'CLAVE'} } } = %$fact;
    }
  }
  return \%RESUL;
}
=cut

1;

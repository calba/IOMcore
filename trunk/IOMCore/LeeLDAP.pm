package IOMCore::LeeLDAP;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
#$VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA = qw(Exporter);

@EXPORT      = @EXPORT_OK =  qw( SacaEntradaLDAP SacaEntradaLDAPDN
                                 ValorLDAP ExisteEntradaLDAP
                                 AddEntradaLDAP  CierraConexionLDAP
                                 BorraEntradaLDAP ModificaEntradaLDAP 
                                 AddOrModify );
%EXPORT_TAGS = ( );

##########################################################################

use Net::LDAP;
use IOMCore::FichLog;
use Data::Dumper;

sub SacaEntradaLDAP(\%$$;@);
sub SacaEntradaLDAPDN(\%$);
sub ValorLDAP(\%$;$);
sub ConectaServidorLDAP(\%);
sub ExisteEntradaLDAP(\%$);
sub AddEntradaLDAP(\%$\%);
sub ModificaEntradaLDAP(\%$\@);
sub CierraConexionLDAP(\%);
sub AddOrModify(\%$$);

sub SacaEntradaLDAP(\%$$;@)
{ my $CONFIG=shift;
  my $filtro=shift;
  my $campoindice=shift;
  my @param=@_;
  my $contnoind=0;

  my ($ldap,$mesg,%resul,$entry);

  do
  { printLOG(%$CONFIG,"Error en la conexi&oacute;n a ",$CONFIG->{'LDAP_HOST'},
                      ". Consulte con el administrador.");
    return %resul;
  } unless(defined($ldap=ConectaServidorLDAP(%$CONFIG)));

  $ldap->bind ;    # an anonymous bind

  $mesg = $ldap->search (  # perform a search
                          base   => $CONFIG->{'LDAP_BASE'},
                          filter => $filtro,
                          @param
                        );
  $mesg->code && do
  { #Mensaje de error
    return %resul;
  };

  foreach $entry ($mesg->all_entries)
  { my (%aux,$attr,$claveind);
    my $huboind=0;

    %aux=();
    #Extrae el DN y lo añade siempre
    $aux{'dn'}{$entry->dn()}++;
    foreach $attr ($entry->attributes)
    { map { $aux{$attr}{$_}++; }  ($entry->get_value($attr));
      if ($attr eq $campoindice)
      { $huboind=1;
      };
    }
    $claveind=$huboind?(keys %{$aux{$campoindice}})[0]:"noind".$contnoind++;
    %{$resul{$claveind}}=%aux;
  }

  return %resul;
};

sub ValorLDAP(\%$;$)
{ my $entradaLDAP=shift;
  my $clave=shift;
  my $separador=shift||"";

  my $resul;

  return "" unless defined $entradaLDAP->{$clave};

  $resul=join($separador,sort keys %{$entradaLDAP->{$clave}});

  return $resul;
};

sub ConectaServidorLDAP(\%)
{ my $CONFIG=shift;
  my $ldap;

  if (defined($CONFIG->{'xLDAP'}))
  { $ldap=$CONFIG->{'xLDAP'};
  } else
  { my ($host);
    $host = $CONFIG->{'LDAP_HOST'} || 'localhost';
    defined($CONFIG->{'LDAP_BASE'}) || do
    { printLOG(%$CONFIG,"No se ha definido la base del directorio LDAP de $host.");
      return $ldap;
    };
    $ldap = Net::LDAP->new($host) || do
    { printLOG(%$CONFIG,"No me pude conectar al servidor LDAP en $host. Consulte al administrador. Mensaje: $@");
      return $ldap;
    };
    $CONFIG->{'xLDAP'}=$ldap;
  };
  return $ldap;
};

sub ExisteEntradaLDAP(\%$)
{ my $CONFIG=shift;
  my $dn=shift;
  my %auxi;

  %auxi=SacaEntradaLDAPDN(%$CONFIG,$dn);


  return (scalar keys %auxi)>0;
};

sub AddEntradaLDAP(\%$\%)
{ my $CONFIG=shift;
  my $dn=shift;
  my $entrada=shift;
  my $resul=0;

  my ($ldap,$mesg,@auxi);

  do
  { printLOG(%$CONFIG,"Error en la conexi&oacute;n a ",$CONFIG->{'LDAP_HOST'},
                      ". Consulte con el administrador.");
    return $resul;
  } unless(defined($ldap=ConectaServidorLDAP(%$CONFIG)));

  $mesg = $ldap->bind( $CONFIG->{'LDAP_BIND'}, 
                       password => $CONFIG->{'LDAP_PASSWD'} );

  if($mesg->code)
  { #Mensaje de error
    printLOG(%$CONFIG,"AddEntradaLDAP: Problemas al hacer BIND: ",
                        $mesg->error);
    $resul=0;
    return $resul;
  }
  @auxi=%{$entrada};

  $mesg = $ldap->add( $dn,
                      attrs => [ @auxi],
                    );

  if($mesg->code)
  { #Mensaje de error
    printLOG(%$CONFIG,"AddEntradaLDAP:: Problemas al hacer ADD: ",
                        $mesg->error);
    $resul=0;
  } else
  { $resul=1;
  };

  return $resul;
};

sub BorraEntradaLDAP(\%$)
{ my $CONFIG=shift;
  my $dn=shift;
  my $resul=0;

  my ($ldap,$mesg);

  do
  { printLOG(%$CONFIG,"Error en la conexi&oacute;n a ",$CONFIG->{'LDAP_HOST'},
                      ". Consulte con el administrador.");
    return $resul;
  } unless(defined($ldap=ConectaServidorLDAP(%$CONFIG)));

  $mesg = $ldap->bind( $CONFIG->{'LDAP_BIND'}, 
                       password => $CONFIG->{'LDAP_PASSWD'} );

  if($mesg->code)
  { #Mensaje de error
    printLOG(%$CONFIG,"BorraEntradaLDAP: Problemas al hacer BIND: ",
                        $mesg->error);
    $resul=0;
    return $resul;
  }

  $mesg = $ldap->delete($dn);

  if($mesg->code)
  { #Mensaje de error
    printLOG(%$CONFIG,"BorraEntradaLDAP: Problemas al hacer DELETE: ",
                        $mesg->error);
    $resul=0;
  } else
  { $resul=1;
  };

  return $resul;
};

sub CierraConexionLDAP(\%)
{ my $CONFIG=shift;

  if (defined($CONFIG->{'xLDAP'}))
  { $CONFIG->{'xLDAP'}->unbind;
    delete $CONFIG->{'xLDAP'};
  };
};


sub ModificaEntradaLDAP(\%$\@)
{ my $CONFIG=shift;
  my $dn=shift;
  my $cambios=shift;
  my $resul=0;

  my ($ldap,$mesg,@auxi);

  do
  { printLOG(%$CONFIG,"Error en la conexi&oacute;n a ",$CONFIG->{'LDAP_HOST'},
                      ". Consulte con el administrador.");
    return $resul;
  } unless(defined($ldap=ConectaServidorLDAP(%$CONFIG)));

  $mesg = $ldap->bind( $CONFIG->{'LDAP_BIND'}, 
                       password => $CONFIG->{'LDAP_PASSWD'} );

  if($mesg->code)
  { #Mensaje de error
    printLOG(%$CONFIG,"ModificaEntradaLDAP: Problemas al hacer BIND: ",
                        $mesg->error);
    $resul=0;
    return $resul;
  }
  @auxi=@{$cambios};

printLOG(%$CONFIG,"ModificaEntradaLDAP: Antes de modify", Dumper($cambios));
  $mesg = $ldap->modify( $dn,
                      'changes' => [ @auxi ],
                    );
printLOG(%$CONFIG,"ModificaEntradaLDAP: Despues de modify", Dumper($mesg));

  if($mesg->code)
  { #Mensaje de error
    printLOG(%$CONFIG,"ModificaEntradaLDAP: Problemas al hacer MODIFY: ",
                        $mesg->error);
    $resul=0;
  } else
  { $resul=1;
  };

  return $resul;
};

sub SacaEntradaLDAPDN(\%$)
{ my $CONFIG=shift;
  my $dn=shift;

  my ($ldap,$mesg,%resul,$entry);

  do
  { printLOG(%$CONFIG,"Error en la conexi&oacute;n a ",$CONFIG->{'LDAP_HOST'},
                      ". Consulte con el administrador.");
    return %resul;
  } unless(defined($ldap=ConectaServidorLDAP(%$CONFIG)));

  $ldap->bind ;    # an anonymous bind
  $mesg = $ldap->search (  # perform a search
                          base   => $dn,
                          scope => 'base',
                          filter => "objectclass=*",
                        );
  $mesg->code && do
  { #Mensaje de error
    return %resul;
  };

  return %resul unless (scalar $mesg->all_entries);

  foreach $entry ($mesg->all_entries)
  { my (%aux,$attr);

    %aux=();
  
    foreach $attr ($entry->attributes)
    { map { $aux{$attr}{$_}++; }  ($entry->get_value($attr));
    }
    %resul=%aux;
  }
  return %resul;
};

sub AddOrModify(\%$$)
{ my $actual=shift;
  my $campo=shift;
  my $valor=shift;
  my $haycampo=0;
  my @resul;

  $haycampo=defined($actual->{$campo});

  if ($valor)
  { if ($haycampo)
    { @resul = ( 'replace' => [ $campo => $valor ]);
    } else
    { @resul = ( 'add' => [ $campo => $valor ]);
    }; 
  } else
  { if ($haycampo)
    { @resul = ( 'delete' => [ $campo => [] ]);
    } else
    { @resul = ();
    }; 
  };
  return @resul;
};





1;

=head1 NAME

IOMCore::LeeLDAP - Efectua una consulta LDAP y almacena las respuestas en un hash.

=head1 SYNOPSIS

  use IOMCore::LeeLDAP;

  %CONFIG=( 'LDAP_HOST'=>'myhost',
            'LDAP_BASE'=>'mybase');

  %resul=SacaEntradaLDAP( %CONFIG, "mifiltro");
  

=head1 DESCRIPCION

  Esta clase es un recubrimiento de Net::LDAP para presentar los resultados de
  una forma conveniente a las necesidades de las aplicaciones.

  El formato de salida es un hash indexado por el campo uid de cada entrada 
  cuyos valores son hashes de las entradas indexados por el atributo. Cada 
  atributo es a su vez un hash.

  Ejemplo de la salida:

$VAR1 = {
          'calba' => {
                       'employeeType' => {
                                           'ING' => 1
                                         },
                       'cn' => {
                                 'CESAR ALBA PEREZ' => 1
                               },
                       'objectClass' => {
                                          'inetorgperson' => 1,
                                          'usuario' => 1,
                                          'organizationalRole' => 1,
                                          'top' => 1,
                                          'Person' => 1,
                                          'organizationalperson' => 1
                                        },
                     }
        };

  REQUIERE tener instalado Net::LDAP

=head1 Version

$Id: LeeLDAP.pm,v 1.4 2008-03-17 06:48:52 calba Exp $

=head1 Cambios

$Log: not supported by cvs2svn $
Revision 1.3  2004/12/10 09:15:28  calba
Añadidas nuevas funciones

Revision 1.2  2003/07/09 18:40:12  calba
- Añadida función ValorLDAP:  a partir de una entrada saca el contenido de una variable. Si es una lista, hace un join con un separador que se pasa como parametro.

Revision 1.1  2003/06/17 18:12:21  calba
Carga inicial.


=cut

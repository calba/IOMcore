package IOMCore::LeeLDAP;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
#$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA = qw(Exporter);

@EXPORT      = qw( SacaEntradaLDAP ValorLDAP );
@EXPORT_OK   = qw( SacaEntradaLDAP ValorLDAP );
%EXPORT_TAGS = ( );

##########################################################################

use Net::LDAP;

sub SacaEntradaLDAP(\%$);
sub ValorLDAP(\%$;$);

sub SacaEntradaLDAP(\%$)
{ my $CONFIG=shift;
  my $filtro=shift;

  my ($ldap,$mesg,%resul,$host,$entry);

  $host = $CONFIG->{'LDAP_HOST'} || 'localhost';
  defined($CONFIG->{'LDAP_BASE'}) || do
  { #Mensaje de error
    return %resul;
  };
  $ldap = Net::LDAP->new($CONFIG->{'LDAP_HOST'}) || do
  { #Mensaje de error
    return %resul;
  };

  $ldap->bind ;    # an anonymous bind

  $mesg = $ldap->search (  # perform a search
                          base   => $CONFIG->{'LDAP_BASE'},
                          filter => $filtro
                        );
  $mesg->code && do
  { #Mensaje de error
    return %resul;
  };

  foreach $entry ($mesg->all_entries)
  { my (%aux,$attr);

    %aux=();
  
    foreach $attr ($entry->attributes)
    { map { $aux{$attr}{$_}++; }  ($entry->get_value($attr));
    }
    %{$resul{(keys %{$aux{'uid'}})[0]}}=%aux;
  }

  $ldap->unbind;   # take down session

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

$Id: LeeLDAP.pm,v 1.2 2003-07-09 18:40:12 calba Exp $

=head1 Cambios

$Log: not supported by cvs2svn $
Revision 1.1  2003/06/17 18:12:21  calba
Carga inicial.


=cut

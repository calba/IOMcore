package IOMCore::WebMensajes;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA = qw(Exporter);

@EXPORT      = @EXPORT_OK   = qw( Mensaje PonMensajes ListaPopUp ComponURL);
%EXPORT_TAGS = ( );

##########################################################################

use IOMCore::FichLog;
use CGI qw/:standard/;

sub ComponURL($;$);
sub ListaPopUp(\%$$$$);
sub Mensaje(\%;@);
sub PonMensajes(\%);

sub Mensaje(\%;@)
{ my $CONFIG=shift;
  push @{$CONFIG->{'MENSAJES'}},join("",@_);
};

##FUNCION PonMensajes(@mensajes)
sub PonMensajes(\%)
{ my $CONFIG=shift;
  my $resul="";

  if (defined($CONFIG->{'MENSAJES'}) && @{$CONFIG->{'MENSAJES'}})
  { $resul=join("",'<TABLE BGCOLOR="#00CC00" FGCOLOR="#FF0000" WIDTH="100%">',
                   "\n",'<TR><TD>',"\n",
                   "<P>Se han producido los siguientes mensajes:</P>\n",
                   "<UL>\n",
                   (map { printLOG(%{$CONFIG},$_); "<LI>$_</LI>\n"; }
                       (@{$CONFIG->{'MENSAJES'}})),
                   "</UL>\n",
                   "</TD></TR></TABLE>\n");
  };
  return $resul;
};

##FUNCION ListaPopUp(%valores,$param,$etiqValor$etiqEtiq$defecto)
sub ListaPopUp(\%$$$$)
{ my $VALORES=shift;
  my $param=shift;
  my $etiqValor=shift;
  my $etiqEtiq=shift;
  my $defecto=shift;
  my (%etiqs,@valores,$selected,$i);

  $selected="-";
  foreach $i (sort keys %$VALORES)
  { push @valores,$VALORES->{$i}{$etiqValor};
    $etiqs{$VALORES->{$i}{$etiqValor}}=$VALORES->{$i}{$etiqEtiq};
    if ($VALORES->{$i}{$etiqValor} eq $defecto)
    { $selected=$defecto;
    };
  };

  return popup_menu(-name=>$param,
                    -values=>[@valores],
                    -default=>$selected,
                    -labels=>\%etiqs,
                    -override=>1);
};

sub ComponURL($;$)
{ my $url=shift;

  return join('/',$url,@_);
};



1;

=head1 NAME

IOMCore::

=head1 SYNOPSIS

  use IOMCore::
...

=head1 DESCRIPCION

=head1 Version

$Id: WebMensajes.pm,v 1.5 2008-05-06 22:48:33 calba Exp $

=head1 Cambios

$Log: not supported by cvs2svn $
Revision 1.4  2005/08/20 21:48:53  calba
- Error en el prototipo de ComponURL

Revision 1.3  2005/08/20 21:13:48  calba
- Añadida funcion ComponURL para aplicaciones tipo REST (en las que la URL tiene mucho significado)
- Prototipadas las funciones

Revision 1.2  2004/12/10 09:15:28  calba
A�adidas nuevas funciones

Revision 1.1  2003/07/10 08:40:29  calba
Carga inicial


=cut

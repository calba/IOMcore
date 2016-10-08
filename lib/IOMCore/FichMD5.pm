package IOMCore::FichMD5;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(CalcMD5Cadena CalcMD5Fichero CalcOID);
%EXPORT_TAGS = ( );

##########################################################################

use Digest::MD5;

=pod
  IOMCore::FichMD5: Calcula el hash MD5

  Uso:

  use IOMCore::FichMD5;

  #Cadena 
  $hash=CalcMD5Cadena($cadena);

  #Fichero
  $hash=CalcMD5Fichero($fichero);

  #OID
  $hash=CalcOID($longitud,$cadena1,$cadena2...);

=cut

sub CalcMD5Fichero($)
{ my $file = shift || return undef;
  local *FILE;
  my ($result);

  open(FILE, $file) or do
  { print STDERR "No pude abrir $file: $!\n";
    return undef;
  };
  binmode(FILE);
  $result=Digest::MD5->new->addfile(*FILE)->hexdigest;
  close(FILE);
  return $result;
};

sub CalcMD5Cadena($)
{ my $cadena = shift || return undef;
  my $res = Digest::MD5->new;
  $res->add($cadena);
  return $res->hexdigest();
};

sub CalcOID($$;@)
{ my $longi=shift;
  my $res = Digest::MD5->new;
  $res->add(@_);
  return substr($res->hexdigest(),0,$longi);
};

1;

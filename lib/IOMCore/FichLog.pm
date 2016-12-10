package IOMCore::FichLog;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA = qw(Exporter);

@EXPORT_OK = @EXPORT = qw( printLOG printLOGmask printLOGlevel %FLvoid TRAZA );
%EXPORT_TAGS = ( );

##########################################################################

use vars qw( %FLvoid );
%FLvoid=();

sub printLOG(\%@);
sub printLOGmask(\%$@);
sub printLOGlevel(\%$@);
sub TRAZA(\%@);

sub printLOG(\%@)
{ my $CONFIG=shift;
  my $cadena;
  my ($flag)=0;
  my $linea;
  local *HANDERR;

  $cadena=join(" ",@_);
  $linea = scalar(localtime)." [$$] $cadena\n";

  if (defined($CONFIG->{'LOGFILE'}))
  { $flag=1;
    open(HANDERR,">>".$CONFIG->{'LOGFILE'}) || do
    { *HANDERR = *STDERR;
      $flag=0;
    };
  } else
  { *HANDERR = *STDERR;
  };
  print HANDERR $linea;
  close HANDERR if ($flag);
};

#Alias de printLOG (hecho para distinguir de los printLOG y para facilitar la
#eliminacion
sub TRAZA(\%@)
{ my $CONFIG=shift;
  return printLOG(%$CONFIG,@_);
};

sub printLOGlevel(\%$@)
{ my $CONFIG=shift;
  my $level=shift;

  if (defined($CONFIG->{'LOG'}) && ($level >= $CONFIG->{'LOG'}))
  { printLOG(%{$CONFIG},@_);
  };
};

sub printLOGmask(\%$@)
{ my $CONFIG=shift;
  my $mask=shift;

  if (defined($CONFIG->{'LOG'}) && ($mask & $CONFIG->{'LOG'}))
  { printLOG(%{$CONFIG},@_);
  };
};

1;

package IOMCore::FichLog;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = qw( printLOG printLOGmask printLOGlevel %FLvoid );
@EXPORT_OK   = qw( printLOG printLOGmask printLOGlevel %FLvoid );
%EXPORT_TAGS = ( );

##########################################################################

use vars qw( %FLvoid );
%FLvoid=();

sub printLOG(\%@);
sub printLOGmask(\%$@);
sub printLOGlevel(\%$@);

sub printLOG(\%@)
{ my $CONFIG=shift;
  my $cadena;
  my ($flag)=0;
  my $linea;
  local *HANDERR;

  $cadena=join("",@_);
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

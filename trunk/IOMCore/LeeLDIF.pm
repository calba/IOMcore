package IOMCore::LeeLDIF;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = qw( ldif2hash );
@EXPORT_OK   = qw( ldif2hash );
%EXPORT_TAGS = ( );

#############################################################################

sub ldif2hash($);

sub ldif2hash($)
{ my $fichname=shift;

  my ($linea,%RESUL,%provis);
  local (*HANDIN);

  if ($fichname eq "-")
  { *HANDIN=*STDIN;
  } else
  { open(HANDIN,"$fichname") || die "ORROR: ldif2hash no pudo abrir $fichname";
  };

  while (defined($linea=<HANDIN>))
  { chomp $linea;
    next if ($linea =~ m/^\s*\#/);
    if ($linea =~ m/^\s*$/)
    { if (%provis)
      { if (defined($provis{'dn'}))
        { $RESUL{$provis{'dn'}}={%provis};
        };
        %provis=();
      };
    } else
    { my ($campo,$sep,$valor);

      ($campo,$sep,$valor)=($linea =~m/(.*?)(::?) (.*)/);
      if (defined($provis{$campo}))
      { if (ref($provis{$campo}) eq "ARRAY")
        { push @{$provis{$campo}},$valor;
        } else
        { my @data;
          push @data,$provis{$campo},$valor;
          $provis{$campo}=[@data];
        };
      } else
      { $provis{$campo}=$valor;
      };
    };
  };
  if (%provis)
  { if (defined($provis{'dn'}))
    { $RESUL{$provis{'dn'}}={%provis};
    };
    %provis=();
  };

  if ($fichname ne "-")
  { close HANDIN;
  };

  return %RESUL;

};

1;


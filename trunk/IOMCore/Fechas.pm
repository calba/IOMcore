package IOMCore::Fechas;

use strict;
use warnings;

BEGIN {
use Exporter   ();
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
# if using RCS/CVS, this may be preferred
$VERSION = do { my @r = (q$Revision: 1.1.1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA         = qw(Exporter);
@EXPORT      = qw(&LeeFestivos &LeeFestivos &Dias2FechaDC &FechaDMY2Dias &FechaBD2Dias &Dias2FechaYMD &Dias2FechaDMY &Dias2DiaSem);
# as well as any optionally exported functions
@EXPORT_OK      = qw(&LeeFestivos &LeeFestivos &Dias2FechaDC &FechaDMY2Dias &FechaBD2Dias &Dias2FechaYMD &Dias2FechaDMY &Dias2DiaSem);
}

use Date::Calc qw( Date_to_Days Today Add_Delta_YMD Date_to_Text Add_Delta_Days Day_of_Week check_date );

my @DiasSem=qw( - L M X J V S D );

sub LeeFestivos($)
{ my $fichconf=shift;
  my (%resul,@resul,$linea);

  open(HANDIN,$fichconf) || do
  { print STDERR "Error al abrir: $fichconf: $!";
    return undef;
  };

  while(defined($linea=<HANDIN>))
  { my ($clave,$valor);

    chomp $linea;
    $linea =~ s/\cM//g;
    $linea =~ s/^\s*//g;
    $linea =~ s/\s*$//g;

    next if (($linea =~ m/^\s*$/) || ($linea =~ m/^\s*#/));

    if ($linea =~ m#(\d{1,2})[/-](\d{1,2})[/-](\d{4})#)
    { $resul{$linea}++;
    };
  };
  foreach $linea (keys %resul)
  { $linea =~ m#(\d{1,2})[/-](\d{1,2})[/-](\d{4})#;
    my ($dia,$mes,$anno)=($1,$2,$3);
    push @resul,Date_to_Days($anno,$mes,$dia);
  };
  return @resul;

};

##FUNCION Dias2FechaDC($dias)
sub Dias2FechaDMY($)
{ my $dias=shift;
  my ($y,$m,$d);
  ($y,$m,$d)=Add_Delta_Days(1,1,1, $dias - 1);

  return "$d-$m-$y";

};

##FUNCION Dias2FechaDC($dias)
sub Dias2FechaYMD($)
{ my $dias=shift;
  my ($y,$m,$d);
  ($y,$m,$d)=Add_Delta_Days(1,1,1, $dias - 1);

  return "'$y-$m-$d'";

};

##FUNCION Dias2FechaDC($dias)
sub Dias2FechaDC($)
{ my $dias=shift;
  return (($dias>0)?Add_Delta_Days(1,1,1, $dias - 1):undef)
};

##FUNCION FechaDMY2Dias($fecha)
sub FechaDMY2Dias($)
{ my $fecha=shift;
  my ($anno,$mes,$dia);
  if ($fecha =~ m#(\d{1,2})[/-](\d{1,2})[/-](\d{4})#)
  { ($dia,$mes,$anno)=($1,$2,$3);
  } else
  { ($dia,$mes,$anno)=(0,0,0);
  };
  return (check_date($anno,$mes,$dia))?Date_to_Days($anno,$mes,$dia):0;
};

##FUNCION FechaBD2Dias($fecha)
sub FechaBD2Dias($)
{ my $fecha=shift;
  my ($anno,$mes,$dia);
  if ($fecha =~ m/(\d{4})-(\d{2})-(\d{2})/)
  { ($anno,$mes,$dia)=($1,$2,$3);
  } else
  { ($dia,$mes,$anno)=(0,0,0);
  };
  return (check_date($anno,$mes,$dia))?Date_to_Days($anno,$mes,$dia):0;
};

sub Dias2DiaSem($)
{ my $dias=shift;

  return $DiasSem[Day_of_Week(Dias2FechaDC($dias))];
};

1;
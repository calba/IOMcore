package IOMCore::Fechas;

use strict;
use warnings;

BEGIN {
use Exporter   ();
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
# if using RCS/CVS, this may be preferred
$VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA         = qw(Exporter);
@EXPORT_OK = @EXPORT = qw(&LeeFestivos &Dias2FechaDC &FechaDMY2Dias 
                  &FechaBD2Dias &Dias2FechaYMD &Dias2FechaDMY &Dias2DiaSem
                  Dias2Time Time2Dias Dias2NumDiaSem Time2FechaHora
                  Hoy2Dias );
# as well as any optionally exported functions
}

use Date::Calc qw( Date_to_Days Today Add_Delta_YMD Date_to_Text Add_Delta_Days Day_of_Week check_date );
use Time::Local;

my @DiasSem=qw( - L M X J V S D );

sub LeeFestivos($)
{ my $fichconf=shift;
  my (%resul,@resul,$linea);
  
  @resul=();

  open(HANDIN,$fichconf) || do
  { print STDERR "Error al abrir: $fichconf: $!";
    return @resul;
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

sub Dias2FechaDMY($;$)
{ my $dias=shift;
  my $sep=shift||"/";
  my ($y,$m,$d);
  ($y,$m,$d)=Add_Delta_Days(1,1,1, $dias - 1);

  return sprintf("%02d%s%02d%s%04d",$d,$sep,$m,$sep,$y);
};

sub Dias2FechaYMD($;$)
{ my $dias=shift;
  my $sep=shift||"/";
  my ($y,$m,$d);
  ($y,$m,$d)=Add_Delta_Days(1,1,1, $dias - 1);

  return sprintf("%04d%s%02d%s%02d",$y,$sep,$m,$sep,$d);
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

sub Dias2NumDiaSem($)
{ my $dias=shift;

  return Day_of_Week(Dias2FechaDC($dias));
};

sub Dias2Time($)
{ my $dias=shift;
  my ($dia,$mes,$year,@aux);

  if (@aux=Add_Delta_Days(1,1,1, $dias - 1))
  { ($year,$mes,$dia)=@aux;
    return timelocal(0,0,0, $dia, $mes-1, $year-1900);
  } else
  { return undef;
  }
};

sub Time2Dias($)
{ my $time=shift;
  my ($dia,$mes,$year);

  (undef, undef, undef, $dia, $mes, $year, undef, undef, undef) = localtime($time);
  return (check_date($year+1900,$mes+1,$dia))?Date_to_Days($year+1900,$mes+1,$dia):0;
};

sub Time2FechaHora($;$)
{ my $time=shift;
  my $sep=shift||"/";
  my ($seg,$min,$hor,$dia,$mes,$year);

  ($seg, $min,$hor,$dia,$mes,$year, undef, undef, undef) = localtime($time);
  return sprintf("%02i%s%02i%s%04i %02i:%02i:%02i",
                       $dia,$sep,$mes+1,$sep,$year+1900,$hor,$min,$seg);
};

sub Hoy2Dias()
{ return Time2Dias(time());
};


1;

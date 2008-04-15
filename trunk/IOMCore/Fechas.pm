package IOMCore::Fechas;

use strict;
use warnings;

BEGIN {
use Exporter   ();
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
# if using RCS/CVS, this may be preferred
$VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA         = qw(Exporter);
@EXPORT_OK = @EXPORT = qw(&LeeFestivos &Dias2FechaDC &FechaDMY2Dias 
                  &FechaBD2Dias &Dias2FechaYMD &Dias2FechaDMY &Dias2DiaSem
                  Dias2Time Time2Dias Dias2NumDiaSem Time2FechaHora
                  Hoy2Dias PubDate2Time Time2FechaYMD);
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

sub PubDate2Time($)
{ my $pubdate=shift;
  my ($dia,$mes,$year,$hora,$min,$seg,$TZ);

  my %meses= ( 'jan' =>1,
               'january' =>1, 
               'feb' =>2,
               'february' =>2,
               'mar' =>3,
               'march' =>3,
               'apr' =>4,
               'april' =>4,
               'may' =>5,
               'jun' =>6,
               'june' =>6,
               'jul' =>7,
               'july' =>7,
               'aug' =>8,
               'august' =>8,
               'sep' =>9,
               'sept' =>9,
               'september' =>9,
               'oct' =>10,
               'october' =>10,
               'nov' =>11,
               'november' =>11,
               'dec' =>12,
               'december' =>12,
               #En español
               'ene' =>1,
               'abr' =>4,
               'ago' =>8,
               'dic' =>12);

  return 0 unless defined($pubdate);
  
#<pubDate>Fri, 22 Apr 2005 16:22:45 GMT</pubDate>
  if ($pubdate =~ m!(:?.*),\s+
                    (\d{1,2})\s+
                    (\w+)\s+
                    (\d{4})
                    (\s+(\d{2}):(\d{2})(:(\d{2})))?
                    (\s+(.+))?
                   !ix)
  { my ($dia,$mes,$year,$hora,$min,$seg,$TZ,$nummes);

    $dia=$2;
    $mes=$3;
    $year=$4;
    $hora=$6||0;
    $min=$7||0;
    $seg=$9||0;
    $TZ=$11||"";
    $nummes=$meses{lc($mes)};
    unless (defined($nummes=$meses{lc($mes)}))
    { print STDERR "IOMCore::Fechas. PubDate2Time. Mes desconocido: |$mes|. ",
                      "Devuelve 0.\n";
      return 0;
    };

    return timelocal($seg, $min, $hora, $dia, $nummes-1, $year-1900);
  } elsif ($pubdate =~ m#(\d{4})-(\d{1,2})-(\d{1,2})#)
  { my ($dia,$mes,$year);

    $dia=$3;
    $mes=$2;
    $year=$1;
    return timelocal(0, 0, 0, $dia, $mes-1, $year-1900);
  } elsif ($pubdate =~ m!((:?\w+),\s+)?
                         (\w+)\.?\s+
                         (\d{1,2}),\s+                    
                         (\d{4})
                         (\s+(\d{2}):(\d{2})(:(\d{2})))?
                         (\s+(.+))?
                        !ix)
  { my ($dia,$mes,$year,$hora,$min,$seg,$TZ,$nummes);

    $dia=$4;
    $mes=$3;
    $year=$5;
    $hora=$7||0;
    $min=$8||0;
    $seg=$9||0;
    $TZ=$11||"";
    $nummes=$meses{lc($mes)};
    unless (defined($nummes=$meses{lc($mes)}))
    { print STDERR "IOMCore::Fechas. PubDate2Time. Mes desconocido: |$mes|. ",
                      "Devuelve 0.\n";
      return 0;
    };
    
    return timelocal($seg, $min, $hora, $dia, $nummes-1, $year-1900);
  } else
  { print STDERR "IOMCore::Fechas. PubDate2Time. Parametro no casa la RE ",
                  "|$pubdate|. Devuelve 0.\n";
    return 0;
  };
};

sub Time2FechaYMD($;$)
{ my $time=shift;
  my $sep=shift||"";
  my ($dia,$mes,$year);

  (undef, undef, undef, $dia, $mes, $year, undef, undef, undef) = localtime($time);
  return sprintf("%04d%s%02d%s%02d",$year+1900,$sep,$mes+1,$sep,$dia);
};

1;

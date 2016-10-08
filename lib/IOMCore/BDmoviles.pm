package BDmoviles;

use strict;
use diagnostics;

BEGIN {
  use Exporter   ();
  #$Exporter::Verbose=1;
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  # if using RCS/CVS, this may be preferred
  $VERSION = do { my @r = (q$Revision: 1.1.1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
  @ISA         = qw(Exporter);
  @EXPORT      = qw( BD2mem mem2html sacarDiferencias leerFichero sacarBDaFichero );
  # as well as any optionally exported functions
  @EXPORT_OK   = qw($Var1 %Hashit &func3);
   }
  
=pod
 Funciones y datos para el
 manejo de los móviles en la BD
 el fichero de móviles del
 año en curso 

=cut

sub sacarBDaFichero($);
sub leerFichero($$);
sub BD2mem($$$$); 
sub mem2html($$$);
sub sacarDiferencias($$);
sub muestraTabla($); # Aux

# Nombres a utilizar en vez de Nombre APELLIDO1
my %login2nick=(
  aimp62 => "Ana I. Martín",
  avr35 => "Antonio Valle",
  afp06   => "Alfonso Fraga",
  igm62   => "Ismael García",
  erg62 => "Eduardo Rubio",
  lrtg20  => "Lucía Ruiz-Tapiador",
  madoz   => "Ángela Madoz",
  ner => "Natalia Esquivel",
  mfs03 => "Marcos Feijoo",
  mep62   => "María Escalante",
  jga62 => "Jaime Gutiérrez",
  rdi07 => "Raúl Díez",
  ajpm62 => "Javier Pérez",
  morag19 => "Guillermo Lafuente",
  rvg55 => "Ricardo Velasco",
  jrmp06 => "José Ramón Morato",
  cmp55 => "Carlos Massó",
  rfo82 => "Rafael Fernández",
  mrj237 => "Miguel Rojo"
);
# Orden de los móviles en el fichero de salida
my @moviles=("BAD", "ES-CNSO", "ES-SMAS", "BAD-TMB", "ADSL BR", "CGP Terra");

=pod
Sacar de la BD un fichero de turnos de móviles del
año actual.
Parámetros:
  Referencia a la conexión a la BD
Devuelve referencia a array con los turnos
[
  '22/05/2002',
  'Miguel Tabernero',
  'María Escalante Palacio',
  '-',
  'David Horcajo',
  'Raúl Díez Inclán',
  ''
],
[
  '29/05/2002',
  'Carlos Massó de Pablo',
  'José Ramón Morato Polo',
  '-',
  'Eduardo Posadas',
  'Guillermo Lafuente Moraga',
  '#'
],

=cut
sub sacarBDaFichero($) {
  my $dbh=shift;
my $cond=" YEAR(inicioMovil)=YEAR(NOW()) ";
# TODO : Cambiar aquí el intervalo temporal por argumentos cambiando $cond
#
my $query=q{ SELECT movil, inicioMovil, turnosMovil.login, CONCAT(Nombre, " ", APELLIDO1) AS NombreCompleto, comentario };
$query.="\nFROM turnosMovil LEFT JOIN personas ON turnosMovil.login=personas.login";
$query.="\nWHERE \n\t" . $cond . "\n ORDER BY inicioMovil, movil";

my $sth = $dbh->prepare($query) or print "Error: " . $dbh->errstr;

$sth->execute;
my $r_row;
my %moviles;
my $fecha;
my $nombre;
my @fechas; # Para guardar las fechas ordenadas
my @comentarios; #Para guardar un comentario por fecha
while ( $r_row=$sth->fetchrow_hashref() ) {
  # Cambio formato de fecha
  $fecha=$r_row->{"inicioMovil"};
  $fecha=~s!(\d{4})-(\d{2})-(\d{2})!$3/$2/$1!;
  unless ( grep(/$fecha/, @fechas)>0 ) {
    push @fechas, $fecha;
    push @comentarios, defined($r_row->{"comentario"})?$r_row->{"comentario"}:"";
  };
  #TODO : Aquí iría la traducción a nombre completo/nick/...
  # $nombre=defined($r_row->{"NombreCompleto"})?$r_row->{"login"}:"";
  $nombre=defined($r_row->{"NombreCompleto"})?$r_row->{"NombreCompleto"}:"";
  if ( exists $login2nick{$r_row->{"login"}} ) { $nombre=$login2nick{$r_row->{"login"}}; };
  $moviles{$fecha}{$r_row->{"movil"}}=$nombre;
  #$moviles{$fecha}{$r_row->{"movil"}}=$r_row->{"NombreCompleto"};

};
my @linea=qw{ "" "" "" Z "" "" "" };
my @turnos;
foreach $fecha ( @fechas ) {
  #print STDERR "$fecha => " . Dumper( $moviles{$fecha} );
  $linea[0]=$fecha;
  $linea[1]=$moviles{$fecha}{"ES-CNSO"};
  $linea[2]=$moviles{$fecha}{"ES-SMAS"};
  # Hueco TMB $linea[3]=
  if ( $linea[3] eq  "" ) { $linea[3]="-"; };
  $linea[4]=$moviles{$fecha}{"ADSL BR"};
  $linea[5]=$moviles{$fecha}{"CGP Terra"};
  $linea[6]=shift @comentarios;
  #print join("|",@linea)  ."\n";
  @{$turnos[$#turnos+1]}=@linea;
  map { $_="" } @linea;
 };
 return \@turnos;
}

=pod
Función para leer un fichero de móviles y pasarlo 
al formato para la base de datos;
Parámetros
  Referencia a la BD
  Nombre del fichero en el formato:
02/01/2002|Antonio Valle|Miguel Rojo Jiménez|Z|Ismael García Montoro|Guillermo Lafuente Moraga|# (hasta el 6)
09/01/2002|Sergio García Carranza|Natalia Esquivel Rojas|-|David Horcajo|Raúl Díez Inclán|# (del 7 al 15)
16/01/2002|Eduardo Rubio Gómez|Ana I. Martín|-|Jaime Gutiérrez Andrés|Eduardo Posadas|
  

Los nombres reconocidos son los nombres completos de la base de datos
y las abreviaturas del hash login2nick.
Devuelve ref a una lista:
[
[
  '2002-05-22',
  '',
  'ES-CNSO',
  'matm20'
  '# (hasta el 6)'
],
[
  '2002-05-22',
  '',
  'ES-SMAS',
  'mrj237'
  '# (hasta el 6)'
]
]
=cut
sub leerFichero($$) {
my $dbh=shift;
my $fichero=shift;
my $i;
# Abrir fichero
open IN, "<" . $fichero or die "No puedo abrir $fichero: $!\n";

# Construir hash nick2login (invirtiendo login2nick)
my %nick2login;
map { $nick2login{$login2nick{$_}}=$_ } keys %login2nick;

# Construir hash nombreC2login (de la BD)
my %nombreC2login;
my $query=<<EOF;
SELECT login, CONCAT(Nombre, " ", APELLIDO1) 
FROM personas 
WHERE baja IS NULL 
OR baja>=DATE_SUB(NOW(), INTERVAL 1 YEAR)
EOF
# Existe la posibilidad de leer un fichero donde haya alguien dado de baja hace más de un
# año, pero la despreciamos.
# Puede haber gente con mismo nombre completo pero distinto login (ejplo
# madoz, madoz03) 
my $sth=$dbh->prepare($query);
$sth->execute() or die $dbh->errstr;
while ( $i=$sth->fetchrow_arrayref ) { $nombreC2login{ $i->[1] }=$i->[0]; };
$sth->finish;
#
#print Dumper(\%nombreC2login);

# Leer línea
my @linea;
my @turnos;
while(<IN>) {
  next if (/^$/ || /^#/ );
  chomp;
  # Invertir fecha
  s!(\d{2})/(\d{2})/(\d{4})!$3-$2-$1!g;
  @linea=split(/\|/);
  my $comentario=$linea[6];
  my $fecha=$linea[0];
  #print Dumper(\@linea) . " fecha= $fecha, comentario=$comentario\n";
  #
  my $login;
  for ( $i=1; $i<=$#moviles; $i++ ) {
    # Esquivar TMB
    next if ( $i == 3 );
    # Leer turno -> averiguar login de la persona y nombre del movil
    if ( exists($nick2login{$linea[$i]}) ) 
      { $login=$nick2login{$linea[$i]}; }
    elsif ( exists($nombreC2login{$linea[$i]}) ) 
      { $login=$nombreC2login{$linea[$i]}; }
    #elsif ( $linea[$i]=~m/^$|-|Z|\s+/ )
    # { $login=$linea[$i]; }
    else # Nombre desconocido
      { die "leerFichero $fichero: No puedo entender el nombre $linea[$i]: \n" . join("|", @linea); };
    # Meter ref en array 
    $turnos[$#turnos+1]=[ $fecha, "", $moviles[$i], $login, $comentario ];
  };
};
# Devolver ref.
return \@turnos;
close IN;
};

=pod
sacarDiferencias
Recibe como parametros
  Referencia a conexion a la BD
  Referencia a listado leido de fichero (sub leerFichero)
y muestra por pantalla una serie de comandos SQL
para dejar la BD igual que como indica el fichero
=cut
sub sacarDiferencias($$) {
my $dbh=shift;
my $r_turnos=shift;

my $query=q{ SELECT inicioMovil, movil, login, comentario FROM turnosMovil WHERE inicioMovil=? and movil=? };
my $sth=$dbh->prepare($query) or die $dbh->errstr;
my $r_Fich;
my $r_BD;
my $cambios="";
my @result;
TURNO: foreach $r_Fich ( @{$r_turnos} ) {
  $cambios="";
  $sth->execute($r_Fich->[0], $r_Fich->[2]) or die $dbh->errstr;
  $r_BD=$sth->fetchall_arrayref;

  if ( scalar(@{$r_BD}) > 1 ) { # Más de un resultado ¿?
    print " -- Entradas múltiples para móvil $r_Fich->[2] en $r_Fich->[0], me lo salto\n";
    next TURNO;
  };
  if ( scalar(@{$r_BD}) == 0 ) { # Entrada nueva
    $cambios="INSERT INTO turnosMovil VALUES (";
    $cambios.=join(",", map { $dbh->quote($_) } @{$r_Fich}) . ");";
    push @result, $cambios;
    next TURNO;
  };
  if ( $r_BD->[0][2] ne $r_Fich->[3] ) { # Cambio de responsable
    $cambios="\tlogin=" . $dbh->quote($r_Fich->[3]);
  };
  unless ( defined($r_BD->[0][3]) ) { $r_BD->[0][3]=""; };
  unless ( defined($r_Fich->[4]) ) { $r_Fich->[4]=""; };
  if ( $r_BD->[0][3] ne $r_Fich->[4] ) { # Cambio de comentario
    if ( $cambios ne "" ) { $cambios.=",\n"; };
    $cambios.="\tcomentario=" . $dbh->quote($r_Fich->[4]);
  };
  if ( $cambios eq "" ) { next TURNO; };

  $cambios="UPDATE turnosMovil SET\n" . $cambios;
  $cambios.="\nWHERE inicioMovil=" . $dbh->quote($r_Fich->[0]);
  $cambios.=" AND movil=" . $dbh->quote($r_Fich->[2]) . ";";
  push @result, $cambios;
}; # TURNO

if ( scalar @result > 0 ) { print join("\n", @result) . "\n"; };
}

=cut
sub BD2mem($$$$)
Recibe 
  Referencia a $dbh
  Fecha inicial (yyyy-mm-dd)
  Fecha final (yyyy-mm-dd)
  Referencia a lista de móviles ( "ADSL BR", "CGP Terra" ) que 
  recuperar de la BD. Si es una lista vacía [] se sacan todos.
Devuelve referencia a una 
estructura con todos los turnos de
móviles con inicio en ese intervalo.
Ejemplo:
my $r=BD2mem($dbh, "2002-05-01", "2002-09-15", [ ]);
$r= [
  [
  '2002-05-22',
  '',
  'ES-CNSO',
  'matm20'
  '# (hasta el 6)'
  ],
  [
  '2002-05-22',
  '',
  'ES-SMAS',
  'mrj237'
  '# (hasta el 6)'
  ]
]
=cut
sub BD2mem($$$$) {
my ($dbh, $inicio, $fin, $r_mov)=@_;
my $query=q{ SELECT inicioMovil, movil, login, comentario FROM turnosMovil
  WHERE inicioMovil>=? AND inicioMovil<? 
};
if ( scalar(@{$r_mov}) > 0 ) 
  { $query.=q{ AND movil IN (} . join(",", map { $dbh->quote($_) } @{$r_mov}) . ");"; };
my $sth=$dbh->prepare($query) or die $dbh->errstr;
$sth->execute($inicio, $fin);
my $r;
my @turnos;

while ($r=$sth->fetchrow_arrayref) {
  push @turnos, [ $r->[0], "", $r->[1], $r->[2], $r->[3] ];
}
return \@turnos;
}

=cut
sub mem2html($$)
Recibe $dbh y una estructura con los turnos y genera la página
de turnos de móviles. El tercer argumento es una referencia a
la lista en la que saldrán ordenados los turnos, si existen. Los
turnos que estén en la estructura $2 pero no en $3 saldrán al final
[
[
  '2002-05-22',
  '',
  'ES-CNSO',
  'matm20'
  '# (hasta el 6)'
],
[
  '2002-05-22',
  '',
  'ES-SMAS',
  'mrj237'
  '# (hasta el 6)'
]
]
[ "ADSL BR", "CGP Terra" ]
=cut
sub mem2html($$$) {
my $dbh=shift;
my $r_turnos=shift;
my $r_movil=shift;

use POSIX qw(:time_h :locale_h);

my $title="TablaMoviles"; # Header HTML
my $cabecera="M&oacute;viles en el Grupo de Instalaciones"; # Cabecera tabla

my $old_locale=POSIX::setlocale(LC_TIME);
POSIX::setlocale(LC_TIME, "es.ISO8859-15");
my $hoy=POSIX::strftime "%d de %B de %Y", localtime;

print <<EOF;
<!DOCTYPE HTML public "-//w3c//dtd html 4.1 transitional//en">
<html>
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
      <title>$title</title>
      <!--------------------------------------------->
      <!--------------------------------------------->
      <!---- Fichero: TablaMoviles.htm          ----->
      <!---- Autor:                             ----->
      <!---- Fecha: $hoy       ----->
      <!---- Telefonica I+D                     ----->
      <!--------------------------------------------->
      <!--------------------------------------------->
      </head>
      <body>
      &nbsp;
      <center>
      <p><b><font color="#0000FF">Actualizado: </font><font color="#FF0000">
      $hoy <br><hr>
      <table BORDER NOSAVE width=90%>
      <tr>
      <th  BGCOLOR="#000000"><font color="#FFFFFF">$cabecera</font></th>
      </tr>
      </table>

EOF
# Tabla de números de teléfono
my $r;
my $query=q{ SELECT descripcion, numero, numeroCorto FROM moviles };
my $sth=$dbh->prepare($query);

my %moviles;
$sth->execute or die $dbh->errstr;
while ( $r=$sth->fetchrow_arrayref ) {
   $moviles{$r->[0]}=<<EOF;
<th>
<font color="#FF0000">($r->[0]) $r->[2]<br>
$r->[1]</font>
</th>
EOF
};
$sth->finish;

# Tabla de login a Nombre Completo
$query=q{ SELECT login, CONCAT(Nombre, " ", APELLIDO1) AS NombreCompleto FROM personas };
$sth=$dbh->prepare($query);
$sth->execute or die $dbh->errstr;
my %personas;
while ( $r=$sth->fetchrow_arrayref ) {
  $personas{$r->[0]}=$r->[1];
  if ( exists($login2nick{$r->[0]}) )
    { $personas{$r->[0]}=$login2nick{$r->[0]}; };
  };
$sth->finish;

# A recorrer la estructura recibida.
# Acumulamos hasta el cambio de mes 
# para poder ver la cabecera.
my ($fecha, $mes, $anio, $movil, $login);
my $oldmes=0;
my %tabla;
foreach $r ( @{$r_turnos} ) {
  ($fecha,  $movil, $login)=($r->[0], $r->[2], $r->[3]);
  $mes=$fecha;
  $mes=~s!(\d{4})[/-]([0-9]+)[/-]\d{2}!$2!;
  $anio=$1-1900;
  $fecha=~s!(\d{4})[/-](\d{2})[/-](\d{2})!$3/$2/$1!;

  # Cambio de mes.
  # Mostramos la tabla del mes anterior e inicializamos la estructura de la tabla
  if ( $oldmes != $mes ) { 
    if ( defined ($tabla{"Mes"}) ) {
      muestraTabla(\%tabla); 
    };
    $tabla{"cabecera"}=[];
    $tabla{"Mes"}=uc(POSIX::strftime("%B %Y",  0, 0, 0, 0, $mes, $anio, 0)); # 06 -> JUNIO
    if ( scalar(@{$r_movil}) > 0  ) { # Para que las columnas salgan según el orden de @{r_movil}
      my $i=0;
      for ( $i=0; $i<scalar( @{$r_movil}); $i++ ) {
        $tabla{$r_movil->[$i]}=$i;
        $tabla{"cabecera"}->[$i]=$moviles{$r_movil->[$i]};
      };
    };
  }

  if ( ! exists($tabla{$movil}) )  # Sólo se entra cuando no hay array de ordenar (@{$r_movil})
    { 
    $tabla{$movil}=scalar @{$tabla{"cabecera"}};
    push @{$tabla{"cabecera"}}, $moviles{$movil};
  };
  if ( ! exists($tabla{$fecha}) )
    {
    push @{$tabla{"ordenFechas"}}, $fecha; # Para no perder el orden cronológico
  };
  unless ( exists($personas{$login}) ) { die "No encontrado nombre para $login\n"; };
  $tabla{$fecha}[$tabla{$movil}]=<<EOF;
<th>$personas{$login}</th>
EOF
  #$mes=strftime("%B", 0, 0, 0, 12, 11, 95, 2);
  #print STDERR "Leyendo turno del mes $mes ($fecha), de $personas{$login} para el movil de $movil\n";
  #print STDERR "Dumper: " . Dumper(\%tabla);
  $oldmes=$mes;
};
muestraTabla(\%tabla);
print "\t</body>\n</html>";

$sth->finish;

setlocale(LC_TIME, $old_locale);
}

=cut
sub muestraTabla($)
Imprime por pantalla la tabla de un mes
{
"Mes" => Nombre Mes,
"cabecera" => [ num1, num2, .., numN ],
"movilN" => N-1,
"ordenFechas" => [ "fecha", "fecha", .. "fecha" ],
"fecha" => [ turno1, turno2, .. turnoN ]
}
]

=cut
sub muestraTabla($) {
my $r=shift;
# Mostrar Tabla
#
# print STDERR "Dumper: " . Dumper($r);
my $ncol=scalar @{$r->{"cabecera"}};
my $span=$ncol+1;
print <<EOF;
<table BORDER NOSAVE width=90%>
<tr>
<th></th>

<th COLSPAN="$ncol" BGCOLOR="#FFFF80"></a>
$r->{"Mes"}</th></tr>
<th></th>
EOF
print join("\n", @{$r->{"cabecera"}}) . "\n";
my $f;
my $t;
my $i;
foreach $f ( @{$r->{"ordenFechas"}} ) {
  print <<EOF;
<tr>
<th BGCOLOR="#008080"><a name="$f"><font color="#FFFFFF">$f</a></font></th>
EOF
  #print join("\n", @{$r->{$f}})."\n</tr>\n";
  foreach $i ( 0 .. scalar(@{$r->{"cabecera"}})-1 ) {
    $t="<th>-</th>\n"; # Para el caso de que no esté puesto el turno.
    if ( defined($r->{$f}[$i]) )
      { $t=$r->{$f}[$i]; };
    print $t;
    };
  };
print "</table>\n";


## EOF
# Vaciar la estructura recibida
undef %{$r};
}

1;

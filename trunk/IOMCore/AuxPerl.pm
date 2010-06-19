package IOMCore::AuxPerl;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
@ISA = qw(Exporter);

@EXPORT      = qw( QuitaRepes  NotEmpty );
@EXPORT_OK   = @EXPORT;
%EXPORT_TAGS = ( );

##########################################################################

sub NotEmpty($);
sub QuitaRepes(\@);

#Devuelve true si la cadena tiene texto
sub NotEmpty($)
{ my $var=shift;
  return 0 unless defined($var);
  return ($var !~ m/^$/);
};

sub QuitaRepes(\@)
{ my $orig=shift;
  my %auxi;

  map { $auxi{$_}++ } (@$orig);

  return keys %auxi;
};


1;

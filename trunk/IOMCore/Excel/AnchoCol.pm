package IOMCore::Excel::AnchoCol;

use strict;

my $LONGIDEFECTO=4;

sub new
{ my $self  = {};
  my $defecto=shift||$LONGIDEFECTO;
  $self->{'DEFECTO'}=$defecto;
  bless($self);
  return $self;
};

sub Entrada($$$)
{ my $self = shift;
  my $columna=shift;
  my $valor=shift||"";
  my $longi=length($valor);

  if (defined($self->{'COLUMNAS'}{$columna}))
  { $self->{'COLUMNAS'}{$columna}=($longi>$self->{'COLUMNAS'}{$columna})?
                                       $longi:
                                       $self->{'COLUMNAS'}{$columna};

  } else
  { $self->{'COLUMNAS'}{$columna}=$longi;
  };
};

sub Default
{ my $self = shift;

  if (@_)
  { $self->{'DEFECTO'} = shift;
  };
  return $self->{'DEFECTO'};
};

sub Reset($$)
{ my $self = shift;
  my $columna=shift;

  delete($self->{'COLUMNAS'}{$columna});
};

sub Ancho($$)
{ my $self = shift;
  my $columna=shift;

  return ($self->{'COLUMNAS'}{$columna})||$self->{'DEFECTO'};
};

sub Columnas
{ my $self = shift;


  return keys %{$self->{'COLUMNAS'}};
};

1;

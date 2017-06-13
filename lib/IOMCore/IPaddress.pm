package IOMCore::IPaddress;

use strict;
use diagnostics;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = "1.0";
@ISA     = qw(Exporter);

@EXPORT = qw( String2Address  String2PlainAddressString Address2String
  CompareAddresses AddressType AddressBelongsToNet CIDR2mask );
@EXPORT_OK   = @EXPORT;
%EXPORT_TAGS = ();

##########################################################################
use Net::IP;
use Scalar::Util qw( blessed );

sub String2Address(\%$);
sub String2PlainAddressString(\%$);
sub Address2String(\%$;$);
sub CompareAddresses(\%$$);
sub AddressType($);
sub AddressBelongsToNet(\%$$);
sub CIDR2mask($);

sub String2Address(\%$)
{
  my $CONFIG = shift;
  my $string = shift;

  my ( $IPadd, $IPaddSTR );

  #print STDERR "String2Address: $string  Antes.\n";
  defined( $CONFIG->{'_CACHE'}{'_IPOBJS'}{$string} )
    and return $CONFIG->{'_CACHE'}{'_IPOBJS'}{$string};

  do
  {
    $IPadd = Net::IP->new($string) || do
    {
      my $errorSTR = Net::IP->Error();
      print STDERR
        "String2Address: address '$string' not valid: $errorSTR . Skipping.\n";
      return $IPadd;
    };

  };

  #print STDERR "String2Address: $string ",Dumper($IPadd);

  $CONFIG->{'_CACHE'}{'_IPOBJS'}{$string} = $IPadd;
  $IPaddSTR = Address2String( %$CONFIG, $IPadd );
  if ( $IPaddSTR ne $string )
  {
    $CONFIG->{'_CACHE'}{'_IPOBJS'}{$IPaddSTR} = $IPadd;
  }
  return $IPadd;
}

sub String2PlainAddressString(\%$)
{
  my $CONFIG = shift;
  my $string = shift;

  my ( $IPadd, $IPaddSTR );

  #print STDERR "String2Address: $string  Antes.\n";
  defined( $CONFIG->{'_CACHE'}{'_IPOBJS'}{$string} )
    and return ( $CONFIG->{'_CACHE'}{'_IPOBJS'}{$string} )->ip();

  do
  {
    $IPadd = String2Address( %$CONFIG, $string ) || do
    {
      my $errorSTR = Net::IP->Error();
      print STDERR
        "String2Address: address '$string' not valid: $errorSTR . Skipping.\n";
      return $IPadd;
    };

  };

  #print STDERR "String2Address: $string ",Dumper($IPadd);

  $CONFIG->{'_CACHE'}{'_IPOBJS'}{$string} = $IPadd;
  $IPaddSTR = Address2String( %$CONFIG, $IPadd );
  if ( $IPaddSTR ne $string )
  {
    $CONFIG->{'_CACHE'}{'_IPOBJS'}{$IPaddSTR} = $IPadd;
  }
  return $IPadd->ip();
}

sub Address2String(\%$;$)
{
  my $CONFIG     = shift;
  my $IPobj      = shift;
  my $cidrFormat = shift || 1;

  my $result =
    $cidrFormat
    ? ( $IPobj->ip()
       . (
       $IPobj->{'is_prefix'} ? sprintf( "/%i", $IPobj->prefixlen() ) : "/32" ) )
    : $IPobj->ip();

  return $result;
}

sub CompareAddresses(\%$$)
{
  my $CONFIG = shift;
  my $a      = shift;
  my $b      = shift;

  my ( $A, $B );

  $A = ( String2Address( %$CONFIG, $a ) )->intip();
  $B = ( String2Address( %$CONFIG, $b ) )->intip();

  return ( $A->bcmp($B) );
}

sub AddressType($)
{
  my $IPobj = shift;
  my %IPsegments = (
                     'typeA' => Net::IP->new('10.0.0.0/8'),
                     'typeB' => Net::IP->new('172.16.0.0/12'),
                     'typeC' => Net::IP->new('192.168.0.0/16'),
  );

  for my $type ( keys %IPsegments )
  {
    $IPobj->overlaps( $IPsegments{$type} ) and return $type;
  }
  return "public";
}

sub AddressBelongsToNet(\%$$)
{
  my $CONFIG  = shift;
  my $address = shift;
  my $net     = shift;
  my ( $IPobj, $NETobj );

  $IPobj =
    ( ( blessed($address) || "" ) eq "Net::IP" )
    ? $address
    : String2Address( %$CONFIG, $address );
  $NETobj =
    ( ( blessed($net) || "" ) eq "Net::IP" )
    ? $net
    : String2Address( %$CONFIG, $net );

  return ( $NETobj->overlaps($IPobj) == $IP_B_IN_A_OVERLAP );
}

sub CIDR2mask($)
{
  my $CIDR = shift;

  #Taken from https://jmorano.moretrix.com/2010/08/calculate-netmask-in-perl/

  my $_bit = ( 2**(32- $CIDR ) ) - 1;
  my ($full_mask) =
    unpack( "N", pack( "C4", split( /./, '255.255.255.255' ) ) );
  my $netmask =
    join( '.', unpack( "C4", pack( "N", ( $full_mask - $_bit -1 ) ) ) );

  return $netmask;

}
1;

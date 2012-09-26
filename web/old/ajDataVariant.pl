#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2012
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
# cd /usr/ports/converters/p5-JSON-XS && make install clean
=head

��� ������� $F{uid} ���������� �������� ��������� ��� ���� � ������� = $F{alias}

$F{x} � $F{y} - ������� ����� ������� ���������� ����, ��������������� nody.js
��� ����� �� ajax ������.

$F{orig_x} � $F{orig_y} - ����� ������������ ������� ���������� ����, ������������
����� ajax ������ ���� � ��������� ����, �.� ��� ����� ���������� ���� �� ����������.

=cut

use strict;
use vars qw( $OUT %F $DOC $Url $Adm $Ugrp );
use Data;


$ses::json = [];

my $Fuid = int $F{uid};
my $Falias = $F{alias};
my $Finame = $F{iname};             # ��� <input> ����, � ������� ����� ������� ���� �� ������������ ���������
$Finame =~ s|["'\\]||g;             # javascript

my $fields = Data->get_fields($Fuid);

my $field = $fields->{$Falias};
if( ! ref $field )
{
    debug("������� � ������ `$Falias` �� ����������");
    return 1;
}

my $out = '';
my $variants = $field->variant();

if( scalar @$variants > 10 && $F{var} eq '' )
{   # ����� ��������� - ������� ������ ��������� ����� ������������ ���������
    my %var1 = map{ substr($_->{descr},0,1) => 1 } @$variants;
    # ��� ����������� �� ������ 3� ������
    my %var3;
    map{ $var3{substr($_->{descr},0,3)}++ } @$variants;
    my @var = ();
    push @var, $_ foreach( sort{ $a cmp $b } keys %var1);
    push @var, $_ foreach( sort{ $var3{$a} <=> $var3{$b} } grep{ $var3{$_}>2 } keys %var3);
    $out .= '<br>';
    my $i = 0;
    foreach my $var( @var )
    {
        $out .= ' '.$Url->a($var,
            -class  =>'ajax',
            orig_x  => $F{x}+0,
            orig_y  => $F{y}+0,
            uid     => $Fuid,
            var     => $var,
            alias   => $Falias,
            iname   => $Finame,
        );
        $i++ < 6 && next;
        $i = 0;
        $out .= '<br>';
    }
    $out = _('[div big]',$out);
}
 else
{
    foreach my $var( @$variants )
    {
        $F{var} && $var->{descr} !~ /^$F{var}/ && next;
        $out .= url->a( $var->{descr}, -base=>'#', -onclick => "nody.set_field('$Finame','$var->{value}'); nody.modal_close(); return false;" ); 
    }
    $out = _('[div navmenu]',$out);
}

$out = $lang::ajDataVariant_title.' `'.$field->{title}.'`' . $out;

push @$ses::json, {
    id  => 'modal_window',
    x   => ($F{orig_x} || $F{x})+0,
    y   => ($F{orig_y} || $F{y})+0,
    data => $out,
};

return 1;

1;

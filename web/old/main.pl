#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2012
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
use strict;
use vars qw( %F $Url $Adm );

my $out = '';
$out .= $Url->a('������ ���������', a=>'mytune') if !$Adm->{pr}{108};
$out .= $Url->a('����� ������', a=>'user') if $Adm->{pr}{88};
$out .= $Url->a('�����', a=>'yamap') if $Adm->{pr}{topology};
$out .= $Url->a('���. �����', a=>'report') if $Adm->{pr}{fin_report};
$out .= $Url->a('�������� ���������� �����', a=>'cards') if $Adm->{pr}{cards};
$out .= $Url->a('��������������', a=>'admin') if $Adm->{pr}{SuperAdmin};
$out .= $Url->a('���������', a=>'tune') if $Adm->{pr}{SuperAdmin};

Doc->template('base')->{left_block} = Menu($out);


1;

#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2012
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
use strict;
use vars qw( %F $Url $Adm $Ugrp );

chk_priv('topology');

$cfg::yamap_key ne '' or debug('warn', '��� ����� ��� yandex api ($cfg::yamap_key)');
$cfg::yamap_url ||= 'https://api-maps.yandex.ru/1.1/index.xml?key=';
#Doc->template('base')->{head_tag} .= "\n".v::tag('script', -body=>'', src=>$cfg::yamap_url.$cfg::yamap_key, type=>'text/javascript');
Doc->template('base')->{head_tag} .= "\n".
    v::tag('script', -body=>'', src=>'http://api-maps.yandex.ru/2.0/?load=package.full&mode=debug&lang=ru-RU', type=>'text/javascript');

my %map_param = (
    # ����� �����, ���� �� ������, �� ����� ����� ������
    mapCenterX  => 35.066425,
    mapCenterY  => 48.466633,

    # ���������� ���� �������� ( uid : {����������} )
    # 1 : { gpsX : 35, gpsY : 48 },
    # 5 : { gpsX : 36, gpsY : 47 },
    users       => '',

    places      => '',
);

if( $cfg::yamap_center =~ /^(\d+\.\d+),(\d+\.\d+)$/ )
{
    $map_param{mapCenterX} = $1;
    $map_param{mapCenterY} = $2;
}
 else
{
    debug('warn', '�� ������ ����� ����� ($cfg::yamap_center)');
}

# -- ����� ---

my $separator = '';
my $places = '';
my $db = Db->sql("SELECT * FROM places WHERE gpsX>0");
while( my %p = $db->line )
{
    $places .= $separator;
    $places .= "$p{id} : { gpsX : $p{gpsX}, gpsY : $p{gpsY} }";
    $separator = ",\n";
}

$map_param{places} = $places;

my $users = '';
my $separator = '';
my $db = Db->sql("SELECT u.id, u.grp, d._gps FROM users u JOIN data0 d ON u.id = d.uid WHERE d._gps<>''");
while( my %p = $db->line )
{
    my $uid = $p{id};
    $Adm->{grp_lvl}{$p{grp}} or next;
    $p{_gps} =~ /^(\d+\.\d+),(\d+\.\d+)$/ or next;
    $users .= $separator;
    $users .= "$uid : { gpsX : $1, gpsY : $2 }";
    $separator = ",\n";
}

$map_param{users} = $users;

ToRight Box( wide => 1, title => '��� �������', msg =>
    join(' | ',
        url->a('�� �����', -base=>'#', -class=>"mark_col_show", -rel=>0),
    )
);

my $counters = {};
my $collection_id = 1; # � ��������� 0 ����� ��� �������
my $u_groups = '';
my $separator = '';
my $db = Db->sql("SELECT * FROM webses_data WHERE aid=? AND module='yamap' ORDER BY created DESC LIMIT 6", $Adm->{id});
while( my %p = $db->line )
{
    my $VAR1;
    my $data = eval $p{data};
    if( $@ )
    {
        debug('warn', "������ �������� ������ �� ����� `$p{unikey}`: $@");
        next;
    }
    ref $data eq 'HASH' or next;
    $data->{from} eq 'users' or next;       # ������ �� ������ ...
    ref $data->{ids} eq 'ARRAY' or last;    # ������ id �� �������
    ref $data->{info} eq 'ARRAY' or last;   # ������ � html-������������ ����
    my $filtr = _('[p]', join '<br>', @{$data->{info}});
    my $time = the_hh_mm( int(($ses::t-$p{created})/60) ).' �����';
    ToRight Box( wide => 1, title => $time, msg =>
        $filtr.
        join(' | ',
            url->a('�� �����', -base=>'#', -class=>"mark_col_show", -rel=>$collection_id),
            url->a('��������', _unikey=>$data->{return_to}),
            url->a('��������', _unikey=>$data->{return_to}, mod=>''),
            url->a('x', a=>'operations', act=>'del_ses_data', unikey=>$p{unikey}, return_to=>'yamap'),
        )
    );

    my $ids = join ',', map { "$_:1" } @{$data->{ids}};
    $u_groups .= $separator;
    $u_groups .= "$collection_id : {$ids}";
    $separator = ",\n";
    $collection_id++;
}
$map_param{u_groups} = $u_groups;

# ���� ���� ���������� ��������� ��������� - ����� ����� ���������� �� �����
$map_param{Marks_draggable} = $Adm->{pr}{82}? 'true' : 'false';

Show tmpl('yamap', %map_param);
#Doc->template('base')->{document_ready} .= " YaMaps();";

$counters->{no_access} && ToRight Menu("�� ������� ���� �������, � ������ ������� � ��� ��� �������. �� ����� �� ����������.");
$counters->{no_gps} && ToRight Menu("� $counters->{no_gps} �������� �� ������� �� ������� ����������. �� ����� �� ����������");

1;

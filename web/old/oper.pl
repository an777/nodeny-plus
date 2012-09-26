#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2011
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------

$Fact=$F{act};
$Fop=$F{op};
$Ftime=int $F{time};
$Fid=int $F{id};

my %subs = (
 'contacts' => 2,
 'c_grp'    => 2,
 'dopfields'=> 2,
 'nets'     => 2,
 'newuser'  => 2,
 'of'       => 2,
 'plans3'   => 2,
 'str'      => 2,
 'sat'      => 2,
 'usr_grp'  => 2,
 'usr_pack' => 2,
 'workers'  => 2,
 'points'   => 2,
);

exists $subs{$Fact} or Error_('����������� ������� act = [filtr|bold]',$Fact);
$Mess_UntrustAdmin='�� �������� ������, ��������� ��� ����������� �� �� �������, ��� ��������� �� ���������� �����������.';
$scrpt .= "&amp;act=$Fact";
require "$cfg::dir_web/o_$Fact.pl";

# name		- ��� �������� � ����������� ������, ��������, '������ �������'
# tbl		- �������
# field_id	- �������� ��������� ����, �� �������� ���������� ������� ����������� ��������, ��������, 'id'

$menu = o_menu();
$menu .= $br.$Url->a('������� ���������', a=>'tune') if $Adm->{pr}{2};

ToLeft Menu($menu);

$d->{form_header}={'act'=>$Fact,'op'=>'save','time'=>$t,'rand'=>int(rand 2**32)};
$d->{button} = $d->{priv_edit}? '��������' : '��������';

$then_url=$br2.&CenterA("$scrpt&op=list",'����� &rarr;');

# ���������� ��������� �� ������ &o_getdata! - ��� ��� ����� ����������

if( $Fop eq 'new' )
{
   &check_edit_priv($d->{priv_edit});
   $d->{name_action}='�������� '.$d->{name};
   $d->{form_header}{id}=0;
   &o_new;
   &o_show;
}
 elsif( $Fop eq 'edit' )
{
   &check_edit_priv($d->{priv_show});
   $d->{name_action}=($d->{priv_edit}? '��������� ':'�������� ').$d->{name};
   $d->{form_header}{id}=$Fid;
   &oper_getdata;
   &o_show;
}
 elsif( $Fop eq 'copy' )
{
   &check_edit_priv($d->{priv_edit});
   $d->{allow_copy} or Error("�������� ����� $d->{name} �� �������������.$go_back");
   $d->{name_action}='�������� ����� '.$d->{name};
   &oper_getdata;
   $Fid=0;
   $d->{form_header}{id}=0;
   &o_show;
}
 elsif( $Fop eq 'save' )
{
   $Fid && &oper_getdata;
   &o_save;
   &check_edit_priv($d->{priv_edit});
   $sql=$d->{sql};
   $_=Digest::MD5->new;
   $param_hash=$_->add($sql)->b64digest;
   if( $Fid ) {&run_update} else {&run_insert}
}
 elsif( $Fop eq 'del' )
{
   &oper_getdata;
   &check_edit_priv($d->{priv_edit});
   &run_delete;
}
 elsif( $Fop && defined($d->{"addsub_$Fop"}) )
{
   &{ $d->{"addsub_$Fop"} };
}
 else
{
   &check_edit_priv($d->{priv_show});
   &o_list;
}

Exit();

sub check_edit_priv
{
 $_[0] or &Error("��� ������� ������������ ���������� (act=$Fact, op=$Fop).$go_back");
}

sub oper_getdata
{
 $p=&sql_select_line($dbh,"SELECT time FROM changes WHERE tbl='$d->{tbl}' AND act=2 AND fid=$Fid",'������� �� ������');
 if ($p)
 {  # ���� �������, ������ �� ������� ���������! �������� ������ ������������ (������ �������� � �.�.)
    # &the_short_time($p->{time},$t,1) - ����� ������� �������� ��������� ����� `�������`, ���� ����
    $d->{when_deleted}=&the_short_time($p->{time},$t,1)." ������ � $Fid $d->{name} ���� �������.".$then_url;
 }
 &o_getdata;
}

sub run_delete
{
 $d->{no_delete} && &Error("�������� $d->{name} ������������� ��������, ��������� ".$d->{no_delete}.$go_back);

 $h=$d->{old_data}? '������� ������:'.&div('message',$d->{old_data}) : '';
 $Ftime or &Error("���������� �������� $d->{name}?".$br2.$h.$br.&CenterA("$scrpt&op=$Fop&id=$Fid&time=$t",'�������'));

 $rows=&sql_do($dbh,"DELETE FROM $d->{tbl} WHERE $d->{field_id}=$Fid LIMIT 1");
 $rows or &Error("�������� $d->{name} �� ���������.");

 &sql_do($dbh,"INSERT INTO changes SET tbl='$d->{tbl}',act=2,time=$Ftime,fid=$Fid,adm=$Adm->{id}","� ������� ��������� �����������, ��� ������ � �������� �����=$Fid, �������");

 &{ $d->{sub_postdel} } if defined $d->{sub_postdel};
 &OkMess("<span class=big>�������� $d->{name} ���������</span>.".$then_url);

 $h=$d->{old_data} && ", $d->{old_data}";
 ToLog("! $Adm->{info_line} �������� $d->{name} ($d->{field_id}=$Fid$h).");
}

sub run_insert
{
 $Frand=int $F{rand};
 $p=&sql_select_line($dbh,"SELECT * FROM changes WHERE tbl='$d->{tbl}' AND act=1 AND time=$Ftime AND fid=$Frand AND adm=$Adm->{id} AND param_hash='$param_hash'",
      '���� �� � ������� ��������� ���������� � ���, ��� ������ ��� �������');
 $p && &Error("���� ������ ��������� ������ �� �������� $d->{name}. ��������, �� �������� �������� � ��������� �������� ������. ������ ��� ���� ������� �����.".$then_url);

 $rows=&sql_do($dbh,"INSERT INTO $d->{tbl} SET $sql");
 $rows or &Error("�������� $d->{name} <span class=error>�� ���������</span>.".$then_url);

 &sql_do($dbh,"INSERT INTO changes SET tbl='$d->{tbl}',act=1,time=$Ftime,fid=$Frand,param_hash='$param_hash',adm=$Adm->{id}");

 $h=!!$d->{new_data} && &div('message',$d->{new_data});
 &OkMess("<span class=big>�������� $d->{name} ���������</span>.".$h.$br2.&CenterA($scrpt,'����� &rarr;'));
 ToLog("$Adm->{info_line} �������� $d->{name}. $d->{new_data}");
}

sub run_update
{
 $p=&sql_select_line($dbh,"SELECT * FROM changes WHERE tbl='$d->{tbl}' AND act=3 AND fid=$Fid AND time=$Ftime AND adm=$Adm->{id} AND param_hash='$param_hash'");
 $p && &Error("���� ������ ������ ��������� $d->{name} � ��������� ���� �� �������, ������� �� ��� ��������. ��������, �� �������� �������� � ��������� �������� ������.");

 $rows=&sql_do($dbh,"UPDATE $d->{tbl} SET $sql WHERE $d->{field_id}=$Fid LIMIT 1");
 $rows or &Error(&Printf('������ �� ��������� [] [error].',$d->{name},'�� ��������'));

 &sql_do($dbh,"INSERT INTO changes SET tbl='$d->{tbl}',act=3,time=$Ftime,fid=$Fid,param_hash='$param_hash',adm=$Adm->{id}");

 $h=!!$d->{old_data} && &div('message',$d->{old_data}).' &rarr; ';
 $h=!!$d->{new_data} && $h.&div('message',$d->{new_data});
 &OkMess(&Printf('[span big][][]',"��������� $d->{name} ��������� �������.",$h,$then_url));

 $h=$d->{new_data}? ", $d->{old_data} &rarr; $d->{new_data}" : '';
 ToLog("$Adm->{info_line} ��������� $d->{name} ($d->{field_id}=$Fid$h)");
}

sub Check_SuperPriv
{
 $Adm->{pr}{SuperAdmin} or Error('������ ��������.');
 $Adm->{trusted} or Error($Mess_UntrustAdmin);
} 


1;

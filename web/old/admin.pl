#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2011
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------

sub Get_filtr_fields
{
 my @f = @_;
 return map{ v::filtr($p->{$_}) } (@f);
}

sub Get_fields
{
 return map{$p->{$_} }(@_);
}

sub CenterA
{
 return Center( div('nav',ahref(@_)) );
}

$Adm->{pr}{SuperAdmin} or Error('������������ ����������.');
$Adm->{trusted} or Error('�� �������� ������, ��������� ��� ����������� �� �� �������, ��� ��������� �� ���������� �����������.');

ToTop _('[]&nbsp;[]&nbsp;[]',
    $Url->a('������ ���������������', act=>'list_admin', -class=>'nav'),
    $Url->a('�������� ������', act=>'new_admin', -class=>'nav'),
    $Url->a('������� ���������', a=>'tune', -class=>'nav')
);

my %subs = (
 'new_admin'    => 1,
 'save_new'     => 1,
 'list_admin'   => 1,
 'del_admin'    => 1,
 'del_admin_now'=> 1,
 'edit_priv'    => 1,
 'update_priv'  => 1,
 'edit_data'    => 1,
 'update_data'  => 1,
 'copy_data'    => 1,
 'copy_data_now'=> 1,
);

my $Fact = $F{act};
$Fact='list_admin' if ! $subs{$Fact};

&{$Fact};

Exit();

sub get_admin_data
{
 $id = int $F{id};
 $p = sql_select_line($dbh,"SELECT *,AES_DECRYPT(passwd,'$Passwd_Key') FROM admin WHERE id=$id LIMIT 1","SELECT *,AES_DECRYPT(passwd,'...') FROM admin WHERE id=$id LIMIT 1");
 if( !$p )
 {
    $p=&sql_select_line($dbh,"SELECT time FROM changes WHERE tbl='admin' AND act=2 AND fid=$id");
    $p && Error( the_short_time($p->{time},1)." ������� ������ �������������� � $id ���� �������." );
    Error("�� ���������� ������� ������ �������������� � id=$id.");
 }
 ($login,$privil) = Get_fields('login','privil');
}

sub SPriv
{
 ($r1,$r2)=($r2,$r1) if $_[0];
 $_=$_[1];
 $row_id++;
 my $url = url->a(['[&darr;]'], -base=>'#show_or_hide', -rel=>"my_x_$row_id");
 $out.="<tr class=$r1>".($_[3]? "<$tc>".$url : '<td>&nbsp;');
 $out.="</td><td><input type=checkbox name=a$_ value=1 onchange=\"javascript:document.form.a$_.className='modified';\"".($pr{$_}? ' checked' : '')."></td><$tl colspan='2'>$_[2]</td></tr>";
 $out.="<tr class='$r1 my_x_$row_id' style='display:none'><$tl colspan='4'>$_[3]</td></tr>" if $_[3];
}

sub check_admin_login
{
 my $Flogin = trim($_[0]);
 $Flogin =~ /[^a-zA-z0-9]/ && Error("� ������ �������������� ������������ ������������ �������. ����������� ������ ��������� ����� � �����.");
 $Flogin or Error("���� `�����` �� ������ ���� ������ ��� ������ 0.");
 return $Flogin;
}

sub show_admin_url
{
 my($id, $msg) = @_;
 ToTop _('[]&nbsp;([]&nbsp;&nbsp;[])',
    $msg,
    $Url->a('����������', act=>'edit_priv', id=>$id),
    $Url->a('������', act=>'edit_data', id=>$id),
 );
}

# -----------------------------------
sub new_admin
{
 Doc->template('base')->{main_v_align} = 'middle';
 ToTop '�������� ������� ������ ������ ��������������';
 Show MessageBox(
    $Url->form( act => 'save_new',
        Table('tbg1',
            RRow('','ll', $lang::msg_login, v::input_t(name=>'login')).
            RRow('','ll', $lang::msg_pass,  v::input_t(name=>'passwd'))
        ).
        Center( v::submit($lang::btn_go_next) )
    )
 );
}


sub save_new
{
 my $Flogin = check_admin_login($F{login});
 my $Fpasswd = trim($F{passwd});
 my %p = Db->select_line("SELECT login FROM admin WHERE login=? LIMIT 1", $Flogin);
 # ���� ���� ���-�� ����������� ������ �������� ������ � ����� �������, �� INSERT �� ���������� ��-�� ������������ ����
 %p && Error_('[] [bold] [][p]', '����� � �������', $Flogin, '��� ����������.','������� ������ �������������� �� �������.');
 Db->do("INSERT INTO admin SET login=?, passwd=AES_ENCRYPT(?,?)", $Flogin, $Fpasswd, $cfg::Passwd_Key);
 my $id = Db::result->insertid;
 $id or Error_('[p][p]',"������ ��� ���������� sql-������� �������� ������� ������ $Flogin.","�������� ������������� � ����� ������� ��� ����������.");
 ToLog("!! $Adm->{info_line} ������ ����� ������������� � ������� $Flogin.");
 $Url->redirect( act => 'edit_priv', id => $id, -made => "������� ������� ������ �������������� � ������� $Flogin")
}

sub del_admin
{
 get_admin_data();
 ErrorMess(
    $Url->form( act => 'del_admin_now', id =>$id,
        _('[] [bold][p][p]',
            '�� ����������� ������� ������ �������������� � �������', $login,
            "����� ��������� ������������� ����������� �������� �������� ������� �������������� (������ '�������')",
            Center(v::submit('�������'))
        )
    )
 );
}

sub del_admin_now
{
 get_admin_data();
 my $rows = Db->do("DELETE FROM admin WHERE id=? LIMIT 1", $id);
 $rows<1 && Error("������� ������ �������������� � ������� `$login` �� �������.");
 ToLog("!! $Adm->{info_line} ������� ������� ������ �������������� $login (id=$id)");
 Db->do("INSERT INTO changes SET tbl='admin',act=2,fid=$id,adm=$Adm->{id},time=unix_timestamp()");
 $Url->redirect( act => '', -made => "������� ������ �������������� � ������� `$login` �������");
}

sub list_admin
{
 $colspan=9;
 $header=&RRow('tablebg','c3ccccc','�����','�������������','[X]','���','���������','��������','����������?');
 $out='';
 $outleft='';
 $sth=&sql($dbh,"SELECT * FROM admin ORDER BY login");
 while( $p=$sth->fetchrow_hashref )
 {
    ($login,$privil,$id) = Get_fields('login','privil','id');
    %pr = ();
    $pr{$_} = 1 foreach( split /,/,$privil );
    $enabled = $pr{1}? '' : '��������';
    $super = $pr{3}? '<span class=error>����������</span>' : $pr{2}? '���������� ����������' : '&nbsp;';
    ($name,$post)=&Get_filtr_fields('name','post');
    $out .= RRow($pr{1}? '*': 'rowoff','llllllccc',
        v::bold($login),
        ahref("$scrpt&act=edit_priv&id=$id",'����������'),
        ahref("$scrpt&act=edit_data&id=$id",'������'),
        ahref("$scrpt&act=copy_data&id=$id",'�����'),
        ahref("$scrpt&act=del_admin&id=$id",'�'),
        "<div nowrap>$name</div>",
        $post,
        $enabled,
        $super
    );
 }
 $out or Error_('[p h_center][p h_center]',
    '�� ������� �� ���� ������� ������ ��������������.',
    $Url->a('�������', act=>'new_admin')
 );
 Show Table('width100 nav2',
   &RRow('','tt',
     $outleft && MessageBox($outleft),
     &Table('tbg3',&RRow('head',$colspan,v::bold('������ ���������������')).$out)
   )
 );
}

sub edit_priv
{
 &get_admin_data;
 $row_id=0;
 $pr{$_}=1 foreach (split /,/,$privil);
 $nbsp="&nbsp;" x 4;
 show_admin_url($id, _('[] [bold]', '�������������� ���������� �������������� ', $login));
 $out=
   &RRow('nav','4',qq{<a href='#' onclick="SetAllCheckbox('privs',1); return false;">�������� ���</a> <a href='#' onclick="SetAllCheckbox('privs',0); return false;">������ ���</a>},'&nbsp;').
   "<tr class=row1><td width=3%>&nbsp;</td><td width=3%><input type=checkbox name=a1 value=1 onchange=\"javascript:document.form.a1.className='modified';\"".
       ($pr{1} && ' checked')."></td><td colspan=2>�������</td></tr>";
 $out.=&RRow('head','4', v::bold('���������� �����������'));

 SPriv(1,3,'����������');
 
 $out.=&RRow('head','4', v::bold('������ ����������'));
 SPriv(1,2, '�������� �������� �������� NoDeny');
 SPriv(1,15,'�������� ������� ������� ��������','�� ��������������� �������� �.�. �������� �������� ��������� ������� ��� ��������� ������, ����� �� ��������. ����� ������� ����������� ������ &#171;���������&#187;');
 SPriv(1,17,'�������� ����������� ������','�������� ����������� ������. ��������������� ������ ��� ��� ����� �������� � �������, � ������� ����� ����� ������');

 $out.=&RRow('head','4',v::bold('�������� ���������� �����. ������ ����������.'));
 SPriv(1,21,'������ � ���������������� �������� �������� ���������� �����');
 SPriv(1,22,'���������/�������� ��������');
 SPriv(1,23,'�������� ����� ����������');

 $out.=&RRow('head','4',v::bold('�������� ���������� �����.'));
 SPriv(1,116,'����� ��������� �������� �� ������ ���������������','������� �������, ���� �������������� ����� ��������� �������� �������� �� �������� ��������������');
 SPriv(1,111,"������� ������ �������� � ��������� ".v::commas('����� ������������ ��� �������'),'� ������� ������, �������� �������� ������������ ������ ����� ���� ��� ��� ���� �������. � ������ �������, ����� � �������� �����������, ��� �����-�� ����� �������, �������� �������, ��� �� ����� ������������. ��� ������ � ����� ������ ������������. ������, ���� ������� ����� - ����������, ������� ������� �������� �� ����� NoDeny, �� ���������� ���� ����������� �������� ���� �������� ��� ����������� � ���������');

 $out.=&RRow('head','4',v::bold('���������'));
 SPriv(1,24,"�������������� ������ ����������");
 SPriv(1,25,"���������� ������� ����������");
 SPriv(1,29,"����������� ������/��������� ��������� ��� ���������");
  
 $out.=&RRow('head','4',v::bold('�������. ������ ����������'));
 SPriv(1,11,'�������������� �������� ������ ������� ��������','����� �������� ��������� � ���� �������������� �������� ���������� ���� (�������), ����� ��� ����� ������ ����������� ������, � ������� ������� ���� ����� �� �������������� � ������� 10 ����� ����� ��������');
 SPriv(1,12,'�������������� ����� ��������','���������� �������������� �������� ������� ��������������. ���������� ������ ����� ������ �������������������');
 SPriv(1,13,'��������� �������������� ����� �������� ������� ����������������','�������������� �������� ������� ������ ����� ������������� ��� ������ ������� ���� ���� � ��� ���� ����� �� �������������� ����� ��������');
 SPriv(1,27,'��������� ��������� ��������','������ ����� ���� ����������� �������������� �������� ������������ ������� � ���������� ��� ������������ ������� � ������ ��������� ����������� � ������');
 SPriv(1,19,'���������� ������� �������� ����� ����������������');
 
 $out.=&RRow('head','4',v::bold('�������� ��������'));
 SPriv(1,51,'�������� ��������');
 SPriv(1,52,"�������� �������� ������� ��������������",'���������� ������� ����� �� ��������� ��������� ����������� ������ ������� ������� ��������������. ��� ������� � ���, ��� ��� ��������� �������� ������� ������������� ������ ������ &#171;������ �������&#187; - ��� ������� ����� �������. ���������� ������� ����� ���������:<br> - �������� �������� ����������� ������ ��������������� ��� &#171;������� ����&#187;<br> - ����� ������ �������� ������� �������������� � ���������� ���������� &#171;�� �����&#187;');
 SPriv(1,14,'�������� �������');

 $out.=&RRow('head','4',v::bold('���������� ��������'));
 SPriv(1,54,"���������� ����� �������");
 SPriv(1,56,"���������� ��������� ��������",'�������, ������� ������������� �������� ����� �������� ���������� ����.');
 SPriv(1,57,"���������� �������� `������` ������",'��� ���������� `�������` ��������. ����� ������ ������ ���������� �������.');
 SPriv(1,53,"���������� `������������ ��������`",'������������ ������� - �������, ������� ������������ �� ��������� NoDeny � ������ ����������� �������. ��� ������� ����� ��������� `������` ������ �� ������������ ����, ����������� � ����������. � ������� ������ `������������ �������` �� �����.');
 SPriv(1,58,"���������� �������� ��� ������� ����",'������� � ����������� �� ��������� �������� � ���������.');
 SPriv(1,59,"���������� �������/������� ����������");
 SPriv(1,55,"�������� ��������� �������");
 SPriv(1,34,"�������� ������������� ��������� (���� ���� ��� ������������ �������)");
 SPriv(1,60,"��������������/�������� �������� �� ������ 10 ����� �� �� ��������",'��� ����� ��������� ��������/������� ��������� ������ ���� �� ��� ������ � ������� ��������� 10 �����. ��� ���� ����������� ��������� ������, � ������ ������� �� ���� ���������� ����� ��������� ����� ������ ��������.');
 SPriv(1,62,"����� ����� ����������� � ��������� ���������� ����� ����������������, �.� ����� ���� ����������� ���� ������������ �������");
  
 $out.=&RRow('head','4',v::bold('����������'));
 SPriv(1,61,"�������� ������ �������");
 SPriv(1,70,"��������� ������ �������");

 $out.=&RRow($r1,'4',"$nbsp ����� ���� ����������� ������:");
 &SPriv(0,72,"$nbsp �����");
 &SPriv(0,71,"$nbsp ������");
 &SPriv(0,73,"$nbsp ������");
 &SPriv(0,74,"$nbsp ��������");
 &SPriv(0,75,"$nbsp ���");
 &SPriv(0,77,"$nbsp ������ � ��������");
 &SPriv(0,78,"$nbsp ������� ����������");
 &SPriv(0,69,"$nbsp % ������");
 &SPriv(0,79,"$nbsp ��������� (������/������/���������)");
 &SPriv(0,80,"$nbsp ����������� (������������� ��� ���)");
 &SPriv(0,82,"$nbsp �������������� ������");
 &SPriv(0,86,"$nbsp �����������");

 $out.=&RRow($r1,'4','');
 SPriv(1,100,"������ � ���������� ����������");

 SPriv(1,88,'�������� ������� ������� ��������');
 SPriv(1,106,'���������� �������');

 $out.=&RRow('head','4',v::bold('��������� ����'));
 SPriv(1,94,'������ � ������� ��������� ����');
 SPriv(1,95,'��������� � ������� ��������� ����');

 $out.=&RRow('head','4',v::bold('��������'));
 SPriv(1,98,'������ � ���������: ���������� ������� ����������, �������� ��������� ������ ������');
 SPriv(1,104,'�������� ��������� ����� �������');
 SPriv(1,99,'��������� ��������� ������ ������');
 SPriv(1,105,'��������� ��������� ������ �������');

 $out="<table width=90% class=tbg1 id=privs>$out</table>".$br;

 $out.="<table width=90% class=tbg1>".
   &RRow('head','4',v::bold('����������� ����')).
   "<tr class=row1><td width=3%>&nbsp;</td><td width=3%>&nbsp;</td><td colspan=2>&nbsp;</td></tr>";
 &SPriv(1,108,"������ �� ��������� ������ ��������",'������ �� �������� �������, ��������� ������� ������ � �.�. ������� ����� ��� ����� ��� ���������� ������� ������� ������');
 &SPriv(1,120,"��� �������� ������� ������ ������� �� ���������� ���� ������ ������, � ������������� ��� (�����) ������������� �� �������������� ���");
 &SPriv(1,300,'����� �������� ���������� ����� ��� �������������','������� ����� ������ � ��� ������, ���� ������� ������ �������� ������� �����������, ������� �� ����� ������� � ������� NoDeny, �.�. �� ����� ����������� ����� ��������');
 &SPriv(1,301,'�������������� ������� �������� �������� � ����� '.v::commas('����� ������������'),'������� ����� ������ � ��� ������, ���� ������� ������ �������� ������� �����������, ������� ������� �������� �� ����� ������� NoDeny');
 $out.='</table>'.$br;

 Show MessageBox(
    $Url->form( act => 'update_priv', id =>$id, Center(v::submit('���������')).$out )
 );
}

sub update_priv
{
 &get_admin_data;
 $Fprivil='0';
 map { $Fprivil.=",$1" if /^a(\d+)$/ } keys %F;

 $privil.=',';
  my @f = (
  1, '������� ������',
  3, '����������',
  5, '���. ������ �������',
  10,'���. �������',
  11,'���. �������� ������ ������� ��������',
  15,'�������� ��������',
  17,'�������� ���������',
  18,'���. ��� ��������� �������� ��������������',
  22,'���������/�������� �������� ����������',
  28,'���. �������',
  30,'������������ �� ������ ������ ������ ������',
  31,'������������ �� ������ ������',
  33,'�������� ����� �������� ����������',
  61,'�������� ������� ��������',
 );
 my $warn = '!';
 my $msg = '';
 while( my $i = shift @f )
 {
    $_ = $F{"a$i"};
    my $m = shift @f;
    $msg .= ", $m - $_" if ($_ && $privil!~/,$i,/ && ($_='���') && ($warn='!!')) ||
                          (!$_ && $privil=~/,$i,/ && ($_='����'));
 }

 my $rows = Db->do("UPDATE admin SET privil=? WHERE id=? LIMIT 1", $Fprivil, $id);
 $rows<1 && Error("��������� ������ ��� ���������� sql-�������. ���������� �������������� $login �� ��������.");
 ToLog("$warn $Admin_UU �������� ���������� �������������� $login (id=$id)$msg (priv: $Fprivil)");
 $Url->redirect( act => 'edit_priv', id => $id, -made => "�������� ���������� �������������� $login");
}

sub edit_data
{
 &get_admin_data;
 ($passwd,$name,$post)=&Get_filtr_fields("AES_DECRYPT(passwd,'$Passwd_Key')",'name','post');
 &show_data($id,$id);
} 


sub copy_data
{
 get_admin_data();
 ErrorMess(
    '�� ����������� ������� ����� ������� ������ �������������� '.v::bold($login).'.'.$br2.
        '����� ����������� ��� ����� � ������� � �������.'.$br2.
        CenterA("$scrpt&act=copy_data_now&id=$id",'������� �����').&ahref($scrpt,'�� ���������')
 );
}


sub copy_data_now
{
 get_admin_data();
 $privil= Db->filtr($privil);
 $old_login = $login;
 $login="COPY_$id";
 $sth=$dbh->prepare("INSERT INTO admin (login,passwd,name,privil) VALUES ('$login',AES_ENCRYPT('-','$Passwd_Key'),'-','$privil')");
 $sth->execute;
 $new_id=$sth->{mysql_insertid} || $sth->{insertid}; # �������� id ������ ��� ��������� ������
 &Error("������ ��� ���������� sql-������� �������� ������� ������.") unless $new_id;
 &ToLog("!! $Admin_UU ������� ����� ������� ������ �������������� $old_login. ��� ����� ������� ������ $login.");
 ($passwd,$name,$post)=('-','-',&Get_filtr_fields('post'));
 &show_data($id,$new_id);
}

sub show_data
{
 ($id,$save_id)=@_;
 ToTop '�������������� ������ ��������������';

 $row_id=0;

 # � ����� ������� �������� ������
 $list_grp='';
 $sth = sql($dbh,"SELECT * FROM user_grp ORDER BY grp_name");
 while( $p=$sth->fetchrow_hashref )
 {
    $grp_id=$p->{grp_id};
    # � ������ � � ����� ������ ����� ����, � ���������� �������� �������� ������ /,������,/, �.� ��� ������ ������� � ������
    $list_grp.="<input type=checkbox value=1 name=g$grp_id".($p->{grp_admins}=~/,$id,/ && ' checked').
     "><input type=checkbox value=1 name=gg$grp_id".($p->{grp_admins2}=~/,$id,/ && ' checked').
     '> '.&Filtr_out($p->{grp_name}).$br;
 } 

 $out=
    RRow('*','ll','�����',v::input_t(name=>'login', value=>$login)).
    RRow('*','ll','������',v::input_t(name=>'passwd', value=>$passwd)).
    RRow('*','ll','���',v::input_t(name=>'name', value=>$name)).
    RRow('*','ll','���������',v::input_t(name=>'post', value=>$post));

 if( $list_grp )
 {
    $list_grp=qq{<div id=allgrp>$list_grp</div><a href='#' onclick="SetAllCheckbox('allgrp',1); return false;">�������� ���</a>$br<a href='#' onclick="SetAllCheckbox('allgrp',0); return false;">������ ���</a>};
    $out.=&RRow('*','lll','������ � ������� ��������',$list_grp,
       '1 ������� - ������������ ������ � ������ (������ �������� ip, ������, ���, ������)'.$br2.
       '2 ������� - ������ ������ � ������.'.$br2.
       '���������� ������� - ������ �������� ������');
 }

 Show MessageBox(
    $Url->form( act => 'update_data', id => $save_id,
        Table('tbg3',$out).
        Center( v::submit('���������') )
    )
 );
}

sub update_data
{
 &get_admin_data;
 $oldpasswd=$p->{"AES_DECRYPT(passwd,'$Passwd_Key')"};

 my $Flogin = check_admin_login($F{login});

 $p=&sql_select_line($dbh,"SELECT * FROM admin WHERE login='$Flogin' AND id<>$id");
 $p && &Error('������ � ������� '.v::bold($Flogin).' ��� ����������!');

 $Fpasswd=trim(Db->filtr($F{passwd}));
 $Fname=Db->filtr($F{name});

 $Fpost=Db->filtr($F{post});

 $rows=$dbh->do("UPDATE admin SET login='$Flogin',passwd=AES_ENCRYPT('$Fpasswd','$Passwd_Key'),name='$Fname',post='$Fpost' WHERE id=$id LIMIT 1");
 $rows<1 && &Error("��������� ������ ��� ���������� sql-�������. ������ �������������� �� ��������.");
 ToLog("! $Admin_UU �������� ������ �������������� $login.".
   ($login ne $Flogin && " ����� ����� $Flogin.").
   ($oldpasswd ne $F{passwd} && ' ������� ������.')
 );

 # � ����� ������� ��������� ������
 $sth=&sql($dbh,"SELECT * FROM user_grp");
 while ($p=$sth->fetchrow_hashref)
 {
    $grp_id=$p->{grp_id};
    $g1=$p->{grp_admins};
    $g2=$p->{grp_admins2};
    $g1=~s|,$id,|,|;
    $g2=~s|,$id,|,|;
    $g1=~s|0$||;
    $g2=~s|0$||;
    $g1.="$id," if $F{"g$grp_id"} || $F{"gg$grp_id"};
    $g2.="$id," if $F{"g$grp_id"} && $F{"gg$grp_id"};
    $g1.='0';
    $g2.='0';
    Db->do("UPDATE user_grp SET grp_admins='$g1',grp_admins2='$g2' WHERE grp_id=$grp_id LIMIT 1");
 }

 # ���� ������ ������� - ������ ��� �������� ������ ������� ������
 if( $oldpasswd ne $F{passwd} )
 {
    Db->do("DELETE FROM admin_session WHERE admin_id=?", $id);
 } 

 $Url->redirect( act => 'edit_data', id => $id, -made => "�������� ������ �������������� $Flogin");
}

1;

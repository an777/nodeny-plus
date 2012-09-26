#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2011
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
$Adm->{pr}{show_fio} or Error('������ ��������. ������������ ����������.');
$Adm->{trusted} or Error('�� �������� ������, ��������� ��� ����������� �� �� �������, ��� ��������� �� ���������� �����������.');

if( !$F{act} )
{
   $OUT.=&MessX('�������� �������� �������, ��� ������ ��������� �����',1,0);
   $DOC->{base}{head_tag} .= qq{<meta http-equiv="refresh" content="0; url='$scrpt&act=check_now'">};
   &Exit;
}


# �������� ������ ������
# ...

LoadMoneyMod();

$out='';
if( $Adm->{pr}{SuperAdmin} )
{  # ����������. ��������, ��� ���� ������ �� ���� �������
   $out.=!$Adm->{grp_lvl}{$_} && &commas($UGrp_name{$_}).',' foreach (keys %UGrp_name);
   $out="�� ������������������, �� �� ������ ������ � �������: $out ".
      "������� ������� � ���� ������� �� ����� ���������. ��� �� ����������� ������.".$br2 if $out; # ������� ����� '�������' �� ����� �.�. ��� �����:)
}else
{
   $OUT.=$br.&MessX('���������� �������� �������. ��������, ����������� ������ �� ���������� ������� � ������ ��������, � ������� �� ������ ������.');
}

$out1=$out2=$out3='';

my $Allow_grp = join ',',keys %{$Adm->{grp_lvl}};
$where=!$Adm->{pr}{SuperAdmin} && "u.grp IN ($Allow_grp) AND"; # ��� ����������� �� ������ ������ �� ������ �.� ����� ��������� �������� � �������������� �������
$sth=&sql($dbh,"SELECT u.*,SUM(cash) AS cash FROM users u LEFT JOIN pays p ON u.id=p.mid ".
  "WHERE $where (p.type IN (10,20) OR p.type IS NULL) GROUP BY u.id ORDER BY u.mid,u.sortip");
while ($p=$sth->fetchrow_hashref)
  {
   next if $p->{balance}==$p->{cash};
   $out1.='<li>'.&ShowClient($p->{id},$p->{name},'')." - ������ ������� ������ ($p->{balance} $gr) ".
     "�� �������� � ������ ���� ����������� �������� ($p->{cash} $gr). ".
     "��������� ������ ������������� �������.</li>";
  }

%grps=%pakets=();
# ORDER BY mid ����������
$sth=&sql($dbh,"SELECT * FROM users ".(!$Adm->{pr}{SuperAdmin} && "WHERE grp IN ($Allow_grp)")." ORDER BY mid,sortip");
while ($p=$sth->fetchrow_hashref)
  {
   ($id,$mid,$name,$ip,$sortip,$grp,$paket,$state,$balance)=&Get_fields qw(
     id  mid  name  ip  sortip  grp  paket  state  balance );
   $grps{$id}=$grp;
   $pakets{$id}=$paket;
   $client=&ShowClient($id,$name,'');
   $out3.="<li>$client ������ �� ������������, � ����� ".&commas($Plan::main->{$paket}{name_short})." ��������� �������������.</li>" if $Plan_flags[$paket]=~/k/ && ($state ne 'off');

   if ($ip!~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ || $1>255 || $2>255 || $3>255 || $4>255)
   {
      $out1.="<li>$client - ������������ ip: ".&commas(&Filtr_out($ip)).'</li>';
   }
    else
   {
      $good_sortip=$2*65536 + $3*256 + $4;
      if ($good_sortip!=$sortip)
      {
         $rows=&sql_do($dbh,"UPDATE users SET sortip=$good_sortip WHERE id=$id LIMIT 1");
         $out3.="<li>$client - ������������ id ���������� (���� sortip). ".($rows==1? '����������.':&bold('�� ����������.')).'</li>';
      }
   }

   if (!$mid)
   {  # �������� ������
      $out1.="<li>$client � �������������� ������ � $grp</li>" if !$UGrp_name{$grp} && $Adm->{pr}{SuperAdmin};
   }
    else
   {  # �������� ������
      if ($grp!=$grps{$mid})
      {
         $out2.="<li>$client - ��������� ������, ����� ������ �� ��������� � ��������. ��� $grp, ������������ � $grps{$mid}</li>";
         &sql_do($dbh,"UPDATE users SET grp=$grps{$mid} WHERE id=$id LIMIT 1");
      }
      if ($paket!=$pakets{$mid})
      {
         $out2.="<li>$client - ��������� ������, ����� �� ��������� � ������� ������ �������� ������. ��� $paket, ������������ � $pakets{$mid}</li>";
         &sql_do($dbh,"UPDATE users SET paket=$pakets{$mid} WHERE id=$id LIMIT 1");
      }
      if ($balance!=0)
      {
         $out2.="<li>$client - ��������� ������ ����� ������ �� ������ ����, ������ ������� ���� ������ �� �������� ������. ������ �������� ������ �������.</li>";
         &sql_do($dbh,"UPDATE users SET balance=0 WHERE id=$id AND mid=$mid LIMIT 1",'�������� ������ �������� ������');
      }
   }

   if ($mid && $cash!=0)
   {  # ������ �� ��������� �������� ����� ����� �������� = 0, �� ��� ������ ��������
      $out1.="<li>$client - �������� ������ � �� ��� �������� �������. ������� ���������� ��������� �� �������� ������.</li>";
   }
  }

sub check_tarif
{
 ($f,$sql,$h)=@_;
 $sth=&sql($dbh,"SELECT u.id,u.name,u.$f FROM users u LEFT JOIN plans2 p ON u.$f=p.id WHERE u.mid=0 AND u.grp IN ($Allow_grp) AND $sql (p.name='' OR p.id IS NULL)",
   '���� ������� �� �������������� ������� � �� ������� ��� ��������?');
 $out1.='<li>'.&ShowClient($p->{id},$p->{name},'')." - �������������� $h � ".$p->{$f}.'</li>' while ($p=$sth->fetchrow_hashref);
}

&check_tarif('paket','','�����');
&check_tarif('next_paket','u.next_paket<>0 AND','���������� �����');

{
 last unless $Adm->{pr}{SuperAdmin};
 $out4='';
 $i=0;
 $sth=&sql($dbh,"SELECT * FROM users_trf WHERE uid NOT IN (SELECT id FROM users)",'� ������� users_trf ���� ������-������?');
 while ($p=$sth->fetchrow_hashref)
 {
    $h='id='.$p->{uid}.
       ", in1=$p->{in1} out1=$p->{out1}".
       ", in2=$p->{in2} out2=$p->{out2}".
       ", in3=$p->{in3} out3=$p->{out3}".
       ", in4=$p->{in4} out4=$p->{out4}";
    &ToLog("��������� ������ � ������� users_trf, $h");
    $out4.=$h.$br;
    $i++;
 } 
 if ($i)
 {
    $limit=50;
    if ($i<=$limit)
    {
       $rows=&sql_do($dbh,"DELETE FROM users_trf WHERE uid NOT IN (SELECT id FROM users) LIMIT $limit");
       $out4.=&bold("������� $rows �������");
    }else
    {
       $out4.=&bold('��������! ���������, ��� ������� ������� �����. NoDeny ������� �� �������������� �������� ������ ������������� �� ��� ������ '.
        '��������� ���� ��� ��������� ���� ���� ������. ��� ���������� ����� ��������� id ������������� ���� � �������� �� ��� ����������, ����� �������� ��� '.
        '�����������. ���� �� �� ������ �� ����� �������� ����������, �.� ��� ������������� ������-������, ��������� sql-������:<br><br>'.
        "DELETE FROM users_trf WHERE uid NOT IN (SELECT id FROM users)");
    }
    $out1.="<li>� ������� users_trf ������������ ������, ������� �� ������������� �� � ����� ��������. �������� ��� ��������� � ���������� ".
      "������������� �������� ��������, �.� �� ���������� ������� NoDeny. ��� ��������� ������ ���� ������� ����� ������ ������� �� ������� ".
      "��� ������ ������������� � �� ��������� � ��� ������ �� ������ ��������. ������� ����� ���������� � ���� ������� �� �������� � ����� ���� ".
      "�������, ������ ����� ����� ������� ������ �������� ������ ������� �� ������� �����. �� ������ ������ ������ ����� �������� � �����, ����� ".
      "� ������� ���� ����������� ������. ������ id �������:$br2$out4</li>";
 }

 @f=(
    "���������� ������� � ������� �������� (pays), ������� ������� � �������������� � �� ���������",
    "FROM pays p LEFT JOIN users u ON u.id=p.mid WHERE u.grp IS NULL and p.mid>0",'p.*',
    "���� mid ��������� �� ������������� ���������� ������. ���� type ����� 10 � ��� ���� bonus='', �� ������ ���������� - ".
      "�������� ������� �������� �� ���������� '�� �����' � �������������� admin_id.",

    "���������� ������� � ������� �������� (pays), ������� ������� � �������������� � �� �����������",
    "FROM pays p LEFT JOIN j_workers w ON p.mid=-w.worker WHERE w.office IS NULL and p.mid<0",'p.*',
    "���� mid ��� ����� ��������� �� ������������� ������ ��������� � ������� j_workers. �������� ������� �������� �� ���������� '�� �����' � �������������� admin_id.",

    "���������� ������� ���� '�������� ��������' � ������� �������� (pays), ������� ������� � �������������� � �� ����������������",
    "FROM pays p LEFT JOIN admin a ON p.reason=a.id WHERE p.type=40 AND a.office IS NULL",'p.*',
    "���� reason ��������� �� �������������� �������������� � ������� admin. �������� ������� �������� �� ���������� '�� �����' � �������������� admin_id.",

    "���������� ������� ���� '�������� ��������' � ������� �������� (pays), ������� ������� � �������������� � �� ����������������",
    "FROM pays p LEFT JOIN admin a ON p.coment=a.id WHERE p.type=40 AND a.office IS NULL",'p.*',
    "���� coment ��������� �� �������������� �������������� � ������� admin. �������� ������� �������� �� ���������� '�� �����' � �������������� admin_id.",

    "���������� ������� � ������� �������� (pays), ����� ������� ����������� � ������� ���������������",
    "FROM pays p LEFT JOIN admin a ON p.admin_id=a.id WHERE p.admin_id<>0 AND a.office IS NULL",'p.*',
    "���� admin_id ��������� �� �������������� �������������� � ������� admin.",

    "���������� ������� � ������� �������� (pays), � ������� ����������� �������� �����, ������ ������� �� �������� ����������� (���������, �������)",
    "FROM pays WHERE type NOT IN (10,20,40) AND cash<>0",'*',
    '��������� ���� cash � 0 �� �������� �� ���������� ��������� ������� ��� ��������������, �������������� ������. ������ ������������ ����������� ������ ��������� ����� ��������.',

    "���������� ������� ��������� � ������� �������� (pays), � ������� ��� ���� ����������� ������",
    "FROM pays WHERE type=30 AND reason='' AND coment=''",'*',
    '����� ����� ������� ����� ������.',
 );

 $out4='';
 while ($mess=shift @f)
 {
    $sql=shift @f;
    $sql_fields=shift @f;
    $mess2=shift @f;
    $p=&sql_select_line($dbh,"SELECT COUNT(*) AS n $sql",$mess);
    $out4.="<li>$mess: ".&bold($p->{n}).". ������ ������� ������ �������� �������� ������:".$br.
      "SELECT $sql_fields $sql$br$mess2</li>" if $p && $p->{n}>0;
 }
 $out2.=$out4;

 $out4='';
 $sth=&sql($dbh,"SELECT p.id FROM plans2 p LEFT JOIN newuser_opt n ON p.newuser_opt=n.id WHERE p.name<>'' AND p.newuser_opt<>0 AND n.opt_name IS NULL",
   '������ � ��������������� ������������������ �������������');
 $out4.=&ahref("$scrpt0&a=tarif&act=show&id=$p->{id}",$p->{id}).', ' while ($p=$sth->fetchrow_hashref);
 $out2.="<li>������ � ��������������� ������������������ �������������: $out4</li>" if $out4;
} 

$out.=&div('message',$out1? "<span class=error>��������� ��������:</span>$br2<ul>$out1</ul>" : '��������� ������� ���.',1);
$out.=&div('message',$out2? &bold('������ ��������:').$br3."<ul>$out2</ul>" : '������ ������� ���.',1);
$out.=&div('message','����������� ��������:'.$br3."<ul>$out3</ul>",1) if $out3;

$OUT.=&div('message lft',$out).$br;

# === �������� �������� ������ ===

&Exit;

1;

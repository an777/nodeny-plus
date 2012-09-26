#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008, 2009
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
$d={
	'name'		=> '������ ���������',
	'tbl'		=> 'c_grps',
	'field_id'	=> 'grp',
	'priv_show'	=> $Adm->{pr}{98},
	'priv_edit'	=> $Adm->{pr}{99},
};

sub o_menu
{
 return	&bold_br('������ ���������').
	&ahref($scrpt,'������ �����').
	($Adm->{pr}{99} && &ahref("$scrpt&op=new",'����� ������')).$br.
	&ahref("$scrpt&act=contacts",'��������').
	&ahref("$scrpt0&a=operations&act=help&theme=c_grp",'�������');
}

sub o_list
{
 $out='';
 $where=!$Adm->{pr}{104} && " WHERE g.office IN (0,$Adm->{office})";
 $sth=&sql($dbh,"SELECT g.*,COUNT(c.grp) AS n FROM c_grps g LEFT JOIN c_contacts c ON g.grp=c.grp $where GROUP BY g.grp ORDER BY g.office,g.name_grp");
 while ($p=$sth->fetchrow_hashref)
   {
    ($grp,$office,$name_grp,$n)=&Get_filtr_fields('grp','office','name_grp','n');
    $h=$Adm->{pr}{99} && ($Adm->{pr}{105} || $office==$Adm->{office}); # 105 - ���. �������� ����� �������
    $out.=&RRow('*','llccc',
      $name_grp,
      $cfg::Offices{$office} || '<span class=disabled>�������� ���� �������</span>',
      $n,
      &ahref("$scrpt&op=edit&id=$grp'",$h? '���':'��������'),
      $h && $n<1? &ahref("$scrpt&op=del&id=$grp'",'X') : ''
    );
   }

 $out or &Error(($Adm->{pr}{104}? '�� ������� �� ����� ������ ���������.' :
                  '�� ������� �� ����� ������ ��������� ����� ������.').$br2.
    ($Adm->{pr}{99} && &ahref("$scrpt&op=new",'������� ������')),$tend);

 $OUT.=&Table('tbg3 nav3 width100',
   &RRow('head','5',&bold_br('������ ���������')).
   &RRow('tablebg','cccC','������ ���������','�����','���������','��������').$out);
}

sub o_show
{
 if ($Adm->{pr}{105})
   {# ���� ����� �� ��������� ��������� ����� �������
    $offices=&Get_Office_List($office);
   }else
   {# � ����� ������ � ������� ���� �������� ����� ������ �.� � ������ ������ ����� �� ��������� � ����� ������� ����� ���� ����
    $offices=v::input_h('office',$office).($cfg::Offices{$office} || '���� �������');
   } 

 $OUT.=&form(%{$d->{form_header}},
   &Table('tbg3',
     &RRow('head','C',&bold_br($d->{name_action})).
     &RRow('*','ll','�������� ������',v::input_t('name_grp',$name_grp,50,127)).
     &RRow('*','ll','����� �������� ������ ������',$offices).
     &RRow('head','C',$Adm->{pr}{99} && ($Adm->{pr}{105} || $office==$Adm->{office})? &submit_a('���������') : "$go_back<br><br>")
   )
 );
}

sub o_getdata
{
 $p=&sql_select_line($dbh,"SELECT g.*,COUNT(c.grp) AS n FROM c_grps g LEFT JOIN c_contacts c ON g.grp=c.grp WHERE g.grp=$Fid GROUP BY g.grp");
 unless ($p)
   {
    $_=&sql_select_line($dbh,"SELECT time FROM changes WHERE tbl='c_grps' AND act=2 AND fid=$Fid");
    &Error(&the_short_time($_->{time},$t)." ������ ��������� � $Fid ���� �������.",$tend) if $_;
    &Error("������ ��������� ������ ������ ��������� � $Fid",$tend);
   }
 ($name_grp,$office,$n)=&Get_filtr_fields('name_grp','office','n');
 &Error("� ��� ��� ������� � ��������� ������ �������.",$tend) if !$Adm->{pr}{104} && $office && $office!=$Adm->{office};
 $d->{priv_edit}=$office!=$Adm->{office}? $Adm->{pr}{105} : $Adm->{pr}{99}; # ���� ����� ������, �� ��������� ���������� ����� �������������� ��������� ����� �������
 $d->{no_delete}='������ �������� ��������. ������� �� ��� ���������� � ������ ������.' if $n>0; # ��������� ����, ��� ������� ������
 $_='������ ��������� '.&commas($name_grp);
 $_.=' ������ '.commas($cfg::Offices{$office}) if $cfg::Offices{$office};
 $d->{name}=$_;
}

sub o_new
{
 $name_grp='';
 $office=$Adm->{office};
}

sub o_save
{
 $Fname_grp=&trim(&Filtr($F{name_grp}));
 $Fname_grp eq '' && &Error("�� �� ������� �������� ������ ���������. ��������� �� �������.$go_back",$tend);
 $Foffice=int $F{office};
 !$Adm->{pr}{105} && $Foffice!=$Adm->{office} && &Error("��� �� ��������� ������������� �������� ������ �������.",$tend);
 $d->{sql}="name_grp='".&Filtr_mysql($Fname_grp)."',office=$Foffice";
 $d->{new_data}=$Fname_grp ne $name_grp && '����� �������� ������ ���������: '.&commas($Fname_grp);
}

1;

#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008, 2009
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
$d={
	'name'		=> '��������',
	'tbl'		=> 'c_contacts',
	'field_id'	=> 'id',
	'priv_show'	=> 1,
	'priv_edit'	=> 1,
};

sub o_menu
{
 $Fgrp=defined $F{grp}? int $F{grp} : -1;
 $Fgrp=-1 if $Fgrp<-1;
 $grps='<option value=0>������</option>';
 %c_grps=();
 $sth=&sql($dbh,"SELECT * FROM c_grps ".(!$Adm->{pr}{104} && "WHERE office=$Adm->{office} ")."ORDER BY name_grp");
 while ($p=$sth->fetchrow_hashref) 
   {
    ($grp,$name_grp)=Get_filtr_fields('grp','name_grp');
    $grps.="<option value=$grp>$name_grp</option>";
    $c_grps{$grp}=$name_grp;
   }
 $grps.='</select>';
 $h=$grps;
 $h="<select name=grp size=1><option value=-1>��� ��������</option>$h";
 $grps="<select name=grp size=1>$grps";
 $h=~s/<option value=$Fgrp>/<option value=$Fgrp selected>/;
 return &bold_br('��������').
   &form('#'=>1,'act'=>$Fact,"$h<br><br>".v::input_t('text',$F{text},20,80)." <input type=submit value='�����'>").$br2.
   &ahref("$scrpt&act=contacts&op=new",'����� �������').$br.
   &ahref("$scrpt&act=c_grp",'������');
}

sub o_list
{
 $out='';
 $txt2=$txt=$F{text};
 $txt2=~tr/qwertyuiop[]asdfghjkl;'zxcvbnm,.QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>/����������������������������������������������������������������/;
 $txt=&Filtr_mysql($txt);
 $txt2=&Filtr_mysql($txt2);

 $where=$Fgrp>=0? "c.grp=$Fgrp" : '1';
 $where.=" AND c.id_admin=$Adm->{id}" unless $Fgrp;
 $where.=" AND (c.id_admin=$Adm->{id} OR c.grp<>0)" if $Fgrp<0;
 $where.=" AND (g.office IN (0,$Adm->{office}) OR c.grp=0)" if $Fgrp && !$Adm->{pr}{104}; # ��� ���� ������������� �������� ����� �������
 $where.=" AND (c.name_contact LIKE '%$txt%' OR c.contact LIKE '%$txt%' OR c.name_contact LIKE '%$txt2%' OR c.contact LIKE '%$txt2%')" if $txt!~/^\s*$/;

 $sql="SELECT c.*,g.name_grp,g.office FROM c_contacts AS c LEFT JOIN c_grps g ON c.grp=g.grp WHERE $where ORDER BY g.office,c.name_contact";
 ($sql,$page_buttons,$rows,$sth)=&Show_navigate_list($sql,$start,70,"$scrpt&grp=$Fgrp&text=".&URLEncode($F{text}));

 while ($p=$sth->fetchrow_hashref)
   {
    ($id,$grp,$id_admin,$name_grp,$office)=&Get_filtr_fields('id','grp','id_admin','name_grp','office');
    $name_grp=&bold('������ �������') unless $grp;
    # ��������� �������������, ����:
    #  - ������ ������� ���
    #  - ���� ����� ������������� �������� ������ ������� ���
    #  - ����� ������������� �������� ������ ������ � ����� ���� ���� ������� �� �������� � ������
    $h=!$grp || $Adm->{pr}{105} || ($Adm->{pr}{99} && ($office==$Adm->{office} || $office==0));
    $out.=&RRow('*','llllcc',
       &Show_all($p->{name_contact}),
       &Show_all($p->{contact}),
       $name_grp,
       $cfg::Offices{$office},
       $h && ahref("$scrpt&op=edit&id=$id'",'��������'),
       $h && ahref("$scrpt&op=del&id=$id'",'�������')
     );
   }

 $out or &Error("�� ������� �� ������ ��������.",$tend); 

 $OUT.=&Table('tbg3 nav3 width100',
   &RRow('head','6',&bold_br('��������')).
   ($page_buttons && &RRow('head','6',$page_buttons)).
   &RRow('tablebg','ccccC','���','�������','������','�����','��������').
   $out
 );
}

sub o_show
{
 $grps='������� ����� �������� ������ ���'.v::input_h('grp'=>0) unless $Adm->{pr}{99};
 $OUT.=&form(%{$d->{form_header}},
   &Table('tbg3',
     &RRow('head','C',&bold_br($d->{name_action})).
     &RRow('*','ll','������ ��������',$grps).
     &RRow('*','ll','���',v::input_t('name_contact',$name_contact,50,127)).
     &RRow('*','ll','�������',"<textarea rows=8 cols=40 name=contact>$contact</textarea>").
     (!!$id_admin && &RRow('*','ll','��������� ��������������','������������� '.&bold($admin)." (id=$id_admin)")).
     &RRow('head','C',$d->{priv_edit}? &submit_a('���������') : "$go_back<br><br>")
   )
 );
}

sub o_getdata
{
 $p=&sql_select_line($dbh,"SELECT c.*,g.office,a.admin FROM c_contacts AS c LEFT JOIN c_grps g ON c.grp=g.grp ".
    "LEFT JOIN admin a ON c.id_admin=a.id WHERE c.id=$Fid LIMIT 1");
 unless ($p)
   {
    $_=&sql_select_line($dbh,"SELECT time FROM changes WHERE tbl='c_contacts' AND act=2 AND fid=$Fid");
    &Error(&the_short_time($_->{time},$t)." ������� � $Fid ��� ������",$tend) if $_;
    &Error("������ ��������� ������ �������� � $Fid",$tend);
   }
 ($grp,$id_admin,$office)=&Get_fields('grp','id_admin','office');
 ($name_contact,$contact,$admin)=&Get_filtr_fields('name_contact','contact','admin');
 &Error("� ��� ��� ������� � ����� ������ ���������.",$tend) if !$grp && $id_admin!=$Adm->{id};
 &Error("� ��� ��� ������� � ��������� ������ �������.",$tend) if !$Adm->{pr}{104} && $grp && $office!=$Adm->{office};
 $d->{priv_edit}=!$grp? 1 : $office!=$Adm->{office}? $Adm->{pr}{105} : $Adm->{pr}{99}; # ���� ����� ������, �� ��������� ���������� ����� �������������� ��������� ����� �������
 $grps=~s/<option value=$grp>/<option value=$grp selected>/;
 $h=defined $c_grps{$grp}? &commas($c_grps{$grp}) : "� id=$grp";
 $d->{name}='�������� '.&commas($name_contact).($grp? " � ������ ��������� $h" : " � ������ ���������");
}

sub o_new
{
 $contact=$name_contact='';
 $grp=-1;
 $id_admin=0;
}

sub o_save
{
 $Fname_contact=&trim(&Filtr($F{name_contact}));
 $Fcontact=&Filtr_mysql($F{contact});
 $Fname_contact eq '' && &Error("�� �� ������� �������� ��� ��������. ��������� �� �������.$go_back",$tend);
 $Fgrp=int $F{grp};
 $Fgrp=0 if $Fgrp<0;
 $Fgrp=0 if $Fgrp && !$Adm->{pr}{99}; # �� ��������� ����������/��������� ������� � ������, ���� ��������� ������������� ���� ������
 # ��������� ������ �� �����, ����� ������ ������� ���� �����, ��������� ��� �� ��� ������ �������
 $d->{sql}="id_admin=$Adm->{id},name_contact='$Fname_contact',contact='$Fcontact',grp=$Fgrp";
 $d->{new_data}=$Fname_contact ne $name_contact && ($Fid? '����� ��������: ' : '��������: ').&commas($Fname_contact);
 $h=defined $c_grps{$Fgrp}? &commas($c_grps{$Fgrp}) : "� id=$Fgrp";
 $d->{new_data}.=($d->{new_data} && '. ').($Fid? '��������� ' : '������� ').
    ($Fgrp? "� ������ ��������� $h" : "� ������ `������`, �.�. �� ����� �������� ������ ���������������") if $Fgrp!=$grp;
}

1;

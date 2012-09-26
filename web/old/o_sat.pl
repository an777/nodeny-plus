#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008, 2009
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
$d={
	'name'		=> '������������ ���������',
	'tbl'		=> 'conf_sat',
	'field_id'	=> 'id',
	'priv_show'	=> $Adm->{pr}{main_tunes},
	'priv_edit'	=> $Adm->{pr}{edt_main_tunes},
};

sub o_menu
{
 return	&ahref($scrpt,'������ ����������').
	($Adm->{pr}{edt_main_tunes} && &ahref("$scrpt&op=new",'����� ��������'));
}

sub sat_load_config
{
 $satcfg_fname = "$cfg::dir_web/satellite.cfg";
 open(FL,"<$satcfg_fname") or Error("������ �������� �����-������� ������������ ��������� <b>$satcfg_fname</b>!",$tend);
 @cfg_lines=<FL>;
 close(FL);
}

sub o_list
{
 $out='';
 $sth=&sql($dbh,"SELECT * FROM conf_sat ORDER BY login");
 while ($p=$sth->fetchrow_hashref)
   {
    ($id,$login,$name)=&Get_filtr_fields('id','login','name');
    $out.=&RRow('*','llcc',
      "&nbsp;&nbsp;$login",
      "&nbsp;&nbsp;$name",
      &ahref("$scrpt&op=edit&id=$id",$d->{button}),
      $Adm->{pr}{edt_main_tunes} && &ahref("$scrpt&op=del&id=$id",'�')
    );
   }

 $out or &Error('� ���� ������ ��� ������� �� ��� ������ ���������.'.$br2.&ahref("$scrpt&op=new",'������� ������ ���������'),$tend);

 $OUT.=&Table('tbg3 nav3 width100',
   &RRow('head','4',&bold_br('������ ����������')).
   &RRow('head','cccC','�����','��������','��������').
   $out);
}

sub o_getdata
{
 $p=&sql_select_line($dbh,"SELECT * FROM conf_sat WHERE id=$Fid LIMIT 1");
 $p or &Error($d->{when_deleted} || "������ ��������� ������� ��������� � id=$Fid.",$tend);
 ($login,$name,$comment)=&Get_fields('login','name','comment');
 $name=&Filtr($name);
 foreach (split /\n/,$p->{config}) {$c{$1}=$2 if /^([^ ]+) (.*)$/}
 $d->{name}=&Printf('��������� � ������� [filtr|commas]',$login);
}

sub o_new
{
 $login=$name=$comment='';
}

sub o_show
{
 $ses::role eq 'admin' or Error($Mess_UntrustAdmin,$tend);
 &sat_load_config;
 $out='';
 foreach $i (@cfg_lines)
   {
    next if $i!~/^([^\s]+)\s+'([^']*)'\s+(.+)$/;
    ($i1,$i2,$i3)=($1,$2,$3);
    if ($i1 eq 'R')
      {
       $out.=&RRow('head','Cl',&bold_br($i2),'��������������� ��������').&RRow('*','E',$i3);
       next;
      }
    $default_value=$i2=~/^\$(.+)$/? ${$1} : $i2;
    # ��������������: ������� ��������; ��������: �������� �� ��������� �� �������
    $value=$d->{form_header}{id}? $c{$i1} : $default_value;
    $out.=&RRow('*','lll',v::input_t("s_$i1",$value,40,255),$i3,v::filtr($default_value));
   }    
 $OUT.=&form(%{$d->{form_header}},
   &Table('tbg1i',
     &RRow('head','3',&bold_br($d->{name_action})).
     &RRow('*','lll','����� ���������',v::input_t('login',$login,40,128),'� ���� ������� ����� �������������� ������� ��������� � ����� ������').
     &RRow('*','lll','��� ���������',v::input_t('name',$name,40,128),'').
     &RRow('*','lll','�����������',v::input_ta('comment',$comment,44,3),'').$out.
     ($Adm->{pr}{edt_main_tunes} && &RRow('head','3',$br.&submit_a('���������').$br2))
   )
 );
}

sub o_save
{
 $ses::role eq 'admin' or Error($Mess_UntrustAdmin,$tend);
 &sat_load_config;
 $Flogin=&trim(&Filtr_mysql($F{login})) || 'SET LOGIN';
 $Fname=&Filtr_mysql($F{name});
 $Fcomment=&Filtr_mysql($F{comment});
 $config='';
 foreach $i (@cfg_lines)
   {
    next if $i!~/^([^\s]+)\s+'([^']*)'\s+(.+)$/ || $1 eq 'R';
    $i1=$1;
    $_=&trim($F{"s_$i1"});
    s|\n||g;
    $config.="$i1 $_\n";
   } 
 $config=&Filtr_mysql($config);  
 $d->{sql}="login='$Flogin',name='$Fname',comment='$Fcomment',config='$config',Passwd_Key='$Passwd_Key',version=0,time=$ut";
 $d->{name}=Printf('��������� � ������� [filr|trim|commas]',$F{login}) if !$Fid;
}

1;

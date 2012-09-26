#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2012
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
# �������� ������� ����� ������������� �� out � �� mysql, �.� ����� �� ����� ������������� �����������
use nomoney;

sub Get_fields
{
 return map{$p->{$_} }(@_);
}

$Adm->{pr}{tarifs} or Error('��� �� ��������� ������������� ������.');

%Flags=(
 'a' => '��������� �������� ����� ���������� ���������� ���������� ������ ����� �� ��������� �����',
 'b' => '���� � ������� ������ ������ �����, �� ������ �� ����� �������� �������������� ����� ������ � ��������� ������',
 'c' => '���� � ������� ������ ������ ����� � ��������� ���������� ������, �� ������ ����� ���������� ������ ������ �� �������� �������',
 'd' => '� �������� ������� ������ �������� ���� ������ ���� ������������',
 'f' => '�������������� ������ ���������� �� ��������� �����',
 'g' => '��� ������� ������ �� ������������ ���������������� �������������� ������ ��� ����� ��������, �.�. ���� ������ ����������� ����� ����� ���������� � ���� ��� ����� ��������',
 'h' => '��������� ��������� ����������� �������',
 'j' => '����������� �������� ������������� � ��� ������� ����� ���������',
 'k' => '������ ������ ���� ������������ ������',
 'm' => '��� ��������� �������� ����������� ��������� ������� � ���������� ���������� �������� �������������� ������ � ���� �� ������. '.
        '����� ����������� ������ �� ������� ����� � ����� �����, ������� ����� ����������� � �������� �������. ������ ������� ����� �������',
 'n' => '�������� �������� � ������ �������, ��������� � ������',
 'p' => '�������� �������. �������������� �����������!',
 'x' => '����������� �������� �� ������������� ��� ������� ����������� 2',
 'y' => '����������� �������� �� ������������� ��� ������� ����������� 3',
 'z' => '����������� �������� �� ������������� ��� ������� ����������� 4', 
); 

$m_tarif<1 && &Error("������� � ���������� ���������� �������� ������.");

$Fact=$F{act};
$Fid=int $F{id};

%subs=(
 'list' => 1,
 'show' => 1,
 'save' => 1,
);


$Fact='list' if !defined $subs{$Fact}; 
&{$Fact};
&Exit;

sub list
{# ������ �������
 $sth=&sql($dbh,"SELECT * FROM plans2 WHERE id<=$m_tarif");
 while( $p=$sth->fetchrow_hashref )
 {
    $i=$p->{id};
    $Plan_name{$i}=$p->{name};
    ($Plan_preset{$i},$Plan_offices{$i},$Plan_m1{$i},$Plan_m2{$i},$Plan_m3{$i},$Plan_m4{$i},$Plan_flags{$i},$Plan_speed{$i})=
      &Get_fields('preset','offices','mb1','mb2','mb3','mb4','flags','speed');
 } 

 $out='';
 for $i (1..$m_tarif)
 {  # �������� � ���� ������������� ������
    defined $Plan_name{$i} && next;
    $rows=Db->do("INSERT INTO plans2 SET id=$i");
    $out.="������ ����� �$i.".$br if $rows==1;
 }
 Show MessageBox('������������� ���������:'.$br2.$out) if $out;

 @out=();
 foreach $i (sort {$Plan_name{$a} cmp $Plan_name{$b}} keys %Plan_name)
 {
    $Plan_name{$i} or next;
    $sort_prefix=$Plan_name{$i};
    $sort_prefix=($Plan_name{$i}=~/^\[(\d+)\]/)? $1 : '';
    $sort_prefix-=1000 if $sort_prefix>1000;
    $p=$Plan_preset{$i};
    $out{$p}||=&RRow('head','3','������ � '.v::bold($p).". $Presets{$p}");
    $h='';
    foreach( 1..4 )
    {
       $h.="����������� <b>$_</b> �����. " if ${"Plan_m$_"}{$i}>=$cfg::unlim_mb;
    }
    $h.="����������� �� ��������. " if $Plan_speed{$i};
    $h.="����������. �������� ����. " if $Plan_flags{$i}=~/d/;
    $h.="�������������� ������ ���������� �� ��������� �����. " if $Plan_flags{$i}=~/f/;
    $h.="��������� ���������� �� ��������� �����. " if $Plan_flags{$i}=~/a/;
    $h.="�������� �������� � ��������� ���������� �������. " if $Plan_flags{$i}=~/n/;
    $out{$p}.=&RRow('*','rll',
       $sort_prefix,
       &ahref("$scrpt&act=show&id=$i",&Del_Sort_Prefix($Plan_name{$i})),
       $h
    );
 }

 $out=join '',map{ $out{$_} } sort{ $a <=> $b } keys %out;
 Show Table('tbg3 width100 nav3',$out);

 $out=join ' &nbsp;&nbsp;', map {&ahref("$scrpt&act=show&id=$_",$_)} (grep !$Plan_name{$_}, 1..$m_tarif);
 Show $br2.&div('message lft','��������� ������:'.$br.$out) if $out;

 $out='';
 $sth=&sql($dbh,"SELECT p.*,a.admin,a.name FROM pays p LEFT JOIN admin a ON a.id=p.admin_id ".
    "WHERE p.type=50 AND p.category IN (471,472) ORDER BY p.time DESC LIMIT 15");
 while ($p=$sth->fetchrow_hashref)
 {
    $tt=$p->{time};
    # ������� ������� ������ ���� �������������� ���� � ��������� 24 ����
    $out.=&tag( 'span',&the_time($tt),'class='.($tt>($t-24*3600)? 'error' : 'disabled') ).' '.v::bold($p->{admin}).': '.v::filtr($p->{coment}).$br;
 }
 Show $out && $br2."��������� �������������� �������:".$br.&div('message lft',$out);
}

# ==========================
#  ���������� ������ ������
# ==========================

sub save
{# �������� ������ �������
 $Adm->{pr}{edt_tarifs} or Error('��� �� ��������� ������ ������.');

 $p=&sql_select_line($dbh,"SELECT * FROM plans2 WHERE id=$Fid");
 $p or &Error("������ ��������� ������ ������ � $Fid. ������ ������ �� ��������.");

 ($old_name,$preset)=&Get_fields('name','preset');

 $old_name=&Filtr($old_name); # �� ������ ������ (������ �������������� ����)
 $preset=int $F{preset};
 $sort_prefix=int $F{sort_prefix}+1000;
 $name=&Filtr($F{name});
 $name='0.' if $name eq '0'; # ���������� ����� if $name ����� true (����� ����������)
 $cname=$name? '������ '.v::commas($name) : '�������������� ������';
 $name="[$sort_prefix]$name" if $name;

 $price=$F{price}+0;
 $price_change=$F{price_change}+0;
 $m2_to_m1=$F{m2_to_m1}+0;
 $k=$F{k}+0;

 $start_hour=$F{s};
 $end_hour=$F{e};
 @f=(\$start_hour,'������',\$end_hour,'���������');
 while( $i=shift @f )
 {
    $h=shift @f;
    if( $$i && ($$i!~/^\d\d?$/ || $$i>23) )
    {
        $$i=0;
        ErrorMess("��������������: `��� $h �������` $cname ����� �������� ��������, ������������ � 0.");
    }
    $$i=int $$i;
 }

 @m=@InOrOut=@o=();
 foreach $i (1..4)
 {
    $m[$i]=&trim($F{"m$i"});
    $m[$i]=$m[$i] eq '!'? $cfg::unlim_mb : int $m[$i];
    $InOrOut[$i]=int $F{"w$i"};
    $o[$i]=$F{"o$i"}+0;
    if( $i>1 && $m[$i] && $o[$i]==0 )
    {
        ErrorMess("<b>��������������</b>: � ������ $cname � ����������� � $i ���������� �������������� ������, ������ ���� ����������� ����� ����. ".
         "���� ����������� ������ ���� ��������, ��� ����������� � $i ������ ��� <b>�������</b> ������ ����� ��������� 1� ������������. ����� �������, ".
         "�������������� ������ ����������� �$i ����� �������������� ��� �����������. ".
         "���� �� �� ������ ����� ��� ����������� ������������������ �� ������ - ���������� ����������� � ��������� ��������. ���� �� ������ ������� ".
         "����������� ����������� - ���������� �������������� ������ � �������� ".v::commas('!').' (������ '.v::commas('��������������� ����').'), '.
         "� ����������� � 1 $gr/��. � ����� ������ ������ ����� ����������� ��������� '�����������', � ���� ����������� ���������� �� �����")
    }
 }

 $flags=join '', grep $F{"flag$_"}, ('a'..'z');

 $speed=int $F{speed};
 $speed_out=int $F{speed_out};
 $speed2=int $F{speed2};
 $newuser_opt=int $F{newuser_opt};

 $offices = join ',', grep{ $F{"of_$_"} } sort{ $a <=> $b } keys %cfg::Offices;
 $offices = ",$offices," if $offices;

 $usr_grp = join ',', grep{ $F{"ugrp_$_"} } sort{ $a <=> $b } keys %$Ugrp;
 $usr_grp = ",$usr_grp," if $usr_grp;

 $pays_opt='';

 $sql="UPDATE plans2 SET ".
   "name='$name',price=$price,price_change=$price_change, ".
   "mb1=$m[1],mb2=$m[2],mb3=$m[3],mb4=$m[4], ".
   "priceover1=$o[1],priceover2=$o[2],priceover3=$o[3],priceover4=$o[4], ".
   "in_or_out1=$InOrOut[1],in_or_out2=$InOrOut[2],in_or_out3=$InOrOut[3],in_or_out4=$InOrOut[4], ".
   "speed=$speed,speed_out=$speed_out,speed2=$speed2, ".
   "start_hour=$start_hour,end_hour=$end_hour,k=$k, ".
   "m2_to_m1=$m2_to_m1,".
   "flags='$flags',".
   "preset=$preset,".
   "newuser_opt=$newuser_opt,".
   "offices='$offices',".
   "usr_grp='$usr_grp',".
   "pays_opt='$pays_opt',".
   "script='".Filtr_mysql(trim($F{plan_script}))."',".
   "descr='".Filtr_mysql(trim($F{descr}))."'".
  " WHERE id=$Fid LIMIT 1";

 $rows=Db->do($sql);

 $rows<1 && &Error("������. ������ $cname (� $Fid) �� ��������!");

 $h=$name? qq{��� ������ "$name"} : '����� ���������� (���������)';
 $mess="������� ����� � $Fid, ".(!$old_name? "�� �������������� ����� ��� ���������� (���������). ������ $h":
       $old_name ne $name? qq{�� �������������� � ������ ���� ��� "$old_name", ������ $h} : $h);

 Pay_to_DB( type => 50, category => 471, reason => "���� ���� �� �������� �� ��������� �������", coment => $mess );

 $mess = "$Adm->{info_line} $mess";

 ToLog("! $mess");
 Show MessageBox("����� ".&ahref("$scrpt&act=show&id=$Fid",&Del_Sort_Prefix($name))." ��������.".$br2.
   '������� ������� ������ '.&ahref("$scrpt&a=restart&act=send&s=2",'�������� ������').' ��� ���������� ���������.'.$br2.
   '��������� ������ ����� ���� ��� ��������� ��������� ���� �������.'.$br2.&ahref("$scrpt&act=list",'������ �������'));
}


# =============================
# ����������� ���������� ������
# =============================

sub Get_filtr_fields
{
 my @f = @_;
 return map{ v::filtr($p->{$_}) } (@f);
}

sub show
{
 $p=&sql_select_line($dbh,"SELECT * FROM plans2 WHERE id=$Fid");
 $p or &Error("������ ��������� ������ ������ � $Fid.");

 $name=&Filtr($p->{name});
 $sort_prefix=$name=~s|^\[(\d+)\]||? $1-1000 : '';
 $sort_prefix=0 if $sort_prefix<0;
 ($m1,$m2,$m3,$m4,$price,$price_change,$over1,$over2,$over3,$over4)=&Get_fields('mb1','mb2','mb3','mb4','price','price_change','priceover1','priceover2','priceover3','priceover4');
 ($m2_to_m1,$start_hour,$end_hour,$k,$flags,$speed,$speed_out,$speed2,$preset)=&Get_fields('m2_to_m1','start_hour','end_hour','k','flags','speed','speed_out','speed2','preset');
 ($InOrOut1,$InOrOut2,$InOrOut3,$InOrOut4,$offices,$usr_grp,$pays_opt,$newuser_opt)=&Get_fields('in_or_out1','in_or_out2','in_or_out3','in_or_out4','offices','usr_grp','pays_opt','newuser_opt');
 ($plan_script,$descr)=&Get_fields('script','descr');

 $listx="<option value=0>����</option><option value=1>�����</option><option value=2>�����</option><option value=3>�������</option>";
 @in_out=();
 foreach $i (1..4)
 {
    ${"over$i"}=sprintf("%.5f",${"over$i"}) if ${"over$i"} && ${"over$i"}<0.001;
    ${"m$i"}='!' if ${"m$i"}>=$cfg::unlim_mb;
    $in_out[$i]=$listx;
    $h=$name? ${"InOrOut$i"} : 2; # ���� ����� �����, �� �������������� ������������ - `��������� ������`
    $in_out[$i]=~s/$h/$h selected/;
    $in_out[$i]="<select name=w$i size=1>$in_out[$i]</select>";
 }

 # ������� �������� ����������� �� �������
 ($class1,$class2,$class3,$class4)=('','','',''); # ���� � ������� �� ����� �������
 $sth=&sql($dbh,"SELECT * FROM nets WHERE preset=$preset AND priority=0");
 ${'class'.$_->{class}}=v::filtr($_->{comment}) while ($_=$sth->fetchrow_hashref);

 $presets='';
 foreach (sort {$a <=> $b} (keys %Presets)) {$presets.="<br>&nbsp;&nbsp;<b>$_</b> - $Presets{$_}"}

 $Offices='';
 $Offices.="<input type=checkbox value=1 name=of_$_".($offices=~/,$_,/ && ' checked').
    "> $cfg::Offices{$_}".$br foreach (sort {$a <=> $b} (keys %cfg::Offices));
 $Offices=&bold('��� �������. � ���������� ������� ��� ������� ����') unless $Offices;

 $Usr_grp='';
 foreach ( sort{ $Ugrp->{$a}{name} cmp $Ugrp->{$b}{name} } keys %$Ugrp )
 {
    $Adm->{grp_lvl}{$_} or next; # ������ � ���� ������ ��������� ������������
    $Usr_grp.="<input type=checkbox value=1 name=ugrp_$_".($usr_grp=~/,$_,/ && ' checked')."> $Ugrp->{$_}{name}".$br;
 }

 $Pays_opt='';

 $list_nu_opt='';

 Show form_a('act'=>'save','id'=>$Fid);
 Show Table('tbg3 width100',&RRow('head nav2','cc',&submit('���������'),$br.&ahref($scrpt,'������ �������').$br)) if $Adm->{pr}{edt_tarifs};

 Show "<table><tr><td valign=top><table class='tbg3 width100'>".
   &RRow('*','ll',v::input_t(name=>'name',value=>$name),'�������� ������. ���������� �������� ��������� ������������� ������').
   &RRow('*','ll',v::input_t(name=>'sort_prefix',value=>$sort_prefix).' ������� ����������','�����').
   &RRow('*','ll',v::input_t(name=>'preset', value=>$preset).' ������','�����, ����������� ����� ������� �� �������� ��� ������� ��������� ����� �� ������� �������� ����� ����� ������� '.
                 "�������� ����������� � ������� ��� ���� �����������. �� ������ ��������� �������:$presets").
   ($list_nu_opt && &RRow('*','ll',$list_nu_opt,'����������������� �����������. ���� ��� �������� ������� ������ ������� ����� ������ ������� �����, �� ������������� ����� ��������� ������ �� �����������, ��������� � ���� ����.'));

 $out=join $br,map{ "<input type=checkbox name=flag$_ value=1".($flags=~/$_/ && ' checked')."> - $Flags{$_}" }(sort keys %Flags);
 Show RRow('*','L',$out);

 Show RRow('*','ll',v::input_t(name=>'price',value=>$price)." ��������� ��������� �����",
     "������ ����� ����� ��������� �� ����� ������� � ������������� �� ���������� ������������ �������������� ��������. �� ���� ���������. ".
     "���������� � 0, ���� �� ���������������� ������ ������ ��������������� ������������� �������").
  &RRow('*','ll',v::input_t(name=>'price_change',value=>$price_change)." ��������� ��������","��������� �������� �� ������ ����� � �������� ������").
  &RRow('*','ll',v::input_t(name=>'speed',value=>$speed||'')." �������� �������",
    "��������, �� ������� ����� ��������������� ������ � ��������. 0 ���� ������ �������� �� ������������ ��������.").
  &RRow('*','ll',v::input_t(name=>'speed_out',value=>$speed_out||'')." �������� ������� �� �����",
    "��������� ��������. 0 ���� ������ �������� ��������� �� ��, ��� ��������� �������� ����� �������� ������ ��������, �.�. ����������� �� �������� ����� ����������� �� ����� �������� � ��������� ��������").
  &RRow('*','C',"����������� �1. <b>$class1</b>").
  &RRow('*','ll',v::input_t(name=>'m1',value=>$m1)." �������������� ������, ��",
    '���������� ������� ������� �� ������������, �.�. ������ � ���������. ������� '.v::commas('!').' (������ '.v::commas('��������������� ����').') ��� ���������').
  &RRow('*','ll',v::input_t(name=>'o1',value=>$over1)." ��������� ����������, $gr/��",
    "��������� ������� ��������� ���������� ��������������� �������. ���� ������ �������� ����� ����� 0, �� ��� ���������� ��������������� ������� ������ � �������� ����������� �� ����������� ������ ������").
  &RRow('*','ll',"$in_out[1] ������������ ������������",
    "������������ �������, ������� ����� ����������������. ��������, ���� ������ '����' - ��������� ������ �� ����� ����������� ��� �������� ��������� ������� �����������").
  &RRow('*','C',"����������� �2. <b>$class2</b>").
  &RRow('*','ll',v::input_t(name=>'m2',value=>$m2)." �������������� ������, ��",
    "���������� ������� ������� �� ������������, �.�. ������ � ���������").
  &RRow('*','ll',v::input_t(name=>'o2',value=>$over2)." ��������� ����������, $gr/��",
    "��������� ������� ��������� ���������� ��������������� �������. ���� ������ �������� ����� ����� 0, ��� ������� ������ ������ ������� ����������� ����� ����������� � ����������� �1. ".
    "��������, ����� ������� ����� ��� ��������� ������� ��������� ������� �� �����/������� ������, �� ��� ������  ������� ���������� �����������").
  &RRow('*','ll',"$in_out[2] ������������ ������������",
    "������������ �������, ������� ����� ����������������. ��������, ���� ������ '����' - ��������� ������ �� ����� ����������� ��� �������� ��������� ������� �����������").
  &RRow('*','ll',v::input_t(name=>'m2_to_m1',value=>$m2_to_m1)." ��������� �������.2 / �������.1",
    "���� �� ����� 0, �� ��� ����������� ������� ����������� �1, ���������� ������ ����� ����������� ����� '�������' � �������� ����������� ������ ����� �������. ������� ������������ ��� �����������").
  &RRow('*','C',"����������� �3. <b>$class3</b>").
  &RRow('*','ll',v::input_t(name=>'m3',value=>$m3)." �������������� ������, ��",
    "���������� ������� ������� �� ������������, �.�. ������ � ���������").
  &RRow('*','ll',v::input_t(name=>'o3',value=>$over3)." ��������� ����������, $gr/��",
    "��������� ������� ��������� ���������� ��������������� �������. ���� ������ �������� ����� ����� 0, ��� ������� ������ ������ ������� ����������� ����� ����������� � ����������� �1. ".
    "��������, ����� ������� ����� ��� ��������� ������� ��������� ������� �� �����/������� ������, �� ��� ������  ������� ���������� �����������").
  &RRow('*','ll',"$in_out[3] ������������ ������������",
    "������������ �������, ������� ����� ����������������. ��������, ���� ������ '����' - ��������� ������ �� ����� ����������� ��� �������� ��������� ������� �����������").
  &RRow('*','C',"����������� �4. <b>$class4</b>").
  &RRow('*','ll',v::input_t(name=>'m4',value=>$m4)." �������������� ������, ��",
    "���������� ������� ������� �� ������������, �.�. ������ � ���������").
  &RRow('*','ll',v::input_t(name=>'o4',value=>$over4)." ��������� ����������, $gr/��",
    "��������� ������� ��������� ���������� ��������������� �������. ���� ������ �������� ����� ����� 0, ��� ������� ������ ������ ������� ����������� ����� ����������� � ����������� �1. ".
    "��������, ����� ������� ����� ��� ��������� ������� ��������� ������� �� �����/������� ������, �� ��� ������  ������� ���������� �����������").
  &RRow('*','ll',"$in_out[4] ������������ ������������",
    "������������ �������, ������� ����� ����������������. ��������, ���� ������ '����' - ��������� ������ �� ����� ����������� ��� �������� ��������� ������� �����������").
  &RRow('head','C',"����������� �� �������. ���������� � 0 ��������� � �������� ����� ��� ���������� ����������� (�������) �� �������").
  &RRow('*','ll',v::input_t(name=>'k',value=>$k)." ��������",
    "��������, ������� ����� �������������� � ���������� ������� ����� ��������� � �������� ����� �����.".$br2.
     '= 0 - ������� ��������'.$br2.
     '&gt; 0 - �� ��� ����� ����� ���������� ������ �������, ���������� � ���������� ������� ����� '.
     '`���������` � `��������` �����.'.$br2.
     '&lt; 0 - ��������, ��� ��� ������� ���������� ������� ������ ����� �������������. '.
     '����� ������� � ������ �� ������� �� ������� �������� ��� ����������� ������ ����� �����������. '.$br2.
     '= 1 - � ��������� �������� ������� ������ ����������� 1 ����� �������� ��� ����������� '.
     ($Traf_change_dir? "2, � ����������� 3 - ��� ����������� 4" : "3, � ����������� 2 - ��� ����������� 4")
   ).
  &RRow('*','ll',v::input_t(name=>'s',value=>$start_hour).' ��������� �����','��� �����').
  &RRow('*','ll',v::input_t(name=>'e',value=>$end_hour).' �������� �����','��� �����').
  
  &RRow('head','C',&bold_br('�������� ����������� �����������')).
  &RRow('*','ll',v::input_t(name=>'speed2',value=>$speed2||''),
    "��������, �� ������� ����� ��������������� ������ � �������������� (����������) ������������. 0 ���� ������ �������� ��������� ����������� �������� �� �������� ��������� �����������.").
 
  &RRow('head','C',&bold_br('���������������� ��������� ������')).
  &RRow('*','ll',v::input_ta('plan_script',$plan_script,30,5),'������ �������� ��������������� ��������� ��������� ������ � ����������� �� ��������. ������ �� ��������� ����� �������������� ������ ��� ������� ���������� � �������������'.
    $br2.'0 - ������������ ���������� ����������'.$br2.
    $br2."8:xx - ���������������� ���������� ���������, ��� �� $gr - ������ ��������� ����� � �����".$br2.
    "9:xx - �������� ��������� � ������� xx $gr"
  ).
  &RRow('head','C',&bold_br('�������� ��� ��������')).
  &RRow('*','C',v::input_ta('descr',$descr,70,6)).
 '</table>';

  Show "</td><td valign=top>".
    MessageBox('������ �������, �������������� ������� ����� ����� ������ � ������� ������'.$br2.$Offices.$br2.
        '������ ����� ��������, ������� ������ ���������� ������ ����� ����� ���������� ����������. �������� ��������, '.
        '��� ���� �������� �������� ������ ������ ������� �� ��������� �����, �� ��������������� ������ �������� �� ����������������.<br><br>'.
        $Usr_grp.$br2
   ).
   '</td></tr></table></form>';
}

1;

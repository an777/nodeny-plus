#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2011
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
sub go
{
 $OUT.=$br;
 $go_main=$br2.&CenterA("$scrpt&a=101",'�� ������� &rarr;');

 $p=&sql_select_line($dbh,"SELECT mid FROM pays WHERE mid=$Mid AND type=50 AND category=450 LIMIT 1",'������������ �����/����� ��������� �����?');
 $p && &Error("��� �� ��������� ��������/���������� �������������� ����� ��������� �����. ��� ����� ������� ������ �������������.$go_main",$EOUT);

 $balance=$U{$Mid}{balance};
 $my_preset=$U{$Mid}{preset};
 $paket = $U{$Mid}{paket};
 $paket3 = $U{$Mid}{paket3};
 $next_paket = $U{$Mid}{next_paket};
 $next_paket3 = $U{$Mid}{next_paket3};
 $only_my_preset=$Plan_flags[$paket]=~/c/; # ������ ����� ���������� ������ ������, ������� ������ �������� ������ ($my_preset)

 $Fpaket=int $F{paket};
 $act=int $F{act};
 $actd=int($act/10);

 {
  last if $actd!=1;
  # ��������� ������
  &SP_AddPaket;
  return;
 }

 $out1=&SP_Select("$scrpt&act=21",0);
 $out2=&SP_Select("$scrpt&act=31&balance=$balance",1); # �������� ������, ����� �������������� ��������� ��������� � ���������� ���������� ��������
 $out3=&SP_Select3("$scrpt&act=41",0);
 $out4=&SP_Select3("$scrpt&act=51&balance=$balance",1); 

 &Error('��� �������� ������, ������� �� ������ �������� ����� ���������� ����������.',
        $EOUT) if !($out1 || $out2 || $out3 || $out4 || $next_paket || $next_paket3);

 {
  $act && last;
  $out=&div('big cntr','�������� ��������:').$br2.'<ul>';
  $out.='<li>�� ��������� ����� � ��� �������� �������������� ����� ��������� ����� �� '.
    &bold($Plan_name_short[$next_paket]).'. '.&ahref("$scrpt&act=21&paket=0",'�������� ����� ��������� �����').
    $br2.'</li>' if $next_paket;
  $out.='<li>�� ��������� ����� � ��� �������� �������������� ����� ��������� ����� �� '.
    &bold($Plans3{$next_paket3}{name_short}).'. '.&ahref("$scrpt&act=41&paket=0",'�������� ����� ��������� �����').
    $br2.'</li>' if $next_paket3;
  $out.='<li>'.&ahref("$scrpt&act=20",'����� ��������� ����� �� ��������� �����').$br2.'</li>' if $out1;
  $out.='<li>'.&ahref("$scrpt&act=30",'��������� �������� ��������� �����').$br2.'</li>' if $out2;
  $out.='<li>'.&ahref("$scrpt&act=40",'����� ��������������� ��������� ����� �� ��������� �����').$br2.'</li>' if $out3;
  $out.='<li>'.&ahref("$scrpt&act=50",'��������� �������� ��������������� ��������� �����').'</li>' if $out4;
  $out.='</ul>';
  $OUT.=&MessX($out,1);
  return;
 }

 {
  last if $actd!=2 && $actd!=4;
  $p=&sql_select_line($dbh,"SELECT COUNT(*) AS n FROM pays WHERE mid=$Mid AND type=50 AND category=428 AND time>($ut-3600*24)");
  $p && $p->{n}>=$Max_paket_sets && &Error('�� ��������� ����� ������� ����� ��������� �����. '.
     "�� ����������� ������������ ����� ���� $Max_paket_sets ��� � 24 ����. ������������.",$EOUT);
 }

 &SP_SetNextPaket	if $actd==2;	# ����� ������ �� ��������� �����
 &SP_SetPaket		if $actd==3;	# ���������� ����� ������
 &SP_SetNextPaket3	if $actd==4;	# ����� ���.������ �� ��������� �����
 &SP_SetPaket3		if $actd==5;	# ���������� ����� ���.������
}

sub Check_Packet
{
 my $i=$_[0];
 $i or return(1);
 return(0) if $i>$m_tarif ||
   $i<0 ||
   !$Plan_name[$i] ||
   $Plan_flags[$i]!~/a/ ||
   ($only_my_preset && $my_preset!=$Plan_preset[$i]) ||
   $Plan_usr_grp[$i]!~/,$grp,/;
 $_[1] && !$Plan_price_change[$i] && return(0);
 return(1);
}


sub SP_AddPaket
{# --- ��������� ������ ---
 $ErrMessP='��������� ��������� ����� �� ����� ���� ������������';
 $act>10 && $F{balance}!=$balance && &Error("���������� ��������� ������ �������. �������� �� ��� ����������� ��������� ��������� ����� ���� ����������� ���� ��������� ���������� ��������. �������� ������ ".&commas('�������'),$EOUT);
 $Plan_flags[$paket]!~/m/ && &Error("$ErrMessP - � ����� �������� ����� ��� �� �������������.",$EOUT);
 $start_day && &Error($V? "$V $ErrMessP - ���� ������ ����������� ����� �� ����� ����": $ErrMessP,$EOUT);
 $U{$Mid}{money_over} or &Error("$ErrMessP - � ��� ��� ����������� � ������� �������� �����. �������� ��������� ��� �����������.",$EOUT);

 $got_money=$Plan_price[$paket];

 {
  last if $act!=10;
  &SP_Select("$scrpt&act=11&balance=$balance",0,0); # �������� ������, ����� �������������� ��������� ��������� � ���������� ���������� ��������
  $out or &Error("��� �������� ������, ������� �� ������ �������� � ������� ������.",$EOUT);
  $OUT.=&div('message lft',$br.'����������� ������� ��������:'.$br2.
    "�� ������ ������ �� ��� ���������� �������������� �������� ��������� � ��������� ".
    "���������� ������� ���������� ".&bold(sprintf("%.2f",$U{$Mid}{money_over}))." $gr ".
    "����������� �������� ���������� �� ������ ������� ".&ahref("$scrpt&a=101",'�� ������� �������� ����������').
    '. � ���������� ������, ���� �� ������ ���������� ������, �� �������� ����������� ����� ����������. '.
    '������������� ������������� ��� ����������� ���������� �������������� �������� ���� �� ����� ����� ������. '.
    '��� ����� �������� ����� ����������� ���������:'.$br2.
    &bold("<ul><li> � ������ ������ � ������ ����� ����� ����� ��������� �������� ��������� �����: $got_money $gr, ".
    "�.� ��� �����������, ��������� ����</li>".
    '<li> ������������ ���� ������ ����� �������</li>'.
    '<li> �� �������� �������� ����, ������� ����� ����������� �� ����� �������� ������</li></ul>').$br2.
    '�������� ��������: � ���� ����� � ������ ����� ����� ������ �� ��� ������ �����������! ������� � ���, ������� �� ��������. '.
    '�����, ��������, ��� ����������� ������ �������������� �������� � ������ ����������� ��������� �����.'.$br2.
    &bold('����� ������ ��������� ����� � ������ ����, �� �� ������� �������� ����������� ��������!').$br2.
    &CenterA("$scrpt&a=101",'��������').$br2
  ).$br2.$out;
  return;
 }

 (!$Fpaket || !&Check_Packet($Fpaket,0)) && &Error("��������� ��������� ����� �� ��������� - ���������� ���� ������ �������.",$EOUT);

 $coment="����������� ������ �� ������ ������� � �������� �� �����: ".($Plan_name_short[$paket]||"id=$paket")."\n������:";

 $i=0;
 $reason="������ �� ������������. ����-�����:\n";
 foreach $z ($Traf1,$Traf2,$Traf3,$Traf4)
 {
    ($t1,$t2)=($T[$i*2],$T[$i*2+1]); # �������� � ��������� ������ �����������
    $i++;
    $coment.="\n$c[$i]: $z ��" if ${"Plan_over$i"}[$paket]>0;
    ($t1+$t2) or next;
    ($t1,$t2)=(&split_n($t1),&split_n($t2));
    $reason.="$i: $t1 - $t2\n";
 }

 $coment.="\n����������� ������� �� ���������.\n��������� ������ `$Plan_name_short[$Fpaket]`";

 $rows=&sql_do($dbh,"UPDATE users_trf SET in1=0,in2=0,in3=0,in4=0,out1=0,out2=0,out3=0,out4=0 WHERE uid=$Mid LIMIT 1");
 $rows<1 && &Error("��������� ������. ��������� ������ �����.$go_back",$EOUT);

 $rows=&sql_do($dbh,"INSERT INTO pays SET mid=$Mid,cash=-($got_money),type=10,bonus='y',admin_id=$Adm->{id},admin_ip=INET_ATON('$RealIp'),reason='$reason',coment='$coment',category=110,time=$ut");
 if ($rows<1)
 {
    &ToLog("!! ��� ����������� ������ �� ������ ������� id=$Mid ��������� ������ �������� �������-������, ��� �� ����� ������� ������ �������.");
    &Error("��������� ������. ��������� ������ �����.$go_back",$EOUT);
 }

 $rows=&sql_do($dbh,"UPDATE users SET balance=balance-($got_money),paket=$Fpaket WHERE id=$Mid LIMIT 1");
 $rows<1 && &ToLog("!! ����� ������������ ������ �� ������ ��������� ������ ��������� ������� ������� id=$Mid. ��������� ������ �� $got_money $gr");
 &sql_do($dbh,"UPDATE users SET paket=$Fpaket WHERE mid=$Mid LIMIT 1");

 &OkMess("��������� ��������� ����� ���������. � ������ ����� ����� ��������� ����������� ��������� ����� ��� ����� �����������.",$EOUT);
}


# --- ����� ������ �������� ������ ---

sub SP_SetPaket
{
 {
  defined $F{paket} or last;
  $Plan_flags[$paket]=~/b/ && &Error('��� ������� �������� ���� �� ��������� �������������� ������ ��� �� ����. ��� ����� ������� ������ �������������.',$EOUT);
  (!$Fpaket || !&Check_Packet($Fpaket,1)) && &Error('����� ��������� ����� �� ��������� - ���������� ���� ������ �������.',$EOUT);
  $F{balance}!=$balance && &Error('���������� ��������� ������ �������. �������� �� ��� ������� �������� ���� ���� ����������� ���� ��������� ���������� ��������. '.
     '�������� ������ '.&ahref("$scrpt&a=115",'�������'),$EOUT);
  $Fpaket==$paket && &Error('����� ��������� ����� �� ��������� - �� ������� ��� �� �������� ����, ������� � ��� � ������ ������.'.$go_main,$EOUT);
  $got_money=$Plan_price_change[$Fpaket];
  $got_money>=$balance && &Error('�� ����� ������� ������������ ������� ��� ����� ��������� �����.',$EOUT);
  $coment="`$Plan_name_short[$paket]` �� `$Plan_name_short[$Fpaket]`";
  $p_now=&commas($Plan_name_short[$paket]);
  $p_want=&commas($Plan_name_short[$Fpaket]);
  if( $act==31 )
  {
     &OkMess("<span class='big story'>&nbsp;&nbsp;<span class=error>��������!</span>. � ������ ������ �� �������������� �� �������� ����� $p_now. ".
       "�� ������ �������� ��� �� ����� $p_want ���������� $Plan_price_change[$Fpaket] $gr ��� ������ �������, � ������ ����� ����� ����� ������������� ".
       &bold($got_money)." $gr".$br2.
       " ����� ������ �������� ������������ ����� ����������� � ������� ���������� �����, ��� ���� ����� ������ ����� ��������� ��� ��� ����� �� ".
       "��������� �� ��������� �������� ����� � ������ ������</span>.".$br3.
       &CenterA("$scrpt&act=32&balance=$balance&paket=$Fpaket",'���������� ����� ��������� �����').$br3.
       &CenterA($scrpt,'����������'),$EOUT);
     return;
  }

  $coment="����� ��������� ����� $coment";
  $rows=&sql_do($dbh,"INSERT INTO pays SET mid=$Mid,cash=-($got_money),type=10,bonus='y',admin_id=$Adm->{id},admin_ip=INET_ATON('$RealIp'),coment='$coment',category=105,time=$ut");
  $rows<1 && &Error($V? "$V ������ �������� �������-������ �� ����� ��������� �����" : "��������� ������. ��������� ������ �����.$go_back",$EOUT);

  $rows=&sql_do($dbh,"UPDATE users SET balance=balance-($got_money),paket=$Fpaket WHERE id=$Mid LIMIT 1");
  $rows<1 && &ToLog("!! ����� ������� ����� ��������� ����� ��������� ������ ��������� ������� ������� id=$Mid. ��������� ������ �� $got_money $gr");

  &OkMess(&div('big',"����� ��������� ����� ���������. � ������ ����� ����� $got_money $gr").$go_main,$EOUT);
  return;
 }

 $out2 or return;

 $OUT.=&MessX(&div('big','����� ��������� ����� � ������� ������. ��������! �������� �������.').$br2.
   '���� � ������ �������� �������� ����, �� ������� �� ������ �������� ���� �������. '.
   '����� ������, � ���� �� ������ ����� ����������� ������ ������ �������� ������ �� �����. ����� �������� ���� '.
   '����� ����������� ��� ����� �� ��� ���������� � ������ �������� ������, �.�. ������ �� ������� ������ '.
   '�� ����� ��������� � ������ �����.',1,1).$out2;
}



# --- ����� ������ �� ��������� ����� ---

sub SP_SetNextPaket
{
 {
  defined($F{paket}) or last;
  $Plan_flags[$paket]=~/b/ && &Error('��� ������� �������� ���� �� ��������� �������������� ������ ��� �� ����. ��� ����� ������� ������ �������������.',$EOUT);
  # ��������� ������, $i - � ������ ��� 0 - `�� ������`
  &Check_Packet($Fpaket,0) or &Error('������� ��������. ������ ������� ��� �� email.',$EOUT);
  $Fpaket==$next_paket && &Error('����� ��������� ����� �� �������� - �� ������� ��� �� �������� ����, ������� ��� ������� �� ��������� �����.',$EOUT);

  &sql_do($dbh,"UPDATE users SET next_paket=$Fpaket WHERE id=$Mid LIMIT 1");
  Pay_to_DB(uid=>$Mid, type=>50, category=>428, reason=>$Fpaket? $Plan_name_short[$Fpaket] : '');

  OkMess($Fpaket? '����� ����� ��������� ����� ���������� ������ �� '.&bold($Plan_name_short[$Fpaket]).' ��������.'.$go_main :
     '�� ���� �������� � ��������� ������ �� �������� ��� ������� �������� ����.',$EOUT);
  return;
 }
 
 $out1 or return;

 $OUT.=&MessX(&div('big cntr','����� ��������� ����� �� ��������� �����').$br2.
   "���� � ������ �������� �������� ����, �� ������� ��� ������������� ���������� ������� ��� ����������� ���������� ������.".$br2.
   "��� ����������� �������������� �������� ������� �� ����� ������������ ������� �� ������ �������:".$br.
     &div('lft','<ul><li>�������� - �� ������� ������ �� ���������� ������</li>'.
     '<li>��������� - �� ������� ������ �� ������������ ������</li>'.
     '<li>����� - �� ������� �� ������������ � ���������� ������</li>'.
     '<li>���������� ������������ - �� ������� �� �� ������, ������� ������ (���� �� ���������� ���� �� ������������)</li></ul>'.
     '���� �������� �������������� �������� ����� �������� '.&commas('�����������').' - � ������ ��������� ��������� ������� ������������.'
     ),1,1
   ).$out1;
}


sub SP_Select
{ 
 ($url,$only_now_change_pkt)=@_;
 # $only_now_change_pkt - ���������� ������ �� ������, �� ������� ����� ������� � ������� ������ (����� ��������� ��������)

 %pkts=();
 foreach $i (1..$m_tarif)
 {
    $pkts{$i}=$Plan_price[$i] if &Check_Packet($i,$only_now_change_pkt)
 }

 $out='';
 foreach $i (sort { $pkts{$a} <=> $pkts{$b} } keys %pkts)
 {# � ������� ����������� ��������� ������
    $preset=$Plan_preset[$i];
    @c=('',&Get_Name_Class($preset));
    $out.=&RRow('head','lc','�������� ����',&ahref("$url&paket=$i",$Plan_name_short[$i])).
          &RRow('*','lr',"����, $gr",&bold($Plan_price[$i]));
    $out.=&RRow('*','L',&Show_all($Plan_descr[$i])) if $Plan_descr[$i];
    $out.=&RRow('* error','lr',"��������� �������� �� ������ �������� ����, $gr",&bold($Plan_price_change[$i])) if $only_now_change_pkt;
    for $j (1..4)
    {
       $price_over_mb=${"Plan_over$j"}[$i];
       next if $j>1 && !$price_over_mb;
       $mb_in_paket= $Plan::main->{$i}{mb}{$j};
       $in_or_out_traf=&Get_name_traf(${"InOrOut$j"}[$i]);
       $out.=&RRow('*','lr',
          "$c[$j]) ������. ������������ ��<br>������������ $in_or_out_traf",
          $mb_in_paket<$cfg::unlim_mb? $mb_in_paket : &bold('�����������')
       );
       $out.=&RRow('*','lr',"���� ����������, $gr/��",$price_over_mb) if $mb_in_paket<$cfg::unlim_mb;
    }

    my $sum_mb += $Plan::main->{$i}{mb}{$_} foreach( 0..4 );
    if(($sum_mb + $Plan_over1[$i]+$Plan_over2[$i]+$Plan_over3[$i]+$Plan_over4[$i])==0)
    {
       $out.=&RRow('*','L',&bold('������ ������� � �������� �� ���������������'));
    }
     elsif ($Plan_over1[$i]==0)
    {
       $out.=&RRow('*','L','��� ���������� ��������������� ������� '.&commas($c[1]).', ������ � �������� ����� ������������')
    }

    if ($time_in_tarifs && $Plan_start_hour[$i] && $Plan_end_hour[$i])
    {
       if ($Plan_k[$i]<=0)
       {
          $out.=&RRow('*','L','����������� �� ������� �����, �.�. ������ � �������� ����� �������� ������ � ������������ ����� �����')
       }
        else
       {
          $out.=&RRow('*','L',"� ���������� ������� � $Plan_start_hour[$i] �� $Plan_end_hour[$i] ����� ������ ����� �������� � ������������� $Plan_k[$i]")
       }
    }

    $out.=&RRow('*','L',"�������� ���� ���������������, ��� ���� �� �� ���������� ��� ��������� ������� $c[1], �� $c[2] ������ ".
      "����� ���� �������� ��� $c[1] � �����������: 1 $c[1] �� = $Plan_m2_to_m1[$i] $c[2] ��") if $Plan_m2_to_m1[$i];

    $out.=&RRow('*','L',"�������� ������� ���������� $Plan_speed[$i] ����/���") if $Plan_speed[$i];
 }

 $out&&=&Table('tbg1 nav2',$out);
 return $out;
}


sub SP_SetNextPaket3
{
 {
  last unless defined $F{paket};
  $Fpaket==$next_paket3 && &Error('����� ��������� ����� �� �������� - �� ������� ��� �� �������� ����, ������� ��� ������� �� ��������� �����.',$EOUT);

  $Fpaket && $Plans3{$Fpaket}{usr_grp_ask}!~/,$grp,/ && &Error('����� ��������� ����� �� �������� - ������������� �����.',$EOUT);

  &sql_do($dbh,"UPDATE users SET next_paket3=$Fpaket WHERE id=$Mid LIMIT 1");
  &Insert_Event_In_DB(428,$Fpaket? $Plans3{$Fpaket}{name_short} : '');

  &OkMess($Fpaket? '����� ����� ��������� ����� ���������� ������ �� '.&bold($Plans3{$Fpaket}{name_short}).' ��������.'.$go_main :
     '�� ���� �������� � ��������� ������ �� �������� ��� ������� �������� ����.',$EOUT);
  return;
 }

 $out1 or return;

 $OUT.=&MessX(&div('big cntr','����� ��������������� ��������� ����� �� ��������� �����')).$br2.$out3;
}

# --- ����� ���.������ �������� ������ ---

sub SP_SetPaket3
{
 {
  defined($F{paket}) or last;

  $Plans3{$Fpaket}{usr_grp_ask}!~/,$grp,/ && &Error('����� ��������� ����� �� ��������� - ������������� �����.',$EOUT);
  $Plans3{$Fpaket}{price_change}==0 && &Error('����� ��������� ����� �� ��������� - �� ������ ����� �� ��������� ������������� � �������� ������.',$EOUT);

  $F{balance}!=$balance && &Error('���������� ��������� ������ �������. �������� �� ��� ������� �������� ���� ���� ����������� ���� ��������� ���������� ��������. '.
     '�������� ������ '.&ahref("$scrpt&a=115",'�������'),$EOUT);
  $Fpaket==$paket3 && &Error('����� ��������������� ��������� ����� �� ��������� - �� ������� ��� �� �������� ����, ������� � ��� � ������ ������.'.$go_main,$EOUT);
  $got_money=$Plans3{$Fpaket}{price_change};
  $got_money>=$balance && &Error('�� ����� ������� ������������ ������� ��� ����� ��������� �����.',$EOUT);
  $coment="`$Plans3{$paket}{name_short}` �� `$Plans3{$Fpaket}{name_short}`";
  $p_now=&commas($Plans3{$paket}{name_short});
  $p_want=&commas($Plans3{$Fpaket}{name_short});
  if ($act==51)
  {
     &OkMess("<span class='big story'>&nbsp;&nbsp;<span class=error>��������!</span>. � ������ ������ �� �������������� �� �������� ����� $p_now. ".
       "�� ������ �������� ��� �� ����� $p_want ���������� $Plans3{$paket}{price_change} $gr ��� ������ �������, � ������ ����� ����� ����� ������������� ".
       &bold($got_money)." $gr".$br2.
       " ����� ������ �������� ������������ ����� ����������� � ������� ���������� �����, ��� ���� ����� ������ ����� ��������� ��� ��� ����� �� ".
       "��������� �� ��������� �������� ����� � ������ ������</span>.".$br3.
       &CenterA("$scrpt&act=52&balance=$balance&paket=$Fpaket",'���������� ����� ��������� �����').$br3.
       &CenterA($scrpt,'����������'),$EOUT);
     return;
  }

  $coment="����� ��������� ����� $coment";
  $rows=&sql_do($dbh,"INSERT INTO pays SET mid=$Mid,cash=-($got_money),type=10,bonus='y',admin_id=$Adm->{id},admin_ip=INET_ATON('$RealIp'),coment='$coment',category=105,time=$ut");
  $rows<1 && &Error($V? "$V ������ �������� �������-������ �� ����� ��������� �����" : "��������� ������. ��������� ������ �����.$go_back",$EOUT);

  $rows=&sql_do($dbh,"UPDATE users SET balance=balance-($got_money),paket3=$Fpaket WHERE id=$Mid LIMIT 1");
  $rows<1 && &ToLog("!! ����� ������� ����� ��������� ����� ��������� ������ ��������� ������� ������� id=$Mid. ��������� ������ �� $got_money $gr");
  &sql_do($dbh,"UPDATE users SET paket3=$Fpaket WHERE mid=$Mid LIMIT 1");

  &OkMess(&div('big',"����� ��������� ����� ���������. � ������ ����� ����� $got_money $gr").$go_main,$EOUT);
  return;
 }

 $out2 or return;

 $OUT.=&MessX(&div('big','����� ��������� ����� � ������� ������. ��������! �������� �������.').$br2.
   '���� � ������ �������� �������� ����, �� ������� �� ������ �������� ���� �������. '.
   '����� ������, � ���� �� ������ ����� ����������� ������ ������ �������� ������ �� �����. ����� �������� ���� '.
   '����� ����������� ��� ����� �� ��� ���������� � ������ �������� ������, �.�. ������ �� ������� ������ '.
   '�� ����� ��������� � ������ �����.',1,1).$out4;
}

sub SP_Select3
{
 ($url,$only_now_change_pkt)=@_;
 # $only_now_change_pkt - ���������� ������ �� ������, �� ������� ����� ������� � ������� ������ (����� ��������� ��������)

 $out='';
 foreach $i (sort {$Plans3{$a} cmp $Plans3{$b}} grep $Plans3{$_}{usr_grp_ask}=~/,$grp,/, keys %Plans3)
 {
    $t{$_}=$Plans3{$i}{$_} foreach ('name_short','price','price_change','descr');
    next if $only_now_change_pkt && $t{price_change}==0;
    $out.=&RRow('head','lc','�������� ����',&ahref("$url&paket=$i",$t{name_short}));
    $out.=&RRow('* error','lr',"��������� �������� �� ������ �������� ����, $gr",&bold($t{price_change})) if $only_now_change_pkt; 
    $out.=&RRow('*','lr',"����, $gr",&bold($t{price}));
    $out.=&RRow('*','ll','��������',&Show_all($t{descr}));
 }
 $out&&=&Table('tbg1 nav2',$out);
 return $out;
}

1;      

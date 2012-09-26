#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2011
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
#   ������ ��������� �������� 

# ��������� ���������� �������, ���� reason:  id_�����:�����_���������_��������:���������_�������
# � ����� ������� ���� ���� ��������� �����, ����������� ��������� ������

# ������� �������� �����:
#  opt_id	- id �����
#  opt_time 	- ����� ��������, ���� =0, �� ��� ��� �����, ������ id ���������� � ���� opt_descr 
#  opt_descr	- ��������� �������� �����

sub go
{
 $plg_id='payopt';
 $OUT.=&MessX('������ ��������� ��������. '.&ahref("$scrpt&a=4",'������'),1,1);

 %otime=();
 $sth=&sql($dbh,"SELECT reason FROM pays WHERE category=111 AND mid=$Mid ORDER BY time",'�������������� �������� �����');
 while( $p=$sth->fetchrow_hashref )
 {
    @opts=split /\n/,$p->{reason};
    foreach $o (@opts)
    { 
       ($oid,$time)=split /:/,$o;
       $otime{$oid}=$time if !defined($otime{$oid}) || $time>$otime{$oid};
    } 
 }

 $Fopt=int $F{opt};			# ����� ���������� ����� ��� 0, ���� ��� �� ���������
 $paket=$U{$Mid}{paket};
 $pays_opt=$Plan_pays_opt[$paket];	# ����� ������� ����������� ������ ����� ��������� ��� ������ �������
 $out='';				# ������ �������������� �����
 $out1='';				# ������ ���� ��������� �����
 $out2='';				# ������ ���� ��������� �����
 %o=();					# ��������� �����, ������� ������ ������
 %odescr=();
 # time=0 - ������� ����, ��� ��� ��������� �� �������� (���) �����
 $sth=&sql($dbh,"SELECT * FROM pays_opt WHERE opt_time>0 ORDER BY opt_name",'������ ���� ������������ �����');
 while( $p=$sth->fetchrow_hashref )
 {
    $oid=$p->{opt_id};
    next if $pays_opt!~/,$oid,/;	# ����� ������� �� ��������������� ��� �����
    ($opay,$otime,$ocls)=&Get_fields('opt_pay','opt_time','trf_class');
    ($oname,$odescr{$oid})=&Get_filtr_fields('opt_name','opt_descr');
    # ����� �������� ����� � ����: � ���� y ����� z �����
    $days=int $otime/86400;		# ����
    $min=int(($otime % 86400)/60);	# �����
    $time="$days ���� ";
    $time.=(int $min/60).' ��� '.($min % 60).' ���' if $min;
    $out1.=&RRow('*','clll',&bold($opay),&ahref("$scrpt&opt=$oid",$oname),$time,$odescr{$oid});
    ($o{pay},$o{name},$o{descr},$its_pack)=($opay,$oname,$odescr{$oid},0) if $oid==$Fopt;
    $odescr{$oid}.=". ���� �������� $time" if $time;

    # ���� ����� ������������ - ������� � ������ ��������������
    if( $otime{$oid}>$t )
    {  # ����� ����� �� �����
       $out.=&bold($oname).'. ����� ������������� �� '.&bold(&the_time($otime{$oid}));
       $out.=$br2;
    }    
 }

 @opts=(); # ������ �����, �������� � ���, ���� ������ ������ ��� ����� $Fopt
 $sth=&sql($dbh,"SELECT * FROM pays_opt WHERE opt_time=0 ORDER BY opt_name",'������� ���� �����');
 while( $p=$sth->fetchrow_hashref )
 {
    ($oid,$opay)=&Get_fields('opt_id','opt_pay');
    ($oname,$odescr)=&Get_filtr_fields('opt_name','opt_descr');
    next if $pays_opt!~/,$oid,/;	# ����� ������� �� ��������������� ��� �����
    $descr='';
    foreach (split /,/,$odescr)
    {
       $i=int $_;
       next if !$i || !defined($odescr{$i});
       $descr.=$odescr{$i}.$br2;
       push @opts,$i if $oid==$Fopt;
    }
    next unless $descr;			# ��� �� ����� ����� � ���� - ������ � ������ ����
    $out2.=&RRow('*','cll',&bold($opay),&ahref("$scrpt&opt=$oid",$oname),$descr);
    ($o{pay},$o{name},$o{descr},$its_pack)=($opay,$oname,$descr,1) if $oid==$Fopt;
 } 

 &Error("� ����� �������� ����� ��������� ������� �� �������������.",$EOUT) if !$out1 && !$out2;
 ($F{ok} eq 'no') && &Error("�� ���������� �� ������� �����.",$EOUT);

 if( !$Fopt )
 {
    $OUT.=$br.&div('message lft','�������� �����:'.$br2.$out).$br if $out;
    if( !$out || !$F{dontshowopt} )
    {
       $OUT.=&div('lft',&Table('tbg3 nav2',&RRow('head','cclc',&bold_br("���������, $gr"),'�����','���� ��������','��������').$out1)) if $out1;
       $OUT.=$br.&div('lft',&Table('tbg3 nav2',&RRow('head','ccc',"���������, $gr",'���','��������').$out2)) if $out2;
    } 
    return;
 }

 defined($o{name}) or &Error("��������� ����� �����. �������� ��������.",$EOUT);

 $final_balance=sprintf("%.2f",$U{$Mid}{final_balance});

 # ��������� ����� "���������" �.�. "�����������" ����� ������� �� ������
 &Error("����� �� ������������ �.�. ������� ������������� ��������� ����� ������: ���� ����������� ����������� ������ ���� �� ".
   "�������� ������� ������ �� ��������� ������ (�������� �������� ��������). ".&ahref("${scrpt}a=115",'�������� ������ ��������')." �� ������� ".
   "���� �� ������������ ������������ ������.",$EOUT) if $F{ok} eq 'yes' && abs($F{balance}-$final_balance)>0.01;

 $OUT.="<div class='message nav2' align=justify>".
   &Printf('[br]�� ������� ����� [bold] ���������� [bold] [][br2]�������� �����:[br2][][br2]',$o{name},$o{pay},$gr,$o{descr});
 $tend='</div>'.$go_back.$EOUT;
 ($final_balance-$o{pay})<0 && &Error("� ��������� �� ����� ����� ($final_balance $gr) ������������ ������� ��� ��������� ������ ������ ($o{pay} $gr).",$tend);

 if( $F{ok} ne 'yes' )
 {
    $OUT.=&bold('��������').
      ". ���� �� �������� � �������� ������ ������ ������� ������ &#171;������� ����� �����������&#187;. ����� ���� � ������ ����� ����� ����� ����� ".
      "<b>$o{pay} $gr</b> <span class=error>����� ������������� ������� ������ ������, �� �� ������� �������� ��� �������!</span><br><br><br><br>".
      &div('cntr',
        &Table('table2',
          &RRow('','ll',
            &form('!'=>1,'opt'=>$Fopt,'ok'=>'yes','balance'=>$final_balance,&submit_a('������� ����� �����������')),
            &form('!'=>1,'ok'=>'no',&submit_a('�����������'))
          )
        )
      ).$tend;
    return;
 }

 @opts=($Fopt) if !$its_pack;
 $reason=$coment=$payopt='';
 foreach $o (@opts)
 {
    $p=&sql_select_line($dbh,"SELECT * FROM pays_opt WHERE opt_id=$o LIMIT 1");
    $p or &Error("����� �� ������������. ���������� ������ ($plg_id-1). ���������� ������ �����.",$tend);
    ($otime,$cls,$oname,$opay)=&Get_fields('opt_time','trf_class','opt_name','opt_pay');

    $when=$t+$otime;
    $opt_name=&Filtr($oname);
    $coment.="��������� �����: $opt_name. �������� ���������� ".&the_date($when);

    $reason.="$o:$when:$cls:0:0\n";
    $payopt.="$cls:0\n";

    $coment.="\n\n";
 }

 $reason or &Error("����� �� ������������. ���������� ������ ($plg_id-2). ���������� ������ �����.",$tend);
 chop $reason;
 chop $coment;
 chop $coment;

 $coment="��� �����: ".&Filtr_mysql($o{name})."\n\n$coment" if $its_pack;
 $rows=&sql_do($dbh,"INSERT INTO pays SET mid=$Mid,cash=-($o{pay}),type=10,bonus='y',category=111,admin_id=$Adm->{id},admin_ip=INET_ATON('$RealIp'),".
   "reason='$reason',coment='$coment',time=$ut");

 $rows<1 && &Error("��������� ����� �� ���������. ���������� ������ ($plg_id-3). ���������� ������ �����.",$tend);

 $payopt=~s|[\\']||g;
 $payopt && &sql_do($dbh,"UPDATE users_trf SET options=CONCAT('$payopt',options) WHERE uid=$Mid LIMIT 1");

 $rows=&sql_do($dbh,"UPDATE users SET balance=balance-($o{pay}) WHERE id=$Mid LIMIT 1");
 if( $rows<1 )
 {
    Pay_to_DB(uid=>$Mid, type=>50, category=>510);
    &Error("��������� ����� ��������� ��������. ���������� ������ ($plg_id-4). �������� �� ���� ������������.",$tend);
 } 

 $OUT.='</div>'.$br;
 &OkMess("������ ����� ��������� �������. ".&bold('����� ����� ������������ � ������� ���������� �����').$br2.&ahref("$scrpt&a=115",'���������� �������')); 
}

1;      

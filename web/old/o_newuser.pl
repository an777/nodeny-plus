#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008, 2009
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
$d={
	'name'		=> '������������������ �����������',
	'tbl'		=> 'newuser_opt',
	'field_id'	=> 'id',
	'priv_show'	=> $Adm->{pr}{main_tunes},
	'priv_edit'	=> $Adm->{pr}{edt_main_tunes},
};

sub o_menu
{
 ToTop '����������������� �����������';
 return
	&ahref($scrpt,'������ �� id').
	&ahref("$scrpt&order=1",'������ �� �����').
	&ahref("$scrpt&order=2",'������ �� ���������').
	&ahref("$scrpt&order=3",'������ �� ������').$br.
	($Adm->{pr}{edt_main_tunes} && &ahref("$scrpt&op=new",'������� �����')).$br.
	&ahref("$scrpt0&a=operations&act=help&theme=newuser_opt",'�������');
}

sub o_list
{
 $out='';
 $order_by=('id','opt_name','opt_enabled','pay_sum')[int $F{order}] || 'id';
 $sth=&sql($dbh,"SELECT * FROM newuser_opt ORDER BY $order_by");
 while ($p=$sth->fetchrow_hashref)
   {
    ($id,$opt_time,$pay_sum,$opt_enabled,$opt_action)=&Get_fields('id','opt_time','pay_sum','opt_enabled','opt_action');
    ($opt_name,$opt_comment)=&Get_filtr_fields('opt_name','opt_comment');
    $out.=&RRow($opt_enabled? '*' : 'rowoff','clrcclcc',
       $id,
       $opt_name,
       $pay_sum,
       !!$opt_enabled && ($opt_enabled==1? '�������� ������' : '������'),
       !!$opt_action && '����',
       $opt_comment,
       &ahref("$scrpt&op=edit&id=$id'",$d->{button}),
       $Adm->{pr}{edt_main_tunes} && &ahref("$scrpt&op=del&id=$id'",'X')
    );
   }

 !$out && &Error('� ���� ������ ��� �� ������ ������������������ �����������.'.$br2.
    &ahref("$scrpt0&a=operations&act=help&theme=newuser_opt",'������� �� ����������������� ������������').$br2.
    &ahref("$scrpt&op=new",'������� ����������������� �����������'),$tend);

 $OUT.=&Table('tbg1 nav3 width100',
   &RRow('head','8',&bold_br('������ ����������������� �����������')).
   &RRow('tablebg','ccccccC','Id','��������',"����� ������, $gr",'������ ���','��������������� ��������','�����������','��������').$out);
}

sub o_getdata
{
 $p=&sql_select_line($dbh,"SELECT * FROM newuser_opt WHERE id=$Fid LIMIT 1");
 !$p && &Error($d->{when_deleted} || "������ ��������� ������ ������������������ ����������� � $Fid",$tend);

 ($opt_name,$opt_time,$pay_sum,$opt_enabled,$opt_action,$opt_comment,$pay_comment,$pay_reason)=&Get_fields qw(
   opt_name  opt_time  pay_sum  opt_enabled  opt_action  opt_comment  pay_comment  pay_reason );
 $opt_name=&Filtr($opt_name);
 $d->{name}=&Printf('������������������ ����������� [commas]',$opt_name);

 @f = (
   ["plans2 WHERE name<>'' AND","$scrpt0&a=tarif&act=show&id="],
   ['plans3 WHERE',"$scrpt&act=plans3&op=edit&id="],
 );
 $h='';
 foreach $f (@f)
   {
    $sth=&sql($dbh,"SELECT id,name FROM $f->[0] newuser_opt=$Fid");
    $h.=$br.&ahref("$f->[1]$_->{id}",$_->{name}) while ($_=$sth->fetchrow_hashref);
    !$h && next;
   }
 $d->{no_delete}='��� ������������ � �������� ������:'.$br.$h if $h;
}

sub o_new
{
 $opt_name=$opt_comment=$pay_comment=$pay_reason='';
 $opt_time=$pay_sum=$opt_action=0;
 $opt_enabled=1;
}

sub o_show
{
 ToTop $d->{name_action};
 $opt_status.='<select name=opt_enabled>'.
   '<option value=0'.($opt_enabled==0 && ' selected').'>���������</option>'.
   '<option value=1'.($opt_enabled==1 && ' selected').'>��� �������� ������</option>'.
   '<option value=2'.($opt_enabled==2 && ' selected').'>��� �������� ������</option>'.
 '</select>';

 $OUT.=&form(%{$d->{form_header}},&Table('tbg1',
    &RRow('*','lll','��������',v::input_t('opt_name',$opt_name,50,127),'').
    &RRow('*','lll','����� ������',v::input_t('pay_sum',$pay_sum,50,127),'�����, �� ������� ����� ������� ������ ������� � �������� ��������������� ������ ����� �� ����� �������� ������� ������. ����� ����� ���� ��� ������������� (�����) ��� � �������������. ������� �������� ��������� �������� �������.').
    &RRow('*','lll','������',$opt_status,'��������� - �������������� �� ������ ������������ ��� �����������.<br><br>'.
     					'��� �������� ������ - ����������� ����� ����� ��������� ������ ��� �������� �������� ������, ��� �������� ��� �� ����� ����������.<br><br>'.
     					'��� �������� ������ - ����������� ����� ����� ��������� ������ ��� �������� �������� ������, ��� �������� ��� �� ����� ����������. �������� �������� - ����� ��������� ��������� �����������.').
    &RRow('*','lll','��������������� ��������',v::input_t('opt_action',$opt_action,50,127),'���� ������� ��������� ��������, �� ����� ����� �������� ������� ������, � ������� �������� ����� �������� ����������� '.&commas('��������������� �������'),', ������� ������������� ����� ��������� ����� �������� ���������� �������. � ������ ������ ����� ������������ ������ ���� ������� � ����� 1 - ���������� ���� ������������� �������� ����� �����. ���������� ��� �����. ��� ���������').
    &RRow('*','lll','����� ���������������� ��������',v::input_t('opt_time',$opt_time,50,127),'���������� ������ ����� �������� ������� ������, ����� ������� ����� ��������� ��������������� �������.').
    &RRow('*','lll','����������� � �������',v::input_ta('pay_comment',$pay_comment,38,6),'�����������, ������� ����� ���������� � ������� ������ �� �����������. ��������, ������� '.&commas('����������� �� �����')).
    &RRow('*','lll','�������������� ������',v::input_ta('pay_reason',$pay_reason,38,6),'��������, ��� �������� ����������� � ������������ ������� ��������� ���������������� �����-���� ������, ��������, � ��������� ����������� '.&commas('���������� �� ������').' ���������� ������� ����� ������ ���� �������� ��������� �� ������� ���������. '.
					'� ����� ������ ������� � ���� ���� �����, ������� ����� �������� � ��������� ����, ������� ������ ��� ���������������. � ������ ������� $1 - ����� � ���� ����� ����� ���������� �� ������, ������� ���� ������������� �� ����� �������� ������������������ �����������.').
    &RRow('*','lll','�����������',v::input_ta('opt_comment',$opt_comment,38,6),'����������� � ������� �����������. ����� ���������� ������������� �������������� ����� �� � ������ ����������� ��� ������� ��, ������� �����.').
    ($Adm->{pr}{edt_main_tunes} && &RRow('head','3',&submit_a('���������')))
 ));
}

sub o_save
{
 $Fopt_name=&Printf('[filtr|trim]',$F{opt_name}) || '����� �����������';

 $Fpay_sum=$F{pay_sum}+0;
 abs($Fpay_sum)>1_000_000 && &Error("������� ������� ����� �������.$go_back",$tend);
 $Fopt_enabled=int $F{opt_enabled};
 $Fopt_enabled=1 if $opt_enabled<0 || $opt_enabled>2;
 $Fopt_action=int $F{opt_action};
 $Fopt_time=int $F{opt_time};

 $Fpay_comment=$F{pay_comment};
 $Fpay_reason=$F{pay_reason};
 $Fopt_comment=$F{opt_comment};

 $d->{sql}="opt_name='$Fopt_name',".
	"pay_comment='".&Filtr_mysql($Fpay_comment)."',".
	"pay_reason='".&Filtr_mysql($Fpay_reason)."',".
	"opt_comment='".&Filtr_mysql($Fopt_comment)."',".
	"pay_sum=$Fpay_sum,opt_enabled=$Fopt_enabled,opt_action=$Fopt_action,opt_time=$Fopt_time";

 $rec_state=('���������','��� ��������','��� ��������')[$Fopt_enabled];
 if ($Fid)
   {
    $d->{new_data}=$Fopt_name ne $opt_name && '����� ��������: '.&commas($Fopt_name);
    $d->{new_data}.=($d->{new_data} && '. ')."�������� ����� ������ � $pay_sum �� $Fpay_sum" if $Fpay_sum!=$pay_sum;
    $d->{new_data}.=($d->{new_data} && '. ')."���������: $rec_state" if $Fopt_enabled!=$opt_enabled;
    $d->{new_data}.=($d->{new_data} && '. ')."��������������� �������� ����������� � $Fopt_action" if $Fopt_action!=$opt_action;
   }
    else
   {
    $d->{new_data}='��������: '.&commas($Fopt_name).", ����� ������ $Fpay_sum, ���������: $rec_state, ��������������� ��������: $Fopt_action";
   }
}

1;

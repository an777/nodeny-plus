#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2011
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
if ($F{mess})
{
   $url="$scrpt&a=payshow&nodeny=event";
   Show $br3.MessageBox('������ ������ ����. ����� 10 ������ ���������� ������� �� �������� ��������� �������.'.$br3.&CenterA($url,'������� &rarr;'),1,0);
   Doc->template('top_block')->{header}.=qq{<meta http-equiv="refresh" content="10; url='$url'">};
   &Exit;
}

$Fact=$F{act};

if( $Fact eq 'send' )
{   # ������� ������ ��������� �����
   $Adm->{pr}{SuperAdmin} or Error('��� ������� ������������ ����������.');
   $ses::auth->{role} eq 'admin' or Error('�� �������� ������, ��������� ��� ����������� �� �� �������, ��� ��������� �� ���������� �����������.');
   $s=int $F{s};
   $rows=Db->do("INSERT INTO dblogin SET mid=0,act=$s,time=$ut");
   $rows<1 && Error('������ sql. '.&ahref("$scrpt&act=$Fact&s=$s",'������� ������ ��������'));
   Exit();
}

Show div('message nav2 lft',&Table('tbg3',
  &RRow('','C','������� ���� NoDeny ������:').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=7",'�������'),'������� ������ ����� ��������� ������ �������, �.�. ����� ������ ��������� ����� �� ��������� ��������').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=1",'������� �������'),'�������, �� ����� ���������� �������. ������������� ��������� ������� �������').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=10",'���������� ����'),'').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=4",'�������� ������ ��������'),"������ �������� ����������� ����� ������ $interval_oprosa_state ������, ������� ������ ��� ������������� ������������ ������ ������").
  &RRow('*','ll',&ahref("$scrpt&act=send&s=2",'���������� ������'),'������� �������� ������ ����� ��������� �������').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=3",'���������� ������ �����������'),'������� �������� ������ ����� �������������� � ������� &#171;���������&#187; &rarr; &#171;�����������&#187;').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=5",'Ping'),'������� ping, � ����� ������ ������ ������� pong').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=6",'������ ������'),'��� ��������� ������� ������� ���� ������ ������ �������� ������, ��������� ����� ������ ������� � ���, ��� � ����������� ��������� ����� ����� ������������').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=8",'������ sql'),'').
  &RRow('*','ll',&ahref("$scrpt&act=send&s=9",'��������� ������ sql'),'')
 )).$br if $ses::auth->{role} eq 'admin';

if( !$Adm->{pr}{logs} )
{
   Show $br.div('message','��� ���� �� ������������ �.� � ��� ��� ���������� �� ��� ��������.');
   Exit();
}
   
unless (open(LOG,"<$Log_file"))
{
   Show $br.&div('message','��� ���� '.v::bold($Log_file).(-e $Log_file? ' �� �������� ��� ������. ��������� ��������� � ����� �������.' : ' �����������.'));
   &Exit;
}

$ahref='';
if ($Fact ne 'fulllog')
  {
   seek(LOG,-32000,2);
   $ahref=&CenterA("$scrpt&act=fulllog",'������ ���');
  }

@lg=reverse <LOG>;
grep {s/^(.+?) !! (.+?)\n/$1 <span class=error>$2<\/span>\n/} @lg;
grep {s/^(.+?) ! (.+?)\n/$1 <span style='color:#c22020'>$2<\/span>\n/} @lg;
$lg=join('',@lg);
$lg=~s/\n/<br>/g;
close (LOG);

Show div('message cntr',v::bold('���-���� ������� ��������:').
   "<div class='row1 lft' style='overflow:scroll; width:100%; height:350px'>$lg</div>$ahref");

1;

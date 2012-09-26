#!/usr/bin/perl
# ------------------- NoDeny ------------------
# Copyright (�) Volik Stanislav, 2008..2011
# Read license http://nodeny.com.ua/license.txt
# ---------------------------------------------
@NetMask=(
  '0.0.0.0',
  '128.0.0.0',
  '192.0.0.0',
  '224.0.0.0',
  '240.0.0.0',
  '248.0.0.0',
  '252.0.0.0',
  '254.0.0.0',
  '255.0.0.0',
  '255.128.0.0',
  '255.192.0.0',
  '255.224.0.0',
  '255.240.0.0',
  '255.248.0.0',
  '255.252.0.0',
  '255.254.0.0',
  '255.255.0.0',
  '255.255.128.0',
  '255.255.192.0',
  '255.255.224.0',
  '255.255.240.0',
  '255.255.248.0',
  '255.255.252.0',
  '255.255.254.0',
  '255.255.255.0',
  '255.255.255.128',
  '255.255.255.192',
  '255.255.255.224',
  '255.255.255.240',
  '255.255.255.248',
  '255.255.255.252',
  '255.255.255.254',
  '255.255.255.255',
);

@nNet_ErrList1=(
 '��� ��',
 '������� ����� ���� � ������ �������� ��������',
 '������� ����� ip',
 '������� ������ ���� �� ����� � �������� �����������',
 '�� ���� ��������� ���� �� ������� �����, ����������� �����������',
 '� ����� �� ������� �����, ������������ �����������, ������� ������ ��� ������� ���� �� �����',
);

# === &nNet_GetAllRawIp =============================
# ���������� ������ �� ������ ���� ip �������� NoDeny
# ������:
#   $all=&nNet_GetAllRawIp;
#   print $all->{'10.0.0.98'}
# ==================================================
sub nNet_GetAllRawIp
{
 my $all={};
 my $sth=&sql($dbh,"SELECT ip FROM users");
 $all->{$_->{ip}}=1 while ($_=$sth->fetchrow_hashref);
 return $all;
}

# === &nNet_GetNextIp ==================================
# ������ ���������� ip � �������� �������
# ����:
#  0 - ���� � ���� xx.xx.xx.xx/yy
# �������:
#  0 - ip ��� 0 ���� ���������� �������� ����� (������� ������ ���� ��� ��� ��������� ip)
#  1 - ip ����� (���� + 1)
#  2 - ����� ������� � ���� '255.255.240.0'
#  3 - sortip
# =================================================
sub nNet_GetNextIp
{
 my ($net)=@_;
 my ($ip);
 return(0) if $net!~/^\s*(\d+)\.(\d+)\.(\d+)\.(\d+)\/(\d+)\s*$/;
 my $net_mask=$5;
 my $net_raw=pack('CCCC',$1,$2,$3,$4);
 my ($i1,$i2,$i3,$i4)=($1,$2,$3,$4);
 my $last_ip_raw=$net_raw | pack('B32',0 x $net_mask,1 x (32-$net_mask)); # ��������� ip �������� ���� 
 my $gate_ip=$i1*256**3 + $i2*256**2 + $i3*256 + $i4; # ��� �� inet_aton !!, ����� �� �������� _����������_ �����
 my $last_ip=$gate_ip + (2**(32-$net_mask)) -1; # �������� ��������: ������� 1
 $gate_ip++;
 my $first_ip=$gate_ip+1;
 my $got_it=0;
 my $all=&nNet_GetAllRawIp;
 while ($first_ip<$last_ip)
 {
    $ip=int($first_ip/16777216).'.'.int($first_ip%16777216/65536).'.'.int($first_ip%65536/256).'.'.($first_ip%256);
    $first_ip++;
    next if $all->{$ip};
    $got_it=1;
    last;
 } 

 return(0) unless $got_it;

 $net_mask=$NetMask[$net_mask];
 $gate_ip=int($gate_ip/16777216).'.'.int($gate_ip%16777216/65536).'.'.int($gate_ip%65536/256).'.'.($gate_ip%256);
 $ip=~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
 return($ip,$gate_ip,$net_mask,$2*65536+$3*256+$4);
}

# ==== &nNet_NetsList =============================
# ���������� ������ �� ������ �������� �����.
# ���� ������: 2� �������� �������� ����� ������
#
# ������, ������� ��� ���� 10 �������:
# ($nets,$err_mess)=&nNet_NetsList;
# foreach (@{$nets->{10}})
#   {
#    $net=join ".",unpack("C4",$_->{net});
#    $mask=join ".",unpack("C4",$_->{mask});
#    $OUT.="net: $net, mask: $mask, class: $_->{class}<br>";
#   }
# =================================================
sub nNet_NetsList
{
 my($cls,$dir,$fname,$m,$mask,$mask32,$net,$p,$port,$preset,$sth);
 my %all=();
 my @f;
 $dir = $cfg::dir_home;
 $mask32=pack('B32',1 x 32);
 foreach $preset( keys %Presets,'0' )
 {
    $m=[];
    $sth=&sql($dbh,"SELECT * FROM nets WHERE preset=$preset AND priority>0 ORDER BY priority,class");
    while ($p=$sth->fetchrow_hashref)
    {
        $cls=$p->{class};
        $port=$p->{port};
        if ($p->{net}!~/^\s*file:\s*(.+)$/io)
        {
            return('',"� �������� ����������� ���� `$p->{net}` ������ �������") if $p->{net}!~/^(\d+)\.(\d+)\.(\d+)\.(\d+)\/?(\d+)?$/o;
            return('',"� �������� ����������� ���� `$p->{net}` ����� ����� > 32") if $5>32;
            $mask=defined $5? pack('B32',1 x $5,0 x (32-$5)) : $mask32;
            push @$m,{
                'net'       => pack('CCCC',$1,$2,$3,$4),
                'mask'      => $mask,
                'masklen'   => defined $5? $5 : 32,
                'port'      => $port,
                'class'     => $cls,
                'comment'   => $p->{comment}
            };
            next;
        }

        $fname=$1;
        $fname="$dir/$fname" if $fname!~/^\//;
        open(FL,"<$fname") or return('',"�� ������� ��������� ���� `$fname`");

        @f=<FL>;
        close(FL);

        $mask=$port||32; # ��� ����� ���� ��������� �� ���������� �����
        foreach $net (@f)
        {
            chomp $net;
            next if $net!~/^\d/o || $net!~/^([^\s]+)\s*(.*)$/o;
            $port=int $2;
            return('',"� ����� `$fname` ���� `$1` ������ �������") if $1!~/^(\d+)\.(\d+)\.(\d+)\.(\d+)\/?(\d+)?$/;
            return('',"� ����� `$fname` ���� `$net` ����� ����� > 32") if $5>32;
            $_=defined $5? $5 : $mask;
            push @$m,{
             'net'=>pack('CCCC',$1,$2,$3,$4),
             'port'=>$port,
             'mask'=>pack('B32',1 x $_,0 x (32-$_)),
             'masklen'=>$_,
             'class'=>$cls,
             'comment'=>'�� �����: '.$fname,
             'dynamic'=>1
            };
        }
    }
    $all{$preset}=$m;
 }
 return (\%all,'');
}


# === &nNet_GetIpClass ===========================
# ��������� ������ ���� �� ip � �������
# ����:
#  0 - ip
#  1 - port
#  2 - ������ �� ������ ����� ��������� �������
# �������:
#  0 - ����� ���� ��� ��������� ip. <0 ���� ������
#      ����������� ������ � @nNet_ErrList1
# ------------------------------------------------
# �������������� ���������� ���������� ���������
# &nNet_NetsList ��� ��������������
# ================================================
sub nNet_GetIpClass
{
 my ($ip,$port,$m)=@_;
 return(-2) if $ip!~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ || $1>255 || $2>255 || $3>255 || $4>255;
 $ip=pack('CCCC',$1,$2,$3,$4);
 # ���� ip �� ����� ����������� �� � ����� �����, �� ����� ����� �����:
 my $cls=($1>223 && $1<240) || $1==127 || $ip eq '255.255.255.255'? 0:1;
 foreach (@{$m})
   {
    next if ($ip & $_->{mask}) ne $_->{net} || ($_->{port} && $_->{port}!=$port);
    return $_->{class};
   }
 return $cls;
}

1;      

## Ocservauto For Debian 0.8

This script may help you setup your own openconnect_server in debian(>=7),ubuntu(>=14.04).

这是一枚适用于deibian的openconnect_server安装脚本。中文详情 [戳这里](http://www.fanyueciyuan.info/fq/ocserv-debian.html)

============

## USAGE
```shell
apt-get update
apt-get upgrade
apt-get install wget
wget -N --no-check-certificate "https://raw.githubusercontent.com/user1121114685/Ocserv_for_Debian_Ubuntu/master/ocservauto.sh" && chmod +x ocservauto.sh && bash ocservauto.sh
bash ocservauto.sh
```

Profiles in /etc/ocserv/

When you change the profiles,restart the vpn server.
```shell
/etc/init.d/ocserv restart
```

You can get help 
```shell
bash ocservauto.sh h
```

![首页图片](https://github.com/user1121114685/Ocserv_for_Debian_Ubuntu/blob/master/20181213005045.jpg?raw=true "封面图片简介") 

============

## LICENCE
Ocservauto For Debian Copyright (C) liyangyijie released under GNU GPLv2

Ocservauto For Debian Is Based On SSLVPNauto v0.1-A1

SSLVPNauto For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2



    Copyright (C) 2015  liyangyijie

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

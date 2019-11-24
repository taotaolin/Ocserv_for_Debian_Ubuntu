#!/bin/bash

#===============================================================================================
#   System Required:  Debian 7+
#   Description:  Install OpenConnect VPN server for Debian
#   Ocservauto For Debian Copyright (C) liyangyijie released under GNU GPLv2
#   Ocservauto For Debian Is Based On SSLVPNauto v0.1-A1
#   SSLVPNauto v0.1-A1 For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2
#   Date: 2015-07-10
#   Thanks For
#   http://www.infradead.org/ocserv/
#   https://www.stunnel.info  Travis Lee
#   http://luoqkk.com/ luoqkk
#   http://ttz.im/ tony
#   http://blog.ltns.info/ LTNS
#   https://github.com/clowwindy/ShadowVPN (server up/down script)
#   http://imkevin.me/post/80157872840/anyconnect-iphone
#   http://bitinn.net/11084/
#   http://zkxtom365.blogspot.jp/2015/02/centos-65ocservcisco-anyconnect.html
#   https://registry.hub.docker.com/u/tommylau/ocserv/dockerfile/
#   https://www.v2ex.com/t/158768
#   https://www.v2ex.com/t/165541
#   https://www.v2ex.com/t/172292
#   https://www.v2ex.com/t/170472
#   https://sskaje.me/2014/02/openconnect-ubuntu/
#   https://github.com/humiaozuzu/ocserv-build/tree/master/config
#   https://blog.qmz.me/zai-vpsshang-da-jian-anyconnect-vpnfu-wu-qi/
#   http://www.gnutls.org/manual/gnutls.html#certtool-Invocation
#   Max Lv (server /etc/init.d/ocserv)
#===============================================================================================

###################################################################################################################
#base-function                                                                                                    #
###################################################################################################################

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"


sh_ver="1.0.6 2019.11.24"

#default info set
function Default_Info(){
    DefaultUser="Ramiko.me"
    DefaultPassword="Ramik0"
    if [ $1 = "username" ]; then
        echo $DefaultUser
    elif [ $1 = "password" ]; then
        echo $DefaultPassword
    fi
}

#error and force-exit
function die(){
    echo -e "\033[33mERROR: $1 \033[0m" > /dev/null 1>&2
    exit 1
}

#info echo
function print_info(){
    echo -n -e '\e[1;36m'
    echo -n $1
    echo -e '\e[0m'
}

##### echo
function print_xxxx(){
    xXxX="#############################"
    echo
    echo "$xXxX$xXxX$xXxX$xXxX"
    echo
}

#warn echo
function print_warn(){
    echo -n -e '\033[41;37m'
    echo -n $1
    echo -e '\033[0m'
}

#color line
color_line(){
    echo
    while read line
    do
        echo -e "\e[1;33m$line"
        echo
    done
    echo -en "\e[0m"
}

#get random word 获取$1位随机文本，剔除容易识别错误的字符例如0和O等等
function get_random_word(){
    D_Num_Random="8"
    Num_Random=${1:-$D_Num_Random}
    str=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c $Num_Random`
    echo $str
}

#系统转发设置
function SYSCONF(){
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
    echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
    sed -i '/soft nofile/d' /etc/security/limits.conf
    echo "* soft nofile 51200" >> /etc/security/limits.conf
    sed -i '/hard nofile/d' /etc/security/limits.conf
    echo "* hard nofile 51200" >> /etc/security/limits.conf
    cat >/etc/sysctl.conf<<EOFSYS
#This line below add by user.
#sysctl net.ipv4.tcp_available_congestion_control
#modprobe tcp_htcp
net.ipv4.ip_forward = 1
fs.file-max = 51200
net.core.wmem_max = 8388608
net.core.rmem_max = 8388608
net.core.rmem_default = 131072
net.core.wmem_default = 131072
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_rmem = 10240 81920 8388608
net.ipv4.tcp_wmem = 10240 81920 8388608
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_congestion_control = htcp
net.ipv4.icmp_echo_ignore_all = 1
#net.ipv4.tcp_fastopen = 3
EOFSYS
    [ -f "/proc/sys/net/ipv4/tcp_fastopen" ] && [ -f /etc/sysctl.conf ] && sed -i 's/#net.ipv4.tcp_fastopen/net.ipv4.tcp_fastopen/g' /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    echo -e "${Info} ipv4 转发服务已经部署完成 !"
    wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/taotaolin/Ocserv_for_Debian_Ubuntu/master/iptables.rules.sh' >/etc/ocserv/iptables.rules    ###########################################################
    sed -i '/\/etc\/ocserv\/iptables.rules/d' /etc/crontab
    while [ -z "$(sed -n '$p' /etc/crontab)" ]; do sed -i '$d' /etc/crontab; done
    sed -i "\$a\@reboot root bash /etc/ocserv/iptables.rules\n\n" /etc/crontab
    echo -e "${Info} iptables 防火墙设置已经完成 !"
}

#Default_Ask "what's your name?" "li" "The_name"
#echo $The_name
function Default_Ask(){
    echo
    Temp_question=$1
    Temp_default_var=$2
    Temp_var_name=$3
    if [  -f ${CONFIG_PATH_VARS} ]; then
        New_temp_default_var=`cat $CONFIG_PATH_VARS | grep "^$Temp_var_name=" | cut -d "'" -f 2`
        Temp_default_var=${New_temp_default_var:-$Temp_default_var}
    fi
#if yes or no 
    echo -e -n "\e[1;36m$Temp_question\e[0m""\033[31m(Default:$Temp_default_var)\033[0m"
    echo
    read Temp_var
    if [ "$Temp_default_var" = "y" ] || [ "$Temp_default_var" = "n" ]; then
        Temp_var=$(echo $Temp_var | sed 'y/YESNO0/yesnoo/')
        case $Temp_var in
            y|ye|yes)
                Temp_var=y
                ;;
            n|no)
                Temp_var=n
                ;;
            *)
                Temp_var=$Temp_default_var
                ;;
        esac
    else
        Temp_var=${Temp_var:-$Temp_default_var}        
    fi
    Temp_cmd="$Temp_var_name='$Temp_var'"
    eval $Temp_cmd
    print_info "你输入的是: ${Temp_var}"
    echo
    print_xxxx
}

#Press any key to start 任意键开始
function press_any_key(){
    echo
    print_info "按任意键开始...或按Ctrl+C取消！"
    get_char_ffff(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }    
    get_char_fffff=`get_char_ffff`
    echo
}

function fast_Default_Ask(){
    if [ "$fast_install" = "y" ]; then
        print_info "在快速模式下, $3 将从 $CONFIG_PATH_VARS"
    else
        Default_Ask "$1" "$2" "$3"
        [ -f ${CONFIG_PATH_VARS} ] && sed -i "/^${Temp_var_name}=/d" $CONFIG_PATH_VARS
        echo $Temp_cmd >> $CONFIG_PATH_VARS
    fi
}

#配置文件$1中是否含有$2
function character_Test(){
sed 's/^[ \t]*//' "$1" | grep -v '^#' | grep "$2" > /dev/null 2>&1
[ $? -eq 0 ] && return 0
}

#检测安装
function check_install(){
    exec_name="$1"
    deb_name="$2"
    Deb_N=""
    deb_name=`echo "$deb_name"|sed "s/^${Deb_N}[ \t]*\(.*\)/\1/"`
    for Exe_N in $exec_name
    do
        Deb_N=`echo "$deb_name"|sed 's/^\([^ ]*\).*/\1/'`
        deb_name=`echo "$deb_name"|sed "s/^${Deb_N}[ \t]*\(.*\)/\1/"`
        if (which "$Exe_N" > /dev/null 2>&1);then
            print_info "Check [ $Deb_N ] ok"
        else
            DEBIAN_FRONTEND=noninteractive apt-get -qq -y install "$Deb_N" > /dev/null 2>&1
            apt-get clean
            print_info "Install [ $Deb_N ] ok"
        fi
    done
}

###################################################################################################################
#core-function                                                                                                    #
###################################################################################################################

#多服务器共用一份客户端证书模式以及正常模式下，主服务器的安装主体
function install_OpenConnect_VPN_server(){
#get base info and base tools
    check_Required
#custom-configuration or not 自定义安装与否
    fast_Default_Ask "用自定义配置安装ocserv？【选Y使用证书模式】（y/n）" "n" "Custom_config_ocserv"
    clear && print_xxxx
    [ "$Custom_config_ocserv" = "y" ] && {
        print_info "使用自定义配置安装ocserv。"
        print_xxxx
        get_Custom_configuration
    }
    [ "$Custom_config_ocserv" = "n" ] && {
        print_info "自动安装，选择密码登陆."
        print_xxxx
        self_signed_ca="y" && ca_login="n"
    }       
#add a user 增加初始用户
    add_a_user
#press any key to start 任意键开始
    press_any_key
#install dependencies 安装依赖文件
    pre_install
#install ocserv 编译安装软件
    tar_ocserv_install
#make self-signd server-ca 制作服务器自签名证书
    [ "$self_signed_ca" = "y" ] && make_ocserv_ca
#make a client cert 若证书登录则制作客户端证书
    [ "$ca_login" = "y" ] && {
        [ "$self_signed_ca" = "y" ] && {
            ca_login_clientcert
        }
    }
#configuration 设定软件相关选项
    set_ocserv_conf
#防火墙配置
    SYSCONF
#stop all 关闭所有正在运行的ocserv软件
    stop_ocserv
#no certificate,no start 没有服务器证书则不启动
    [ "$self_signed_ca" = "y" ] && start_ocserv 
#show result 显示结果
    show_ocserv    
}

#多服务器共用一份客户端证书模式，分服务器的安装主体
function install_Oneclientcer(){
    [ ! -f ${Script_Dir}/ca-cert.pem ] && die "${Script_Dir}/ca-cert.pem NOT Found."
    [ -f ${Script_Dir}/crl.pem ] && CRL_ADD="y"
    self_signed_ca="y" && ca_login="y"
    check_Required
    Default_Ask "Input your own domain for ocserv." "$ocserv_hostname" "fqdnname"
    get_Custom_configuration_2
    press_any_key
    pre_install && tar_ocserv_install
    make_ocserv_ca
    cd ${Script_Dir}
    rm -rf /etc/ocserv/ca-cert.pem && rm -rf /etc/ocserv/CAforOC
    mv ${Script_Dir}/ca-cert.pem /etc/ocserv
    set_ocserv_conf
    #防火墙配置
    SYSCONF
    [ "$CRL_ADD" = "y" ] || {
        sed -i 's|^crl =.*|#&|' ${LOC_OC_CONF}
    }
    [ "$CRL_ADD" = "y" ] && {
        mv ${Script_Dir}/crl.pem /etc/ocserv
    }
    stop_ocserv && start_ocserv
    ps cax | grep ocserv > /dev/null 2>&1
    if [ $? -eq 0 ]; then
    print_info "Your install was successful!"
    else
    print_warn "Ocserv start failure,ocserv is offline!"
    print_info "You could check ${Script_Dir}/ocinstall.log"
    fi
}

#环境检测以及基础工具检测安装
function check_Required(){
#check root
    [ $EUID -ne 0 ] && die '请以root用户运行'
    print_info "Root权限通过！"
#debian-based only
    [ ! -f /etc/debian_version ] && die "必须在基于Debian的系统上运行."
    print_info "基于Debian   ok"
#tun/tap
    [ ! -e /dev/net/tun ] && die "TUN/TAP不可用。"
    print_info "TUN/TAP OK"
#check install 防止重复安装
    [ -f /usr/sbin/ocserv ] && die "Ocserv已经安装。"
    print_info "没有安装！"
#install base-tools 
    print_info "安装基础工具！"
    apt-get update  -qq
    check_install "curl vim sudo gawk sed insserv nano" "curl vim sudo gawk sed insserv nano"
    check_install "dig lsb_release" "dnsutils lsb-release"
    insserv -s  > /dev/null 2>&1 || ln -s /usr/lib/insserv/insserv /sbin/insserv
    print_info "基础工具安装成功"
#only Debian 7+
    surport_Syscodename || die "对不起，不支持你的系统"
    print_info "系统正常支持"
#check systemd
    ocserv_systemd="n"
    pgrep systemd-journal > /dev/null 2>&1 && ocserv_systemd="y"
    print_info "系统状态 : $ocserv_systemd"
#sources check
    source_wheezy_backports="y" && source_jessie="y"
    character_Test "/etc/apt/sources.list" "wheezy-backports" || source_wheezy_backports="n"
    character_Test "/etc/apt/sources.list" "jessie" || source_jessie="n"
    print_info "Sources check ok"
#get info from net 从网络中获取信息
    print_info "获取信息中....."
    get_info_from_net
    print_info "获取成功"
    clear
}

function log_Start(){
    echo "SYS INFO" >${Script_Dir}/ocinstall.log
    echo "" >>${Script_Dir}/ocinstall.log
    sed '/^$/d' /etc/issue >>${Script_Dir}/ocinstall.log
    uname -r >>${Script_Dir}/ocinstall.log
    echo "" >>${Script_Dir}/ocinstall.log
    echo "INSTALL INFO" >>${Script_Dir}/ocinstall.log
    echo "" >>${Script_Dir}/ocinstall.log
}

function get_info_from_net(){
    ocserv_hostname=$(wget -qO- ipv4.icanhazip.com)
    if [ $? -ne 0 -o -z $ocserv_hostname ]; then
        ocserv_hostname=`dig +short +tcp myip.opendns.com @resolver1.opendns.com`
    fi
    OC_version_latest=$(curl -sL "http://ocserv.gitlab.io/www/download.html" | sed -n 's/^.*version is <b>\(.*$\)/\1/p')
}

function get_Custom_configuration(){
#whether to use the certificate login 是否证书登录,默认为用户名密码登录
    fast_Default_Ask "是否选择证书登录？（y/n）" "n" "ca_login"
#whether to generate a Self-signed CA 是否需要制作自签名证书
    fast_Default_Ask "为您的服务器生成自签名CA？（y/n）" "y" "self_signed_ca"
    if [ "$self_signed_ca" = "n" ]; then
        Default_Ask "为ocserv输入您自己的域名." "$ocserv_hostname" "fqdnname"
    else 
        fast_Default_Ask "您的证书名字" "Ramiko" "caname"
        fast_Default_Ask "你的组织名称？" "Ramiko.me" "ogname"
        fast_Default_Ask "你的公司名称？" "Ramiko.me" "coname"
        Default_Ask "您的服务器的域名？" "$ocserv_hostname" "fqdnname"
    fi
#question part 2
    get_Custom_configuration_2
}

function get_Custom_configuration_2(){
#Which ocserv version to install 安装哪个版本的ocserv
    [ "$OC_version_latest" = "" ] && {
        print_warn "无法连接到官方网站，请从github下载ocserv."
        print_xxxx
    } || {
        fast_Default_Ask "$OC_version_latest 是最新的版本，但是推荐默认版本。选择哪个？" "$Default_oc_version" "oc_version"
    }
#which port to use for verification 选择验证端口
    fast_Default_Ask "使用哪个端口进行验证？（TCP端口）" "443" "ocserv_tcpport_set"
#tcp-port only or not 是否仅仅使用tcp端口，即是否禁用udp
    fast_Default_Ask "是否只使用tcp端口？（y/n）" "n" "only_tcp_port"
#which port to use for data transmission 选择udp端口 即专用数据传输的udp端口
    if [ "$only_tcp_port" = "n" ]; then
        fast_Default_Ask "数据传输使用哪个端口？（UDP端口）" "443" "ocserv_udpport_set"
    fi
#boot from the start 是否开机自起
    fast_Default_Ask "系统启动时启动ocserv？（y/n）" "y" "ocserv_boot_start"
#Save user vars or not 是否保存脚本参数 以便于下次快速配置
    fast_Default_Ask "是否将vars保存为fast模式？" "n" "save_user_vars"
}

#add a user 增加一个初始用户
function add_a_user(){
    if [ "$ca_login" = "n" ]; then
        Default_Ask "输入用户名." $(Default_Info "username") "username"
        Default_Ask "输入密码." $(Default_Info "password") "password"
    fi
    if [ "$ca_login" = "y" ] && [ "$self_signed_ca" = "y" ]; then
        Default_Ask "输入一个名字给 p12证书文件." "Ramiko" "name_user_ca"
        while [ -d /etc/ocserv/CAforOC/user-${name_user_ca} ]; do
            Default_Ask "名称已经存在，请更改一个！" "$(get_random_word 4)" "name_user_ca"
        done
        Default_Ask "输入您的p12证书文件的密码。" $(Default_Info "password") "password"
#set expiration days for client p12-cert 设定客户端证书到期天数
        Default_Ask "输入p12证书文件的过期天数。" "9527" "oc_ex_days"
    fi
}

#dependencies onebyone
function Dependencies_install_onebyone(){
    for OC_DP in $oc_dependencies
    do
        print_info "安装 $OC_DP "
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $TEST_S $OC_DP
        if [ $? -eq 0 ]; then
            print_info "Install [ ${OC_DP} ] ok!"
            apt-get clean
        else
            print_warn "[ ${OC_DP} ] not be installed!"
        fi
    done
}

#lz4 from github
function tar_lz4_install(){
    print_info "从github安装lz4"
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq remove --purge liblz4-dev
    mkdir lz4
    LZ4_VERSION=`curl -sL "https://github.com/Cyan4973/lz4/releases/latest" | sed -n 's/^.*tag\/\([^"]*\).*/\1/p' | head -n1` 
    curl -SL "https://github.com/Cyan4973/lz4/archive/$LZ4_VERSION.tar.gz" -o lz4.tar.gz
    tar -xf lz4.tar.gz -C lz4 --strip-components=1 
    rm lz4.tar.gz 
    cd lz4 
    make -j"$(nproc)" && make install
    cd ..
    rm -r lz4
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ]; then
        ln -sf /usr/local/lib/liblz4.* /usr/lib/x86_64-linux-gnu/
    else
        ln -sf /usr/local/lib/liblz4.* /usr/lib/i386-linux-gnu/
    fi
    print_info "[ lz4 ] ok"
}

#install freeradius-client 1.1.7
function tar_freeradius_client_install(){
    print_info "安装 freeradius-client-1.1.7"
    DEBIAN_FRONTEND=noninteractive apt-get -y -qq remove --purge freeradius-client*
    wget -c ftp://ftp.freeradius.org/pub/freeradius/freeradius-client-1.1.7.tar.gz
    tar -zxf freeradius-client-1.1.7.tar.gz
    cd freeradius-client-1.1.7
    ./configure --prefix=/usr --sysconfdir=/etc
    make -j"$(nproc)" && make install
    cd ..
    rm -rf freeradius-client*
    print_info "[ freeradius-client ] ok"
}

function test_source_install(){
    [ "$1" = "n" ] && {
        echo "deb http://ftp.debian.org/debian $2 main contrib non-free" >> /etc/apt/sources.list.d/ocserv.list
        apt-get update
    }
    oc_dependencies="$3" && TEST_S="-t $2 -f --force-yes"
    Dependencies_install_onebyone
    [ "$1" = "n" ] && {
        rm -rf /etc/apt/sources.list.d/ocserv.list
        apt-get update
    }
}

#install dependencies 安装依赖文件
function pre_install(){
#keep kernel 防止某些情况下内核升级
    echo linux-image-`uname -r` hold | dpkg --set-selections > /dev/null 2>&1
    apt-get upgrade -y
    echo linux-image-`uname -r` install | dpkg --set-selections > /dev/null 2>&1
#no upgrade from test sources 不升级不安装测试源其他包
    [ ! -d /etc/apt/preferences.d ] && mkdir /etc/apt/preferences.d
    [ ! -d /etc/apt/apt.conf.d ] && mkdir /etc/apt/apt.conf.d
    [ ! -d /etc/apt/sources.list.d ] && mkdir /etc/apt/sources.list.d    
    cat > /etc/apt/preferences.d/my_ocserv_preferences<<'EOF'
Package: *
Pin: release wheezy
Pin-Priority: 900
Package: *
Pin: release wheezy-backports
Pin-Priority: 90
EOF
    cat > /etc/apt/apt.conf.d/77ocserv<<'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::Get::Install-Recommends "false";
APT::Get::Install-Suggests "false";
EOF
#gnutls-bin(certtool) is too old on wheezy/trusty/utopic,bugs with only one OU etc
#gnutls-bin（certtool）于wheezy/trusty/utopic太旧，OU只能一个的等等问题
    [ "$oc_D_V" = "wheezy" ] || {
        oc_add_dependencies="libgnutls28-dev libseccomp-dev libhttp-parser-dev libkrb5-dev"
        [ "$oc_D_V" = "trusty" ] || {
            oc_add_dependencies="$oc_add_dependencies libprotobuf-c-dev"
            [ "$oc_D_V" = "utopic" ] || {
                oc_add_dependencies="$oc_add_dependencies gnutls-bin"
            }
        }     
    }
    oc_dependencies="openssl autogen gperf pkg-config make gcc m4 build-essential libgmp3-dev libwrap0-dev libpam0g-dev libdbus-1-dev libnl-route-3-dev libopts25-dev libnl-nf-3-dev libreadline-dev libpcl1-dev libtalloc-dev libev-dev liboath-dev $oc_add_dependencies"
    TEST_S=""
    Dependencies_install_onebyone   
#install dependencies from wheezy-backports for debian wheezy
    [ "$oc_D_V" = "wheezy" ] && {
        test_source_install "$source_wheezy_backports" "wheezy-backports" "gnutls-bin libgnutls28-dev libseccomp-dev"  
    }
#install dependencies from jessie for ubuntu 14.04
    [ "$oc_D_V" = "trusty" ] && {
        test_source_install "$source_jessie" "jessie" "gnutls-bin libtasn1-6-dev libtasn1-3-dev libtasn1-3-bin libtasn1-6-dbg libtasn1-bin libtasn1-doc"
    }
#install dependencies from jessie for ubuntu 14.10
    [ "$oc_D_V" = "utopic" ] && {
        test_source_install "$source_jessie" "jessie" "gnutls-bin"
    }
#install freeradius-client-1.1.7
    tar_freeradius_client_install
#install lz4
    tar_lz4_install
#clean
    apt-get autoremove -qq -y && apt-get clean
    rm -f /etc/apt/preferences.d/my_ocserv_preferences
    rm -f /etc/apt/apt.conf.d/77ocserv
    print_info "Dependencies  ok"
}

#install ocserv 编译安装
function tar_ocserv_install(){
    cd ${Script_Dir}
#default version  默认版本
    oc_version=${oc_version:-${Default_oc_version}}
    [ "$OC_version_latest" = "" ] && {
#可以换成自己的下载地址
        oc_version='0.10.8'
        curl -SOL "https://github.com/fanyueciyuan/ocserv-backup/raw/master/ocserv-$oc_version.tar.xz"
    } || {
        wget -c ftp://ftp.infradead.org/pub/ocserv/ocserv-$oc_version.tar.xz
    }
    tar xvf ocserv-$oc_version.tar.xz
    rm -rf ocserv-$oc_version.tar.xz
    cd ocserv-$oc_version
#0.10.6-fix
    [ "$oc_version" = "0.10.6" ] && {
        sed -i 's|#ifdef __linux__|#if defined(__linux__) \&\&!defined(IPV6_PATHMTU)|' src/worker-vpn.c
        sed -i '/\/\* for IPV6_PATHMTU \*\//d' src/worker-vpn.c
        sed -i 's|# include <linux/in6.h>|# define IPV6_PATHMTU 61|' src/worker-vpn.c
    }
    ./configure --prefix=/usr --sysconfdir=/etc $Extra_Options
    make -j"$(nproc)"
    make install
#check install 检测编译安装是否成功
    [ ! -f /usr/sbin/ocserv ] && {
        print_warn "Fail..."
        make clean
        die "Ocserv install failure,check ${Script_Dir}/ocinstall.log"
    }
#mv files
    mkdir -p /etc/ocserv/CAforOC/revoke > /dev/null 2>&1
    mkdir /etc/ocserv/{config-per-group,defaults} > /dev/null 2>&1
    cp doc/profile.xml /etc/ocserv
    sed -i "s|localhost|$ocserv_hostname|" /etc/ocserv/profile.xml
    cd ..
    rm -rf ocserv-$oc_version
#get or set config file
    cd /etc/ocserv
    [ ! -f /etc/init.d/ocserv ] && {
        wget -c --no-check-certificate $NET_OC_CONF_DOC/ocserv_debian -O /etc/init.d/ocserv
        chmod +x /etc/init.d/ocserv
        update-rc.d -f ocserv defaults
    }
    [ ! -f ocserv-up.sh ] && {
        wget -c --no-check-certificate $NET_OC_CONF_DOC/ocserv-up.sh
        chmod +x ocserv-up.sh
    }
    [ ! -f ocserv-down.sh ] && {
        wget -c --no-check-certificate $NET_OC_CONF_DOC/ocserv-down.sh
        chmod +x ocserv-down.sh
    }
    [ ! -f ocserv.conf ] && {
        wget -c --no-check-certificate $NET_OC_CONF_DOC/ocserv.conf
    }
    [ ! -f config-per-group/Route ] && {
        wget -c --no-check-certificate $NET_OC_CONF_DOC/Route -O config-per-group/Route
    }
    [ ! -f dh.pem ] && {
        print_info "也许生成DH参数需要一些时间，请稍候……"
        certtool --generate-dh-params --sec-param medium --outfile dh.pem
    }
    clear
    print_info "Ocserv 安装成功"
}

function make_ocserv_ca(){
    print_info "生成自签名CA..."
#all in one doc
    cd /etc/ocserv/CAforOC
#Self-signed CA set
#ca's name#organization name#company name#server's FQDN
    caname=${caname:-Ramiko}
    ogname=${ogname:-Ramiko.me}
    coname=${coname:-Ramiko}
    fqdnname=${fqdnname:-$ocserv_hostname}
#generating the CA 制作自签证书授权中心
#crl_dist_points ocserv并不支持在线crl吊销列表
    openssl genrsa -out ca-key.pem 4096
    cat << _EOF_ > ca.tmpl
cn = "$caname"
organization = "$ogname"
serial = 1
expiration_days = 9527
ca
signing_key
cert_signing_key
crl_signing_key
# An URL that has CRLs (certificate revocation lists)
# available. Needed in CA certificates.
#crl_dist_points = "http://www.getcrl.crl/getcrl/"
_EOF_
    certtool --generate-self-signed --hash SHA256 --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
#generating a local server key-certificate pair 通过自签证书授权中心制作服务器的私钥与证书
    openssl genrsa -out server-key.pem 2048
    cat << _EOF_ > server.tmpl
cn = "$fqdnname"
organization = "$coname"
serial = 2
expiration_days = 9527
signing_key
encryption_key
tls_www_server
_EOF_
    certtool --generate-certificate --hash SHA256 --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
    [ ! -f server-cert.pem ] && die "server-cert.pem NOT Found , make failure!"
    [ ! -f server-key.pem ] && die "server-key.pem NOT Found , make failure!"
#自签证书完善证书链
    cat ca-cert.pem >> server-cert.pem
    cp server-cert.pem /etc/ocserv && cp server-key.pem /etc/ocserv
    cp ca-cert.pem /etc/ocserv
    print_info "自签名证书成功"
}

function ca_login_clientcert(){
#generate a client cert
    print_info "生成客户端证书……"
    cd /etc/ocserv/CAforOC
    caname=`openssl x509 -noout -subject -in ca-cert.pem|sed -n 's/.*CN=\([^=]*\)\/.*/\1/p'`
    if [ "X${caname}" = "X" ]; then
        Default_Ask "告诉我你的CA的名字。" "Ramiko" "caname"
    fi
    name_user_ca=${name_user_ca:-Ramiko}
    while [ -d user-${name_user_ca} ]; do
        name_user_ca=$(Ramiko)
    done
    mkdir user-${name_user_ca}
    oc_ex_days=${oc_ex_days:-9527}
    cat << _EOF_ > user-${name_user_ca}/user.tmpl
cn = "${name_user_ca}"
unit = "Route"
#unit = "All"
uid ="${name_user_ca}"
expiration_days = ${oc_ex_days}
signing_key
tls_www_client
_EOF_
#two group then two unit,but IOS anyconnect does not surport. 
    [ "$open_two_group" = "y" ] && sed -i 's/^#//' user-${name_user_ca}/user.tmpl
#user key
    openssl genrsa -out user-${name_user_ca}/user-${name_user_ca}-key.pem 2048
#user cert
    certtool --generate-certificate --hash SHA256 --load-privkey user-${name_user_ca}/user-${name_user_ca}-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template user-${name_user_ca}/user.tmpl --outfile user-${name_user_ca}/user-${name_user_ca}-cert.pem
#p12
    openssl pkcs12 -export -inkey user-${name_user_ca}/user-${name_user_ca}-key.pem -in user-${name_user_ca}/user-${name_user_ca}-cert.pem -name "${name_user_ca}" -certfile ca-cert.pem -caname "$caname" -out user-${name_user_ca}/user-${name_user_ca}.p12 -passout pass:$password
#cp to ${Script_Dir}
    cp user-${name_user_ca}/user-${name_user_ca}.p12 ${Script_Dir}/${name_user_ca}.p12
    empty_revocation_list
    print_info "生成客户端证书成功"
}

function empty_revocation_list(){
#generate a empty revocation list
    [ ! -f crl.tmpl ] && {
    cat << _EOF_ >crl.tmpl
crl_next_update = 9527 
crl_number = 1 
_EOF_
    certtool --generate-crl --load-ca-privkey ca-key.pem --load-ca-certificate ca-cert.pem --template crl.tmpl --outfile ../crl.pem
    }
}

#modify config file 设定相关参数
function set_ocserv_conf(){
#default vars
    ocserv_tcpport_set=${ocserv_tcpport_set:-443}
    ocserv_udpport_set=${ocserv_udpport_set:-443}
    save_user_vars=${save_user_vars:-n}
    ocserv_boot_start=${ocserv_boot_start:-y}
    only_tcp_port=${only_tcp_port:-n}
#set port
    sed -i "s|\(tcp-port = \).*|\1$ocserv_tcpport_set|" ${LOC_OC_CONF}
    sed -i "s|\(udp-port = \).*|\1$ocserv_udpport_set|" ${LOC_OC_CONF}
#default domain compression dh.pem
    sed -i "s|^[# \t]*\(default-domain = \).*|\1$fqdnname|" ${LOC_OC_CONF}
    sed -i "s|^[# \t]*\(compression = \).*|\1true|" ${LOC_OC_CONF}
    sed -i 's|^[# \t]*\(dh-params = \).*|\1/etc/ocserv/dh.pem|' ${LOC_OC_CONF}
#2-group 增加组 bug 证书登录无法正常使用Default组
    [ "$open_two_group" = "y" ] && two_group_set
    echo "route = 0.0.0.0/128.0.0.0" > /etc/ocserv/defaults/group.conf
    echo "route = 128.0.0.0/128.0.0.0" >> /etc/ocserv/defaults/group.conf
    echo "route = 0.0.0.0/128.0.0.0" > /etc/ocserv/config-per-group/All
    echo "route = 128.0.0.0/128.0.0.0" >> /etc/ocserv/config-per-group/All
#boot from the start 开机自启
Service_ocserv
    # [ "$ocserv_boot_start" = "y" ] && {
    #     print_info "Enable ocserv service to start during bootup."
    #     [ "$ocserv_systemd" = "y" ] && {
    #         systemctl enable ocserv > /dev/null 2>&1 || insserv ocserv > /dev/null 2>&1
    #     }
    #     [ "$ocserv_systemd" = "n" ] && insserv ocserv > /dev/null 2>&1
    # }
#add a user ，the plain login 增加一个初始用户，用户密码方式下
    [ "$ca_login" = "n" ] && plain_login_set
#only tcp-port 仅仅使用tcp端口
    [ "$only_tcp_port" = "y" ] && sed -i 's|^[ \t]*\(udp-port = \)|#\1|' ${LOC_OC_CONF}
#setup the cert login
    [ "$ca_login" = "y" ] && {
        sed -i 's|^[ \t]*\(auth = "plain\)|#\1|' ${LOC_OC_CONF}
        sed -i 's|^[# \t]*\(auth = "certificate"\)|\1|' ${LOC_OC_CONF}
        ca_login_set
    }
#save custom-configuration files or not
    [ "$save_user_vars" = "n" ] && rm -f $CONFIG_PATH_VARS
    print_info "Set ocserv ok"
}

function two_group_set(){
    sed -i 's|^[# \t]*\(cert-group-oid = \).*|\12.5.4.11|' ${LOC_OC_CONF}
    sed -i 's|^[# \t]*\(select-group = \)group1.*|\1Route|' ${LOC_OC_CONF}
    sed -i 's|^[# \t]*\(select-group = \)group2.*|\1All|' ${LOC_OC_CONF}
#    sed -i 's|^[# \t]*\(default-select-group = \).*|\1Default|' ${LOC_OC_CONF}
    sed -i 's|^[# \t]*\(auto-select-group = \).*|\1false|' ${LOC_OC_CONF}
    sed -i 's|^[# \t]*\(config-per-group = \).*|\1/etc/ocserv/config-per-group|' ${LOC_OC_CONF}
#    sed -i 's|^[# \t]*\(default-group-config = \).*|\1/etc/ocserv/defaults/group.conf|' ${LOC_OC_CONF}
}

function plain_login_set(){
    [ "$open_two_group" = "y" ] && group_name='-g "Route,All"'
    (echo "$password"; sleep 1; echo "$password") | ocpasswd -c /etc/ocserv/ocpasswd $group_name $username
}

function ca_login_set(){
    sed -i 's|^[# \t]*\(ca-cert = \).*|\1/etc/ocserv/ca-cert.pem|' ${LOC_OC_CONF}
    sed -i 's|^[# \t]*\(crl = \).*|\1/etc/ocserv/crl.pem|' ${LOC_OC_CONF}
#用客户端证书CN作为用户名来区分用户
    sed -i 's|^[# \t]*\(cert-user-oid = \).*|\12\.5\.4\.3|' ${LOC_OC_CONF}
#用客户端证书UID作为用户名来区分用户
#    sed -i 's|^[# \t]*\(cert-user-oid = \).*|\10\.9\.2342\.19200300\.100\.1\.1|' ${LOC_OC_CONF}
}

function stop_ocserv(){
    /etc/init.d/ocserv stop
    oc_pid=`pidof ocserv`
    if [ ! -z "$oc_pid" ]; then
        for pid in $oc_pid
        do
            kill -9 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "Ocserv进程[$pid]已终止"
            fi
        done
    fi
}

function start_ocserv(){
    [ ! -f /etc/ocserv/server-cert.pem ] && die "server-cert.pem 没找到 !!!"
    [ ! -f /etc/ocserv/server-key.pem ] && die "server-key.pem 没找到!!!"
    /etc/init.d/ocserv start
}

function show_ocserv(){
    ocserv_port=`sed -n 's/^[ \t]*tcp-port[ \t]*=[ \t]*//p' ${LOC_OC_CONF}`
    clear
    echo
    ps cax | grep ocserv > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "\033[41;37mYour Server Domain :\033[0m\t\t$fqdnname:$ocserv_port"
        if [ "$ca_login" = "y" ]; then
            get_new_userca_show
        else
            echo -e "\033[41;37mYour Username :\033[0m\t\t\t$username"
            echo -e "\033[41;37mYour Password :\033[0m\t\t\t$password"
            echo
            print_info "You could use ' sudo ocpasswd -c /etc/ocserv/ocpasswd username ' to add users. "
        fi
        print_info "You could stop ocserv by ' /etc/init.d/ocserv stop '!"
        print_info "Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
        echo
        print_info "Enjoy it!"
        echo
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "n" ]; then
        echo -e "\033[41;37mYour Username :\033[0m\t\t\t$username"
        echo -e "\033[41;37mYour Password :\033[0m\t\t\t$password"
        echo
        print_info "1,You should change Server Certificate and Server Key's name to server-cert.pem and server-key.pem !"
        print_info "2,You should put them to /etc/ocserv !"
        print_info "3,You could start ocserv by ' /etc/init.d/ocserv start ' !"
        print_info "4,You could use ' sudo ocpasswd -c /etc/ocserv/ocpasswd username ' to add users."
        print_info "5,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
        echo
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "y" ]; then
        print_info "1,You should change your Server Certificate and Server Key's name to server-cert.pem and server-key.pem !"
        print_info "2,You should change your Certificate Authority Certificates and Certificate Authority Key's  name to ca-cert.pem and ca-key.pem !"
        print_info "3,You should put server-cert.pem server-key.pem and ca-cert.pem to /etc/ocserv !"
        print_info "4,You should put ca-cert.pem and ca-key.pem to /etc/ocserv/CAforOC !"
        print_info "5,You could use ' bash `basename $0` gc ' to generate a new client-cert."
        print_info "6,You could start ocserv by ' /etc/init.d/ocserv start '."
        print_info "7,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
        echo
    else
        die "Ocserv start failure,check ${Script_Dir}/ocinstall.log"
    fi
}

function check_ca_cert(){
    [ ! -f /usr/sbin/ocserv ] && die "Ocserv NOT Found !!!"
    [ ! -f /etc/ocserv/CAforOC/ca-key.pem ] && die "ca-key.pem NOT Found !!!"
    [ ! -f /etc/ocserv/CAforOC/ca-cert.pem ] && die "ca-cert.pem NOT Found !!!"
}

function get_new_userca(){
    check_ca_cert
    ca_login="y" && self_signed_ca="y"
    add_a_user
    press_any_key
    ca_login_clientcert
    clear
    echo
}

function get_new_userca_show(){
    echo -e "\033[41;37mClient-cert Password :\033[0m\t\t$password"
    echo -e "\033[41;37mClient-cert Expiration Days :\033[0m\t$oc_ex_days"
    echo
    print_info "You should import the client certificate to your device at first."
    print_info "You could get ${name_user_ca}.p12 from ${Script_Dir}."
    print_info "You could use ' bash `basename $0` gc ' to generate a new client-cert."
    print_info "You could use ' bash `basename $0` rc ' to revoke an old client-cert."
}

function Outdate_Autoclean(){
    My_All_Ca=`ls -F|sed -n 's/\(user-.*\)\//\1/p'|sed ':a;N;s/\n/ /;ba;'`
    Today_Date=`date +%s`
    for My_One_Ca in ${My_All_Ca}
    do
        Client_EX_Date=`openssl x509 -noout -enddate -in ${My_One_Ca}/${My_One_Ca}-cert.pem | cut -d= -f2`
        Client_EX_Date=`date -d "${Client_EX_Date}" +%s`
        [ ${Client_EX_Date} -lt ${Today_Date} ] && {
            My_One_Ca_Now="${My_One_Ca}_${Today_Date}"
            mv ${My_One_Ca} ${My_One_Ca_Now}
            mv ${My_One_Ca_Now} -t revoke/
        }
    done
}

function revoke_userca(){
    check_ca_cert
#input info
    cd /etc/ocserv/CAforOC
    Outdate_Autoclean
    clear
    print_xxxx
    print_info "The following is the user list..."
    echo
    ls -F|grep /|grep user|cut -d/ -f1|color_line
    print_xxxx
    print_info "Which user do you want to revoke?"
    echo
    read -p "Which: " -e -i user- revoke_ca
    if [ ! -f /etc/ocserv/CAforOC/$revoke_ca/$revoke_ca-cert.pem ]
    then
        die "$revoke_ca NOT Found !!!"
    fi
    echo
    print_warn "Okay,${revoke_ca} will be revoked."
    print_xxxx
    press_any_key
#revoke   
    cat ${revoke_ca}/${revoke_ca}-cert.pem >>revoked.pem
    certtool --generate-crl --load-ca-privkey ca-key.pem --load-ca-certificate ca-cert.pem --load-certificate revoked.pem --template crl.tmpl --outfile ../crl.pem
    revoke_ca_now="${revoke_ca}_$(date +%s)"
    mv  ${revoke_ca} ${revoke_ca_now}
    mv  ${revoke_ca_now} revoke/
    print_info "${revoke_ca} was revoked."
    echo    
}

function reinstall_ocserv(){
    stop_ocserv
    rm -rf /etc/ocserv
    rm -rf /usr/sbin/ocserv
    rm -rf /etc/init.d/ocserv
    rm -rf /usr/bin/occtl
    rm -rf /usr/bin/ocpasswd
    install_OpenConnect_VPN_server
}
function uninstall_ocserv(){
    stop_ocserv
    rm -rf /etc/ocserv
    rm -rf /usr/sbin/ocserv
    rm -rf /etc/init.d/ocserv
    rm -rf /usr/bin/occtl
    rm -rf /usr/bin/ocpasswd
}
function upgrade_ocserv(){    
    get_info_from_net
    [ "$OC_version_latest" = "" ] && {
    die "Could not connect to the official website."
    }
    Default_Ask "The latest is ${OC_version_latest} ,Input the version you want to upgrade." "$OC_version_latest" "oc_version"
    press_any_key
    stop_ocserv
    rm -f /etc/ocserv/profile.xml
    rm -f /usr/sbin/ocserv
    tar_ocserv_install
    start_ocserv
    ps cax | grep ocserv > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_info "Your ocserv upgrade was successful!"
    else
        print_warn "Ocserv start failure,ocserv is offline!"
        print_info "You could use ' bash `basename $0` ri' to forcibly upgrade your ocserv."
    fi
}

function enable_both_login(){
    character_Test ${LOC_OC_CONF} 'auth = "plain' && {
        character_Test ${LOC_OC_CONF} 'enable-auth = certificate' && {
            die "You have enabled the plain and the certificate login."
        }
        enable_both_login_open_ca
    }
    character_Test ${LOC_OC_CONF} 'auth = "certificate"' && {
    enable_both_login_open_plain
    }
}

function enable_both_login_open_ca(){
    get_new_userca
    sed -i 's|^[# \t]*\(enable-auth = certificate\)|\1|' ${LOC_OC_CONF}
    ca_login_set
    stop_ocserv
    start_ocserv
    clear
    echo
    print_info "The plain login and the certificate login are Okay~"
    print_info "The following is your certificate login info~"
    echo
    get_new_userca_show
    echo
}

function enable_both_login_open_plain(){
    ca_login="n"
    add_a_user
    press_any_key
    plain_login_set
    sed -i 's|^[ \t]*\(auth = "certificate"\)|#\1|' ${LOC_OC_CONF}
    sed -i 's|^[# \t]*\(auth = "plain\)|\1|' ${LOC_OC_CONF}
    sed -i 's|^[# \t]*\(enable-auth = certificate\)|\1|' ${LOC_OC_CONF}
    stop_ocserv
    start_ocserv
    clear
    echo
    print_info "The plain login and the certificate login are Okay~"
    print_info "The following is your plain login info~"
    echo
    echo -e "\033[41;37mYour Username :\033[0m\t\t\t$username"
    echo -e "\033[41;37mYour Password :\033[0m\t\t\t$password"
    echo
}

function help_ocservauto(){
    print_xxxx
    print_info "######################## Parameter Description ####################################"
    echo
    print_info " install ----------------------- Install ocserv for Debian 7+"
    echo
    print_info " fastmode or fm ---------------- Rapid installation for ocserv through $CONFIG_PATH_VARS"
    echo
    print_info " getuserca or gc --------------- Get a new client certificate"
    echo
    print_info " revokeuserca or rc ------------ Revoke a client certificate"
    echo
    print_info " upgrade or ug ----------------- Smoothly upgrade your ocserv"
    echo
    print_info " reinstall or ri --------------- Force to reinstall your ocserv(Destroy All Data)"
    echo
    print_info " pc ---------------------------- At the same time,enable the plain and the certificate login"
    echo
    print_info " occ --------------------------- Verify client certificates through a existing CA"
    echo
    print_info " help or h --------------------- Show this description"
    print_xxxx
}

#################################################################################################################
#surport system codename                                                                                        #
#################################################################################################################

#已经测试过的系统
function surport_Syscodename(){
    oc_D_V=$(lsb_release -c -s)
    [ "$oc_D_V" = "wheezy" ] && return 0
    [ "$oc_D_V" = "jessie" ] && return 0
    [ "$oc_D_V" = "stretch" ] && return 0
    [ "$oc_D_V" = "trusty" ] && return 0
    [ "$oc_D_V" = "utopic" ] && return 0
    [ "$oc_D_V" = "vivid" ] && return 0
    [ "$oc_D_V" = "wily" ] && return 0
    [ "$oc_D_V" = "xenial" ] && return 0
    #TEST NEWER SYS 测试新系统，取消下面一行的注释。
    #[ "$oc_D_V" = "$oc_D_V" ] && return 0
###############################
# # 另一种实现方式
# D_V=( wheezy jessie trusty utopic vivid )
# for DV in ${D_V[*]}
# do
# [ "$oc_D_V" = "$DV" ] && return 0
# done
###############################
}

#此处请不要改变
Script_Dir="$(cd "$(dirname $0)"; pwd)"
#此处请不要改变
CONFIG_PATH_VARS="${Script_Dir}/vars_ocservauto"
#此处请不要改变
LOC_OC_CONF="/etc/ocserv/ocserv.conf"

##################################################################################################################
#main                                                                                                            #
##################################################################################################################
clear
echo "==============================================================================================="
echo
print_info " 系统要求：Debian 7+ Ubuntu 14.04 +"
echo
print_info " 描述:  安装 OpenConnect VPN 服务端"
echo
echo "==============================================================================================="

#ocserv配置文件所在的网络文件夹位置
#如果fork的话，请修改为自己的网络地址
NET_OC_CONF_DOC="https://raw.githubusercontent.com/taotaolin/Ocserv_for_Debian_Ubuntu/master"
#推荐的默认版本
Default_oc_version="0.11.8"
#开启分组模式，每位用户都会分配到All组和Route组。
#All走全局，Route将会绕过大陆。
#证书以及用户名登录都会采取。
#证书分组模式下，ios下anyconnect客户端有bug，请不要使用。
#默认为n关闭，开启为y。
open_two_group="n"
#编译安装ocserv的额外选项
#例如Extra_Options="--with-local-talloc --enable-local-libopts --without-pcl-lib  --without-http-parser --without-protobuf"
#详细请参考./configure --help 或ocserv官网
Extra_Options=""

over(){
	update-rc.d -f ocserv remove
    rm -rf /etc/ocserv
    rm -rf /usr/sbin/ocserv
    rm -rf /etc/init.d/ocserv
    rm -rf /usr/bin/occtl
    rm -rf /usr/bin/ocpasswd
	echo && echo "安装过程错误，ocserv 卸载完成 !" && echo
}

PID_FILE="/var/run/ocserv.pid"
passwd_file="/etc/ocserv/ocpasswd"


List_User(){
	[[ ! -e ${passwd_file} ]] && echo -e "${Error} ocserv 账号配置文件不存在 !" && exit 1
	User_text=$(cat ${passwd_file})
	if [[ ! -z ${User_text} ]]; then
		User_num=$(echo -e "${User_text}"|wc -l)
		user_list_all=""
		for((integer = 1; integer <= ${User_num}; integer++))
		do
			user_name=$(echo -e "${User_text}" | awk -F ':*:' '{print $1}' | sed -n "${integer}p")
			user_status=$(echo -e "${User_text}" | awk -F ':*:' '{print $NF}' | sed -n "${integer}p"|cut -c 1)
			if [[ ${user_status} == '!' ]]; then
				user_status="禁用"
			else
				user_status="启用"
			fi
			user_list_all=${user_list_all}"用户名: "${user_name}" 账号状态: "${user_status}"\n"
		done
		echo && echo -e "用户总数 ${Green_font_prefix}"${User_num}"${Font_color_suffix}"
		echo -e ${user_list_all}
	fi
}

Set_username(){
	echo "请输入 要添加的VPN账号 用户名"
	read -e -p "(默认: admin):" username
	[[ -z "${username}" ]] && username="admin"
	echo && echo -e "	用户名 : ${Red_font_prefix}${username}${Font_color_suffix}" && echo
}
Set_passwd(){
	echo "请输入 要添加的VPN账号 密码"
	read -e -p "(默认: admin8888):" userpass
	[[ -z "${userpass}" ]] && userpass="admin8888"
	echo && echo -e "	密码 : ${Red_font_prefix}${userpass}${Font_color_suffix}" && echo
}


Add_User(){
	Set_username
	Set_passwd
	user_status=$(cat "${passwd_file}"|grep "${username}"':*:')
	[[ ! -z ${user_status} ]] && echo -e "${Error} 用户名已存在 ![ ${username} ]" && exit 1
	echo -e "${userpass}\n${userpass}"|ocpasswd -c ${passwd_file} ${username}
	user_status=$(cat "${passwd_file}"|grep "${username}"':*:')
	if [[ ! -z ${user_status} ]]; then
		echo -e "${Info} 账号添加成功 ![ ${username} ]"
	else
		echo -e "${Error} 账号添加失败 ![ ${username} ]" && exit 1
	fi
}
Del_User(){
	List_User
	[[ ${User_num} == 1 ]] && echo -e "${Error} 当前仅剩一个账号配置，无法删除 !" && exit 1
	echo -e "请输入要删除的VPN账号的用户名"
	read -e -p "(默认取消):" Del_username
	[[ -z "${Del_username}" ]] && echo "已取消..." && exit 1
	user_status=$(cat "${passwd_file}"|grep "${Del_username}"':*:')
	[[ -z ${user_status} ]] && echo -e "${Error} 用户名不存在 ! [${Del_username}]" && exit 1
	ocpasswd -c ${passwd_file} -d ${Del_username}
	user_status=$(cat "${passwd_file}"|grep "${Del_username}"':*:')
	if [[ -z ${user_status} ]]; then
		echo -e "${Info} 删除成功 ! [${Del_username}]"
	else
		echo -e "${Error} 删除失败 ! [${Del_username}]" && exit 1
	fi
}
Modify_User_disabled(){
	List_User
	echo -e "请输入要启用/禁用的VPN账号的用户名"
	read -e -p "(默认取消):" Modify_username
	[[ -z "${Modify_username}" ]] && echo "已取消..." && exit 1
	user_status=$(cat "${passwd_file}"|grep "${Modify_username}"':*:')
	[[ -z ${user_status} ]] && echo -e "${Error} 用户名不存在 ! [${Modify_username}]" && exit 1
	user_status=$(cat "${passwd_file}" | grep "${Modify_username}"':*:' | awk -F ':*:' '{print $NF}' |cut -c 1)
	if [[ ${user_status} == '!' ]]; then
			ocpasswd -c ${passwd_file} -u ${Modify_username}
			user_status=$(cat "${passwd_file}" | grep "${Modify_username}"':*:' | awk -F ':*:' '{print $NF}' |cut -c 1)
			if [[ ${user_status} != '!' ]]; then
				echo -e "${Info} 启用成功 ! [${Modify_username}]"
			else
				echo -e "${Error} 启用失败 ! [${Modify_username}]" && exit 1
			fi
		else
			ocpasswd -c ${passwd_file} -l ${Modify_username}
			user_status=$(cat "${passwd_file}" | grep "${Modify_username}"':*:' | awk -F ':*:' '{print $NF}' |cut -c 1)
			if [[ ${user_status} == '!' ]]; then
				echo -e "${Info} 禁用成功 ! [${Modify_username}]"
			else
				echo -e "${Error} 禁用失败 ! [${Modify_username}]" && exit 1
			fi
		fi
}
Set_Pass(){
	check_installed_status
	echo && echo -e " 你要做什么？
	
 ${Green_font_prefix} 0.${Font_color_suffix} 列出 账号配置
————————
 ${Green_font_prefix} 1.${Font_color_suffix} 添加 账号配置
 ${Green_font_prefix} 2.${Font_color_suffix} 删除 账号配置
————————
 ${Green_font_prefix} 3.${Font_color_suffix} 启用/禁用 账号配置
 
 注意：添加/修改/删除 账号配置后，VPN服务端会实时读取，无需重启服务端 !" && echo
	read -e -p "(默认: 取消):" set_num
	[[ -z "${set_num}" ]] && echo "已取消..." && exit 1
	if [[ ${set_num} == "0" ]]; then
		List_User
	elif [[ ${set_num} == "1" ]]; then
		Add_User
	elif [[ ${set_num} == "2" ]]; then
		Del_User
	elif [[ ${set_num} == "3" ]]; then
		Modify_User_disabled
	else
		echo -e "${Error} 请输入正确的数字[1-3]" && exit 1
	fi
}


check_pid(){
PID=`ps -ef |grep "${NAME}" |grep -v "grep" | grep -v "ocservauto.sh"| grep -v "init.d" |grep -v "service" |awk '{print $2}'`
}

check_installed_status(){
	[[ ! -e /usr/sbin/ocserv ]] && echo -e "${Error} ocserv 没有安装，请检查 !" && exit 1
	[[ ! -e ${LOC_OC_CONF} ]] && echo -e "${Error} ocserv 配置文件不存在，请检查 !" && [[ $1 != "un" ]] && exit 1
}


Start_ocserv(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} ocserv 正在运行，请检查 !" && exit 1
	/etc/init.d/ocserv start
	sleep 2s
	check_pid
	[[ ! -z ${PID} ]] && echo -e " ocserv 启动成功 !"
}
Stop_ocserv(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} ocserv 没有运行，请检查 !" && exit 1
	/etc/init.d/ocserv stop
}
Restart_ocserv(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/ocserv stop
	/etc/init.d/ocserv start
	sleep 2s
	check_pid
	[[ ! -z ${PID} ]] && echo -e " ocserv 启动成功 !"
}


Service_ocserv(){
	if ! wget --no-check-certificate https://raw.githubusercontent.com/taotaolin/Ocserv_for_Debian_Ubuntu/master/ocserv_debian -O /etc/init.d/ocserv; then
		echo -e "${Error} ocserv 服务 管理脚本下载失败 !" && over
	fi
	chmod +x /etc/init.d/ocserv
	update-rc.d -f ocserv defaults
	echo -e "${Info} ocserv 服务 管理脚本下载完成 !"
}


Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/taotaolin/Ocserv_for_Debian_Ubuntu/master/ocservauto.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/ocserv" ]]; then
		rm -rf /etc/init.d/ocserv
		Service_ocserv
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/taotaolin/Ocserv_for_Debian_Ubuntu/master/ocservauto.sh" && chmod +x ocservauto.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}


echo && echo -e "  Ocserv 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}

  新建用户  ocpasswd -c /etc/ocserv/ocpasswd 用户名

  新建证书用户 bash ocservauto.sh getuserca       getuserca可用gc代替   

  吊销证书用户 bash ocservauto.sh revokeuserca    revokeuserca可用rc代替

===============================================================================================

 ${Green_font_prefix}0.${Font_color_suffix}  升级脚本
————————————
 ${Green_font_prefix}1.${Font_color_suffix}  安装 ocserv
 ${Green_font_prefix}2.${Font_color_suffix}  卸载 ocserv
————————————
 ${Green_font_prefix}3.${Font_color_suffix}  重装 ocserv
 ${Green_font_prefix}4.${Font_color_suffix}  开启fast模式
 ${Green_font_prefix}5.${Font_color_suffix}  更新 ocserv
————————————
 ${Green_font_prefix}6.${Font_color_suffix}  证书验证
 ${Green_font_prefix}7.${Font_color_suffix}  同时启用证书登陆和密码登陆
 ${Green_font_prefix}8.${Font_color_suffix}  查看帮助
 ————————————
 ${Green_font_prefix}9.${Font_color_suffix}  启动 ocserv
 ${Green_font_prefix}10.${Font_color_suffix} 停止 ocserv
 ${Green_font_prefix}11.${Font_color_suffix} 重启 ocserv
————————————
 ${Green_font_prefix}12.${Font_color_suffix} 用户管理（账号密码）
 ${Green_font_prefix}13.${Font_color_suffix} 新建证书用户
 ${Green_font_prefix}14.${Font_color_suffix} 吊销证书用户
 ${Green_font_prefix}15.${Font_color_suffix} 使用一证书多用户
————————————" && echo
if [[ -e /usr/sbin/ocserv ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [0-14]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
    log_Start
    install_OpenConnect_VPN_server | tee -a ${Script_Dir}/ocinstall.log
	;;
	2)
    log_Start
    uninstall_ocserv | tee -a ${Script_Dir}/ocinstall.log
	;;
	3)
    log_Start
    reinstall_ocserv | tee -a ${Script_Dir}/ocinstall.log
	;;
	4)
    [ ! -f $CONFIG_PATH_VARS ] && die "$CONFIG_PATH_VARS Not Found !"
    fast_install="y"
    . $CONFIG_PATH_VARS
    log_Start
    install_OpenConnect_VPN_server | tee -a ${Script_Dir}/ocinstall.log
	;;
	5)
    log_Start
    upgrade_ocserv | tee -a ${Script_Dir}/ocinstall.log
	;;
	6)
    log_Start
    install_Oneclientcer | tee -a ${Script_Dir}/ocinstall.log
	;;
	7)
    enable_both_login
	;;
	8)
    clear
    help_ocservauto
	;;
	9)
	Start_ocserv
	;;
	10)
	Stop_ocserv
	;;
	11)
	Restart_ocserv
	;;
	12)
	Set_Pass
	;;
    13)
    character_Test ${LOC_OC_CONF} 'auth = "plain' && {
        character_Test ${LOC_OC_CONF} 'enable-auth = certificate' || {
            die "You have to enable the the certificate login at first."
        }
    }
    get_new_userca
    get_new_userca_show
    ;;
    14)
    revoke_userca
    ;;
    15)
    log_Start
    install_Oneclientcer | tee -a ${Script_Dir}/ocinstall.log
    ;;
    getuserca | gc)
    character_Test ${LOC_OC_CONF} 'auth = "plain' && {
        character_Test ${LOC_OC_CONF} 'enable-auth = certificate' || {
            die "You have to enable the the certificate login at first."
        }
    }
    get_new_userca
    get_new_userca_show
    ;;
    revokeuserca | rc)
    revoke_userca
    ;;
	*)
	echo "请输入正确数字 [0-14]"
	;;
esac


#!/bin/bash
# Author: batcom
# Github: https://github.com/batcom/go-install

# cancel centos alias
[[ -f /etc/redhat-release ]] && unalias -a

source os-detect.sh

can_google=1

force_mode=0

sudo=""

os="Linux"

install_version=""

proxy_url="http://127.0.0.1:7890"

mirror_url=""

nerd_font_url="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/FiraCode/Medium/FiraCodeNerdFont-Medium.ttf"

#######color code########
red="31m"      
green="32m"  
yellow="33m" 
blue="36m"
fuchsia="35m"

install_path="/opt/nvim"

color_echo(){
    echo -e "\033[$1${@:2}\033[0m"
}

#######get params#########
while [[ $# > 0 ]];do
    case "$1" in
        -v|--version)
        install_version="$2"
        echo -e "准备安装$(color_echo ${blue} $install_version)版本golang..\n"
        shift
        ;;
        -f)
        force_mode=1
        echo -e "强制更新golang..\n"
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done
#############################

change_mirror(){
    if [[ -n $mirror_url ]];then
        bash <(curl -sSL https://linuxmirrors.cn/main.sh)
    fi
}

# 获得差集

# 数组1
# arr1=(a b c d e f)
# 数组2
# arr2=(c d b e g)

# 先将交集保存为数组
# arr3=`echo ${arr1[@]} ${arr2[@]} | sed 's/ /\n/g' | sort | uniq -d | sed 's/\n/ /g'`

# arr1 - arr2 差集
# echo ${arr1[@]} ${arr3[@]} | sed 's/ /\n/g' | sort | uniq -u

# arr2 - arr1 差集
# echo ${arr2[@]} ${arr3[@]} | sed 's/ /\n/g' | sort | uniq -u

init(){
    centos_arr=(rhel fedora centos)
    debian_arr=(debian ubuntu)
    os_base_arr=($OSD_BASEDON)
    base_arr=`echo ${centos_arr[@]} ${os_base_arr[@]} | sed 's/ /\n/g' | sort | uniq -d | sed 's/\n/ /g'`
    if [ ${#base_arr[@]} -ne 0 ]; then
        yum install -y git
    else
        base_arr=`echo ${debian_arr[@]} ${os_base_arr[@]} | sed 's/ /\n/g' | sort | uniq -d | sed 's/\n/ /g'`
        if [ ${#base_arr[@]} -ne 0 ];then
        apt-get install -y git 
        else
        echo "操作系统不明"
        exit
        fi
    fi
}

ip_is_connect(){
    ping -c2 -i0.3 -W1 $1 &>/dev/null
    if [ $? -eq 0 ];then
        return 0
    else
        return 1
    fi
}

setup_env(){
    if [[ $sudo == "" ]];then
        profile_path="/etc/profile"
    elif [[ -e ~/.zshrc ]];then
        profile_path="$HOME/.zprofile"
    elif [[ -e ~/.bashrc ]];then
        profile_path="$HOME/.bashrc"
    fi
    if [[ -z `echo $PATH|grep $install_path` ]];then
        echo 'export PATH=$PATH:'$install_path >> $profile_path
    fi
    source $profile_path
}

check_network(){
    ip_is_connect "google.com"
    [[ ! $? -eq 0 ]] && can_google=0
}

setup_proxy(){
    if [[ $can_google == 0 ]]; then
        export "http_proxy=$proxy_url"
        export "https_proxy=$proxy_url"
    fi
}

sys_arch(){
    arch=$(uname -m)
    if [[ `uname -s` == "Darwin" ]];then
        os="Darwin"
        if [[ "$arch" == "arm64" ]];then
            vdis="macos-arm64"
            lazygit_id="Darwin_arm64"
        else
            vdis="macos-x86_64"
            lazygit_id="Darwin_x86_64"
        fi
    else
        if [[ "$arch" == "i686" ]] || [[ "$arch" == "i386" ]]; then
            vdis="linux-386"
            lazygit_id="Linux_32-bit"
        elif [[ "$arch" == *"armv7"* ]] || [[ "$arch" == "armv6l" ]]; then
            vdis="linux-armv6l"
            lazygit_id="Linux_armv6"
        elif [[ "$arch" == *"armv8"* ]] || [[ "$arch" == "aarch64" ]]; then
            vdis="linux-arm64"
            lazygit_id="Linux_arm64"
        elif [[ "$arch" == *"s390x"* ]]; then
            vdis="linux-s390x"
        elif [[ "$arch" == "ppc64le" ]]; then
            vdis="linux-ppc64le"
        elif [[ "$arch" == "x86_64" ]]; then
            vdis="linux64"
            lazygit_id="Linux_x86_64"
        fi
    fi
    [ $(id -u) != "0" ] && sudo="sudo"
}

install_neovim(){
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-$vdis.tar.gz
    # $sudo rm -rf /opt/nvim
    $sudo tar -C $install_path -xzf nvim-$vdis.tar.gz
}

downloadNerdFonts(){
    if [[ $os == "Linux" ]];then
        mkdir -p ~/.local/share/fonts
        cd ~/.local/share/fonts && curl -fLO $nerd_font_url
    elif [[ $os == "Darwin" ]];then
        cd ~/Library/Fonts && curl -fLO $nerd_font_url
    fi
}

install_lazygit(){
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    if [[ $os == "Linux" ]];then
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_${lazygit_id}.tar.gz"
        tar -C /usr/local/bin -xzf lazygit.tar.gz lazygit
    elif [[ $os == "Darwin" ]];then
        brew install lazygit
    fi    
}

main(){
    sys_arch
    check_network
    setup_env
    setup_proxy
    install_neovim
    downloadNerdFonts
    install_lazygit
    echo -e "neovim `color_echo ` 安装成功!"
}

main

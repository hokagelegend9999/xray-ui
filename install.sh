#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error:${plain} Script ini harus dijalankan sebagai root user!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Sistem tidak terdeteksi, silakan hubungi pembuat script!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${red}Gagal mendeteksi arsitektur, menggunakan arsitektur default: ${arch}${plain}"
fi

echo "Arsitektur: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "Software ini tidak mendukung sistem 32-bit (x86), silakan gunakan sistem 64-bit (x86_64)"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Silakan gunakan CentOS 7 atau versi yang lebih baru!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Silakan gunakan Ubuntu 16 atau versi yang lebih baru!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Silakan gunakan Debian 8 atau versi yang lebih baru!${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

#This function will be called when user installed x-ui out of sercurity
config_after_install() {
    echo -e "${yellow}Untuk alasan keamanan, port, username dan password harus diubah setelah instalasi/pembaruan${plain}"
    read -p "Apakah Anda ingin melanjutkan?[y/n]": config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "Silakan set username Anda:" config_account
        echo -e "${yellow}Username Anda akan diset sebagai:${config_account}${plain}"
        read -p "Silakan set password Anda:" config_password
        echo -e "${yellow}Password Anda akan diset sebagai:${config_password}${plain}"
        read -p "Silakan set port panel:" config_port
        echo -e "${yellow}Port panel Anda akan diset sebagai:${config_port}${plain}"
        echo -e "${yellow}Konfirmasi pengaturan, proses penyettingan...${plain}"
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}Username dan password berhasil diset${plain}"
        /usr/local/x-ui/x-ui setting -port ${config_port}
        echo -e "${yellow}Port panel berhasil diset${plain}"
    else
        echo -e "${red}Dibatalkan, semua pengaturan menggunakan nilai default, silakan ubah segera${plain}"
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/vaxilu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Gagal mendeteksi versi x-ui, mungkin melebihi batas API Github, silakan coba lagi nanti atau instal versi x-ui secara manual${plain}"
            exit 1
        fi
        echo -e "Versi terbaru x-ui terdeteksi: ${last_version}, memulai instalasi"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Gagal mengunduh x-ui, pastikan server Anda dapat mengunduh file dari Github${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "Memulai instalasi x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Gagal mengunduh x-ui v$1, pastikan versi ini ada${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/vaxilu/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} berhasil diinstal, panel telah berjalan"
    echo -e ""
    echo -e "Cara menggunakan script manajemen x-ui: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - Menampilkan menu manajemen (fitur lebih lengkap)"
    echo -e "x-ui start        - Memulai panel x-ui"
    echo -e "x-ui stop         - Menghentikan panel x-ui"
    echo -e "x-ui restart      - Merestart panel x-ui"
    echo -e "x-ui status       - Melihat status x-ui"
    echo -e "x-ui enable       - Mengaktifkan x-ui pada saat boot"
    echo -e "x-ui disable      - Menonaktifkan x-ui pada saat boot"
    echo -e "x-ui log          - Melihat log x-ui"
    echo -e "x-ui v2-ui        - Migrasi data akun v2-ui ke x-ui"
    echo -e "x-ui update       - Memperbarui panel x-ui"
    echo -e "x-ui install      - Menginstal panel x-ui"
    echo -e "x-ui uninstall    - Menghapus panel x-ui"
    echo -e "----------------------------------------------"
}

echo -e "${green}Memulai instalasi${plain}"
install_base
install_x-ui $1

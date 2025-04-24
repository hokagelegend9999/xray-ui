#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

#Tambahkan beberapa fungsi dasar di sini
function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}
# periksa root
[[ $EUID -ne 0 ]] && LOGE "Kesalahan:  Harus menjalankan skrip ini sebagai root!\n" && exit 1

# periksa os
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
    LOGE "Versi sistem tidak terdeteksi, silakan hubungi penulis skrip!\n" && exit 1
fi

os_version=""

# versi os
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        LOGE "Harap gunakan sistem CentOS 7 atau lebih tinggi!\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        LOGE "Harap gunakan sistem Ubuntu 16 atau lebih tinggi!\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        LOGE "Harap gunakan sistem Debian 8 atau lebih tinggi!\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [default $2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Apakah ingin merestart panel, restart panel juga akan merestart xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Tekan enter untuk kembali ke menu utama: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "Fungsi ini akan memaksa instalasi versi terbaru, data tidak akan hilang, lanjutkan?" "n"
    if [[ $? != 0 ]]; then
        LOGE "Dibatalkan"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "Pembaruan selesai, panel telah direstart otomatis "
        exit 0
    fi
}

uninstall() {
    confirm "Yakin ingin mencopot panel? xray juga akan dicopot?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "Pencopotan berhasil, jika ingin menghapus skrip ini, keluar dari skrip lalu jalankan ${green}rm /usr/bin/x-ui -f${plain} untuk menghapus"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Yakin ingin mengatur ulang username dan password menjadi admin" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "Username dan password telah diatur ulang menjadi ${green}admin${plain}, silakan restart panel sekarang"
    confirm_restart
}

reset_config() {
    confirm "Yakin ingin mengatur ulang semua pengaturan panel? Data akun tidak akan hilang, username dan password tidak akan berubah" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "Semua pengaturan panel telah diatur ulang ke default, silakan restart panel, dan gunakan port default ${green}54321${plain} untuk mengakses panel"
    confirm_restart
}

check_config() {
    info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "gagal mendapatkan pengaturan saat ini, silakan periksa log"
        show_menu
    fi
    LOGI "${info}"
}

set_port() {
    echo && echo -n -e "Masukkan nomor port[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        LOGD "Dibatalkan"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "Pengaturan port selesai, silakan restart panel, dan gunakan port baru ${green}${port}${plain} untuk mengakses panel"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "Panel sudah berjalan, tidak perlu memulai lagi, jika ingin restart silakan pilih restart"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "x-ui berhasil dimulai"
        else
            LOGE "Gagal memulai panel, mungkin karena waktu mulai lebih dari dua detik, silakan periksa informasi log nanti"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "Panel sudah berhenti, tidak perlu menghentikan lagi"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "x-ui dan xray berhasil dihentikan"
        else
            LOGE "Gagal menghentikan panel, mungkin karena waktu berhenti lebih dari dua detik, silakan periksa informasi log nanti"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "x-ui dan xray berhasil direstart"
    else
        LOGE "Gagal merestart panel, mungkin karena waktu mulai lebih dari dua detik, silakan periksa informasi log nanti"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui berhasil diatur untuk mulai otomatis saat boot"
    else
        LOGE "Gagal mengatur x-ui untuk mulai otomatis saat boot"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui berhasil dibatalkan untuk mulai otomatis saat boot"
    else
        LOGE "Gagal membatalkan x-ui untuk mulai otomatis saat boot"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui

    before_show_menu
}

install_bbr() {
    # solusi sementara untuk menginstal bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/vaxilu/x-ui/raw/master/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Gagal mengunduh skrip, silakan periksa apakah mesin ini dapat terhubung ke Github"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        LOGI "Berhasil memperbarui skrip, silakan jalankan skrip lagi" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "Panel sudah terinstal, jangan instal ulang"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "Silakan instal panel terlebih dahulu"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "Status panel: ${green}Berjalan${plain}"
        show_enable_status
        ;;
    1)
        echo -e "Status panel: ${yellow}Tidak berjalan${plain}"
        show_enable_status
        ;;
    2)
        echo -e "Status panel: ${red}Tidak terinstal${plain}"
        ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Mulai otomatis saat boot: ${green}Ya${plain}"
    else
        echo -e "Mulai otomatis saat boot: ${red}Tidak${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "Status xray: ${green}Berjalan${plain}"
    else
        echo -e "Status xray: ${red}Tidak berjalan${plain}"
    fi
}

ssl_cert_issue() {
    echo -E ""
    LOGD "******Petunjuk Penggunaan******"
    LOGI "Skrip ini akan menggunakan skrip Acme untuk mengajukan sertifikat, pastikan:"
    LOGI "1. Mengetahui email registrasi Cloudflare"
    LOGI "2. Mengetahui Cloudflare Global API Key"
    LOGI "3. Domain sudah diarahkan melalui Cloudflare ke server saat ini"
    LOGI "4. Jalur instalasi default sertifikat yang diajukan oleh skrip ini adalah direktori /root/cert"
    confirm "Saya telah mengonfirmasi konten di atas [y/n]" "y"
    if [ $? -eq 0 ]; then
        cd ~
        LOGI "Menginstal skrip Acme"
        curl https://get.acme.sh | sh
        if [ $? -ne 0 ]; then
            LOGE "Gagal menginstal skrip acme"
            exit 1
        fi
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        if [ ! -d "$certPath" ]; then
            mkdir $certPath
        else
            rm -rf $certPath
            mkdir $certPath
        fi
        LOGD "Silakan atur domain:"
        read -p "Input domain Anda di sini:" CF_Domain
        LOGD "Domain Anda diatur sebagai:${CF_Domain}"
        LOGD "Silakan atur kunci API:"
        read -p "Input kunci Anda di sini:" CF_GlobalKey
        LOGD "Kunci API Anda adalah:${CF_GlobalKey}"
        LOGD "Silakan atur email registrasi:"
        read -p "Input email Anda di sini:" CF_AccountEmail
        LOGD "Email registrasi Anda adalah:${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "Gagal mengubah CA default ke Lets'Encrypt, skrip keluar"
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "Gagal menerbitkan sertifikat, skrip keluar"
            exit 1
        else
            LOGI "Berhasil menerbitkan sertifikat, menginstal..."
        fi
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
        --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
        --fullchain-file /root/cert/fullchain.cer
        if [ $? -ne 0 ]; then
            LOGE "Gagal menginstal sertifikat, skrip keluar"
            exit 1
        else
            LOGI "Berhasil menginstal sertifikat, mengaktifkan pembaruan otomatis..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "Gagal mengatur pembaruan otomatis, skrip keluar"
            ls -lah cert
            chmod 755 $certPath
            exit 1
        else
            LOGI "Sertifikat telah diinstal dan pembaruan otomatis diaktifkan, informasi detail sebagai berikut"
            ls -lah cert
            chmod 755 $certPath
        fi
    else
        show_menu
    fi
}

show_usage() {
    echo "Cara penggunaan skrip manajemen x-ui: "
    echo "------------------------------------------"
    echo "x-ui              - Tampilkan menu manajemen (lebih banyak fitur)"
    echo "x-ui start        - Mulai panel x-ui"
    echo "x-ui stop         - Hentikan panel x-ui"
    echo "x-ui restart      - Restart panel x-ui"
    echo "x-ui status       - Lihat status x-ui"
    echo "x-ui enable       - Atur x-ui untuk mulai otomatis saat boot"
    echo "x-ui disable      - Batalkan x-ui untuk mulai otomatis saat boot"
    echo "x-ui log          - Lihat log x-ui"
    echo "x-ui v2-ui        - Migrasikan data akun v2-ui mesin ini ke x-ui"
    echo "x-ui update       - Perbarui panel x-ui"
    echo "x-ui install      - Instal panel x-ui"
    echo "x-ui uninstall    - Copot panel x-ui"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}Skrip Manajemen Panel x-ui${plain}
  ${green}0.${plain} Keluar dari skrip
————————————————
  ${green}1.${plain} Instal x-ui
  ${green}2.${plain} Perbarui x-ui
  ${green}3.${plain} Copot x-ui
————————————————
  ${green}4.${plain} Atur ulang username password
  ${green}5.${plain} Atur ulang pengaturan panel
  ${green}6.${plain} Atur port panel
  ${green}7.${plain} Lihat pengaturan panel saat ini
————————————————
  ${green}8.${plain} Mulai x-ui
  ${green}9.${plain} Hentikan x-ui
  ${green}10.${plain} Restart x-ui
  ${green}11.${plain} Lihat status x-ui
  ${green}12.${plain} Lihat log x-ui
————————————————
  ${green}13.${plain} Atur x-ui untuk mulai otomatis saat boot
  ${green}14.${plain} Batalkan x-ui untuk mulai otomatis saat boot
————————————————
  ${green}15.${plain} Instal bbr dengan satu klik (kernel terbaru)
  ${green}16.${plain} Ajukan sertifikat SSL dengan satu klik (pengajuan acme)
 "
    show_status
    echo && read -p "Masukkan pilihan [0-16]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && uninstall
        ;;
    4)
        check_install && reset_user
        ;;
    5)
        check_install && reset_config
        ;;
    6)
        check_install && set_port
        ;;
    7)
        check_install && check_config
        ;;
    8)
        check_install && start
        ;;
    9)
        check_install && stop
        ;;
    10)
        check_install && restart
        ;;
    11)
        check_install && status
        ;;
    12)
        check_install && show_log
        ;;
    13)
        check_install && enable
        ;;
    14)
        check_install && disable
        ;;
    15)
        install_bbr
        ;;
    16)
        ssl_cert_issue
        ;;
    *)
        LOGE "Masukkan angka yang benar [0-16]"
        ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        check_install 0 && start 0
        ;;
    "stop")
        check_install 0 && stop 0
        ;;
    "restart")
        check_install 0 && restart 0
        ;;
    "status")
        check_install 0 && status 0
        ;;
    "enable")
        check_install 0 && enable 0
        ;;
    "disable")
        check_install 0 && disable 0
        ;;
    "log")
        check_install 0 && show_log 0
        ;;
    "v2-ui")
        check_install 0 && migrate_v2_ui 0
        ;;
    "update")
        check_install 0 && update 0
        ;;
    "install")
        check_uninstall 0 && install 0
        ;;
    "uninstall")
        check_install 0 && uninstall 0
        ;;
    *) show_usage ;;
    esac
else
    show_menu
fi

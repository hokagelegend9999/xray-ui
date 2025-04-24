x-ui
Panel xray yang mendukung multi-protokol dan multi-pengguna

Fitur
Monitoring status sistem

Dukungan multi-pengguna dan multi-protokol, operasi visual melalui web

Protokol yang didukung: vmess, vless, trojan, shadowsocks, dokodemo-door, socks, http

Dukungan konfigurasi transportasi tambahan

Statistik lalu lintas, pembatasan kuota, pembatasan masa berlaku

Dapat menyesuaikan template konfigurasi xray

Dukungan akses panel via https (domain sendiri + sertifikat SSL)

Dukungan penerbitan sertifikat SSL satu klik dengan perpanjangan otomatis

Lebih banyak opsi konfigurasi lanjutan, lihat panel

Instalasi & Pembaruan
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
Instalasi & Pembaruan Manual
Pertama unduh paket terbaru dari https://github.com/vaxilu/x-ui/releases, biasanya pilih arsitektur amd64

Kemudian unggah paket ini ke direktori /root/ server dan login ke server sebagai pengguna root

Jika arsitektur CPU server Anda bukan amd64, ganti amd64 dalam perintah dengan arsitektur lain secara manual

cd /root/
rm x-ui/ /usr/local/x-ui/ /usr/bin/x-ui -rf
tar zxvf x-ui-linux-amd64.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
mv x-ui/ /usr/local/
systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui
Instalasi dengan Docker
Tutorial docker dan image docker ini disediakan oleh Chasing66

Instal docker

shell
curl -fsSL https://get.docker.com | sh
Instal x-ui

shell
mkdir x-ui && cd x-ui
docker run -itd --network=host \
    -v $PWD/db/:/etc/x-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name x-ui --restart=unless-stopped \
    enwaiax/x-ui:latest
Build image sendiri

shell
docker build -t x-ui .
Penerbitan Sertifikat SSL
Fitur dan tutorial ini disediakan oleh FranzKafkaYu

Skrip ini memiliki fungsi penerbitan sertifikat SSL bawaan. Untuk menggunakan skrip ini dalam menerbitkan sertifikat, diperlukan persyaratan berikut:

Mengetahui email registrasi Cloudflare

Mengetahui Cloudflare Global API Key

Domain sudah diarahkan melalui Cloudflare ke server saat ini

Cara mendapatkan Cloudflare Global API Key:



Saat menggunakan cukup masukkan domain, email, API KEY, ilustrasi sebagai berikut:


Catatan:

Skrip ini menggunakan DNS API untuk penerbitan sertifikat

Secara default menggunakan Let'sEncrypt sebagai CA

Direktori instalasi sertifikat adalah /root/cert

Sertifikat yang diterbitkan oleh skrip ini adalah sertifikat wildcard

Penggunaan Bot Telegram (Dalam pengembangan, belum dapat digunakan)
Fitur dan tutorial ini disediakan oleh FranzKafkaYu

X-UI mendukung notifikasi lalu lintas harian, peringatan login panel dan fungsi lainnya melalui bot Telegram. Untuk menggunakan bot Telegram, Anda perlu mendaftar sendiri.
Tutorial pendaftaran spesifik dapat merujuk tautan blog
Petunjuk penggunaan: Atur parameter terkait bot di latar belakang panel, termasuk:

Token bot Telegram

ChatId bot Telegram

Waktu operasi periodik bot Telegram, menggunakan sintaks crontab

Referensi sintaks:

30 * * * * * //Notifikasi setiap menit ke-30

@hourly //Notifikasi setiap jam

@daily //Notifikasi setiap hari (tepat tengah malam)

@every 8h //Notifikasi setiap 8 jam

Konten notifikasi TG:

Penggunaan lalu lintas node

Peringatan login panel

Peringatan kedaluwarsa node

Peringatan peringatan lalu lintas

Lebih banyak fitur dalam perencanaan...

Sistem yang Disarankan
CentOS 7+

Ubuntu 16+

Debian 8+

Pertanyaan Umum
Migrasi dari v2-ui
Pertama instal versi terbaru x-ui di server yang telah menginstal v2-ui, kemudian gunakan perintah berikut untuk migrasi, yang akan memigrasi semua data akun inbound v2-ui ke x-ui, pengaturan panel dan username password tidak akan dimigrasi

Setelah migrasi berhasil, harap matikan v2-ui dan restart x-ui, jika tidak inbound v2-ui akan bertabrakan port dengan inbound x-ui

x-ui v2-ui
Penutupan Issue
Berbagai pertanyaan pemula yang membuat tekanan darah tinggi

Stargazers over time
Stargazers over time


# x-ui

Panel Xray yang mendukung multi-protokol dan multi-user

# Fitur

- Monitoring status sistem
- Dukungan multi-user multi-protokol, operasi visual berbasis web
- Protokol yang didukung: vmess、vless、trojan、shadowsocks、dokodemo-door、socks、http
- Dukungan konfigurasi transport tambahan
- Statistik traffic, limit traffic, limit waktu kedaluwarsa
- Template konfigurasi Xray yang bisa dikustom
- Dukungan akses panel via HTTPS (butuh domain + sertifikat SSL)
- Dukungan pembuatan sertifikat SSL satu klik + auto-renew
- Lebih banyak pengaturan lanjutan (lihat panel)

# Instalasi & Upgrade

```
bash <(curl -Ls https://raw.githubusercontent.com/hokagelegend9999/xray-ui/refs/heads/main/install.sh)
```

## Instalasi & Upgrade Manual

1. Pertama unduh arsip terbaru dari https://github.com/vaxilu/x-ui/releases, biasanya pilih arsitektur `amd64`
2. Unggah arsip ke direktori `/root/` di server dan login sebagai user `root`

> Jika arsitektur CPU server Anda bukan `amd64`, ganti `amd64` dengan arsitektur lain

```
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
```

## Instalasi Menggunakan Docker

> Tutorial docker dan image disediakan oleh [Chasing66](https://github.com/Chasing66)

1. Install docker

```shell
curl -fsSL https://get.docker.com | sh
```

2. Install x-ui

```shell
mkdir x-ui && cd x-ui
docker run -itd --network=host \
    -v $PWD/db/:/etc/x-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name x-ui --restart=unless-stopped \
    enwaiax/x-ui:latest
```

> Build image sendiri

```shell
docker build -t x-ui .
```

## Aplikasi Sertifikat SSL

> Fitur ini disediakan oleh [FranzKafkaYu](https://github.com/FranzKafkaYu)

Persyaratan:
- Email registrasi Cloudflare
- Cloudflare Global API Key
- Domain sudah diarahkan ke server via Cloudflare

Cara mendapatkan Global API Key:
![](media/bda84fbc2ede834deaba1c173a932223.png)
![](media/d13ffd6a73f938d1037d0708e31433bf.png)

Contoh penggunaan:
![](media/2022-04-04_141259.png)

Catatan:
- Menggunakan DNS API
- Default CA: Let'sEncrypt
- Lokasi sertifikat: /root/cert
- Menerbitkan sertifikat wildcard

## Penggunaan Bot Telegram (Dalam pengembangan)

> Fitur ini disediakan oleh [FranzKafkaYu](https://github.com/FranzKafkaYu)

Fitur:
- Notifikasi traffic harian
- Peringatan login panel
- dll

Pengaturan:
- Token bot
- Chat ID
- Jadwal notifikasi (format crontab)

Contoh:
- 30 * * * * * //Notifikasi di detik ke-30
- @hourly      //Setiap jam
- @daily       //Setiap hari
- @every 8h    //Setiap 8 jam

## Sistem yang Disarankan

- CentOS 7+
- Ubuntu 16+
- Debian 8+

# FAQ

## Migrasi dari v2-ui

```
x-ui v2-ui
```

> Setelah migrasi, stop v2-ui dan restart x-ui

## Penutupan Issue

Pertanyaan dasar tidak akan ditanggapi

## Stargazers over time

[![Stargazers over time](https://starchart.cc/vaxilu/x-ui.svg)](https://starchart.cc/vaxilu/x-ui)

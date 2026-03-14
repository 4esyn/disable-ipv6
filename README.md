# disable-ipv6

Простой bash-скрипт для Ubuntu 24.04, который включает или отключает IPv6.

Скрипт работает через `sysctl`, сохраняет настройки в отдельный файл `/etc/sysctl.d/99-ipv6-toggle.conf` и сразу применяет изменения. После запуска он предлагает выбор в меню или принимает команду через аргумент.

## Что делает

- отключает IPv6
- включает IPv6 обратно
- не меняет чужие системные конфиги
- пишет настройки только в свой файл

## Требования

- Ubuntu 24.04
- `bash`
- `sysctl`
- права `root` или `sudo`

## Запуск через curl

Интерактивный запуск:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/4esyn/disable-ipv6/main/ipv6-toggle.sh)
```

Запуск с аргументом:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/4esyn/disable-ipv6/main/ipv6-toggle.sh) disable
bash <(curl -fsSL https://raw.githubusercontent.com/4esyn/disable-ipv6/main/ipv6-toggle.sh) enable
```

## Запуск локально

Интерактивный режим:

```bash
bash ipv6-toggle.sh
```

Запуск с аргументом:

```bash
bash ipv6-toggle.sh disable
bash ipv6-toggle.sh enable
```

## Как это работает

При отключении скрипт записывает такие параметры:

```text
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
```

При включении эти же значения выставляются в `0`.

После этого настройки применяются сразу. Если сеть на сервере продолжает вести себя по-старому, лучше сделать перезагрузку.

## Важно

Скрипт меняет системные сетевые настройки, поэтому запускать его лучше через `sudo` или от имени `root`.

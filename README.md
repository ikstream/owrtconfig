# owrtconfig.sh and owrtflash-ng.sh

## owrtconfig

owrtconfig has to be re-written; however owrtflash-ng is new, as the name says.

## owrtflash-ng.sh

### Features

* flash via http, telnet or ssh over factory-, openwrt-, or custom-firmware
* network configuration with iproute2
* modular function design which is hopefully reuseable
* node config in shell syntax, there are just variables

### Dependencies

Please refer to `_check_requirements`.

### Example directory structures

#### Default settings

```
./defaults/
├── factory
│   ├── tl
│   ├── tl-wr841
│   ├── tl-wr841n-v8
│   └── tl-wr841n-v9
├── generic
├── models
│   ├── tl-wr841
│   ├── tl-wr841n-v8 -> tl-wr841
│   ├── tl-wr841n-v9 -> tl-wr841
│   ├── tl-wr842nd
│   └── tl-wr842nd-v1 -> tl-wr842nd
└── openwrt
```

##### factory settings
Factory default config files confain i.e. "router_ip" and "client_ip",
as well as "user" and "password". If a model has some kind of defauls
across different revisions or a alike, config files shoul be reused by
sourcing them from on to another.

```
# cat defaults/factory/tl-wr841n-v8
#!/bin/sh
# factory defaults: TL-WR841N-v8

. "${__basedir}"/defaults/factory/tl-wr841

# cat defaults/factory/tl-wr841
#!/bin/sh
# factory defaults: TL-WR841

. "${__basedir}"/defaults/factory/tl

# cat defaults/factory/tl
#!/bin/sh
# TP-Link generic factory defaults

router_ip="192.168.0.1"
client_ip="192.168.0.100"

protocol="http"
user="admin"
password="admin"
```

##### Firmware repository

```
./firmware-images/
├── factory
│   ├── README
│   ├── tl-wr841n-v8
│   │   ├── download_factory.sh
│   │   ├── TL-WR841ND_V8_140724
│   │   │   ├── How to upgrade TP-LINK Wireless N Router&AP(192.168.0.1 version).pdf
│   │   │   ├── wr841nv8_en_3_15_9_up_boot(140724).bin
│   │   │   └── wr841nv8_en_3_15_9_up_boot(140724).bin.stripped
│   │   └── TL-WR841ND_V8_140724.zip
│   ├── tl-wr841n-v8.bin -> ./tl-wr841n-v8/TL-WR841ND_V8_140724/wr841nv8_en_3_15_9_up_boot(140724).bin
│   ├── tl-wr841n-v8.bin.stripped -> ./tl-wr841n-v8/TL-WR841ND_V8_140724/wr841nv8_en_3_15_9_up_boot(140724).bin.stripped
│   ├── tl-wr842nd-v1
│   │   ├── download_factory.sh
│   │   ├── TL-WR842ND_V1_130322.zip
│   │   └── wr842ndv1_en_3_12_25_up_boot(130322)
│   │       ├── wr842ndv1_en_3_12_25_up_boot(130322).bin
│   │       └── wr842ndv1_en_3_12_25_up_boot(130322).bin.stripped
│   ├── tl-wr842nd-v1.bin -> ./tl-wr842nd-v1/wr842ndv1_en_3_12_25_up_boot(130322)/wr842ndv1_en_3_12_25_up_boot(130322).bin
│   └── tl-wr842nd-v1.bin.stripped -> ./tl-wr842nd-v1/wr842ndv1_en_3_12_25_up_boot(130322)/wr842ndv1_en_3_12_25_up_boot(130322).bin.stripped
└── openwrt
    ├── openwrt-ar71xx-generic-tl-wr841n-v8-squashfs-factory.bin
    ├── openwrt-ar71xx-generic-tl-wr841n-v8-squashfs-sysupgrade.bin
    ├── tl-wr841n-v8-factory.bin -> openwrt-ar71xx-generic-tl-wr841n-v8-squashfs-factory.bin
    └── tl-wr841n-v8-sysupgrade.bin -> openwrt-ar71xx-generic-tl-wr841n-v8-squashfs-sysupgrade.bin
```

##### Flash over factory helper scripts

```
./flash-over-factory
├── tl-wr841n-v8.sh
└── tl-wr842n-v1.sh
```

##### Various helper scripts

```
./helper_functions/
├── flash_over_openwrt_via_telnet.exp
├── nohup.sh
└── set_passwd_via_telnet.exp
```

#### Node configuration

```
./nodes
├── 001
├── 002
├── 003
├── 0041
└── 0142
```

```
$ cat nodes/0142
#!/bin/sh
# 0142

model="tl-wr841n-v8"
macaddr="a0:f3:c1:05:8a:c2"

#firmware="wr841nv8_en_3_15_9_up_boot(140724).bin"

#protocol="ssh"

#router_ip="192.168.1.1"
#client_ip="192.168.1.100"
#user="root"
#admin="admin"
```

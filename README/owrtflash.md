# owrtflash.sh

## Usage

### To flash over factory router freesh out of the box

```
./owrtflash.sh -H factory-nodes.csv --factory -s
2015-04-04 04:23:41 [info] owrtflash.sh - checking sudo...
2015-04-04 04:23:41 [log] owrtflash.sh - Stopping network connection manager: NetworkManager.
2015-04-04 04:23:41 [info] owrtflash.sh - looping over nodes (factory-nodes.csv)...
2015-04-04 04:23:41 [info] owrtflash.sh - next device: 'tl-wr841n-v8' (64:70:02:59:40:de)
2015-04-04 04:23:41 [info] 64:70:02:59:40:de - testing network connection...
2015-04-04 04:23:41 [log] 64:70:02:59:40:de - network status: OK
2015-04-04 04:23:41 [info] 64:70:02:59:40:de - flashing 'tl-wr841n-v8' with 'tmp/fw/wr841nv8_en_3_15_9_up_boot(140724).bin'
2015-04-04 04:23:43 [log] 64:70:02:59:40:de - flashed firmware on tl-wr841n-v8: (hopefully) OK
2015-04-04 04:23:43 [log] owrtflash.sh - Starting network connection manager: NetworkManager.
2015-04-04 04:23:43 [info] owrtflash.sh - wait 7 seconds...
2015-04-04 04:23:50 [info] owrtflash.sh - exit

./ping-all.sh factory-nodes.csv
2015-04-04 04:23:53 [info] ** checking sudo..
2015-04-04 04:23:53 [info] Stopping network connection manager: NetworkManager.
2015-04-04 04:23:55 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:23:56 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:23:57 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:23:58 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:23:59 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:24:22 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:24:23 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:24:24 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:24:26 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:28 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:30 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:33 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:35 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:37 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:39 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:41 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:43 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:45 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:47 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:49 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:51 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:53 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:55 [warning] 64:70:02:59:40:de is not reachable
2015-04-04 04:24:56 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:24:57 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:24:58 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:24:59 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:25:00 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:25:01 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:25:02 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:25:03 [info] 64:70:02:59:40:de is reachable
2015-04-04 04:25:04 [info] keypressed.
2015-04-04 04:25:04 [log] quit ping-all.sh
2015-04-04 04:25:04 [log] Starting network connection manager: NetworkManager.
```


## Errors

### If not properly connected to a host
```
./owrtflash.sh -H factory-nodes.csv --factory -s
2015-04-04 04:13:47 [info] owrtflash.sh - checking sudo...
2015-04-04 04:13:47 [log] owrtflash.sh - Stopping network connection manager: NetworkManager.
2015-04-04 04:13:48 [info] owrtflash.sh - looping over nodes (factory-nodes.csv)...
2015-04-04 04:13:48 [info] owrtflash.sh - next device: 'tl-wr841n-v8' (64:70:02:59:40:de)
2015-04-04 04:13:48 [info] 64:70:02:59:40:de - testing network connection...
2015-04-04 04:13:48 [error] 64:70:02:59:40:de is not responsing.
2015-04-04 04:13:48 [log] 64:70:02:59:40:de - network status: FAILED
2015-04-04 04:13:48 [log] owrtflash.sh - Starting network connection manager: NetworkManager.
2015-04-04 04:13:48 [info] owrtflash.sh - wait 7 seconds...
2015-04-04 04:13:55 [info] owrtflash.sh - exit
```

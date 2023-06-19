# VPN Configuration

## VPN client

SNX
vpn.ratpdev.com
prenom.nom
mdp office

## Italie 2 SSH tunnels

### For admin access to Talend Studio Italie2

ssh -f -N -L 3389:10.99.3.53:3389 -i credentials/.ssh/private/ratpdev_italie2_datalake_dev_italie_key.pem ubuntu@34.243.73.153

### For Massimo

italie2 dev remote engine
SSH login on 10.99.3.52
ssh -f -N -L 1433:192.168.146.213:1433 -i ratpdev_corp_datalake_key.pem ubuntu@10.200.0.122
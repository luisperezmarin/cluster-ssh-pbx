# Instrucciones de Instalación
## Ambas plantas:
```
yum install pacemaker pcs resource-agents fence-agents-all
```
## Editar /etc/hosts
### colocar los nombres e ip virtual ejemplo:
```
vi /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 pbxha1.corp.itm.gt
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.13.221 pbxha1
192.168.13.215 pbxha2f
192.168.13.216 pbxha
```

### colocar password a usuario hacluster
passwd hacluster

### Iniciar servicio pcsd

systemctl start pcsd

### Habilitar servicios al aranque:
systemctl enable corosync
systemctl enable pacemaker
systemctl enable pcsd

## colocar scripts pbx-ha:
### clonar repo git:

```
git clone https://git.itm.gt/ITM/scripts-cluster-ssh-pbx.git

cd cluster-ssh-pbx

mv -v pbx-ha.conf pbx-ha-screen.conf /etc/

mv -v pbx-ha /etc/logrotate.d/

mv -v itm-replicate sync.sh /usr/local/sbin/
```
### Usar systemd unit:
```
mv -v itmsync.service /etc/systemd/system/
systemctl daemon reload
```
### Configurar pbx-ha.conf
colocar los datos
IP1
IP2
VIP
PBX1
PBX2


### En la planta 1:

## Disable tabla cel base de datos
### crear archivo /etc/asterisk/cel_custom_post.conf
```
vi /etc/asterisk/cel_custom_post.conf
```
### Agregar:
```
[general]
enable=no
```
## Autorizar nodos del cluster:
```
pcs cluster auth pbxha1 pbxha2f -u hacluster -p S0p0rt3. --force
```
### Resultado:
```
pbxha2f: Authorized
pbxha1: Authorized
```
### Crear cluster:
```
pcs cluster setup --force --name itmpbxha pbxha1 pbxha2f
```
### Resultado:
```
Destroying cluster on nodes: pbxha1, pbxha2f...
pbxha1: Stopping Cluster (pacemaker)...
pbxha2f: Stopping Cluster (pacemaker)...
pbxha1: Successfully destroyed cluster
pbxha2f: Successfully destroyed cluster

Sending cluster config files to the nodes...
pbxha1: Succeeded
pbxha2f: Succeeded

Synchronizing pcsd certificates on nodes pbxha1, pbxha2f...
pbxha2f: Success
pbxha1: Success

Restarting pcsd on the nodes in order to reload the certificates...
pbxha2f: Success
pbxha1: Success
```
### Iniciar el cluster:
```
pcs cluster start --all
```
### Resultado:
```
pbxha2f: Starting Cluster...
pbxha1: Starting Cluster...
```
### Colocar propiedad de quorum a ignorar:
```
pcs property set no-quorum-policy=ignore
```
### Agregar fence device (stonith):
```
pcs stonith create PBXHARhv fence_rhevm pcmk_host_map="pbxha1:PBX1-HA;pbxha2f:PBX2-HA" ipaddr=192.168.13.9 ssl=1 login=admin@internal passwd=S0p0rt32017. ssl_insecure=true
pcs stonith create PBXHAIpmi fence_ipmilan pcmk_host_list="pbxha2ff" ipaddr="pbxha2ffipmi" login="pbxha" passwd="S0p0rt3." delay=2 lanplus=1 privlvl="operator" op monitor interval=11s
```

### Crear recurso de ip virtual:
```
pcs resource create VirtualIP ocf:heartbeat:IPaddr2 ip=192.168.13.216 cidr_netmask=32 nic=eth0 op monitor interval=5s
```
### Crear recurso de systemd:
```
pcs resource create ITMSync systemd:itmsync after=VirtualIP op monitor interval=5s
```
### Crear Grupo de recursos y asignar recursos:
```
pcs resource group add ITM VirtualIP
pcs resource group add ITM ITMSync
```
### Agregar preferencia de nodos
```
pcs constraint location ITM prefers pbxha1=200
pcs constraint location ITM prefers pbxha2ff=50
```
## en planta 1:
### usuario asterisk crear llave SSH
```
passwd asterisk
```
### cambiar al usuario asterisk
```
su - asterisk
ssh-keygen ( generar sin passphrase )
ssh-copy-id asterisk@localhost
ssh-copy-id asterisk@pbxha2f
scp -r .ssh asterisk@pbxha2f:
```
## probar ssh entre ambas plantas sin password

### Sincronizar y trasladar de la pbx1 --> pbx2
### en la planta 2:
```
fwconsole stop
```
### en la planta 1:
```
rsync -av /etc/php.ini root@pbxha2f:/etc/php.ini
rsync -av /etc/freepbx.conf root@pbxha2f:/etc/
rsync -av /etc/amportal.conf root@pbxha2f:/etc/
rsync -av --delete /etc/asterisk root@pbxha2f:/etc/
rsync -av --delete /var/www/html root@pbxha2f:/var/www/
rsync -av /etc/pbx-ha.conf root@pbxha2f:/etc/
rsync -av /etc/logrotate.d/pbx-ha root@pbxha2f:/etc/logrotate.d/
rsync -av /usr/local/sbin/itm-replicate root@pbxha2f:/usr/local/sbin/
rsync -av /usr/local/sbin/sync.sh root@pbxha2f:/usr/local/sbin/
rsync -av /etc/systemd/system/itmsync.service root@pbxha2f:/etc/systemd/system/
```

### Detener mariadb ambas plantas
```
systemctl stop mariadb
rsync -av --delete /var/lib/mysql root@pbxha2f:/var/lib/
```
### en ammbas plantas:
```
systemctl start mariadb
```
# Hacer pruebas de cluster

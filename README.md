# BADBOX 2.0 — Lista de IPs de C2

**Blocklist of BADBOX 2.0 / Vo1d / Kimwolf command-and-control (C2) IPs**, observed
on a real ISP network from infected Android TV boxes via DNS sinkhole and firewall
telemetry. Plain-text, CSV and ready-to-import MikroTik `.rsc`. Free to use.

Lista de IPs de servidores de control (C2) de la botnet **BADBOX 2.0** (también
conocida como **Vo1d** / **Kimwolf**), observadas en la red de un ISP real a partir
de TV boxes Android infectados. Pensada para que otros operadores puedan cargarlas
en su MikroTik (u otro equipo) y cortar el tráfico hacia esos C2.

> **No lleva ningún dato de clientes.** Solo las IPs externas de C2, el puerto
> observado, y el ASN/organización de cada IP. Sin IPs internas, sin nombres, sin
> nada privado.

---

## La amenaza, en dos párrafos

BADBOX 2.0 infecta TV boxes Android (y algún proyector/tablet) genéricos. A veces
viene de fábrica; otras veces el usuario habilita "orígenes desconocidos" e instala
una app que trae el malware. El equipo queda enrolado en una botnet y, sin que el
usuario note nada, **sale** a hablar con servidores de control: recibe tareas, se
usa como **proxy residencial** (alguien navega a través de la conexión del cliente),
participa de **DDoS**, o **mina Monero**.

Como el equipo *sale* hacia el C2 (no recibe conexiones entrantes), se lo detecta
por los destinos que contacta. Este feed es justamente eso: las IPs de C2 que vimos
contactar de verdad, con el puerto y a nombre de quién está la IP.

## Archivos

| Archivo | Para qué |
|---|---|
| [`blocklist.txt`](blocklist.txt) | IPs peladas, una por línea. Para scripts o `fetch`. |
| [`c2-ips.txt`](c2-ips.txt) | Igual, pero con puerto, rol y ASN de cada IP. Legible. |
| [`c2-badbox.rsc`](c2-badbox.rsc) | Script de MikroTik: crea el address-list `badbox-c2`. |
| [`c2-ips.csv`](c2-ips.csv) | Todo en columnas (ip, puertos, rol, asn, org, país, familia). |

## Cómo usar en MikroTik

Descargar el `.rsc` al router e importarlo. Crea/actualiza el address-list
`badbox-c2` (no dropea nada por sí solo):

```
/tool fetch url="https://raw.githubusercontent.com/cstrucco/badbox-c2-blocklist/main/c2-badbox.rsc" mode=https
/import c2-badbox.rsc
```

Después, **vos decidís** cómo usar la lista. El `.rsc` trae al final un ejemplo de
regla de `drop`, comentado. Recomendación fuerte: **arrancar con `action=log`** unos
días y recién después dropear (ver la advertencia de abajo).

## Cómo usar en otros equipos

- **iptables / nftables / pfSense / OPNsense**: importar `blocklist.txt` como
  lista de IPs y aplicarla en una regla de bloqueo saliente.
- **Unbound / Pi-hole / RPZ**: este feed es de IPs; para dominios se puede armar uno
  aparte (ver *Contribuir*).

## ⚠️ Advertencia importante

Varias de estas IPs están en **nube compartida** (Alibaba, OVH, Tencent, Google
Cloud, Hetzner). Eso significa que en la misma IP puede haber **otros servicios
legítimos**. Un `DROP` a ciegas puede cortarle a un cliente algo que no tiene nada
que ver con la botnet.

Por eso:

1. **Empezá con `log`, no con `drop`.** Mirá qué clientes tuyos caen en la lista y
   qué puerto usan. El C2 de BADBOX usa puertos raros y sostenidos (`:9998`, `:2918`,
   `:7890`, `:1883`, `:18081`…); el tráfico legítimo a esas nubes usa otros.
2. **Validá antes de cortar en producción.** Esta lista es un punto de partida, no
   una verdad absoluta.
3. Las IPs de C2 **rotan**. Una IP de acá puede quedar limpia con el tiempo, y
   aparecen nuevas. Actualizá seguido.

## Actualización

La lista se regenera desde la telemetría de la red de origen y se vuelve a publicar
acá. La fecha de cada corrida está en la cabecera de cada archivo. Podés seguir el
repo (*Watch*) para enterarte de los cambios.

## Contribuir

¿Viste una IP de C2 de BADBOX en tu red que no está acá, o una que ya deberíamos
sacar? Abrí un *Issue* con la IP, el puerto y por qué la marcás. Sumamos también
dominios de C2 si hay interés.

## Fuente

Observado y mantenido por un operador de red que prefiere no identificarse. Los
datos salen de la telemetría de una red de ISP real (sinkhole DNS + firewall), no de
listas de terceros. Se publica de forma anónima y sin fines de lucro.

## Licencia

Dominio público (**CC0 1.0**). Usá, copiá, modificá y redistribuí libremente, con o
sin atribución. Ver [`LICENSE`](LICENSE).

**Sin garantía.** Los datos se publican "tal cual". Verificá antes de bloquear en
producción; el autor no se responsabiliza por cortes de servicio derivados del uso
de esta lista.

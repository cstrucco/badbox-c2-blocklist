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

Para probarla rápido, descargá el `.rsc` al router e importalo:

```
/tool fetch url="https://raw.githubusercontent.com/cstrucco/badbox-c2-blocklist/main/c2-badbox.rsc" mode=https dst-path=c2-badbox.rsc
/import c2-badbox.rsc
```

Eso crea/actualiza el address-list `badbox-c2`, pero **todavía no bloquea nada** — un
address-list es solo una lista. Los dos pasos que faltan están abajo:
[**Sincronización automática**](#sincronización-automática-recomendado) para que se
actualice sola, y [**Bloquear el tráfico a los C2**](#bloquear-el-tráfico-a-los-c2-mikrotik-raw)
para cortar de verdad (empezando por observar con `log`).

## Sincronización automática (recomendado)

Importar la lista una vez sirve para probar, pero las IPs de C2 **rotan** y este feed
se actualiza seguido. Para no quedarte con una lista vieja, **tenés que armar en tu
MikroTik un script (tarea programada) que descargue la lista solo, 1 o 2 veces por
día.** Se configura una vez y se olvida.

### MikroTik — tarea programada (2 veces por día)

Son dos pasos. El **paso 1 carga la lista ahora mismo** (así queda activa al toque, sin
esperar a la primera corrida programada) y el **paso 2 la deja actualizándose sola**
cada 12 horas. Pegá cada bloque en la terminal del router (New Terminal en Winbox).

**Paso 1 — bajar la lista ya:**

```
/tool fetch url="https://raw.githubusercontent.com/cstrucco/badbox-c2-blocklist/main/c2-badbox.rsc" mode=https dst-path=c2-badbox.rsc
/import c2-badbox.rsc
```

**Paso 2 — programar la actualización automática.** La llave `{` abierta después de
`on-event=` hace que la terminal acepte el bloque multilínea de un solo pegado:

```
/system scheduler
add name=badbox-c2-sync interval=12h comment="Sincroniza blocklist C2 BADBOX" on-event={
    :do {
        /tool fetch url="https://raw.githubusercontent.com/cstrucco/badbox-c2-blocklist/main/c2-badbox.rsc" mode=https dst-path=c2-badbox.rsc;
        :delay 3s;
        /import file-name=c2-badbox.rsc;
    } on-error={
        :log warning "badbox-c2-sync: fallo la descarga, se mantiene la lista anterior";
    };
}
```

- El **paso 1** deja la lista cargada de inmediato; el paso 2 la mantiene al día sola.
- **`interval=12h`** = 2 veces por día. Para 1 vez por día poné `interval=1d`; si
  querés más seguido, `6h`. Con 1 o 2 veces al día alcanza de sobra.
- Si la descarga falla, el `on-error` **deja la lista anterior intacta** y lo avisa en
  el log: nunca te quedás sin lista por un corte de red.
- Para forzar una sincronización cuando quieras: `/system scheduler run badbox-c2-sync`

Verificar que quedó andando (corré una por una y mirá la salida):

- `/ip firewall address-list print where list=badbox-c2` → cuántas IPs cargó (deberían ser ~21)
- `/log print where message~"badbox"` → si hubo algún error
- `/system scheduler print` → cuándo corre la próxima vez

> **Si la descarga falla por certificado** (algunos routers no traen las CAs para
> validar el TLS de GitHub), agregá `check-certificate=no` al `fetch`. Eso baja la
> seguridad de la descarga; usalo solo si no podés cargar las CAs en el router.

## Bloquear el tráfico a los C2 (MikroTik RAW)

Cargar la lista **no bloquea nada por sí sola** — es solo un address-list. Para cortar
de verdad hace falta una regla de firewall que descarte el tráfico hacia esas IPs. Como
las TV box infectadas **salen** a buscar el C2, se bloquea el tráfico cuyo **destino**
está en la lista. La cadena **RAW** es la más eficiente: descarta antes del seguimiento
de conexiones, casi sin costo de CPU.

Tenés **dos opciones**. Si es una red en producción, **empezá por la A**; cuando estés
seguro, pasás a la B.

### Opción A — Observar (recomendada para empezar)

**Registra, NO bloquea.** Varias de estas IPs son de nube compartida (Alibaba, OVH,
Google…), donde puede haber servicios legítimos. Con esta regla mirás unos días quién de
tu red cae en la lista, sin cortarle nada a nadie:

```
/ip firewall raw
add chain=prerouting action=log log-prefix="BADBOX-C2" dst-address-list=badbox-c2 comment="BADBOX C2 - observar"
```

Después revisás qué clientes aparecen y contra qué IP y puerto, con:
`/log print where message~"BADBOX-C2"`

Si son tus clientes hablando con el C2 (puertos raros y sostenidos, tipo `:9998`,
`:2918`, `:7890`, `:1883`, `:18081`), ya podés pasar a bloquear.

### Opción B — Bloquear

**Corta el tráfico** hacia y desde esas IPs:

```
/ip firewall raw
add chain=prerouting action=drop dst-address-list=badbox-c2 comment="BADBOX C2 - salida bloqueada"
add chain=prerouting action=drop src-address-list=badbox-c2 comment="BADBOX C2 - entrada bloqueada"
```

La regla de la Opción A la podés dejar (registra) o sacar. Para ver cuánto está agarrando
el bloqueo, con: `/ip firewall raw print stats where comment~"BADBOX"`

> Si ya tenés reglas `accept` en la cadena RAW, asegurate de que estos `drop` queden
> **antes** (`/ip firewall raw move`), o no llegan a actuar.

## Cómo usar en otros equipos

- **iptables / nftables / pfSense / OPNsense**: importar `blocklist.txt` como
  lista de IPs y aplicarla en una regla de bloqueo saliente. Para sincronizar solo,
  un cron que refresca la copia local cada 6 h:

  ```
  # /etc/cron.d/badbox-c2
  0 */6 * * * root curl -fsS https://raw.githubusercontent.com/cstrucco/badbox-c2-blocklist/main/blocklist.txt -o /etc/badbox-c2.txt && <recargar tu firewall>
  ```
  (reemplazá `<recargar tu firewall>` por lo tuyo: `nft -f …`, `pfctl -f …`, etc.)
- **Unbound / Pi-hole / RPZ**: este feed es de IPs; para dominios se puede armar uno
  aparte (ver *Contribuir*).

## ⚠️ Advertencia importante

Varias de estas IPs están en **nube compartida** (Alibaba, OVH, Tencent, Google
Cloud, Hetzner). Eso significa que en la misma IP puede haber **otros servicios
legítimos**. Un `DROP` a ciegas puede cortarle a un cliente algo que no tiene nada
que ver con la botnet.

Por eso:

1. **No dropees a ciegas.** Usá primero la **Opción A (observar con `log`)** de la
   sección de bloqueo para confirmar que son tus clientes hablando con el C2 y no
   tráfico legítimo a esas nubes.
2. **Validá antes de cortar en producción.** Esta lista es un punto de partida, no
   una verdad absoluta.
3. Las IPs de C2 **rotan**. Una IP de acá puede quedar limpia con el tiempo, y
   aparecen nuevas — por eso conviene la sincronización automática.

## Actualización

La lista se regenera automáticamente desde la telemetría de la red de origen y se
vuelve a publicar acá cuando cambia. La fecha de la última actualización está en la
cabecera de cada archivo. Podés seguir el repo (*Watch*) para enterarte de los
cambios. **Para que tu equipo la tome solo, ver [Sincronización automática](#sincronización-automática-recomendado) más arriba.**

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

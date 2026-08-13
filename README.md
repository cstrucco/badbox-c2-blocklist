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

> ✅ Los comandos de esta sección están **probados en RouterOS 6 y 7**.

Para probarla rápido, descargá el `.rsc` al router e importalo:

```
/tool fetch url="https://raw.githubusercontent.com/cstrucco/badbox-c2-blocklist/main/c2-badbox.rsc" mode=https dst-path=c2-badbox.rsc
/import c2-badbox.rsc
```

Eso crea/actualiza el address-list `badbox-c2`, pero **todavía no hace nada** con él — un
address-list es solo una lista. Lo que falta está abajo:
[**Sincronización automática**](#sincronización-automática-recomendado) para que se
actualice sola, y [**Reportar o bloquear con la lista**](#reportar-o-bloquear-con-la-lista-mikrotik-raw)
para saber qué clientes tuyos están infectados, o cortar el tráfico.

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

## Reportar o bloquear con la lista (MikroTik RAW)

El address-list `badbox-c2` por sí solo no hace nada — es solo una lista. Con una regla
en la cadena **RAW** la podés usar de dos formas: **reportar** qué clientes tuyos hablan
con el C2 (sin cortarles nada), o **bloquear** ese tráfico. Como las TV box infectadas
**salen** a buscar el C2, en los dos casos se mira el tráfico cuyo **destino** está en la
lista. RAW es lo más eficiente: actúa antes del seguimiento de conexiones, casi sin costo
de CPU.

Si es una red en producción, **empezá por la A** (reportar): identificás a los infectados
sin arriesgar cortarle el servicio a nadie.

### Opción A — Reporte de clientes que contactan el C2 (no corta)

Ideal si **no querés bloquear todavía**, solo saber a quién llamar. Esta regla **no
dropea nada**: cada vez que un cliente tuyo habla con una IP de la lista, mete la IP **de
ese cliente** en un address-list aparte (`clientes-con-c2`). Esa lista es, literalmente,
tu **reporte de equipos infectados**:

```
/ip firewall raw
add chain=prerouting action=add-src-to-address-list address-list=clientes-con-c2 address-list-timeout=1d dst-address-list=badbox-c2 comment="BADBOX C2 - registrar cliente (no corta)"
```

- Es **passthrough**: el tráfico del cliente sigue igual, no le cortás nada.
- `address-list-timeout=1d`: el cliente queda listado 1 día desde su último contacto con
  el C2. Si sigue infectado se renueva solo; si deja de hablar con el C2, cae de la lista.

Ver el reporte (tus clientes que contactaron un C2):

```
/ip firewall address-list print where list=clientes-con-c2
```

Cada entrada es la IP de un cliente tuyo. Para saber **quién** es cada uno, cruzá esa IP
con tu propio DHCP / PPPoE / facturación. Así armás la lista de llamados **sin haberle
cortado el servicio a nadie**.

> ¿Querés ver también **a qué IP y puerto** habla cada uno? Sumá una regla de log:
> `add chain=prerouting action=log log-prefix="BADBOX-C2" dst-address-list=badbox-c2` y
> mirá `/log print where message~"BADBOX-C2"`. Los puertos de BADBOX son raros y
> sostenidos (`:9998`, `:2918`, `:7890`, `:1883`, `:18081`).

### Opción B — Bloquear

**Corta el tráfico** hacia y desde esas IPs:

```
/ip firewall raw
add chain=prerouting action=drop dst-address-list=badbox-c2 comment="BADBOX C2 - salida bloqueada"
add chain=prerouting action=drop src-address-list=badbox-c2 comment="BADBOX C2 - entrada bloqueada"
```

Podés **combinar las dos**: si dejás la regla de la Opción A **antes** de los `drop`,
seguís registrando al cliente infectado y además le cortás el C2. Para ver cuánto agarra
el bloqueo: `/ip firewall raw print stats where comment~"BADBOX"`

> Si ya tenés reglas `accept` en la cadena RAW, asegurate de que estas reglas queden
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

1. **No dropees a ciegas.** Usá primero la **Opción A (reportar sin cortar)** de la
   sección de arriba para confirmar que son tus clientes hablando con el C2 y no
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
sacar? Abrí un *Issue*: hay una **plantilla** que te pide la IP, el puerto y la
evidencia, así el reporte queda completo y se puede verificar rápido. Para reportar
**dominios** de C2, abrí un Issue en blanco (los sumamos si hay interés).

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

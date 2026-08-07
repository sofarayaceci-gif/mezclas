# Mezcla Micro Pro

Calculadora de litros para agregar al tanque de solución. Es la conversión a app web
del archivo `Mezcla Micro Pro-Adelante desarollos.xlsx`, con los mismos cálculos y el
mismo orden de la hoja original, más un historial de mezclas.

Adelante Desarrollos.

---

## Cómo usarla

**Sin instalar nada:** abrir `index.html` con doble clic. Funciona en Chrome, Edge o
Firefox, y también en el celular.

**Publicada en internet (GitHub Pages):** en el repositorio, entrar a
*Settings → Pages*, en "Source" escoger la rama `main` y la carpeta `/ (root)`, y
guardar. A los pocos minutos queda disponible en:

```
https://<usuario>.github.io/<repositorio>/
```

Esa dirección se puede abrir desde el celular en planta y agregar a la pantalla de
inicio como si fuera una app.

---

## Qué se digita y qué se calcula

La regla es la misma del Excel: **toda celda que no tenía fórmula es un campo manual**,
y toda celda que sí tenía fórmula la calcula la app.

### Campos manuales

| Campo | Celda en el Excel |
|---|---|
| Número de mezcla | `B1` |
| Concentración de ORD-X170 deseada (%) | `B6` |
| Concentración de ORD-X170 actual, de laboratorio (%) | `B7` |
| Litros de solución en tanque actual | `B8` |
| Litros de solución deseado en el tanque | `B9` |
| Densidad activa (kg/L) | `L3` |
| Factor de depleción de los Cleanwoods | `B14` |

La **fecha** en el Excel era `=NOW()`, así que la app la llena sola con el día de hoy.
Se puede cambiar a mano si se necesita.

### Resultados

| Resultado | Celda | Fórmula |
|---|---|---|
| Litros de ORD-X170 para agregar | `B10` | `((L_deseado × C_deseada/100 − L_actual × C_actual/100) / 0.608) × 1.03` |
| Kg de ORD-X170 para agregar | `G10` | `litros de ORD-X170 × densidad activa` |
| Litros de Cleanwood AC para agregar | `B15` | `((45 × (L_deseado − L_actual) / 0.1757) / 1 000 000) × (1 + depleción)` |
| Litros de Cleanwood 45 Plus para agregar | `B16` | `((100 × (L_deseado − L_actual) / 0.4718) / 1 000 000) × (1 + depleción)` |

Los números `0.608`, `1.03`, `45`, `0.1757`, `100`, `0.4718` y `1 000 000` estaban
escritos dentro de las fórmulas del Excel, no en celdas, así que quedaron fijos en la
app. Están todos juntos en la constante `K`, al inicio del `<script>` de `index.html`,
por si algún día hay que ajustarlos.

### Comprobación

Con los datos con que venía el Excel (0.58 % deseada, 0.58 % actual, 1 056 L actuales,
2 796 L deseados, densidad 0.6088, depleción 0.10) la app da:

- **17,10 L** de ORD-X170 · **10,41 kg**
- **0,49 L** de Cleanwood AC
- **0,41 L** de Cleanwood 45 Plus

Idéntico al Excel.

---

## Historial y sincronización

Las mezclas se ven en todos los dispositivos: lo que se registra en el celular en
planta aparece al abrir la app en la compu, y al revés.

Va contra **el mismo proyecto de Supabase que usa la app de reportes**, con una tabla
nueva llamada `mezclas`. No hay proyecto nuevo, ni cuenta nueva, ni clave nueva que
administrar: la app trae adentro la misma clave pública que `js/nube.js` de reportes.

### Lo único que hay que hacer una vez

Abrir el panel de Supabase → **SQL Editor** → **New query** → pegar todo el contenido
de `esquema.sql` → **Run**.

Mientras eso no se corra, la app funciona igual pero muestra *"Falta la tabla en
Supabase"* en el historial.

### Cómo se comporta

- **Lo local manda para trabajar.** La app funciona completa sin internet, con lo que
  haya guardado en el aparato. La sincronización solo empareja esa copia con la nube
  cuando hay señal.
- **Se sincroniza sola**, sin botón: al abrir la app, cada vez que se guarda o se
  borra una mezcla, y cuando vuelve la conexión.
- El estado se ve en el **punto de color a la par del nombre de la app**, arriba a la
  izquierda. Verde es al día, verde parpadeando es sincronizando, rojo es que algo
  falló y gris es que todavía no ha sincronizado. Pasando el mouse por encima sale el
  detalle.
- Al juntar las dos listas gana, mezcla por mezcla, la versión tocada más
  recientemente.
- **Borrar borra en todos lados.** La fila no se elimina: se marca como borrada con
  fecha nueva. Es la única forma de que un borrado se propague — si se eliminara, el
  otro aparato la volvería a subir la próxima vez y la mezcla reaparecería.

### Respaldo

**Exportar a Excel** genera un `.xlsx` de verdad, armado con la misma forma del Excel
original: los rótulos fijos en la columna A y **una columna por mezcla** a partir de
la B, creciendo hacia la derecha. Lleva los mismos colores de la hoja original
—amarillo en las concentraciones y litros deseados, naranja claro en los litros
actuales, gris en número y fecha, celeste en los resultados— y los mismos formatos de
número. La columna A queda inmovilizada para poder desplazarse a la derecha sin perder
de vista los rótulos.

Se genera sin librerías. Un `.xlsx` por dentro es un zip con unos XML, y el código los
arma a mano: el zip está en la función `zip()`, los estilos en la constante `ESTILOS`,
y la estructura de la hoja en `FILAS_XLSX`. Para agregar o mover una fila de la hoja
basta con tocar ese arreglo.

Ese archivo es el respaldo de verdad. Conviene bajarlo cada cierto tiempo.

### ⚠️ Sobre la seguridad

La app va **sin login**, igual que reportes y por la misma decisión que ya se tomó
allá. La clave pública de Supabase viaja dentro de `index.html`, y el repositorio es
público: cualquiera que la encuentre puede leer, cambiar y borrar las mezclas.

Se acepta ese riesgo porque son datos de proceso —no datos personales ni contraseñas—,
porque cada aparato conserva su copia completa, y porque el `.csv` exportado es el
respaldo real. Si algún día se quiere cerrar, al final de `esquema.sql` está anotado
cómo.

La clave que empieza con `sb_secret_` **no va** en este repositorio ni en ningún
archivo de la app.

---

## Dos cosas pendientes de confirmar con el encargado del proceso

Ninguna cambia el resultado hoy — la app replica el Excel tal como está. Pero conviene
revisarlas:

1. **`0.608` contra `0.6088`.** La fórmula de los litros de ORD-X170 divide entre
   `0.608`, un número escrito dentro de la fórmula. La celda "Densidad activa" del
   Excel decía `0.6088`. Son dos valores distintos para lo que parece ser el mismo
   dato. La diferencia es de un 0,13 %, imperceptible al redondear a dos decimales,
   pero si el correcto es `0.6088` habría que unificarlos.

2. **Qué representan los "Kg para agregar".** Se calculan multiplicando los litros de
   ORD-X170 por la densidad activa. Si ese dato se usa para **pesar el producto en
   balanza**, debería usarse la densidad del producto (cuánto pesa un litro de
   ORD-X170), no la riqueza del ingrediente activo. Si es para reportar kilos de
   ingrediente activo, está correcto como está.

---

## Estructura

```
index.html             La app completa: HTML, CSS y JavaScript en un solo
                       archivo. Sin librerías y sin build. Funciona sin
                       internet; la nube solo la usa para sincronizar.
esquema.sql            La tabla `mezclas`. Se corre una vez en el panel de
                       Supabase, en el mismo proyecto que la app de reportes.
README.md              Este archivo.
```

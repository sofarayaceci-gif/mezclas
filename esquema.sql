/* ══════════════════════════════════════════════════════════════════════════
   Mezcla Micro Pro — la tabla en Supabase

   Va en el MISMO proyecto de Supabase que la app de reportes. No hace falta
   crear un proyecto nuevo ni una clave nueva: esta app usa la misma clave
   pública, y lo único que agrega es la tabla `mezclas`.

   Se corre desde el panel de Supabase:
     SQL Editor → New query → borrar lo que haya → pegar todo esto → Run

   Se puede correr las veces que haga falta: está escrito para no romper nada
   si la tabla ya existe. No borra datos.

   ⚠️ LEER ESTO, QUE NO ES UN DETALLE

   Esta base va SIN login, igual que reportes y por la misma decisión. La tabla
   de acá queda abierta a quien tenga la clave pública de la app, y esa clave
   está dentro de `index.html`, en un repositorio público. Cualquiera que la
   encuentre puede leer, cambiar y borrar las mezclas.

   Se acepta ese riesgo porque:
     · son datos de proceso, no datos personales ni contraseñas;
     · cada aparato conserva su copia completa, así que vaciar la nube no borra
       el trabajo de nadie;
     · el .csv que exporta la app es el respaldo de verdad.

   Si algún día se quiere cerrar: se agrega una columna `user_id uuid default
   auth.uid()`, se cambian las reglas de `to anon` a `to authenticated` con
   `user_id = auth.uid()`, y se le pone formulario de entrar a la app.
   ══════════════════════════════════════════════════════════════════════════ */

/* ── Las mezclas ───────────────────────────────────────────────────────────
   Una fila por mezcla calculada. Guarda tanto lo que se digitó como lo que
   dio el cálculo: la mezcla es un registro de lo que efectivamente se agregó
   al tanque ese día, así que los resultados se conservan aunque algún día
   cambie alguna fórmula.

   La llave es un uid que genera el aparato al guardar, no un número que ponga
   la base. Así la misma mezcla tiene la misma identidad en la compu, en el
   celular y en la nube, y sincronizar se vuelve repetible: subir dos veces la
   misma mezcla la actualiza en vez de duplicarla.

   Es `text` y no `uuid` a propósito, para que las mezclas guardadas antes de
   que existiera la sincronización —que traen un id con otro formato— también
   suban sin problema.                                                        */
create table if not exists public.mezclas (
  uid             text primary key,

  numero          text not null,
  fecha           date not null,

  /* Lo que se digita */
  conc_deseada    numeric not null,
  conc_actual     numeric not null,
  litros_actuales numeric not null,
  litros_deseados numeric not null,
  densidad        numeric not null,
  deplecion       numeric not null,

  /* Lo que calcula la app */
  litros_ord      numeric not null,
  kg_ord          numeric not null,
  cleanwood_ac    numeric not null,
  cleanwood_45    numeric not null,

  /* La fila NO se borra al borrar la mezcla: se marca acá y se le pone fecha
     nueva en `tocado`. Es la única forma de que borrar se propague. Si se
     borrara la fila, cualquier aparato que todavía la tuviera guardada la
     volvería a subir al abrir la app y la mezcla reaparecería en todos lados.

     Con la marca puesta hay algo que comparar, y gana la fecha más nueva: la
     última vez que alguien la tocó. Guardar y borrar pesan igual. */
  borrado         boolean not null default false,

  guardado        timestamptz not null,
  tocado          timestamptz not null,

  creado          timestamptz not null default now()
);

/* El historial se ordena por lo último que se tocó. */
create index if not exists mezclas_por_tocado on public.mezclas (tocado desc);

/* ── Acceso ───────────────────────────────────────────────────────────────
   Hacen falta LAS DOS COSAS, y son distintas:

     · el GRANT dice si el rol puede tocar la tabla;
     · la POLICY dice qué filas puede ver de esa tabla.

   Sin el GRANT, la policy no sirve de nada: PostgREST contesta «permission
   denied for table». Supabase pone el GRANT solo cuando las tablas se crean
   desde su interfaz; creándola con «create table» acá, hay que ponerlo a mano.

   El rol `anon` es el que usa la app, porque va sin login.

   Las reglas son deliberadamente permisivas: es lo que significa «sin login». */
grant select, insert, update, delete on public.mezclas to anon, authenticated;

/* RLS queda encendido igual: sin encenderlo, PostgREST no expone la tabla. */
alter table public.mezclas enable row level security;

/* El «drop policy if exists» es lo que permite correr este archivo de nuevo
   sin que reviente por nombre repetido. */
drop policy if exists "abierto" on public.mezclas;
create policy "abierto" on public.mezclas for all to anon, authenticated
  using (true) with check (true);

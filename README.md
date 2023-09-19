# Introducción:

- Mix Ultimate, es un proyecto similar al Mix Maker de Federico '#8 SickneSS' Fernández. El cual su finalidad es la organización de los juegos competitivos.

# Créditos:

- Federico '#8 SickneSS' Fernández

# Requisitos:

* Activar el módulo SQLite (modules.ini)
* Poner la base de datos (data/sqlite3/sql_mix_ultimate.sq3)
* Poner el archivo de configuración (configs/mix_ultimate.cfg)

# Descripción:

- Si bien su finalidad es la misma, se basa prácticamente en almacenar los datos de las partidas jugadas, las mismas son guardadas al finalizar la partida.

# Estadísticas del mix almacenadas:

- Número de mix's jugados.
- Rondas
- Resultado de la primera y segunda mitad
- Tiempo en el que comenzó y finalizó
- Duración
- Estadísticas de los usuarios (Frags, muertes) de la primera y segunda mitad

• Estadísticas del los usuarios:

*Las estadísticas de los usuarios tanto TK's como desconexiones, son almacenadas en el momento en el que se comete dicha acción, en ellas se guardan:

- Nick
- Número de TK's y desconexiones
- Fecha
- Mapa
- IP
- Equipo
- Número de MIX
- Rondas del mix

# Comandos de chat:

- say /.!mix > Abre el menú de mix
- say /.!rr > (Restart round) Reinicia la ronda sin afectar los resultados, la puntuación, ni el dinero del usuario (Solo en modo mix)
- say /.!rh > (Reset half) Resetea la mitad que se está jugando
- say /.!result > Muesta los resultados del mix actual o del mix anterior
- say /.!chat > Habilita el chat (Administradores) / Pide que habiliten el chat
- say /.!team > Habilita el cambio de equipos (Administradores) / Pide que habiliten el cambio de equipos
- say /.!nick > Habilita el cambio de nick (Administradores) / Pide que habiliten el cambio de nick
- say /.!stats > Muestra en un menú las estadísticas de los mix jugados
- say /.!select > Muestra en un menú a los usuarios para ser seleccionados por los que cortaron (Modo duelo habilitado)

# CVARS
mix_password "1337" > Establece la contraseña del servidor. Por defecto "1337"
mix_prefix "!g[Mix Ultimate]" > Establece el prefijo del mensaje. Por defecto [Mix Ultimate]
mix_finish_half "15" > Establece las rondas para que finalicen las mitades. Por defecto 15 rondas
mix_show_killer "1" > Muestra, en un hud lateral izquierdo, quién mató a quién. Por defecto 1
mix_show_money "1" > Muestra, en un hud lateral izquierdo, el dinero de los usuarios del equipo. Por defecto 1
mix_closed_block_say "1" > Establece si se bloqueará el chat en modo cerrado. Por defecto 1
mix_closed_block_name "1" > Establece si se bloqueará el cambio de nick en modo cerrado. Por defecto 1
mix_result "1" > Muestra los resultados del mix en cada ronda. Por defecto 1
mix_result_type "3" > Establece el tipo de mensaje del resultado en cada ronda. Por defecto 3

# Archivo de configuración (CFG):

```
; Mix Ultimate v1.0 desarrollado por ; Cristian'

; ============================================================

; Establece la contraseña del servidor. Por defecto 1337
mix_password "1337"

; ============================================================

; Establece el prefijo del mensaje. Por defecto [Mix Ultimate]
mix_prefix "!g[Mix Ultimate]"

; ============================================================

; Muestra, en un hud lateral izquierdo, quién mató a quién. Por defecto 1
mix_show_killer "1"

; ============================================================

; Muestra, en un hud lateral izquierdo, el dinero de los usuarios del equipo. Por defecto 1
mix_show_money "1"

; ============================================================

; Establece las rondas para que finalice las mitades. Por defecto 15 rondas
mix_finish_half "15"

; ============================================================

; Establece si se bloqueará el chat en modo cerrado. Por defecto 1
mix_closed_block_say "1"

; ============================================================

; Establece si se bloqueará el cambio de nick en modo cerrado. Por defecto 1
mix_closed_block_name "1"

; ============================================================

; Establece si se bloqueará el cambio de equipos en modo cerrado. Por defecto 1
mix_closed_block_name "1"

; ============================================================

; Muestra los resultados del mix en cada ronda. Por defecto 1
mix_result "1"

; ============================================================

; Establece el tipo de mensaje del resultado en cada ronda. Por defecto 3
mix_result_type "3"

; mix_result_type "1" > Muestra los resultados del mix en un hud
; mix_result_type "2" > Muestra los resultados del mix en el chat
; mix_result_type "3" > Muestra los resultados del mix en el hud y en el chat

; ============================================================
```


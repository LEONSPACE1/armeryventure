# armeryventure

Juego móvil *idle* inspirado en Eatventure: una armería que viaja por la historia, desde la Prehistoria hasta una era futurista. Hecho con **Godot 4.3** (GDScript).

Documento de diseño (GDD): https://claude.ai/artifact/MDbxywJLjPHAEiU13BeDgJ

## Estado

Prototipo de la **Prehistoria** (época 1 de 8):

- 5 estaciones (Lanza de madera, Hacha de mano, Honda, Lanzadardos, Arco y flechas) con niveles, hitos x2 y armeros extra.
- Clientes con pedidos, dependientes que llevan las armas al mostrador.
- 13 mejoras, 15 misiones con estrellas y portal a la siguiente época.
- Interfaz como en Eatventure: arriba solo monedas y época; abajo una barra con Épocas, la misión actual, Misiones y Mejoras (con globos rojos cuando hay algo por hacer). Al tocar una estación se despliega su panel desde abajo; se cierra con la X o tocando el suelo.
- Los armeros fabrican por etapas: ensamblan las piezas, forjan a martillazos sobre las brasas y levantan el arma terminada.
- Los personajes guardan distancia entre sí y cruzan la segunda fila de bancos por los pasillos.
- Guardado automático cada 10 s y ganancias fuera de línea (50 % del ritmo, máximo 2 h).
- Estilo 3D low-poly isométrico hecho por código (sin modelos externos): cueva con antorchas que titilan, sombras, personajes articulados (caminar, respirar, parpadear, saltar de alegría), armeros que martillan con chispas y armas 3D sobre los bancos. Las piezas fijas se juntan en una sola malla (`Art3D.bake`) para que el celular dibuje poco. Los letreros, barras y burbujas son 2D encima de la escena.

## Cómo abrirlo en tu computador

1. Descarga Godot 4.3 desde https://godotengine.org/download (versión estándar, no la de .NET).
2. Abre Godot, pulsa **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Pulsa el botón ▶ (arriba a la derecha) o F5 para jugar.

## Dónde se ajusta el juego

Cada época es un archivo en `data/epocas/` (por ahora `prehistoria.json` y `bronce.json`) con su economía, estaciones, mejoras, misiones y tema visual (escenario, colores, ropa y cascos de los personajes). El orden de las épocas está en `data/epocas/indice.json`. Se puede ajustar o agregar una época sin tocar el código, salvo los modelos 3D de armas nuevas (`scripts/art3d.gd`) y su escenario (`scripts/scenery.gd`).

Al completar todas las misiones, el panel **Épocas** permite viajar a la siguiente: se reinician monedas, niveles, mejoras y misiones.

| Archivo | Qué hace |
| --- | --- |
| `scripts/game_state.gd` | Monedas, niveles, fórmulas, misiones y guardado |
| `scripts/main.gd` | Escena de la armería, clientes, dependientes e interfaz |
| `scripts/art3d.gd` | Piezas 3D (cajas, cilindros, armas, chispas) y unión de mallas |
| `scripts/scenery.gd` | Escenario de cada época (cueva, taller de bronce…) |
| `scripts/weapon_icons.gd` | Íconos de armas sacados de sus modelos 3D |
| `scripts/person3d.gd` | Personaje 3D articulado y sus animaciones |
| `scripts/art.gd` | Dibujo 2D de íconos, letreros e interfaz |
| `scripts/station.gd` | Estación de fabricación y sus armeros |
| `scripts/customer.gd`, `scripts/worker.gd` | Cliente y dependiente |
| `tests/sim.tscn` | Simulación con jugador automático para revisar el ritmo |

Fórmulas (ver GDD): costo de nivel `C(n) = C0 · 1,15^(n-1)`; valor por arma `V(n) = V0 · n · 2^k`, con `k` = hitos alcanzados (niveles 10, 25, 50, 75, 100).

## Probar el ritmo de la economía

```
godot --headless --fixed-fps 30 res://tests/sim.tscn
```

Imprime cada 5 minutos de juego las monedas, el ritmo y los niveles, y al final el segundo en que se completó cada misión.

## Exportar la versión web

```
godot --headless --export-release "Web" build/web/index.html
```

La exportación usa la plantilla sin hilos (`thread_support=false`) para que funcione en GitHub Pages y en Safari de iPhone.

Para revisar el arte sin celular: `xvfb-run godot --rendering-driver opengl3 res://tests/captura.tscn` guarda capturas en `/tmp/claude-0/sim/`.

Otras pruebas: `res://tests/sim.tscn -- --epoca=1` simula la Edad del Bronce, `res://tests/viaje.tscn` comprueba el viaje entre épocas y `res://tests/primer_plano.tscn` captura de cerca la fabricación.

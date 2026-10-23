# armeryventure

Juego móvil *idle* inspirado en Eatventure: una armería que viaja por la historia, desde la Prehistoria hasta una era futurista. Hecho con **Godot 4.3** (GDScript).

Documento de diseño (GDD): https://claude.ai/artifact/MDbxywJLjPHAEiU13BeDgJ

## Estado

Prototipo de la **Prehistoria** (época 1 de 8):

- 5 estaciones (Lanza de madera, Hacha de mano, Honda, Lanzadardos, Arco y flechas) con niveles, hitos x2 y armeros extra.
- Clientes con pedidos, dependientes que llevan las armas al mostrador.
- 13 mejoras, 15 misiones con estrellas y portal a la siguiente época.
- Guardado automático cada 10 s y ganancias fuera de línea (50 % del ritmo, máximo 2 h).
- Arte procedural (sin imágenes): cueva con antorchas, personajes animados (caminar, respirar, parpadear), armeros que martillan con chispas, monedas que vuelan al contador e interfaz con relieve. Todo el dibujo está en `scripts/art.gd`.

## Cómo abrirlo en tu computador

1. Descarga Godot 4.3 desde https://godotengine.org/download (versión estándar, no la de .NET).
2. Abre Godot, pulsa **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Pulsa el botón ▶ (arriba a la derecha) o F5 para jugar.

## Dónde se ajusta el juego

Toda la economía está en `data/prehistoria.json`: costos, valores, tiempos, mejoras y misiones. Se puede cambiar sin tocar el código.

| Archivo | Qué hace |
| --- | --- |
| `scripts/game_state.gd` | Monedas, niveles, fórmulas, misiones y guardado |
| `scripts/main.gd` | Escena de la armería, clientes, dependientes e interfaz |
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

"""Genera los archivos de las épocas 3 a 8 en data/epocas/.

Todas comparten la curva de la Edad del Bronce escalada x10 por época
(los costos y los valores crecen igual, así que el ritmo de juego es el mismo).
Uso: python3 tools/generar_epocas.py
"""
import copy
import json
import os

RAIZ = os.path.join(os.path.dirname(__file__), "..", "data", "epocas")
BRONCE = json.load(open(os.path.join(RAIZ, "bronce.json"), encoding="utf-8"))

# Por estación: (id, nombre, artículo, color, mejora x2)
EPOCAS = [
    {
        "id": "antiguedad", "nombre": "Antigüedad clásica", "siguiente": "Edad Media",
        "estaciones": [
            ("dory", "Lanza de hoplita", "la", "#a8743f", "Asta de fresno"),
            ("aspis", "Escudo redondo", "el", "#b5651d", "Bronce batido"),
            ("gladius", "Gladius", "el", "#9aa3ad", "Hierro templado"),
            ("pilum", "Pilum", "el", "#8a7b5c", "Punta que se dobla"),
            ("balista", "Balista", "la", "#6e5a3c", "Cuerdas de tendón"),
        ],
        "mejoras": ["Ágora llena: clientes 25% más rápido", "Calzadas romanas: dependientes 30% más rápido",
                    "Pórtico más amplio: +2 clientes en la fila", "Contrato con la legión: clientes 25% más rápido",
                    "Sandalias de legionario: dependientes 30% más rápido", "Favor del Senado: x2 todas las ganancias"],
        "tema": {
            "escenario": "templo", "fondo": "#1f1a16", "suelo": "#b5ad9e", "camino": "#b39c7a",
            "alfombra": "#8f2d24", "mostrador_base": "#d8d0c0", "mostrador_tapa": "#8a5a36",
            "ropa_clientes": ["#b8342a", "#e3dccb", "#3f5f8a", "#c9a24a"], "estilos_clientes": [6, 7, 1],
            "ropa_armeros": "#7a5636", "estilo_armeros": 2, "ropa_dependientes": "#5a7a9c",
            "luz_sol": 0.32, "luz_ambiente": 0.26,
        },
    },
    {
        "id": "medieval", "nombre": "Edad Media", "siguiente": "Era de la pólvora",
        "estaciones": [
            ("arco_largo", "Arco largo", "el", "#7a5230", "Tejo inglés"),
            ("cota", "Cota de malla", "la", "#8c9096", "Anillas remachadas"),
            ("ballesta", "Ballesta", "la", "#6b4a2e", "Cranequín de acero"),
            ("espada_larga", "Espada larga", "la", "#a7b0ba", "Acero de Toledo"),
            ("armadura", "Armadura de placas", "la", "#c0c6cc", "Placas pulidas"),
        ],
        "mejoras": ["Feria del pueblo: clientes 25% más rápido", "Caballos de carga: dependientes 30% más rápido",
                    "Mostrador de roble: +2 clientes en la fila", "Torneo real: clientes 25% más rápido",
                    "Botas de cuero: dependientes 30% más rápido", "Sello del rey: x2 todas las ganancias"],
        "tema": {
            "escenario": "castillo", "fondo": "#141517", "suelo": "#6e5338", "camino": "#7d7a74",
            "alfombra": "#2f4f8a", "mostrador_base": "#7d7a74", "mostrador_tapa": "#6b4a2e",
            "ropa_clientes": ["#8a2f2a", "#3f5f3a", "#4a4f8a", "#b59a5a"], "estilos_clientes": [8, 9, 0],
            "ropa_armeros": "#5c4030", "estilo_armeros": 0, "ropa_dependientes": "#6a3f6e",
            "luz_sol": 0.36, "luz_ambiente": 0.27,
        },
    },
    {
        "id": "polvora", "nombre": "Era de la pólvora", "siguiente": "Era industrial",
        "estaciones": [
            ("lanza_fuego", "Lanza de fuego", "la", "#b5562a", "Tubo de bambú"),
            ("canon_mano", "Cañón de mano", "el", "#8a6a3a", "Bronce fundido"),
            ("arcabuz", "Arcabuz", "el", "#7a4f2a", "Llave de mecha"),
            ("mosquete", "Mosquete", "el", "#6b4a30", "Llave de chispa"),
            ("canon", "Cañón", "el", "#3f3f45", "Ánima pulida"),
        ],
        "mejoras": ["Barcos en el puerto: clientes 25% más rápido", "Carretillas de muelle: dependientes 30% más rápido",
                    "Muelle más largo: +2 clientes en la fila", "Patente de corso: clientes 25% más rápido",
                    "Botas de marinero: dependientes 30% más rápido", "Proveedor de la Armada: x2 todas las ganancias"],
        "tema": {
            "escenario": "puerto", "fondo": "#10161c", "suelo": "#7a5a3a", "camino": "#6b5038",
            "alfombra": "#2a4a6e", "mostrador_base": "#5c4030", "mostrador_tapa": "#8a6a44",
            "ropa_clientes": ["#2a3f6e", "#8a2a2a", "#e0d8c0", "#3a3a3a"], "estilos_clientes": [10, 11, 5],
            "ropa_armeros": "#4a3a2e", "estilo_armeros": 5, "ropa_dependientes": "#8a5a2a",
            "luz_sol": 0.34, "luz_ambiente": 0.26,
        },
    },
    {
        "id": "industrial", "nombre": "Era industrial", "siguiente": "Era moderna",
        "estaciones": [
            ("rifle_avancarga", "Rifle de avancarga", "el", "#7a5030", "Cañón estriado"),
            ("revolver", "Revólver", "el", "#5a5f66", "Tambor de seis"),
            ("bayoneta", "Bayoneta", "la", "#a0a6ad", "Acero Bessemer"),
            ("rifle_cerrojo", "Rifle de cerrojo", "el", "#6a4a2e", "Cerrojo pulido"),
            ("ametralladora", "Ametralladora", "la", "#3f444a", "Camisa de agua"),
        ],
        "mejoras": ["Estación del tren: clientes 25% más rápido", "Vagonetas sobre rieles: dependientes 30% más rápido",
                    "Mostrador de hierro: +2 clientes en la fila", "Anuncio en el periódico: clientes 25% más rápido",
                    "Cinta transportadora: dependientes 30% más rápido", "Exposición universal: x2 todas las ganancias"],
        "tema": {
            "escenario": "fabrica", "fondo": "#121212", "suelo": "#4f4a45", "camino": "#5f5a55",
            "alfombra": "#6e2a2a", "mostrador_base": "#4a4f55", "mostrador_tapa": "#6b4a2e",
            "ropa_clientes": ["#c9b98a", "#3a3a3a", "#8a2a2a", "#2f3f6e"], "estilos_clientes": [12, 13, 14],
            "ropa_armeros": "#3f4a5c", "banco": "#5a5f66", "estilo_armeros": 0, "ropa_dependientes": "#6e4a2a",
            "luz_sol": 0.34, "luz_ambiente": 0.26,
        },
    },
    {
        "id": "moderna", "nombre": "Era moderna", "siguiente": "Era futurista",
        "estaciones": [
            ("casco", "Casco", "el", "#5a6b4a", "Kevlar"),
            ("chaleco", "Chaleco antibalas", "el", "#3f4a3a", "Placas de cerámica"),
            ("rifle_asalto", "Rifle de asalto", "el", "#2f3236", "Mira holográfica"),
            ("visor", "Visor nocturno", "el", "#2a5a3a", "Tubo de fósforo verde"),
            ("dron", "Dron", "el", "#4a5560", "Batería de litio"),
        ],
        "mejoras": ["Tienda en línea: clientes 25% más rápido", "Montacargas: dependientes 30% más rápido",
                    "Mostrador doble: +2 clientes en la fila", "Contrato con la policía: clientes 25% más rápido",
                    "Patinetas eléctricas: dependientes 30% más rápido", "Proveedor oficial: x2 todas las ganancias"],
        "tema": {
            "escenario": "tienda", "fondo": "#14171a", "suelo": "#767b80", "camino": "#5a5f64",
            "alfombra": "#2a5a8a", "mostrador_base": "#5a6066", "mostrador_tapa": "#a9b0b6",
            "ropa_clientes": ["#1f2f4f", "#2f3236", "#4a5a3a", "#d0d0d0"], "estilos_clientes": [15, 16, 17],
            "ropa_armeros": "#3f4f5f", "banco": "#4f565e", "estilo_armeros": 0, "ropa_dependientes": "#d05a2a",
            "luz_sol": 0.3, "luz_ambiente": 0.25,
        },
    },
    {
        "id": "futurista", "nombre": "Era futurista", "siguiente": "",
        "estaciones": [
            ("pistola_laser", "Pistola láser", "la", "#3fd0e0", "Cristal enfocado"),
            ("escudo_energia", "Escudo de energía", "el", "#5a8aff", "Campo estable"),
            ("rifle_plasma", "Rifle de plasma", "el", "#b05aff", "Bobina de fusión"),
            ("exotraje", "Exotraje", "el", "#e0e4ea", "Servomotores"),
            ("canon_riel", "Cañón de riel", "el", "#ff8a3f", "Imanes superconductores"),
        ],
        "mejoras": ["Puerto espacial: clientes 25% más rápido", "Botas antigravedad: dependientes 30% más rápido",
                    "Mostrador holográfico: +2 clientes en la fila", "Anuncio en la red galáctica: clientes 25% más rápido",
                    "Teletransporte corto: dependientes 30% más rápido", "Fama intergaláctica: x2 todas las ganancias"],
        "tema": {
            "escenario": "hangar", "fondo": "#06080f", "suelo": "#2a3040", "camino": "#3a4256",
            "alfombra": "#1f6a8a", "mostrador_base": "#3a4256", "mostrador_tapa": "#9aa8c0",
            "ropa_clientes": ["#e0e4ea", "#2a3040", "#3fd0e0", "#b05aff"], "estilos_clientes": [18, 19, 15],
            "ropa_armeros": "#2a3a5a", "banco": "#4a5468", "estilo_armeros": 18, "ropa_dependientes": "#3fd0e0",
            "luz_sol": 0.3, "luz_ambiente": 0.28,
        },
    },
]


def generar(epoca, escala):
    d = {"id": epoca["id"], "nombre": epoca["nombre"], "siguiente": epoca["siguiente"]}
    d["economia"] = copy.deepcopy(BRONCE["economia"])
    d["estaciones"] = []
    for (sid, nombre, _art, color, _m), base in zip(epoca["estaciones"], BRONCE["estaciones"]):
        e = {"id": sid, "nombre": nombre, "color": color, "tiempo": base["tiempo"]}
        for k in ("costo_desbloqueo", "costo_base", "valor_base"):
            e[k] = base[k] * escala
        d["estaciones"].append(e)
    est = epoca["estaciones"]
    # Las mejoras siguen el orden y los costos de la Edad del Bronce
    textos = iter(epoca["mejoras"])
    x2 = iter(est)
    d["mejoras"] = []
    for u in BRONCE["mejoras"]:
        n = copy.deepcopy(u)
        n["costo"] = u["costo"] * escala
        if u["tipo"] == "ganancia":
            sid, nombre, _a, _c, mej = next(x2)
            n["id"] = "x2" + sid
            n["estacion"] = sid
            n["nombre"] = "%s: x2 %s" % (mej, nombre)
        elif u["tipo"] in ("clientes", "velocidad", "fila", "ganancia_todas"):
            n["nombre"] = next(textos)
        d["mejoras"].append(n)
    # Misiones con la misma estructura de la Edad del Bronce
    mapa = {b["id"]: e for b, e in zip(BRONCE["estaciones"], est)}
    d["misiones"] = []
    for m in BRONCE["misiones"]:
        n = copy.deepcopy(m)
        if m["tipo"] == "nivel":
            sid, nombre, art, _c, _m = mapa[m["estacion"]]
            n["estacion"] = sid
            n["texto"] = ("Desbloquea %s %s" % (art, nombre)) if m["meta"] == 1 else \
                ("Sube %s %s al nivel %d" % (art, nombre, m["meta"]))
        elif m["tipo"] == "ganado":
            n["meta"] = m["meta"] * escala
            n["texto"] = "Gana %s monedas en total" % formato(n["meta"])
        d["misiones"].append(n)
    d["tema"] = epoca["tema"]
    return d


def formato(v):
    sufijos = ["", "K", "M", "B", "T", "aa", "ab", "ac", "ad", "ae"]
    i = 0
    while v >= 1000 and i < len(sufijos) - 1:
        v /= 1000.0
        i += 1
    return ("%d" % v if v == int(v) else "%.1f" % v) + sufijos[i]


if __name__ == "__main__":
    indice = ["prehistoria", "bronce"]
    for k, epoca in enumerate(EPOCAS):
        d = generar(epoca, 10 ** (k + 1))
        with open(os.path.join(RAIZ, epoca["id"] + ".json"), "w", encoding="utf-8") as f:
            f.write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
        indice.append(epoca["id"])
    with open(os.path.join(RAIZ, "indice.json"), "w", encoding="utf-8") as f:
        json.dump(indice, f)
    print("Épocas:", indice)

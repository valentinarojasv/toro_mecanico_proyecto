# Toro Mecánico

## Descripción del proyecto

Videojuego 2D desarrollado en Godot 4.7.2 utilizando GDScript.

El objetivo del videojuego es mantener el equilibrio sobre un toro mecánico durante el mayor tiempo posible, superando diferentes desafíos interactivos (QTE) y acumulando puntos.

A medida que transcurre la partida, el toro aumenta su nivel de furia, incrementando progresivamente la dificultad.

---

## Herramientas utilizadas

- Godot 4.7.2
- GDScript
- Git
- GitHub

---

## Características implementadas

- Configuración inicial del proyecto.
- Organización de carpetas y escenas.
- Implementación del escenario principal.
- Creación de la estructura del toro mecánico.
- Creación del jinete y sus cuatro animaciones.
- Programación del balanceo automático del toro.
- Creación de un Resource para configurar el movimiento.
- Implementación del sistema de equilibrio.
- Desarrollo de cinco tipos de eventos QTE.
- Implementación de animaciones de compensación del jinete.
- Indicaciones de dirección: ARRIBA, ABAJO, IZQUIERDA y DERECHA.
- Implementación de cinco niveles de furia.
- Sistema de puntuación, combos y récord.
- Desarrollo del HUD con indicadores de partida.
- Implementación del sistema Turbo con carga y activación.
- Integración de bonificaciones y penalizaciones durante el Turbo.
- Animación de caída y pantalla de fin de partida.
- Integración de recursos gráficos.
- Implementación de música y efectos de sonido.
- Exportación del videojuego a HTML5.

---

## Controles

| Tecla | Acción |
|-------|--------|
| W | Arriba |
| A | Izquierda |
| S | Abajo |
| D | Derecha |
| Espacio | Interacción en eventos QTE |

Durante la partida, las instrucciones aparecen en pantalla indicando la acción que debe realizar el jugador.

En los eventos de compensación, el jinete ejecuta una animación de inclinación antes de mostrar la dirección correspondiente.

---

## Mecánicas del videojuego

### 1. Sistema de equilibrio

El jugador debe mantener su equilibrio sobre el toro mecánico.

La barra de equilibrio disminuye progresivamente durante la partida.

Los QTE correctos permiten recuperar equilibrio, mientras que los errores generan penalizaciones.

### 2. Eventos QTE

El videojuego incorpora cinco tipos de eventos:

1. QTE simple.
2. QTE de dirección y compensación.
3. QTE de mantener presionado.
4. QTE de pulsaciones repetidas.
5. QTE de secuencia.

### 3. Niveles de furia

El toro dispone de cinco niveles de furia.

La dificultad aumenta progresivamente conforme transcurre el tiempo.

### 4. Sistema Turbo

El jugador puede acumular energía mediante resultados perfectos.

Cuando la barra de Turbo está completa, puede activar este modo para obtener bonificaciones temporales.

### 5. Puntuación y récord

El videojuego cuenta con:

- Puntuación por tiempo sobrevivido.
- Bonificaciones por combos.
- Bonificaciones durante el Turbo.
- Registro de la mejor puntuación.
- Conservación del récord entre partidas.

---

## Compatibilidad y pruebas

El videojuego fue probado en los siguientes navegadores:

- Google Chrome.
- Mozilla Firefox.
- Microsoft Edge.
- Navegador web de un dispositivo móvil.

### Pruebas realizadas

- Carga correcta del videojuego.
- Funcionamiento del menú principal.
- Funcionamiento de los botones.
- Ejecución de las mecánicas principales.
- Funcionamiento de los eventos QTE.
- Verificación del sistema de puntuación.
- Conservación del récord al cerrar y abrir el navegador.
- Verificación del funcionamiento en dispositivos móviles.
- Revisión de errores desde el depurador de Godot.

---

## Ejecución del proyecto

Para ejecutar el proyecto original:

1. Instalar Godot Engine 4.7.2.
2. Descargar o clonar este repositorio.
3. Abrir Godot.
4. Seleccionar la opción **Importar**.
5. Buscar el archivo `project.godot`.
6. Importar el proyecto.
7. Ejecutar el videojuego.

---

## Versión web

Toro Mecánico dispone de una versión exportada para navegadores web.

El Build Web incluye:

- `index.html`
- Archivos JavaScript generados por Godot.
- Archivos WebAssembly.
- Recursos necesarios para ejecutar el videojuego.

La versión web debe ejecutarse desde un servidor compatible con los requisitos de exportación de Godot.

---

## Estado del proyecto

**Fase final de desarrollo y entrega.**

Las mecánicas principales del videojuego se encuentran implementadas.

Se completaron las pruebas de funcionamiento en navegadores de escritorio y en un dispositivo móvil.

Actualmente se prepara la entrega final del Build Web, el proyecto de Godot y su documentación.

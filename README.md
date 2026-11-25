# Farther Beyond 3D

Juego espacial en 3D desarrollado en Godot por **Deeper Beyond**.

## Web y descarga para Android

- Web: https://JuanciscoPacketTracer.github.io/farther-beyond-3d/
- APK y versiones: https://github.com/JuanciscoPacketTracer/farther-beyond-3d/releases

La web estática está en `site/`. Presenta la historia del portal, al Astronauta,
el bestiario de Dungeon Critters, los objetos, capturas del gameplay y al equipo.
Consulta la API pública de GitHub para descargar la APK del último release
estable. Si el release más reciente no tiene APK, busca uno anterior que sí
la tenga. Excluye borradores, prereleases y archivos de firma `.idsig`.
Los fallos de conexión o límites de la API se muestran con una opción de
reintento y un enlace directo a Releases. Sin JavaScript sigue disponible
el enlace a Releases.

### Editar contenido

- Nombre, descripción, textos del equipo y ayuda: `site/index.html`.
- Estilos y diseño adaptable: `site/styles.css`.
- Formulario de feedback para quienes ya jugaron como testers: embed de Google
  Forms y enlace alternativo en `site/index.html`.
- Animaciones al desplazarse: elementos `data-reveal` en `site/index.html` y
  su observador en `site/app.mjs`; se desactivan con la preferencia de
  movimiento reducido.
- Carruseles de Critters y gameplay: contenido en `site/index.html` y lógica
  compartida en `site/carousel.mjs`. Avanzan cada 10 segundos; pueden pausarse
  o recorrerse manualmente, y no arrancan automáticamente con movimiento reducido.
- Logotipos, renders, Critters, objetos y capturas: `site/assets/` (incluidos
  explícitamente en `.gitignore`).
- Repositorio de descargas: `site/releases.mjs` y enlaces en `site/index.html`.

La historia y los textos presentan la narrativa y los personajes definidos
para el juego. Las capturas, renders e ilustraciones proceden de sus assets.
La web no publica la APK ni claves de firma en el árbol del repositorio.
`site/.gdignore` evita que Godot importe estos recursos web.

### Validación local

```sh
node --test tests/site-release.test.mjs
python3 -m http.server 8080 --directory site
```

Abre http://localhost:8080. No se necesitan dependencias de npm ni compilación.

### Publicación

En **Settings → Pages → Build and deployment**, selecciona **GitHub Actions**.
El workflow `.github/workflows/pages.yml` prueba y publica únicamente `site/`
cuando cambian sus archivos en `main`; también permite ejecución manual.
Después del despliegue verifica por HTTP la página y su módulo de descargas.

Para actualizar el juego, publica un release estable con un archivo `.apk`
en sus assets. La web detecta la actualización al abrirla o recargarla, sin
necesidad de modificar ni volver a desplegar el sitio. Ejemplo:

```sh
gh release create v1.0.1 --title "Farther Beyond 3D v1.0.1" \
  --notes "Nueva APK para Android." \
  "releases/Farther Beyond 3D.apk"
```

Usa una etiqueta nueva en cada release. Los releases marcados como
prerelease no se ofrecen como descarga estable en la web.

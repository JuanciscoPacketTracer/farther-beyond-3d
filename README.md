# Farther Beyond 3D

Juego espacial en 3D desarrollado en Godot por **Deeper Beyond**.

## Web y descarga para Android

- Web: https://JuanciscoPacketTracer.github.io/farther-beyond-3d/
- APK y versiones: https://github.com/JuanciscoPacketTracer/farther-beyond-3d/releases

La web estática está en `site/`. Presenta el juego, sus imágenes y el equipo.
Consulta la API pública de GitHub para descargar la APK del último release
estable. Si el release más reciente no tiene APK, busca uno anterior que sí
la tenga. Excluye borradores, prereleases y archivos de firma `.idsig`.
Los fallos de conexión o límites de la API se muestran con una opción de
reintento y un enlace directo a Releases. Sin JavaScript sigue disponible
el enlace a Releases.

### Editar contenido

- Nombre, descripción, textos del equipo y ayuda: `site/index.html`.
- Estilos y diseño adaptable: `site/styles.css`.
- Logotipos e imágenes: `site/assets/` (incluidos explícitamente en `.gitignore`).
- Repositorio de descargas: `site/releases.mjs` y enlaces en `site/index.html`.

Los textos descriptivos iniciales son una propuesta editorial; el equipo
puede sustituirlos por la descripción y presentación oficiales.
Las imágenes proceden de los assets proporcionados para el juego.
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

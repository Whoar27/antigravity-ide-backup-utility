# 🛡️ Antigravity Backup & Restore Utility

[![OS - Windows](https://img.shields.io/badge/OS-Windows-blue?style=flat-square&logo=windows)](https://www.microsoft.com/windows)
[![Shell - PowerShell](https://img.shields.io/badge/Shell-PowerShell-blue?style=flat-square&logo=powershell)](https://github.com/PowerShell/PowerShell)
[![License - MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![PRs - Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square)](https://github.com/your-username/antigravity-backup/pulls)

Una solución integral, robusta y automatizada mediante scripts en **PowerShell** para realizar copias de seguridad y migraciones completas de tu entorno de desarrollo en **Antigravity IDE**. Respalda tus preferencias de usuario, temas, atajos, bases de conocimiento de la IA local, configuraciones de enlace e historial de conversaciones para evitar pérdidas accidentales y ahorrar horas de reindexación en tu nueva computadora.

---

## 🎯 El Problema y la Solución

### El problema:
Al reinstalas el software o cambiar de computadora, muchos desarrolladores pierden el acceso a sus configuraciones y, lo que es peor, al **historial de conversaciones y memoria contextual del agente de IA**. Reconstruir o reindexar grandes repositorios puede tardar horas y consume valioso tiempo de procesamiento.

### La solución:
Este repositorio contiene un ecosistema de dos herramientas automatizadas y una estructura detallada que garantiza una migración en minutos, sin pérdida de datos y de manera 100% segura:

*   **`respaldo_antigravity.ps1`**: Script principal de respaldo en PowerShell. Cierra procesos activos del IDE con consentimiento del usuario, recolecta las rutas críticas (Roaming e historial de la IA) y las comprime en un único archivo `.zip` portable.
*   **`respaldo_antigravity.cmd`**: Versión de emergencia en CMD (Batch). Diseñado exclusivamente para entornos de recuperación de Windows (WinRE) o Modo Seguro donde PowerShell no está disponible. Utiliza herramientas 100% nativas como `robocopy` y `tar.exe` para realizar copias y compresión ZIP.
*   **`restaurar_antigravity.ps1`**: Extrae las configuraciones sobreescribiendo quirúrgicamente los directorios necesarios tras generar una copia de seguridad preventiva e instantánea del estado actual de tu máquina para evitar cualquier riesgo de pérdida.

---

## 📂 Anatomía de Datos: ¿Qué respaldamos?

El sistema de respaldo recopila con precisión quirúrgica las siguientes dos ubicaciones esenciales del sistema Windows:

```
📂 Backup_Antigravity_[Fecha].zip
 ┣ 📂 User                 <-- (%APPDATA%\Antigravity IDE\User\)
 ┃ ┣ 📂 globalStorage
 ┃ ┣ 📂 workspaceStorage
 ┃ ┣ 📂 History
 ┃ ┣ 📂 snippets
 ┃ ┣ 📜 settings.json
 ┃ ┣ 📜 storage.json
 ┃ ┗ 📜 keybindings.json
 ┗ 📂 .gemini              <-- (%USERPROFILE%\.gemini\)
   ┣ 📂 config/projects
   ┣ 📂 antigravity-ide/brain
   ┣ 📂 antigravity-ide/conversations
   ┗ 📂 antigravity-ide/implicit
```

### 1. Datos de la Aplicación y Configuración del Editor (Roaming)
*   **Ruta:** `%APPDATA%\Antigravity IDE\User\`
*   *Función:* Almacena tus fragmentos de código, temas, tipografía de letra, historial local de archivos modificados y el panel lateral con la lista de proyectos recientes.

### 2. El "Cerebro" y Conversaciones del Agente de IA (.gemini)
*   **Ruta:** `%USERPROFILE%\.gemini\`
*   *Función:* Guarda los vectores de indexación del código, el enlace de proyectos vinculados con la IA, y tu **historial de chats completo** con todos tus prompts y respuestas acumuladas.

---

## 🚀 Guía de Uso Rápido

Para utilizar esta herramienta de forma segura en Windows, abre una consola de **PowerShell** y sigue los pasos correspondientes:

> [!NOTE]
> **Permisos en Windows:** PowerShell bloquea de forma predeterminada la ejecución de scripts externos. Agrega siempre `-ExecutionPolicy Bypass` antes del archivo para evitar bloqueos del sistema.

### 📥 Realizar una Copia de Seguridad

1. Abre **PowerShell** y navega a la carpeta de este repositorio.
2. Ejecuta el comando de respaldo:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\respaldo_antigravity.ps1
   ```
3. **Control de Procesos:** El script detectará si el IDE o su agente de IA están abiertos y te dará la opción de cerrarlos de forma limpia.
4. **Almacenamiento Inteligente:** Te sugerirá guardar el backup de forma predeterminada en tu **OneDrive** (si está configurado) para que quede en la nube al instante, o bien te permitirá ingresar una ruta personalizada.
5. Obtendrás un único archivo `.zip` comprimido y listo para mover.

### 🚨 Respaldo de Emergencia en Entornos de Recuperación (CMD)

Si tu Windows ha entrado en **modo de recuperación (WinRE)**, pantalla de diagnóstico o modo seguro sin acceso a PowerShell, puedes realizar la copia de seguridad de tu editor desde la consola clásica de comandos de forma 100% nativa:

1. Abre la consola de comandos de recuperación (`CMD`).
2. Conecta un pendrive USB para guardar allí tu copia de seguridad.
3. Navega al directorio del script y ejecuta:
   ```cmd
   respaldo_antigravity.cmd
   ```
4. El script te sugerirá una ruta predeterminada o te permitirá introducir la letra de tu unidad USB externa (ej. `E:\MiRespaldo`).
5. Utilizará de forma invisible la herramienta preinstalada `tar.exe` de Windows 10/11 para crear el archivo `.zip` sin requerir ningún compresor externo.
6. **Nota de Restauración:** Una vez reparado o reinstalado tu sistema y de vuelta en el escritorio de Windows normal, puedes restaurar este archivo `.zip` sin ningún problema usando el script de PowerShell estándar (`restaurar_antigravity.ps1`).

### 📤 Restaurar en una Nueva PC

1. **Importante:** Instala **Antigravity IDE** en tu nueva computadora y ábrelo al menos una vez para generar las estructuras del sistema. Luego ciérralo por completo.
2. Copia los scripts y tu archivo de respaldo `.zip` a la nueva PC.
3. Abre **PowerShell** en la carpeta donde estén tus scripts y ejecuta:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\restaurar_antigravity.ps1
   ```
4. Arrastra el archivo `.zip` del respaldo a la consola (o escribe la ruta completa) y presiona Enter.
5. El script realizará un **respaldo preventivo automático** de tu configuración actual antes de proceder, garantizando que el proceso sea completamente seguro y libre de riesgos.
6. Abre el IDE y tu entorno estará listo y sincronizado.

---

## 🛠️ Alternativa Manual (Paso a Paso)

Si prefieres realizar el proceso manualmente sin hacer uso de los scripts de PowerShell, sigue este flujo riguroso:

### Copia de Seguridad en el PC de Origen
1. Cierra completamente **Antigravity IDE**. Asegúrate de que no haya procesos residuales (`gemini-agent`) activos en el administrador de tareas.
2. Presiona `Win + R` en tu teclado, escribe `%appdata%\Antigravity IDE\` y presiona Enter. Copia la carpeta `User` a un pendrive USB o nube.
3. Presiona `Win + R`, escribe `%userprofile%` y presiona Enter. Copia la carpeta `.gemini` completa al pendrive USB o nube.

### Despliegue en la Nueva PC / Reinstalación
1. Instala **Antigravity IDE** en el nuevo equipo, ábrelo una vez y ciérralo por completo.
2. Copia la carpeta `User` de tu respaldo y pégala en `%appdata%\Antigravity IDE\`, sobreescribiendo si te lo solicita.
3. Copia la carpeta `.gemini` de tu respaldo y pégala directamente en `%userprofile%` (ej: `C:\Users\NUEVO_USUARIO\`), sobreescribiendo si es necesario.

---

## 💡 Preguntas Frecuentes y Solución de Problemas

> [!TIP]
> **¿El archivo de respaldo pesa demasiado?**
> La carpeta `.gemini/antigravity-ide/brain/` puede volverse muy pesada debido al motor de búsqueda vectorial. Si quieres un respaldo extremadamente ligero, puedes excluir el directorio `brain/` copiando únicamente `conversations/` y `config/`. El agente simplemente volverá a indexar tus carpetas al abrirlas en tu nuevo entorno, pero conservarás intacto el 100% de tu valioso historial de chats.

> [!WARNING]
> **Advertencia de Seguridad de PowerShell**
> Si ves el error *"execution of scripts is disabled on this system"*, se debe a la directiva de seguridad del sistema. Solo debes ejecutar el comando agregando la opción `-ExecutionPolicy Bypass` como se detalla en la guía de uso rápido.

---

## 🤝 Contribuciones

¿Has encontrado un error o tienes alguna idea para mejorar este flujo (por ejemplo, soporte nativo para Linux o macOS)? ¡Los pull requests y sugerencias son bienvenidos! 

1. Hace un Fork del proyecto.
2. Crea tu rama de características (`git checkout -b feature/NuevaCaracteristica`).
3. Realiza tus cambios y haz un commit (`git commit -m 'Añade nueva funcionalidad'`).
4. Haz un Push a tu rama (`git push origin feature/NuevaCaracteristica`).
5. Abre un Pull Request.

---

## 📄 Licencia

Este proyecto está bajo la licencia **MIT**. Para más detalles, consulta el archivo `LICENSE` (o utilízalo libremente bajo los términos de la misma).
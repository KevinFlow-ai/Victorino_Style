# VictorinoStyle — Generar paquete .deb en Ubuntu VM

## ¿Qué hace el script?
El script `construir_deb_ubuntu.sh` incluido en el ZIP hace **todo automáticamente**:
1. Instala las dependencias del sistema (clang, cmake, gtk3, etc.)
2. Descarga e instala Flutter SDK si no está en la VM
3. Compila la app para Linux en modo release
4. Crea la estructura del paquete `.deb`
5. Genera el archivo `victorino-style_1.0.0_amd64.deb`

---

## Pasos a seguir

### En Windows — Pasar el ZIP a la VM
El archivo `victorino_flutter_para_linux.zip` ya está generado en esta carpeta.

**Opciones para pasarlo a la VM:**
- **Carpeta compartida** (recomendado): Configura una carpeta compartida en VirtualBox/VMware y copia el ZIP ahí
- **Arrastrar y soltar**: Si tienes "Guest Additions" instaladas en VirtualBox, puedes arrastrar el ZIP directamente a la ventana de la VM
- **USB virtual**: Comparte una unidad USB entre el host Windows y la VM

---

### En Ubuntu VM — Ejecutar el script

Abre un terminal en Ubuntu y ejecuta estos comandos:

```bash
# 1. Descomprimir el ZIP (ajusta la ruta donde lo copiaste)
cd ~
unzip /ruta/al/victorino_flutter_para_linux.zip

# Si lo tienes en carpeta compartida de VirtualBox (suele estar en /media/sf_*)
# unzip /media/sf_Compartida/victorino_flutter_para_linux.zip

# 2. Entrar en la carpeta del proyecto
cd frontend_victorino

# 3. Dar permisos de ejecución al script
chmod +x construir_deb_ubuntu.sh

# 4. Ejecutar el script (pedirá contraseña sudo para instalar dependencias)
./construir_deb_ubuntu.sh
```

El script tardará unos **5-15 minutos** la primera vez (descarga Flutter + compila).

---

### Resultado
Al terminar, encontrarás dentro de la carpeta `frontend_victorino`:
```
victorino-style_1.0.0_amd64.deb
```

---

### Instalar el .deb en Ubuntu
```bash
sudo dpkg -i victorino-style_1.0.0_amd64.deb
```

Para lanzar la app:
- Desde el **menú de aplicaciones** busca "VictorinoStyle"
- O desde terminal: `victorino-style`

### Desinstalar
```bash
sudo dpkg -r victorino-style
```

---

## Requisitos de la VM Ubuntu
- Ubuntu 22.04 LTS o superior (64 bits)
- Al menos **4 GB de RAM** asignados a la VM
- Al menos **10 GB de espacio libre** en disco
- Conexión a internet (para descargar Flutter y dependencias)

---

## Copiar el .deb de vuelta a Windows

Desde Windows (PowerShell), si la VM tiene SSH activo:
```powershell
scp usuario@IP_VM:/home/usuario/frontend_victorino/victorino-style_1.0.0_amd64.deb .
```

O simplemente cópialo a través de la carpeta compartida.

---

*TFG 2DAM 2025/2026 — VictorinoStyle*


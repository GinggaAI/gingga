# 🔥 TROUBLESHOOTING: Browser Cache Issues

**Problema**: Cambios en JavaScript no se reflejan en el navegador
**Síntoma**: El HTML generado NO es del partial Rails, sino del JavaScript viejo

---

## ✅ SOLUCIÓN RÁPIDA

### Opción 1: Cerrar y reabrir navegador

```bash
1. Cierra COMPLETAMENTE el navegador (todas las ventanas)
2. Abre el navegador de nuevo
3. Ve DIRECTO a modo incógnito (Ctrl+Shift+N)
4. Ve a: http://localhost:3000/vlado-entrepreneur/en/planning
```

### Opción 2: Probar en otro navegador

Si usas Chrome, prueba en:
- Firefox
- Edge
- Safari (si estás en Mac)

### Opción 3: Limpiar cache desde Chrome

```
1. chrome://settings/clearBrowserData
2. Time range: "All time"
3. Marca SOLO "Cached images and files"
4. Clear data
5. Reinicia el navegador
```

---

## 🔍 CÓMO VERIFICAR SI ESTÁ FUNCIONANDO

### En el navegador (DevTools → Console):

```javascript
// Debe decir _contentPiece (con underscore) = NUEVO
showContentDetails.toString()

// Debe ser undefined = NO existe (correcto)
typeof buildContentDetailHTML
```

### El HTML debe tener Content Structure:

Cuando hagas click en un content piece, DEBES ver:

```html
<div class="bg-rose-50 p-3 rounded">
  <h5 class="font-medium text-gray-900 mb-1">📖 Content Structure</h5>
  <p class="text-sm text-gray-700">Chronicles In Motion</p>
  <p class="text-xs text-gray-500 mt-1 italic">Narrative framework (what the video says)</p>
</div>
```

Si NO ves esa sección = el navegador tiene JavaScript viejo en caché.

---

## 🛠️ SI NADA FUNCIONA

### Opción nuclear:

```bash
# 1. Stop servidor
# Ctrl+C

# 2. Limpia TODO
./bin/dev-rebuild

# 3. Modifica el archivo para forzar cambio
echo "// Force reload: $(date)" >> app/assets/builds/application.js

# 4. Restart servidor
rails server

# 5. En el navegador:
#    - Cierra TODO
#    - Borra historial/cache completo
#    - Reinicia el navegador
#    - Abre incógnito
#    - Ve a la URL
```

---

## 📊 CHECKLIST DE VERIFICACIÓN

Antes de decir que "no funciona", verifica:

- [ ] Servidor Rails está corriendo
- [ ] Ejecutaste `./bin/dev-rebuild`
- [ ] Reiniciaste el servidor después del rebuild
- [ ] CERRASTE completamente el navegador (no solo la pestaña)
- [ ] Abriste el navegador de nuevo
- [ ] Usaste modo incógnito
- [ ] O probaste en otro navegador
- [ ] `showContentDetails.toString()` dice `_contentPiece`
- [ ] `typeof buildContentDetailHTML` dice `undefined`

Si TODOS los checks pasan y aún no funciona, hay otro problema.

---

**Última actualización**: $(date)

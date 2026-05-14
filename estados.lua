-- estados.lua

-- Vista: Menú de Inicio
function init_intro()
    -- Tabla para gestionar dinámicamente las opciones del menú
    opciones = {
        {nombre="vidas pato", val=3, min=1, max=5},
        {nombre="rival", val=1, textos={"humano", "cpu"}},
        {nombre="modo", val=1, textos={"infinito", "acotado", "desafio"}},
        {nombre="mapa", val=1, textos={"bosque", "lago", "noche"}}
    }
    sel_opc = 1 -- Índice de la opción seleccionada actualmente
end

function upd_intro()
    -- Navegación vertical (Arriba / Abajo)
    if btnp(2) then sel_opc -= 1 end 
    if btnp(3) then sel_opc += 1 end 
    -- Mantener el cursor dentro de los límites de la tabla
    sel_opc = mid(1, sel_opc, #opciones)
    
    -- Modificar valor de la opción actual (Izquierda / Derecha)
    local op = opciones[sel_opc]
    if btnp(0) then op.val -= 1 end 
    if btnp(1) then op.val += 1 end 
    
    -- Limitar los valores según el tipo de opción (numérica o de texto)
    if op.min then
        op.val = mid(op.min, op.val, op.max)
    else
        op.val = mid(1, op.val, #op.textos)
    end
    
    -- Iniciar juego (Botón Z o X)
    if btnp(4) or btnp(5) then 
        -- TODO: En la siguiente fase, inyectaremos 'opciones' dentro de init_game()
        chg_vista("ingame") 
    end
end

function drw_intro()
cls()
    -- Título
    print("pato a la fuga", 22, 10, 11)
    print("configuracion de partida", 14, 25, 7)
    
    -- Dibujar opciones dinámicamente
    local y = 45
    for i=1, #opciones do
        local op = opciones[i]
        local color = (i == sel_opc) and 10 or 6 -- Amarillo si está seleccionado, gris si no
        
        -- Determinar si mostramos un número o un texto
        local txt_val = op.val
        if op.textos then txt_val = op.textos[op.val] end
        
        print(op.nombre .. ": " .. txt_val, 24, y, color)
        
        -- Dibujar el cursor
        if (i == sel_opc) print(">", 16, y, 10)
        
        y += 12
    end
    
    print("presiona z para jugar", 22, 110, 5)
end

-- Vista: Juego principal
function init_game()
    ents = {} -- Limpiar lista de entidades
    cazador = make_cazador()
    pato = make_pato()
    
    -- Inyectar configuración del menú a las variables del juego
    pato.vida = opciones[1].val
    tipo_rival = opciones[2].val
    modo_juego = opciones[3].val
    escenario = opciones[4].val
    
    segundos = 0
    frames = 0
end

function upd_game()
    frames += 1
    if (frames % 30 == 0) segundos += 1
    
    -- Actualizar todas las entidades registradas
    for e in all(ents) do
        e.upd()
    end
    
    -- TODO: Implementar condiciones de derrota y victoria aquí
    -- Condición de derrota del pato (Final malo)
    if pato.vida <= 0 then
        -- TODO: Pantalla de Game Over (Fase 4)
        chg_vista("intro") -- Por ahora lo mandamos al menú
    end
end

function drw_game()
    cls()
    map(0,0,0,0,16,16) 
    
    for e in all(ents) do
        e.drw()
    end
    
    print("tiempo: "..segundos, 4, 4, 7)
    print("vidas pato: "..pato.vida, 70, 4, 7)
end

-- Diccionario maestro de Vistas
vistas = {
    intro = { ini=init_intro, upd=upd_intro, drw=drw_intro },
    ingame = { ini=init_game, upd=upd_game, drw=drw_game }
}

-- Función para transicionar limpiamente entre estados
function chg_vista(v)
    vista = v
    vistas[v].ini()
    _update = vistas[v].upd
    _draw = vistas[v].drw
end
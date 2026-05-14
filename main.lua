-- main.lua

function _init()
    cartdata("pato_sj_2026_final_v8")
    highscore = dget(0)
    
    if (not registro) registro = {}
    
    -- Inyectar el estado inicial (Pantalla de inicio)
    chg_vista("intro")
end

-- Las funciones globales _update() y _draw() 
-- son sobreescritas y asignadas dinámicamente 
-- dentro de la función chg_vista() de estados.lua
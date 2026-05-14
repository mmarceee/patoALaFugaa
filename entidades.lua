-- entidades.lua
ents = {}

function make_entidad(px, py, sprite_id)
    local e = {
        x = px,
        y = py,
        sp = sprite_id,
        vida = 1,
        dx = 0,
        dy = 0
    }
    
    e.upd = function()
        e.x += e.dx
        e.y += e.dy
        -- Colisiones fluidas contra los bordes de la pantalla (Game Feel)
        e.x = mid(0, e.x, 120)
    end
    
    e.drw = function()
        spr(e.sp, e.x, e.y)
    end
    
    add(ents, e)
    return e
end

function make_cazador()
    local c = make_entidad(60, 110, 2)
    c.vel = 2
    c.angulo = 0.25 -- Ángulo inicial: 0.25 apunta directamente hacia arriba en PICO-8
    
    local oupd = c.upd
    c.upd = function()
        c.dx = 0
        
        -- Movimiento horizontal
        if (btn(0)) c.dx = -c.vel
        if (btn(1)) c.dx = c.vel
        
        -- Apuntado (Arriba/Abajo)
        if (btn(2)) c.angulo -= 0.008 -- Gira hacia la derecha
        if (btn(3)) c.angulo += 0.008 -- Gira hacia la izquierda
        
        -- Limitar el arco de disparo para que apunte hacia el cielo
        -- 0 es derecha, 0.5 es izquierda, 0.25 es el centro arriba
        c.angulo = mid(0.05, c.angulo, 0.45)
        
        -- Disparar proyectil
        if btnp(4) then
            local centro_x = c.x + 4 
            local centro_y = c.y
            local vel_bala = 4
            
            make_bala(
                centro_x, 
                centro_y, 
                cos(c.angulo) * vel_bala, 
                sin(c.angulo) * vel_bala
            )
        end
        
        oupd()
    end
    
    local odrw = c.drw
    c.drw = function()
        odrw() -- Dibuja el sprite del cazador primero
        
        -- Lógica visual de la Mirilla
        local radio = 20 -- Distancia de la mirilla al cazador
        local mirilla_x = c.x + 4 + cos(c.angulo) * radio
        local mirilla_y = c.y + 4 + sin(c.angulo) * radio
        
        -- Dibujar una retícula técnica
        line(mirilla_x - 2, mirilla_y, mirilla_x + 2, mirilla_y, 8)
        line(mirilla_x, mirilla_y - 2, mirilla_x, mirilla_y + 2, 8)
        pset(mirilla_x, mirilla_y, 12)
    end
    
    return c
end

-- Constructor de balas
function make_bala(px, py, dir_x, dir_y)
    local b = make_entidad(px, py, 0)
    b.dx = dir_x
    b.dy = dir_y
    b.vida = 100 -- Un poco más de tiempo para que cruce la pantalla
    
    local oupd = b.upd
    b.upd = function()
        b.vida -= 1
        
        -- Si la bala muere o sale, la borramos y cortamos la función
        if b.vida <= 0 or b.y < -5 or b.x < -5 or b.x > 133 then
            del(ents, b)
            return
        end
        
        -- Colisión Segura: Solo si el pato existe
        if pato != nil then
            if abs(b.x - (pato.x + 4)) < 5 and abs(b.y - (pato.y + 4)) < 5 then
                pato.vida -= 1
                del(ents, b)
                -- sfx(0) -- Descomenta esto cuando tengas sonidos
                return
            end
        end
        
        oupd()
    end
    
    b.drw = function()
        circfill(b.x, b.y, 1, 0)
    end
    
    return b
end

function make_pato()
    local p = make_entidad(60, 20, 1)
    p.vel = 1.5
    p.vida = 3
    
    -- variables de la mecánica 
    p.dash_timer = 0    -- duración del impulso
    p.dash_cd = 0       -- enfriamiento (cooldown)
    p.direccion = 1     -- 1 derecha, -1 izquierda
    
    local oupd = p.upd
    p.upd = function()
        p.dx = 0
        
        -- reducir contadores
        if (p.dash_timer > 0) p.dash_timer -= 1
        if (p.dash_cd > 0) p.dash_cd -= 1
        
        -- determinar dirección para el dash [cite: 9]
        if (btn(0,1)) p.direccion = -1
        if (btn(1,1)) p.direccion = 1
        
        -- activar dash (botón x del j2)
        if btnp(5,1) and p.dash_cd <= 0 then
            p.dash_timer = 8  -- dura 8 frames
            p.dash_cd = 60    -- 2 segundos de espera (a 30fps)
            sfx(5)            
        end
        
        -- lógica de movimiento e instanciación de la estela 
        if p.dash_timer > 0 then
            p.dx = p.direccion * 4 
            
            -- CREA UNA PLUMA CADA 2 FRAMES MIENTRAS DURA EL DASH
            if frames % 2 == 0 then 
                make_pluma(p.x + 2, p.y + 2)
            end
        else
            -- movimiento normal si no hay dash
            if (btn(0,1)) p.dx = -p.vel
            if (btn(1,1)) p.dx = p.vel
        end
        
        oupd()
    end
    
    local odrw = p.drw
    p.drw = function()
        -- 1. Lógica de animación de alas 
        local sp_actual = 1
        if (frames % 8 >= 4) sp_actual = 17 
        
        -- 2. Efecto visual de parpadeo durante el dash
        if p.dash_timer > 0 then
            pal(1, 7) -- el color oscuro parpadea a blanco
        end
        
        -- 3. Dibujar el sprite (volteo corregido)
        -- Si p.direccion es < 0 (izq), volteamos el sprite que mira a la derecha
        local voltear_sprite = (p.direccion < 0)
        spr(sp_actual, p.x, p.y, 1, 1, voltear_sprite)
        
        pal() -- resetear colores
        
        -- 4. Indicador de Cooldown (HUD sobre el pato) [cite: 19]
        if p.dash_cd > 0 then
            rectfill(p.x, p.y-3, p.x+7, p.y-2, 5) -- fondo
            rectfill(p.x, p.y-3, p.x+(p.dash_cd/60)*7, p.y-2, 12) -- carga
        end
    end
    
    return p
end

function make_pluma(px, py)
    local pl = make_entidad(px, py, 33) -- 18 es el sprite de tu pluma
    pl.dx = rnd(1)-0.5 -- pequeña deriva lateral
    pl.dy = 0.5        -- cae lentamente
    pl.vida = 15       -- dura medio segundo (15 frames)
    
    local oupd = pl.upd
    pl.upd = function()
        pl.vida -= 1
        if (pl.vida <= 0) del(ents, pl)
        oupd()
    end
    
    pl.drw = function()
        -- hace que la pluma se vuelva gris antes de desaparecer
        if (pl.vida < 5) pal(7, 6) 
        spr(pl.sp, pl.x, pl.y)
        pal()
    end
end
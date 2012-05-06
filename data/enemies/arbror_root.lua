-- A root of Master Arbror

local immobilized = false
local disappearing = false
local speed = 32
local timer

function event_appear()

  sol.enemy.set_life(1)
  sol.enemy.set_damage(4)
  sol.enemy.create_sprite("enemies/arbror_root")
  sol.enemy.set_size(64, 16)
  sol.enemy.set_origin(28, 6)
  sol.enemy.set_invincible()
  sol.enemy.set_attack_consequence("hookshot", "immobilized")
  sol.enemy.set_attack_consequence("arrow", "protected")
  sol.enemy.set_attack_consequence("boomerang", "protected")
  sol.enemy.set_attack_consequence("sword", "protected")
  sol.enemy.set_push_hero_on_sword(true)
  sol.enemy.set_can_hurt_hero_running(true)
end

function event_restart()

  local sprite = sol.enemy.get_sprite()
  if disappearing then
    sprite:set_animation("disappearing")
    sol.enemy.set_invincible()
    sol.enemy.stop_movement()
    sol.enemy.set_can_attack(false)
  elseif immobilized then
    sprite:set_animation("hurt_long")
    if timer ~= nil then
      timer:stop()
    end
    timer = sol.timer.start(10000, disappear)
    sol.enemy.stop_movement()
    sol.enemy.set_can_attack(false)
  else
    timer = sol.timer.start(1000, go)
    sol.enemy.set_can_attack(true)
  end
end

function go()

  if not immobilized then
    local m = sol.movement.movement_create("path_finding")
    m:set_speed(speed)
    sol.enemy.start_movement(m)
  end
end

function event_hurt(attack, life_points)

  if not immobilized then
    -- tell my father that I will be immobilized
    father_name = sol.enemy.get_father()
    if father_name ~= "" then
      sol.enemy.send_message(father_name, "begin immobilized")
    end
    if timer ~= nil then
      timer:stop()
    end
  end
end

function event_immobilized()

  -- just immobilized
  immobilized = true
  sol.enemy.restart() -- to stop the buit-in behavior of being immobilized
end

function disappear()

  if not disappearing then
    local sprite = sol.enemy.get_sprite()
    sprite:set_animation("disappearing")
    sol.enemy.set_invincible()
    sol.enemy.set_can_attack(false)

    father_name = sol.enemy.get_father()
    if father_name ~= "" then
      sol.enemy.send_message(father_name, "end immobilized")
    end
    if timer ~= nil then
      timer:stop()
    end
    disappearing = true
  end
end

function event_sprite_animation_finished(sprite, animation)

  if animation == "disappearing" then
    sol.map.enemy_remove(sol.enemy.get_name())
  end
end

function event_message_received(src_enemy, message)

  if message == "disappear" then
    disappear()
  else
    -- the message is the speed
    speed = tonumber(message)
  end
end


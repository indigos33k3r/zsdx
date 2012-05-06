-- Simple green soldier: a stupid soldier with a small sword
-- who goes in a random direction.
-- Unlike the normal green soldier, he cannot see or follow the hero.

-- The enemy appears: set its properties
function event_appear()

  sol.enemy.set_life(2)
  sol.enemy.set_damage(2)
  sol.enemy.create_sprite("enemies/simple_green_soldier")
  sol.enemy.set_size(16, 16)
  sol.enemy.set_origin(8, 13)
end

-- The enemy was stopped for some reason and should restart
function event_restart()

  local m = sol.movement.create("straight")
  m:set_speed(0)
  sol.enemy.start_movement(m)
  local direction4 = math.random(4) - 1
  go(direction4)
end

-- An obstacle is reached: stop for a while, looking to a next direction
function event_obstacle_reached()

  -- look to the left or to the right
  local sprite = sol.enemy.get_sprite()
  local animation = sprite:get_animation()
  if animation == "walking" then
    look_left_or_right()
  end
end

-- The movement is finished: stop for a while, looking to a next direction
function event_movement_finished(movement)
  -- same thing as when an obstacle is reached
  event_obstacle_reached()
end

--  The animation of a sprite is finished
function event_sprite_animation_finished(sprite, animation)

  -- if the enemy was stopped and looking to a direction, go to that direction
  local direction = sprite:get_direction()
  if animation == "stopped_watching_left" then
    go((direction + 1) % 4)
  elseif animation == "stopped_watching_right" then
    go((direction + 3) % 4)
  end
end

-- Makes the soldier walk towards a direction
function go(direction4)

  -- set the sprite
  local sprite = sol.enemy.get_sprite()
  sprite:set_animation("walking")
  sprite:set_direction(direction4)

  -- set the movement
  local m = sol.enemy.get_movement()
  local max_distance = 40 + math.random(120)
  m:set_max_distance(max_distance)
  m:set_smooth(true)
  m:set_speed(40)
  m:set_angle(direction4 * math.pi / 2)
end

-- Makes the soldier look to its left or to its right (random choice)
function look_left_or_right()

  local sprite = sol.enemy.get_sprite()
  if math.random(2) == 1 then
    sprite:set_animation("stopped_watching_left")
  else
    sprite:set_animation("stopped_watching_right")
  end
end


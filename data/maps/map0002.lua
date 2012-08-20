local map = ...
-- Rupee house

-- Initializations made when the map has just been loaded
local playing_game_1 = false
local playing_game_2 = false
local playing_game_3 = false
local already_played_game_1 = false
local game_1_rewards = {5, 20, 50} -- possible rupee rewards in game 1
local game_2_bet = 0
local game_2_reward = 0
local game_2_man_sprite = nil
local game_2_timer
local game_2_slots = {
  slot_machine_left =   {initial_frame = 6, initial_delay = 70, current_delay = 0, symbol = -1, sprite = nil},
  slot_machine_middle = {initial_frame = 15, initial_delay = 90, current_delay = 0, symbol = -1, sprite = nil},
  slot_machine_right =  {initial_frame = 9, initial_delay = 60, current_delay = 0, symbol = -1, sprite = nil}
} -- the key is also the entity name
local game_3_timer

-- Function called when the map starts
function map:on_started(destination_point_name)

  for k, v in pairs(game_2_slots) do
    v.sprite = map:npc_get_sprite(k)
    v.sprite:set_frame(v.initial_frame)
  end
  game_2_man_sprite = map:npc_get_sprite("game_2_man")
end

-- Function called when the player wants to talk to a non-playing character
function map:on_npc_interaction(npc_name)

  if npc_name == "game_1_man" then
    -- game 1 dialog

    if playing_game_1 then
      -- the player is already playing: tell him to choose a chest
      map:dialog_start("rupee_house.game_1.choose_chest")
    else

      -- see if the player can still play
      local unauthorized = map:get_game():get_boolean(16)

      if unauthorized then
	-- the player already won much money
	map:dialog_start("rupee_house.game_1.not_allowed_to_play")
      else 
	if not already_played_game_1 then
	  -- first time: long dialog with the game rules
	  map:dialog_start("rupee_house.game_1.intro")
	else
	  -- quick dialog to play again
	  map:dialog_start("rupee_house.game_1.play_again_question")
	end
      end
    end

  elseif npc_name == "game_2_man" then
    -- game 2 dialog

    if playing_game_2 then
      -- the player is already playing: tell him to stop the reels
      map:dialog_start("rupee_house.game_2.playing")
    else
      -- dialog with the game rules
      map:dialog_start("rupee_house.game_2.intro")
    end

  elseif npc_name == "game_3_man" then
    -- game 3 dialog

    if playing_game_3 then
      -- the player is already playing: let him restart the game
      map:dialog_start("rupee_house.game_3.restart_question")
    else
      -- see if the player can still play
      unauthorized = map:get_game():get_boolean(17)

      if unauthorized then
	-- the player already won this game
	map:dialog_start("rupee_house.game_3.not_allowed_to_play")
      else
	-- game rules
	map:dialog_start("rupee_house.game_3.intro")
      end
    end

  elseif string.find(npc_name, "^slot_machine_") then
    
    if playing_game_2 then

      game_2_man_sprite:set_direction(0)

      if game_2_slots[npc_name].symbol == -1 then
	-- stop this reel

	local sprite = game_2_slots[npc_name].sprite
	local current_symbol = math.floor(sprite:get_frame() / 3)
	game_2_slots[npc_name].symbol = (current_symbol + math.random(2)) % 7
	game_2_slots[npc_name].current_delay = game_2_slots[npc_name].current_delay + 100
	sprite:set_frame_delay(game_2_slots[npc_name].current_delay)

	-- test code (temporary code to win every game)
	--	 for k, v in pairs(game_2_slots) do
	--	    v.symbol = game_2_slots[npc_name].symbol
	--	    v.current_delay = game_2_slots[npc_name].current_delay + 100
	--	    v.sprite:set_frame_delay(v.current_delay)
	--	 end
	-----------

	sol.audio.play_sound("switch")
	map:hero_freeze()
      end
    else
      sol.audio.play_sound("wrong")
      map:dialog_start("rupee_house.pay_first")
    end
  end
end

-- Function called when the dialog box is being closed
-- dialog_id: name of the first message of the sequence that has just finished
-- answer: the answer of the question (0 or 1) or -1 if there was no question
function map:on_dialog_finished(dialog_id, answer)

  if dialog_id == "rupee_house.game_1.intro" or 
    dialog_id == "rupee_house.game_1.play_again_question" then
    -- if the dialog was the game 1 question

    if answer == 1 then
      -- the player does not want to play the game
      map:dialog_start("rupee_house.game_1.not_playing")
    else
      -- wants to play game 1

      if map:get_game():get_money() < 20 then
	-- not enough money
	sol.audio.play_sound("wrong")
	map:dialog_start("rupee_house.not_enough_money")

      else
	-- enough money: reset the 3 chests, pay and start the game
	map:chest_set_open("chest_1", false)
	map:chest_set_open("chest_2", false)
	map:chest_set_open("chest_3", false)

	map:get_game():remove_money(20)
	map:dialog_start("rupee_house.game_1.good_luck")
	playing_game_1 = true
      end
    end

  elseif dialog_id == "rupee_house.game_2.intro"  or
    dialog_id == "rupee_house.game_2.reward.none" then

    if answer == 1 then
      -- don't want to play the game
      map:dialog_start("rupee_house.game_2.not_playing")
    else
      -- wants to play game 2
      map:dialog_start("rupee_house.game_2.choose_bet")
    end

  elseif dialog_id == "rupee_house.game_2.choose_bet" then

    if answer == 0 then
      -- bet 5 rupees
      game_2_bet = 5
    else
      -- bet 20 rupees
      game_2_bet = 20
    end

    if map:get_game():get_money() < game_2_bet then
      -- not enough money
      sol.audio.play_sound("wrong")
      map:dialog_start("rupee_house.not_enough_money")
    else
      -- enough money: pay and start the game
      map:get_game():remove_money(game_2_bet)
      map:dialog_start("rupee_house.game_2.just_paid")
      playing_game_2 = true

      -- start the slot machine animations
      for k, v in pairs(game_2_slots) do
	v.symbol = -1
	v.current_delay = v.initial_delay
	v.sprite:set_animation("started")
	v.sprite:set_frame_delay(v.current_delay)
	v.sprite:set_frame(v.initial_frame)
	v.sprite:set_paused(false)
      end
    end
  elseif string.find(dialog_id, "^rupee_house.game_2.reward.") then
    -- reward in game 2
    map:get_game():add_money(game_2_reward)

  elseif dialog_id == "rupee_house.game_3.intro" or 
    dialog_id == "rupee_house.game_3.restart_question" then
    -- if the dialog was the game 3 question

    if answer == 1 then
      -- don't want to play the game
      map:dialog_start("rupee_house.game_3.not_playing")
    else
      -- wants to play game 3

      if map:get_game():get_money() < 10 then
	-- not enough money
	sol.audio.play_sound("wrong")
	map:dialog_start("rupee_house.not_enough_money")

      else
	-- enough money: reset the game, pay and start the game

	reset_blocks()
	map:tile_set_enabled("game_3_barrier_1", false)
	map:tile_set_enabled("game_3_barrier_2", false)
	map:tile_set_enabled("game_3_barrier_3", false)
	map:tile_set_enabled("game_3_middle_barrier", false)
	if game_3_timer ~= nil then
	  game_3_timer:stop()
	  game_3_timer = nil
	end

	map:get_game():remove_money(10)
	map:dialog_start("rupee_house.game_3.go")
	playing_game_3 = true
      end
    end

  elseif dialog_id == "rupee_house.game_3.go" then 
    game_3_timer = sol.timer.start(8000, game_3_timeout)
    game_3_timer:set_with_sound(true)
    map:sensor_set_enabled("game_3_sensor", true);

  -- stop game 3 when the player founds the piece of heart
  elseif string.find(dialog_id, "^found_piece_of_heart") then
    map:tile_set_enabled("game_3_final_barrier", false)
    sol.audio.play_sound("secret")
    playing_game_3 = false
  end
end

-- Function called when the player opens an empty chest (i.e. a chest
-- whose feature is to call the script).
-- chest_name: name of the chest being open
function map:on_chest_empty(chest_name)

  if not playing_game_1 then
    -- trying to open a chest but not playing yet
    map:dialog_start("rupee_house.pay_first") -- the game man is angry
    map:chest_set_open(chest_name, false) -- close the chest again
    sol.audio.play_sound("wrong")
    map:hero_unfreeze() -- restore the control
  else
    -- give a random reward
    local index = math.random(#game_1_rewards)
    local amount = game_1_rewards[index]
    if amount == 50 and not already_played_game_1 then
      -- don't give 50 rupees at the first attempt
      amount = 5
    end

    -- give the rupees
    if (amount == 5) then
      map:treasure_give("rupee", 2, -1)
    elseif (amount == 20) then
      map:treasure_give("rupee", 3, -1)
    elseif (amount == 50) then
      map:treasure_give("rupee", 4, -1)
    end

    if amount == 50 then
      -- the maximum reward was found: the game will now refuse to let the hero play again
      map:get_game():set_boolean(16, true)
    end

    playing_game_1 = false
    already_played_game_1 = true
  end
end

-- Function called when the timer of game 3 ends.
function game_3_timeout()
  sol.audio.play_sound("door_closed")
  map:tile_set_enabled("game_3_middle_barrier", true)
end

-- Function called when a sensor is activated
function map:on_hero_on_sensor(sensor_name)

  if sensor_name == "game_3_sensor" then
    -- stop the timer when the player reaches this point
    if game_3_timer ~= nil then
      game_3_timer:stop()
      game_3_timer = nil
    end
    sol.audio.play_sound("secret")
    map:sensor_set_enabled("game_3_sensor", false)
  end
end

-- Updates the slot machine
function map:on_update()

  if playing_game_2 then

    -- stop the reels when necessary
    local nb_finished = 0
    for k, v in pairs(game_2_slots) do
      if sol.main.sprite_is_paused(v.sprite) then
	nb_finished = nb_finished + 1
      end
    end

    for k, v in pairs(game_2_slots) do
      local frame = sol.main.sprite_get_frame(v.sprite)

      if not sol.main.sprite_is_paused(v.sprite) and frame == v.symbol * 3 then
	v.sprite:set_paused(true)
	v.initial_frame = frame
	nb_finished = nb_finished + 1

	if nb_finished < 3 then
	  map:hero_unfreeze()
	else
	  playing_game_2 = false
	  game_2_timer = sol.timer.start(500, game_2_timeout)
	end
      end
    end
  end
end

-- This function gives the reward to the player in the slot machine game
function game_2_timeout()

  -- see if the player has won
  local i = 1
  local green_found = false
  local blue_found = false
  local red_found = false
  local symbols = {-1, -1, -1};
  for k, v in pairs(game_2_slots) do
    symbols[i] = v.symbol

    if symbols[i] == 0 then
      green_found = true
    elseif symbols[i] == 2 then
      blue_found = true
    elseif symbols[i] == 4 then
      red_found = true
    end

    i = i + 1
  end

  if symbols[1] == symbols[2] and symbols[2] == symbols[3] then
    -- three identical symbols

    if symbols[1] == 0 then -- 3 green rupees
      map:dialog_start("rupee_house.game_2.reward.green_rupees")
      game_2_reward = 5 * game_2_bet
    elseif symbols[1] == 2 then -- 3 blue rupees
      map:dialog_start("rupee_house.game_2.reward.blue_rupees")
      game_2_reward = 7 * game_2_bet
    elseif symbols[1] == 4 then -- 3 red rupees
      map:dialog_start("rupee_house.game_2.reward.red_rupees")
      game_2_reward = 10 * game_2_bet
    elseif symbols[1] == 5 then -- 3 Yoshi
      map:dialog_start("rupee_house.game_2.reward.yoshi")
      game_2_reward = 20 * game_2_bet
    else -- other symbol
      map:dialog_start("rupee_house.game_2.reward.same_any")
      game_2_reward = 4 * game_2_bet
    end

  elseif green_found and blue_found and red_found then
    -- three rupees with different colors
    map:dialog_start("rupee_house.game_2.reward.different_rupees")
    game_2_reward = 15 * game_2_bet
  else
    map:dialog_start("rupee_house.game_2.reward.none")
    game_2_reward = 0
  end

  if game_2_reward ~= 0 then
    sol.audio.play_sound("secret")
  else
    sol.audio.play_sound("wrong")
  end

  map:hero_unfreeze()
end

function reset_blocks()

  for i = 3, 16 do
    map:block_reset("block_" .. i)
  end
end


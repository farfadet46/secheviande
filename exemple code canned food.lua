-- [[..]]
-- code from : https://github.com/h-v-smacker/canned_food/blob/master/init.lua

if minetest.get_modpath("unified_inventory") and unified_inventory.register_craft_type then
		unified_inventory.register_craft_type("pickling", {
				description = "Dark room, wooden shelf",
				icon = "canned_food_pickling_icon.png",
				width = 1,
				height = 1,
				uses_crafting_grid = false,
		})
end


-- [[..]]

local lbm_list = {}

-- creating all objects with one universal scheme
for product, def in pairs(canned_food_definitions) do
	if minetest.get_modpath(def.found_in) then
	--if minetest.global_exists(def.found_in) then
		if def.sugar and minetest.get_modpath("farming") or not def.sugar then
			
			-- general description
			
			local nodetable = {
				description = def.proper_name,
				drawtype = "plantlike",
				tiles = {"canned_food_" .. product .. ".png"},
				inventory_image = "canned_food_" .. product .. ".png",
				wield_image = "canned_food_" .. product .. ".png",
				paramtype = "light",
				is_ground_content = false,
				walkable = false,
				selection_box = {
					type = "fixed",
					fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
				},
				groups = { canned_food = 1, 
			                 vessel = 1, 
			                 dig_immediate = 3, 
			                 attached_node = 1 },
				-- canned food prolongs shelf life IRL, but in minetest food never
				-- goes bad. Here, we increase the nutritional value instead.
				on_use = minetest.item_eat(
						math.floor (def.orig_nutritional_value * def.amount * 1.33)
						+ (def.sugar and 1 or 0), "vessels:glass_bottle"),
				-- the empty bottle stays, of course
				sounds = default.node_sound_glass_defaults(),
			}
			
			
			if not def.transforms then
			-- introducing a new item, a bit more nutricious than the source 
			-- material when sugar is used. Always stays the same.
				minetest.register_node("canned_food:" .. product, nodetable)
			
			else
			-- Some products involve marinating or salting, however there is no salt
			-- or vingerar in minetest; instead we imitate this more complex process
			-- by putting the jar on a wooden shelf in a dark room for a long while.
			-- The effort is rewarded accordingly.
			
				-- adding transformation code
				nodetable.on_construct = function(pos)
						local t = minetest.get_node_timer(pos)
						t:start(180)
					end
					
				nodetable.on_timer = function(pos)
						-- if light level is 11 or less, and wood is nearby, there is 1 in 10 chance...
						if minetest.get_node_light(pos) > 11 or 
						   not minetest.find_node_near(pos, 1, {"group:wood"}) 
						   or math.random() > 0.1 then
							return true
						else
							minetest.set_node(pos, {name = "canned_food:" .. product .."_plus"})
							return false
						end
					end
			
				minetest.register_node("canned_food:" .. product, nodetable)
				
				-- add node to the list for LBM
				table.insert(lbm_list, "canned_food:" .. product)
				
				-- a better version
				minetest.register_node("canned_food:" .. product .."_plus", {
					description = def.transforms,
					drawtype = "plantlike",
					tiles = {"canned_food_" .. product .. ".png^canned_food_paper_lid_cover.png"},
					inventory_image = "canned_food_" .. product .. ".png^canned_food_paper_lid_cover.png",
					wield_image = "canned_food_" .. product .. ".png^canned_food_paper_lid_cover.png",
					paramtype = "light",
					is_ground_content = false,
					walkable = false,
					selection_box = {
						type = "fixed",
						fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
					},
					groups = { canned_food = 1, 
						vessel = 1, 
						dig_immediate = 3, 
						attached_node = 1,
						not_in_creative_inventory = 1 },
					-- the reward for putting the food in a cellar is even greater 
					-- than for merely canning it.
					on_use = minetest.item_eat(
							(math.floor(def.orig_nutritional_value * def.amount * 1.33)
							+ (def.sugar and 1 or 0))*2, "vessels:glass_bottle"),
					-- the empty bottle stays, of course
					sounds = default.node_sound_glass_defaults(),
				})
				
				-- register the recipe with unified inventory
				if minetest.get_modpath("unified_inventory") and unified_inventory.register_craft then
					unified_inventory.register_craft({
						type = "pickling",
						output = "canned_food:" .. product .."_plus",
						items = {"canned_food:" .. product},
					})
				end
				
			end
			
			-- a family of shapeless recipes, with sugar for jams
			-- except for apple: there should be at least 1 jam guaranteed
			-- to be available in vanilla game (and mushrooms are the guaranteed
			-- regular - not sweet - canned food)
			local ingredients = {"vessels:glass_bottle"}
			local max = 8
			if def.sugar then
				table.insert(ingredients, "farming:sugar")
				max = 7
			end
			-- prevent creation of a recipe with more items than there are slots
			-- left in the 9-tile craft grid
			if def.amount > max then 
				def.amount = max 
			end
			for i=1,def.amount do
				table.insert(ingredients, def.obj_name)
			end
			minetest.register_craft({
				type = "shapeless",
				output = "canned_food:" .. product,
				recipe = ingredients
			})
		end
	end
end


-- LBM to start timers on existing, ABM-driven nodes
minetest.register_lbm({
	name = "canned_food:timer_init",
	nodenames = lbm_list,
	run_at_every_load = false,
	action = function(pos)
		local t = minetest.get_node_timer(pos)
		t:start(180)
	end,
})

-- The Moor has done his duty, the Moor can go
canned_food_definitions = nil
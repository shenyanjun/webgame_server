
require("pet_fight.matrix.matrix_obj")
require("pet_fight.matrix.matrix_container")
require("pet_fight.matrix.matrix_mgr")

require("pet_fight.pet.pet_obj")
require("pet_fight.pet.pet_bag")
require("pet_fight.pet.pet_container")


require("pet_fight.skill.skill_obj")
require("pet_fight.skill.skill_container")
require("pet_fight.skill.skill_mgr")

require("pet_fight.strategy.strategy_obj")
require("pet_fight.strategy.strategy_container")

require("pet_fight.vedio.vedio")
require("pet_fight.vedio.vedio_container")
require("pet_fight.vedio.vedio_mgr")

require("pet_fight.pet_syn_mgr")
require("pet_fight.pet_vs_container")
require("pet_fight.pet_vs_process")
require("pet_fight.pet_vs_mgr")
require("pet_fight.pet_sort_mgr")

g_matrix_mgr = Matrix_mgr()
g_skill_mgr = Skill_mgr()
g_vedio_mgr = Vedio_mgr()
g_pet_vs_mgr = Pet_vs_mgr()
g_pet_sort_mgr = Pet_sort_mgr()
g_pet_vs_mgr:load()




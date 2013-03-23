

require("reward.gm_function_reward.gm_reward_loader")
require("reward.gm_function_reward.gm_reward_mgr")
require("reward.gm_function_reward.gm_reward_obj")
require("reward.gm_function_reward.gm_reward_process")


g_online_reward = Reward_gm_mgr()
g_online_reward:create_function()


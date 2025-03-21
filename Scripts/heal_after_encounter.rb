############################################ 
#                                          # 
#     HEAL AFTER ENCOUNTER SCRIPT v1.0     # 
#                                          # 
#     Community DLC Content for VX Ace     # 
#                                          # 
# Created by Jason "Wavelength" Commander  # 
#                                          # 
############################################ 

# No matter how badly he's injured - be it from gunshot, blade, burning, acid,
#   you name it - an action-adventure hero never ends up with permanent scars... 
#                                                 ~ TVTropes, "Hollywood Healing" 


############################################ 
#                                          # 
#           ABOUT THIS SCRIPT              # 
#                                          # 
############################################ 

# This script will automatically heal the party after each encounter. 
#     This is not normally possible without a lot of messy eventing. 

# If you'd like, you can use the Setup Options to define how much HP/MP 
#     to restore after battle and under which circumstances the healing 
#     will occur. 

# This script is compatible with most other scripts, including the 
#     "Level-Up Healing" script that is also included in this pack. 
#     Use caution with other scripts that affect HP or MP directly 
#     after battle or modify how the "Death state" is interpreted. 

# As part of the Community DLC Pack, you may use this script royalty-free 
#     for commercial or noncommercial use in any RPG Maker project. 

# More of my work can be found at wavescripts.wordpress.com. 


############################################ 
#                                          # 
#         HOW TO USE THIS SCRIPT           # 
#                                          # 
############################################ 

# This script should be placed in the "Materials" section 
#     of the script editor.  In general, this script should 
#     be placed below other scripts that modify Game_Battler 
#     or Game_BattlerBase. 


############################################ 
#                                          # 
#       HEAL AFTER ENCOUNTER SETUP         # 
#                                          # 
############################################ 
  
# All of the following options can be left alone if desired, or you can 
#      modify them to better customize the script to your game. 

module Enc_Heal 
  
 # Heal Modes represent how the amount or HP or MP healed will be calculated. 
 #     0: No HP (MP) will be healed. 
 #     1: Amount of HP (MP) healed is a fixed amount. 
 #     2: Amount of HP (MP) healed is a percentage of MISSING HP (MP). 
 #     3: Amount of HP (MP) healed is a percentage of MAXIMUM HP (MP). 
 #     4: Amount of HP (MP) healed is determined by a formula. 
  
 HP_Heal_Mode = 3 
 MP_Heal_Mode = 3 
  
 # Heal Amounts are the amount/percentage of HP or MP healed when battle ends. 
 #     NOTE: If a Heal Mode is 4, enter a formula string instead of a number. 
 #     Use the keyword "me" to reference an actor's parameters (for example, 
 #     HP_Healing = "me.luk * 2" will restore health to each actor equal 
 #     to twice their Luck). 
  
 HP_Healing = 10 
 MP_Healing = 20 
  
 # Choose whether or not to remove the "Death state" at the end of battle. 
 #     (If KO is not removed, the KO'ed battler will not receive healing.) 
  
 Remove_KO = true 
  
 # Choose whether or not to run "End of Battle Healing" only for a victory, or 
 #     for any outcome whatsoever (victory/escape/abort/defeat).  If "true", HP 
 #     and MP will only be restored upon victory.  Note that Game Overs will 
 #     still occur if the party is wiped out in a battle that doesn't have the 
 #     "Continue even when Loser" option set. 
  
 Only_On_Win = true 
  
end 

############################################ 
#                                          # 
#               ICKY CODE!                 # 
#                                          # 
############################################ 

# Everything from here on represents the inner workings of the script. 
#       Please don't alter anything from here on unless you are an 
#       advanced scripter yourself (in which case, have at it!)   


class Game_Party < Game_Unit 
  
 # The modification to this class is to allow broader access to whether the 
 #   party won their last battle, necessary for the "Only On Win" option. 

 #-------------------------------------------------------------------------- 
 # * Public Instance Variables 
 #-------------------------------------------------------------------------- 
 attr_accessor   :won_battle         # whether the party won their last battle 

 #-------------------------------------------------------------------------- 
 # * Object Initialization 
 #-------------------------------------------------------------------------- 
 alias :init_with_result :initialize 
 def initialize 
   init_with_result 
   @won_battle = false 
 end 
  
end 

module BattleManager 
  
 class << self 

   #-------------------------------------------------------------------------- 
   # * End Battle 
   #     result : Result (0: Win 1: Escape 2: Lose) 
   #       This alias method stores whether you won your last battle, then 
   #       does the normal "Battle End" processing. 
   #-------------------------------------------------------------------------- 
   alias :battle_end_store_result :battle_end 
   def battle_end(result) 
     if result == 0 
       $game_party.won_battle = true 
     else 
       $game_party.won_battle = false 
     end 
     battle_end_store_result(result) 
   end 
    
 end 

end 

class Game_Battler < Game_BattlerBase 
  
 #-------------------------------------------------------------------------- 
 # * Processing at End of Battle 
 #     This alias method does the normal "On Battle End" processing for 
 #     a party member, then restores HP and MP (and removes KO) if appropriate. 
 #-------------------------------------------------------------------------- 
 alias :on_battle_end_heal :on_battle_end 
 def on_battle_end 
   # First, do the normal "On Battle End" processing 
   on_battle_end_heal 
   # Then, if either the party won the last battle, or gets to heal regardless, 
   #   start the "End of Battle Heal" process on the character. 
   if (($game_party.won_battle) or (!Enc_Heal::Only_On_Win)) 
     # If the Remove KO option is on, remove it. 
     if Enc_Heal::Remove_KO 
       remove_state(death_state_id) 
     end 
     # If the character is not KO'ed... 
     unless self.state?(death_state_id) 
       # Then heal the character's HP based on HP Heal Mode and HP Healing... 
       case Enc_Heal::HP_Heal_Mode 
       when 1 
         # Increase character's HP by the amount specified in HP_Healing 
         @hp += Enc_Heal::HP_Healing 
         # If character now has more HP than their max HP, set it to their max. 
         #   If they have less than 1 HP, set it to 1. 
         @hp = [[@hp, mhp].min, 1].max 
       when 2 
         @hp += (((Enc_Heal::HP_Healing * (mhp - @hp)) / 100.0) + 0.5).to_i 
         @hp = [[@hp, mhp].min, 1].max 
       when 3 
         @hp += (((Enc_Heal::HP_Healing * mhp) / 100.0) + 0.5).to_i 
         @hp = [[@hp, mhp].min, 1].max 
       when 4 
         me = self 
         @hp += (Kernel.eval(Enc_Heal::HP_Healing) rescue 0) 
         @hp = [[@hp, mhp].min, 1].max 
       else 
       end 
       # And also do the same for the character's MP. 
       case Enc_Heal::MP_Heal_Mode 
       when 1 
         @mp += Enc_Heal::MP_Healing 
         @mp = [[@mp, mmp].min, 0].max 
       when 2 
         @mp += (((Enc_Heal::MP_Healing * (mmp - @mp)) / 100.0) + 0.5).to_i 
         @mp = [[@mp, mmp].min, 0].max 
       when 3 
         @mp += (((Enc_Heal::MP_Healing * mmp) / 100.0) + 0.5).to_i 
         @mp = [[@mp, mmp].min, 0].max 
       when 4 
         me = self 
         @mp += (Kernel.eval(Enc_Heal::MP_Healing) rescue 0) 
         @mp = [[@mp, mmp].min, 0].max 
       else 
       end 
     end 
   end 
 end 
  
end
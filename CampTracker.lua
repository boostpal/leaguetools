class "Tracker"
require "MapPositionGOS"

function Tracker:__init()
    PrintChat("C41T CampTracker V0.5 (BETA) loaded")
    self:LoadMenu()
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
    Callback.Add(
        "Draw",
        function()
            self:Draw()
        end
    )
end

function Tracker:LoadMenu()
    self.JTracker 	= {}
    self.JTrackerList = {}

    --JungleTrackerTimersBlueSide
    self.Blue1Pos = nil
    self.Blue1Timer = -1000
    self.Wolf1Pos = nil
    self.Wolf1Timer = -1000
    self.Gromp1Pos = nil
    self.Gromp1Timer = -1000
    self.Chicken1Pos = nil
    self.Chicken1Timer = -1000
    self.Red1Pos = nil
    self.Red1Timer = -1000
    self.Krug1Pos = nil
    self.Krug1Timer = -1000

    --JungleTrackerTimersRedSide
    self.Blue2Pos = nil
    self.Blue2Timer = -1000
    self.Wolf2Pos = nil
    self.Wolf2Timer = -1000
    self.Gromp2Pos = nil
    self.Gromp2Timer = -1000
    self.Chicken2Pos = nil
    self.Chicken2Timer = -1000
    self.Red2Pos = nil
    self.Red2Timer = -1000
    self.Krug2Pos = nil
    self.Krug2Timer = -1000

    self.BaronPosition = nil
    self.BaronTimer = -1000
    self.DragonPosition = Vector()
    self.DragonTimer = -1000

    self.LastEnemyCamp = nil
    self.LastCampDied = nil
    self.LastCampDiedPos = nil
    self.DieTimer = 10
    self.ParseTick = 10
end

local Monsters = {}
local GameTimer = Game.Timer
local DrawText = Draw.Text
local DrawColor = Draw.Color
local ObjCount = Game.ObjectCount
local GameObj = Game.Object
local sqrt = math.sqrt
local HeroCount = GameHeroCount
local Heroes = GameHero

local function GetDistance(pos1, pos2)
	if(pos1 == nil or pos2 == nil) then return "Error" end
    local dx = pos1.x - pos2.x
    local dz = pos1.z - pos2.z
	return sqrt(dx*dx + dz*dz)
end

function Tracker:AlliesInRange(Position, Range)
    local Count = 0 --FeelsBadMan
    for i = 1, HeroCount() do 
		local Hero = Heroes(i)	
        if Hero.team == myHero.team and Hero.dead == false then
            if GetDistance(Hero.pos, Position) < Range then
                Count = Count + 1
            end
        end
    end
    return Count
end

function Tracker:GetAllJungleMinions()
    local JgMonsters = {}
    if self.ParseTick then
        if(GameTimer() > self.ParseTick) then
            for i = 0, ObjCount() do
                local Object = GameObj(i)
                if Object.team == 300 and Object.networkID then
                    Monsters[Object.networkID] = Object
                end
            end
            self.ParseTick = GameTimer() + 1
        end
    else
        self.ParseTick = GameTimer()
    end
    JgMonsters = Monsters
    return JgMonsters
end

function Tracker:ParseJungleMonsters()
    if self.ParseTick then
        if (GameTimer() > self.ParseTick) then
            self.JungleMonsters = Tracker:GetAllJungleMinions()
            self.ParseTick = GameTimer() --+0.1
        end
    else
        self.ParseTick = GameTimer()
    end
end

function Tracker:CampAlive(Position, Range, MonsterName)
    local Count = 0 --FeelsBadMan
    local MinionList = Tracker:GetAllJungleMinions()
    for i, Minion in pairs(MinionList) do	
        if Minion.team == 300 and Minion.dead == false then
            if GetDistance(Minion.pos, Position) < Range then
                if Minion.charName:find(MonsterName) then
                    Count = Count + 1
                end
            end
        end
    end
    return Count
end

function Tracker:GetMonsterSpawnTime(Minion)
    if self.JTracker[Minion.networkID] then
        --print(self.JTracker[Minion.networkID].Object.charName)
        local Timer = 135
        if Minion.charName == "Sru_Crab" then
            Timer = 150
        end
        if Minion.charName == "SRU_Blue" or Minion.charName == "SRU_Red" then
            Timer = 300
        end
        if Minion.visible == false then
            Timer = Timer - 3
        end
        if Minion.networkID and self.JTracker[Minion.networkID].Timer == nil or self.JTracker[Minion.networkID].Timer <= 0 then
            --print(GameTimer() + Timer)
            if Minion.dead then
                return GameTimer() + Timer
            end
        end
        return self.JTracker[Minion.networkID].SpawnTime
    end
    return 0.0			
end

function Tracker:GetMonsterTimer(Minion)
    if self.JTracker[Minion.networkID] then
        local Spawn = self.JTracker[Minion.networkID].SpawnTime
        --print(self.JTracker[Minion.networkID].Object.charName)
        if Spawn ~= nil then
            return Spawn - GameTimer()
        else
            return 0
        end
    end
    return nil
end

function Tracker:GetJungleTracker()
    local JTracker = {}
    local JungleList = Tracker:GetAllJungleMinions()
    for _, Minion in pairs(JungleList) do
        JTracker[Minion.networkID] = {
            Object		= Minion,
            Position 	= Minion.pos,
            SpawnTime	= self:GetMonsterSpawnTime(Minion),
            Timer		= self:GetMonsterTimer(Minion),
        }
    end
    return JTracker
end

function Tracker:GetJTimerList()
    local JTimerList = {}
    --print(JTimerList[1])
    --Monsters[#Monsters+1] = Object
    for _, Element in pairs(self.JTracker) do
        local Minion 		= Element.Object
        local Timer 		= Element.Timer
        --if GetDistance(Minion.pos, myHero.pos) < 500 then
            --Minion.BuffData:ShowAllBuffs()
        --end
        if Minion.dead then
            --print("d")
            if Minion.charName:find("Baron") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print("OK?")
                local StaticPos = Vector(4951, -71, 10432)
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3780.6279296875 52.463195800781 6443.98388671889
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.BaronTimer < GameTimer() and self:CampAlive(StaticPos, 2000, "Baron") == 0 then
                    self.BaronPosition = StaticPos
                    if Minion.visible then
                        self.BaronTimer = GameTimer() + 360
                    else
                        self.BaronTimer = GameTimer() + 357
                    end
                end
            end
            if Minion.charName:find("Dragon") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print("OK?")
                local StaticPos = Vector(9789, -71, 4398)
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3780.6279296875 52.463195800781 6443.98388671889
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.DragonTimer < GameTimer() and self:CampAlive(StaticPos, 2000, "Dragon") == 0 then
                    self.DragonPosition = StaticPos
                    if Minion.visible then
                        self.DragonTimer = GameTimer() + 300
                    else
                        self.DragonTimer = GameTimer() + 297
                    end
                end
            end
            if Minion.charName == "SRU_Blue" then
                local StaticPos = Vector(3734.9819335938, 52.791561126709, 7890.0)
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3734.9819335938 52.791561126709 52.791561126709
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Blue1Timer < GameTimer() then
                    self.Blue1Pos = StaticPos
                    if Minion.visible then
                        self.Blue1Timer = GameTimer() + 300
                    else
                        self.Blue1Timer = GameTimer() + 297
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Blue1"
                        end
                    end
                end
            end
            if Minion.charName == "SRU_Blue" then
                local StaticPos = Vector(11032.0, 51.723670959473, 7002.0)
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --11032.0 51.723670959473 7002.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Blue2Timer < GameTimer() then
                    self.Blue2Pos = StaticPos
                    if Minion.visible then
                        self.Blue2Timer = GameTimer() + 300
                    else
                        self.Blue2Timer = GameTimer() + 297
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Blue2"
                        end
                    end
                end
            end
            --print(Minion.charName)
            if Minion.charName:find("wolf") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                --print("OK?")
                local StaticPos = Vector(3780.6279296875, 52.463195800781, 6443.98388671889)
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --3780.6279296875 52.463195800781 6443.98388671889
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                local MonstersAlive = self:CampAlive(StaticPos, 2000, "wolf")
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Wolf1Timer < GameTimer() and MonstersAlive == 0 then
                    self.Wolf1Pos = StaticPos
                    if self.LastCampDied == "Wolf1" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Wolf1Timer = GameTimer() + 135
                    else
                        self.Wolf1Timer = GameTimer() + 132
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Wolf1"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, StaticPos) < 2000 and self:AlliesInRange(StaticPos, 2000) == 0 and MonstersAlive < 3 and MonstersAlive > 0 then
                        self.LastCampDied = "Wolf1"
                        self.LastCampDiedPos = StaticPos
                    end
                end
            end
            if Minion.charName:find("wolf") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(11008.0, 62.131362915039, 8386.0)
                --print(Minion.pos.x, Minion.pos.y, Minion.pos.z) --11008.0 62.131362915039 8386.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                local MonstersAlive = self:CampAlive(StaticPos, 2000, "wolf")
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Wolf2Timer < GameTimer() and MonstersAlive == 0 then
                    self.Wolf2Pos = StaticPos
                    if self.LastCampDied == "Wolf2" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Wolf2Timer = GameTimer() + 135
                    else
                        self.Wolf2Timer = GameTimer() + 132
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Wolf2"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, StaticPos) < 2000 and self:AlliesInRange(StaticPos, 2000) == 0 and MonstersAlive < 3 and MonstersAlive > 0 then
                        self.LastCampDied = "Wolf2"
                        self.LastCampDiedPos = StaticPos
                    end
                end
            end
            if Minion.charName == "SRU_Gromp" then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(2112.0  ,       51.777313232422 ,       8450.0)
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Gromp1Timer < GameTimer() then
                    self.Gromp1Pos = StaticPos
                    if Minion.visible then
                        self.Gromp1Timer = GameTimer() + 135
                    else
                        self.Gromp1Timer = GameTimer() + 132
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Gromp1"
                        end
                    end
                end
            end
            if Minion.charName == "SRU_Gromp" then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(12702.0 ,       51.691425323486 ,       6444.0)
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Gromp2Timer < GameTimer() then
                    self.Gromp2Pos = StaticPos
                    if Minion.visible then
                        self.Gromp2Timer = GameTimer() + 135
                    else
                        self.Gromp2Timer = GameTimer() + 132
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Gromp2"
                        end
                    end
                end
            end
            if Minion.charName:find("Krug") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(8482.470703125  ,       50.648094177246 ,       2705.9479980469)
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                local MonstersAlive = self:CampAlive(StaticPos, 2000, "Krug")
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Krug1Timer < GameTimer() and MonstersAlive == 0 then
                    self.Krug1Pos = StaticPos
                    if self.LastCampDied == "Krug1" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Krug1Timer = GameTimer() + 135
                    else
                        self.Krug1Timer = GameTimer() + 132
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Krug1"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, StaticPos) < 2000 and self:AlliesInRange(StaticPos, 2000) == 0 and MonstersAlive < 2 and MonstersAlive > 0 then
                        self.LastCampDied = "Krug1"
                        self.LastCampDiedPos = StaticPos
                    end
                end
            end
            if Minion.charName:find("Krug") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(6317.0922851562 ,       56.47679901123  ,       12146.458007812)
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                local MonstersAlive = self:CampAlive(StaticPos, 2000, "Krug")
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Krug2Timer < GameTimer() and MonstersAlive == 0 then
                    self.Krug2Pos = StaticPos
                    if self.LastCampDied == "Krug2" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Krug2Timer = GameTimer() + 135
                    else
                        self.Krug2Timer = GameTimer() + 132
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Krug2"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, StaticPos) < 2000 and self:AlliesInRange(StaticPos, 2000) == 0 and MonstersAlive < 2 and MonstersAlive > 0 then
                        self.LastCampDied = "Krug2"
                        self.LastCampDiedPos = StaticPos
                    end
                end
            end
            if Minion.charName == "SRU_Red" then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(7772.0  ,       53.933303833008 ,       4028.0)
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Red1Timer < GameTimer() then
                    self.Red1Pos = StaticPos
                    if Minion.visible then
                        self.Red1Timer = GameTimer() + 300
                    else
                        self.Red1Timer = GameTimer() + 297
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Red1"
                        end
                    end
                end
            end
            if Minion.charName == "SRU_Red" then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(7108.0  ,       56.300552368164 ,       10892.0)
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Red2Timer < GameTimer() then
                    self.Red2Pos = StaticPos
                    if Minion.visible then
                        self.Red2Timer = GameTimer() + 300
                    else
                        self.Red2Timer = GameTimer() + 297
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Red2"
                        end
                    end
                end
            end
            if Minion.charName:find("Razor") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(6823.8950195312 ,       54.782833099365 ,       5507.755859375)
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                local MonstersAlive = self:CampAlive(StaticPos, 2000, "Razor")
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Chicken1Timer < GameTimer() and MonstersAlive == 0 then
                    self.Chicken1Pos = StaticPos
                    if self.LastCampDied == "Chicken1" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Chicken1Timer = GameTimer() + 135
                    else
                        self.Chicken1Timer = GameTimer() + 132
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Chicken1"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, StaticPos) < 2000 and self:AlliesInRange(StaticPos, 2000) == 0 and MonstersAlive < 6 and MonstersAlive > 0 then
                        self.LastCampDied = "Chicken1"
                        self.LastCampDiedPos = StaticPos
                    end
                end
            end
            if Minion.charName:find("Razor") then -- "SRU_Krug" "SRU_Red" "Sru_Crab" "SRU_Blue" "SRU_Murkwolf" "SRU_Razorbeak" "SRU_Gromp"
                local StaticPos = Vector(7986.9970703125 ,       52.347938537598 ,       9471.388671875)
                --print(Minion.pos.x,",",Minion.pos.y,",",Minion.pos.z) --2102.0  51.777328491211 8454.0
                --Render:DrawCircle(StatB1Pos, 50,255,255,255,255)
                local MonstersAlive = self:CampAlive(StaticPos, 2000, "Razor")
                if GetDistance(Minion.pos, StaticPos) < 2000 and self.Chicken2Timer < GameTimer() and MonstersAlive == 0 then
                    self.Chicken2Pos = StaticPos
                    if self.LastCampDied == "Chicken2" then
                        self.LastCampDied = nil
                        self.LastCampDiedPos = nil
                    end
                    if Minion.visible then
                        self.Chicken2Timer = GameTimer() + 135
                    else
                        self.Chicken2Timer = GameTimer() + 132
                        if self:AlliesInRange(StaticPos, 2000) == 0 then
                            self.LastEnemyCamp = "Chicken2"
                        end
                    end
                else
                    if Minion.visible == false and GetDistance(Minion.pos, StaticPos) < 2000 and self:AlliesInRange(StaticPos, 2000) == 0 and MonstersAlive < 6 and MonstersAlive > 0 then
                        self.LastCampDied = "Chicken2"
                        self.LastCampDiedPos = StaticPos
                    end
                end
            end
        end
    end
    return JTimerList
end

function Tracker:DrawCampTimer()
    local ExtraDist2Camp = 1.15
    if --[[self.CampMarker.Value == 1 and]] self.LastCampDied ~= nil and self.LastCampDiedPos ~= nil then
        if os.clock() - self.DieTimer > 5  then
            self.DieTimer = os.clock()
        else
            if os.clock() > self.DieTimer + 4 then
                self.LastCampDied = nil
                self.LastCampDiedPos = nil
            end
        end
        local R, G, B = 235, 168, 52
        local MinionPos 	= self.LastCampDiedPos
        if MinionPos then
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 131, 235, 52
            DrawText("X", 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
    end
    if --[[self.DrawJungleTimers.Value == 1]] 1 == 1 then
        if self.BaronTimer > GameTimer() + 1 then
            local Timer = self.BaronTimer - GameTimer()
            local MinionPos 	= self.BaronPosition
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.DragonTimer > GameTimer() + 1 then
            local Timer = self.DragonTimer - GameTimer()
            local MinionPos 	= self.DragonPosition
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Blue1Timer > GameTimer() + 1 then
            --print("Working")
            local Timer = self.Blue1Timer - GameTimer()
            local MinionPos 	= self.Blue1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Blue1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Blue2Timer > GameTimer() + 1 then
            --print("Working")
            local Timer = self.Blue2Timer - GameTimer()
            local MinionPos 	= self.Blue2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Blue2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Wolf1Timer > GameTimer() + 1 then
            --print("working")
            local Timer = self.Wolf1Timer - GameTimer()
            local MinionPos 	= self.Wolf1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Wolf1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Wolf2Timer > GameTimer() + 1 then
            --print("working")
            local Timer = self.Wolf2Timer - GameTimer()
            local MinionPos 	= self.Wolf2Pos
            local MapPos		= MinionPos:ToMM() --local MapPos		= Vector() GameHud:World2Map(MinionPos, MapPos)
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Wolf2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Krug1Timer > GameTimer() + 1 then
            local Timer = self.Krug1Timer - GameTimer()
            local MinionPos 	= self.Krug1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            --print("Krug1")
            if self.LastEnemyCamp == "Krug1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Krug2Timer > GameTimer() + 1 then
            local Timer = self.Krug2Timer - GameTimer()
            local MinionPos 	= self.Krug2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            --print("Krug2")
            if self.LastEnemyCamp == "Krug2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Red1Timer > GameTimer() + 1 then
            local Timer = self.Red1Timer - GameTimer()
            local MinionPos 	= self.Red1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Red1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Red2Timer > GameTimer() + 1 then
            local Timer = self.Red2Timer - GameTimer()
            local MinionPos 	= self.Red2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Red2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 20, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Chicken1Timer > GameTimer() + 1 then
            local Timer = self.Chicken1Timer - GameTimer()
            local MinionPos 	= self.Chicken1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Chicken1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Chicken2Timer > GameTimer() + 1 then
            local Timer = self.Chicken2Timer - GameTimer()
            local MinionPos 	= self.Chicken2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Chicken2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Gromp1Timer > GameTimer() + 1 then
            local Timer = self.Gromp1Timer - GameTimer()
            local MinionPos 	= self.Gromp1Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Gromp1" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
        if self.Gromp2Timer > GameTimer() + 1 then
            local Timer = self.Gromp2Timer - GameTimer()
            local MinionPos 	= self.Gromp2Pos
            local MapPos		= MinionPos:ToMM()
            local R, G, B = 255, 255, 255
            if self.LastEnemyCamp == "Gromp2" then
                R, G, B = 235, 64, 52
            end
            if 15 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 235, 168, 52
            end
            if 3 > Timer - (GetDistance(MinionPos, myHero.pos)* ExtraDist2Camp) / myHero.ms then
                R, G, B = 131, 235, 52
            end
            DrawText(string.format("%.0f", Timer), 17, MapPos.x-10, MapPos.y-12, DrawColor(255,R,G,B))
        end
    end
end

function Tracker:Tick()
end

function Tracker:Draw()
    --Tracker:ParseJungleMonsters()
    self.JTracker 	= self:GetJungleTracker()
    self:GetJTimerList()
    self:DrawCampTimer()
end

function OnLoad()
    Tracker()
end
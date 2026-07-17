--[[
  ____                    _          _   _   ___  __
 / ___| _ __   __ _  __ _| |__   ___| |_| |_(_) \/ /
 \___ \| '_ \ / _` |/ _` | '_ \ / _ \ __| __| |\  /
  ___) | |_) | (_| | (_| | | | |  __/ |_| |_| |/  \
 |____/| .__/ \__,_|\__, |_| |_|\___|\__|\__|_/_/\_\
       |_|          |___/
  ____                                      _    _               ____                        _            _    _    _       _            _____
 |  _ \  ___ __      __ ___  _ __  ___   __| |  | |__   _   _   / ___|  _ __    __ _   __ _ | |__    ___ | |_ | |_ (_) ___ | |_  ___    |_   _|___   __ _  _ __ ___
 | |_) |/ _ \\ \ /\ / // _ \| '__|/ _ \ / _` |  | '_ \ | | | |  \___ \ | '_ \  / _` | / _` || '_ \  / _ \| __|| __|| |/ __|| __|/ __|     | | / _ \ / _` || '_ ` _ \
 |  __/| (_) |\ V  V /|  __/| |  |  __/| (_| |  | |_) || |_| |   ___) || |_) || (_| || (_| || | | ||  __/| |_ | |_ | |\__ \| |_ \__ \     | ||  __/| (_| || | | | | |
 |_|    \___/  \_/\_/  \___||_|   \___| \__,_|  |_.__/  \__, |  |____/ | .__/  \__,_| \__, ||_| |_| \___| \__| \__||_||___/ \__||___/_____|_| \___| \__,_||_| |_| |_|
                                                        |___/          |_|            |___/                                         |_____|
    Project: Universal_SilentAim * SpaghettiX
    Developer: ul0verrs
    StartTime: 13/7/2026
    UpdateTime: 13/7/2026
]]

-- /LCOALS
local services, utils, share = {}, {}, {}
local genv                  = getgenv()
local getService            = function(obj, name) return cloneref((obj or game):GetService(name or obj)) end
local waitForChild          = game.WaitForChild
local findFirstChild        = game.FindFirstChild
local findFirstChildofClass = game.FindFirstChildOfClass
local getChildren           = game.GetChildren
local Vector3_new           = Vector3.new
local Vector2_new           = Vector2.new

local inf    = math.huge
local random = math.random

services.Players    = getService(game, "Players")
services.UserInput  = getService(game, "UserInputService")
services.RunService = getService(game, "RunService")

share.loc_Plr = services.Players.LocalPlayer

local stepped = services.RunService.RenderStepped


genv.spgt_silentaim_cfg = genv.spgt_silentaim_cfg or {
    Mode = {
        Raycast  = true,
        MouseHit = false,
        Camera   = false,
    },

    HitPart = {
        Part = {
            Head  = true,
            Torso = false,
            Hrp   = false,
        },

        RandomMode = {
            Enabled        = false,
            HeadShotChance = 0.9,
            RandomHitPart  = {
                Torso = true,
                Hrp   = true,
            },
        },
    },

    FOV = 70,
}



-- /UTILS
function utils:getAllPlayers(ExcludeLocalPlayer: boolean): { Player }
    local plrslist = {}

    for _, plr in ipairs(services.Players:GetPlayers()) do
        if ExcludeLocalPlayer == true and plr == share.loc_Plr then continue end
        table.insert(plrslist, plr)
    end

    return plrslist
end

-- /UI
do

end

-- /UPDATE
do
    Update = {}

    Update.stepped = function()
        local current_locplr = services.Players.LocalPlayer
        share.loc_Plr = current_locplr
    end

    Update.init = function()
        stepped:Connect(Update.stepped)
    end
end

-- /MAIN
do
    local silentaim = {}

    local PartMap = {
        Head  = "Head",
        Torso = "Torso",
        Hrp   = "HumanoidRootPart",
    }

    function canAttack(tar_plr: Player): boolean
        local tar_char = tar_plr.Character ; if not tar_char then return false end

        local radius = genv.spgt_silentaim_cfg.FOV or 70

        local head = findFirstChild(tar_char, "Head") ; if not head or not head:IsA("BasePart") then return false end

        local camera = workspace.CurrentCamera ; if not camera then return false end

        local screenpos, onscreen = camera:WorldToViewportPoint(head.Position) ; if not onscreen then return false end

        local mousePos = services.UserInput:GetMouseLocation()
        local dx = screenpos.X - mousePos.X
        local dy = screenpos.Y - mousePos.Y
        local dist = math.sqrt(dx * dx + dy * dy)

        return dist <= radius
    end

    function silentaim:findCloestPlayer(): (Player, number)
        local loc_mouse      = share.loc_Plr:GetMouse()
        local camera         = workspace.CurrentCamera
        local mouseScreenPos = Vector2_new(loc_mouse.X, loc_mouse.Y)

        local closestPlr = nil
        local minDist    = inf

        for _, plr in ipairs(utils:getAllPlayers(true)) do
            if not canAttack(plr) then continue end

            local char = plr.Character ; if not char then continue end
            local hrp  = findFirstChild(char, "HumanoidRootPart") or findFirstChild(char, "Torso") or findFirstChild(char, "Head") ; if not hrp or not hrp:IsA("BasePart") then continue end

            local vector, onScreen = camera:WorldToScreenPoint(hrp.Position)
            if not onScreen then continue end

            local hrpScreenPos = Vector2_new(vector.X, vector.Y)
            local dist         = (mouseScreenPos - hrpScreenPos).Magnitude

            if dist < minDist then
                minDist    = dist
                closestPlr = plr
            end
        end

        if not closestPlr then return nil end
        return closestPlr, minDist
    end

    function silentaim:getAttackablePartFromPlayer(tar_plr: Player): BasePart
        local tar_char = tar_plr.Character ; if not tar_char then return nil end

        local cfg = genv.spgt_silentaim_cfg.HitPart
        local randomMode = cfg.RandomMode
        
        if not (randomMode and randomMode.Enabled) then
            if cfg.Part.Head  then return findFirstChild(tar_char, PartMap.Head)  end
            if cfg.Part.Torso then return findFirstChild(tar_char, PartMap.Torso) end
            if cfg.Part.Hrp   then return findFirstChild(tar_char, PartMap.Hrp)   end
            return nil
        end

        if random() <= randomMode.HeadShotChance then
            return findFirstChild(tar_char, PartMap.Head)
        end

        local choices = {}
        if randomMode.RandomHitPart.Torso then table.insert(choices, PartMap.Torso) end
        if randomMode.RandomHitPart.Hrp   then table.insert(choices, PartMap.Hrp)   end

        if #choices == 0 then return findFirstChild(tar_char, PartMap.Head) end
        return findFirstChild(tar_char, choices[random(1, #choices)])
    end

    -- /HOOKS
    do
        -- /RAYCAST
        do
            if genv.spgt_silentaim_cfg.Mode.Raycast == false then return end

            local raycast ; raycast = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args   = {...}

                if self ~= workspace or checkcaller() or method ~= "Raycast" then return raycast(self, ...) end

                local tar_plr = silentaim:findCloestPlayer(share.loc_Plr)       ; if not tar_plr then return raycast(self, ...) end
                local tar_part = silentaim:getAttackablePartFromPlayer(tar_plr) ; if not tar_part or not tar_part:IsA("BasePart") then return raycast(self, ...) end

                local origin    = args[1]
                local target    = tar_part.Position
                local direction = (target - origin).Unit * 10000
                args[2] = direction

                return raycast(self, unpack(args))
            end))
        end

        -- /MOUSE_HIT
        do
            if genv.spgt_silentaim_cfg.Mode.MouseHit == false then return end

            local mouse = share.loc_Plr:GetMouse()
            local mt    = getmetatable(mouse)
            local old   = mt.__index ; setreadonly(mt, false)

            mt.__index = newcclosure(function(self, key)
                if checkcaller() or key ~= "Hit" then return old(self, key) end

                local tar_plr = silentaim:findCloestPlayer(share.loc_Plr)       ; if not tar_plr then return old(self, key) end
                local tar_part = silentaim:getAttackablePartFromPlayer(tar_plr) ; if not tar_part or not tar_part:IsA("BasePart") then return old(self, key) end

                return tar_part.CFrame
            end) ; setreadonly(mt, true)
        end

        -- /CAMERA
        do
            if genv.spgt_silentaim_cfg.Mode.Camera == false then return end

            local camera = workspace.CurrentCamera
            local mt     = getmetatable(camera)
            local old    = mt.__index ; setreadonly(mt, false)

            mt.__index = newcclosure(function(self, key)
                if checkcaller() or key ~= "CFrame" then return old(self, key) end

                local realCFrame = old(self, key)
                local tar_plr    = silentaim:findCloestPlayer(share.loc_Plr)    ; if not tar_plr then return realCFrame end
                local tar_part = silentaim:getAttackablePartFromPlayer(tar_plr) ; if not tar_part or not tar_part:IsA("BasePart") then return realCFrame end

                return CFrame.new(realCFrame.Position, tar_part.Position)
            end) ; setreadonly(mt, true)
        end
    end
end

-- /INIT
do
    Update:init()
end
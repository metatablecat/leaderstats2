-- metatablecat 2023
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local ATTRIBUTAL_LEADERSTAT_PREFIX = "stat_"
local ATTRIBUTAL_LEADERSTAT_LENGTH = 5

local API = script.InternalAPI
local Types = require(API.Types)
local Player = require(API.Player)
local Team = require(API.Team)
local Event = require(API.Event)

local listplayers = {}
local listteams = {}

--=================================--

local PlayerAdded: Types.Event<Types.ListPlayer> = Event()
local PlayerRemoving: Types.Event<Types.ListPlayer> = Event()
local TeamAdded: Types.Event<Types.ListTeam> = Event()
local TeamRemoving: Types.Event<Types.ListTeam> = Event()
local FullyInitialised: Types.Event<> = Event()
local AllLeaderstatsReshaped: Types.Event<> = Event()

local LeaderstatsCount = {}
local AllLeaderstatsList = {}

local Public = {}
Public.PlayerAdded = PlayerAdded.Signal
Public.PlayerRemoving = PlayerRemoving.Signal
Public.TeamAdded = TeamAdded.Signal
Public.TeamRemoving = TeamRemoving.Signal
Public.Ready = FullyInitialised.Signal
Public.AllLeaderstatShapeChanged = AllLeaderstatsReshaped.Signal
Public.IsReady = false
Public.AllLeaderstats = AllLeaderstatsList

function Public:GetPlayers()
	return table.clone(listplayers)
end

function Public:GetTeams()
	return table.clone(listteams)
end

function Public:GetPlayerByPlayer(player)
	return listplayers[player]
end

function Public:GetTeamByTeam(team)
	return listteams[team]
end

function Public:GetPlayerByName(name)
	local player = Players:FindFirstChild(name)
	if player then return listplayers[player] end
	error(`Unknown player {name}`)
end

function Public:GetTeamByName(name)
	local team = Teams:FindFirstChild(name)
	if team then return listteams[team] end
	error(`Unknown team {team}`)
end


task.spawn(require(script.Gui), Public)
--=================================--

local function teamAdded(t)
	local listTeam = Team(t)
	listteams[t] = listTeam
	TeamAdded:Fire(listTeam)
end

local function checkAttribute(name, value)
	if value then
		if type(value) ~= "string" and type(value) ~= "number" then return end
	end

	if string.lower(string.sub(name, 1, ATTRIBUTAL_LEADERSTAT_LENGTH)) ~= ATTRIBUTAL_LEADERSTAT_PREFIX then return end
	local leaderstatName = string.sub(name, ATTRIBUTAL_LEADERSTAT_LENGTH + 1)
	return leaderstatName
end

local function recomputeAllLeaderstats(name, value)
	local ev = LeaderstatsCount[name]
	if ev then
		ev += if value ~= nil then 1 else -1
		if ev <= 0 then
			table.remove(AllLeaderstatsList, table.find(AllLeaderstatsList, name))
			LeaderstatsCount[name] = nil
			AllLeaderstatsReshaped:Fire()
		else
			LeaderstatsCount[name] = ev
		end
	elseif value ~= nil then
		table.insert(AllLeaderstatsList, name)
		LeaderstatsCount[name] = 1
		AllLeaderstatsReshaped:Fire()
	end
end

local function initAttributalLeaderstats(p: Player, listPlayer: Types.ListPlayer)
	local function updateAttributalLeaderstat(name, value)
		local leaderstatName = checkAttribute(name, value)
		if not leaderstatName then return end
		if leaderstatName ~= "" then
			recomputeAllLeaderstats(leaderstatName, value)
			listPlayer:ChangeLeaderstat(leaderstatName, value)
		end
	end
	
	p.AttributeChanged:Connect(function(name)
		updateAttributalLeaderstat(name, p:GetAttribute(name))
	end)
	
	for k, v in p:GetAttributes() do
		updateAttributalLeaderstat(k, v)
	end
end

local function playerAdded(p)
	local listPlayer = Player(p)
	-- TODO: Setup leaderstat hook

	if p.Team then
		local t = listteams[p.Team]
		if t then
			t:AddMember(listPlayer)
		end
	end

	p:GetPropertyChangedSignal("Team"):Connect(function()
		local t = listteams[p.Team]
		if listPlayer.Team then
			listPlayer.Team:RemoveMember(listPlayer)
		end

		if t then
			t:AddMember(listPlayer)
		end
	end)

	listplayers[p] = listPlayer
	PlayerAdded:Fire(listPlayer)
	initAttributalLeaderstats(p, listPlayer)
end

for _, team in Teams:GetTeams() do
	teamAdded(team)
end

for _, p in Players:GetPlayers() do
	playerAdded(p)
end

Teams.ChildAdded:Connect(function(t)
	if t:IsA("Team") then
		teamAdded(t)
	end
end)

Teams.ChildRemoved:Connect(function(t)
	if t:IsA("Team") then
		local listTeam = listteams[t]
		listteams[t] = nil -- computation is done player wise so dont need to worry about Removing everyone
		if listTeam then
			TeamRemoving:Fire(listTeam)
		end	
	end
end)

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(p)
	local listPlayer = listplayers[p]
	if listPlayer then
		listplayers[p] = listPlayer:Remove()
		
		-- remove 1 from all leaderstats that this player has
		for k, v in p:GetAttributes() do
			local leaderstatName = checkAttribute(k, v)
			if leaderstatName then
				recomputeAllLeaderstats(leaderstatName, v)
			end
		end
		
		PlayerRemoving:Fire(listPlayer)
	end
end)

FullyInitialised:Fire()
Public.IsReady = true
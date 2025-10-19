local Util = require(script.Util)
local LocalPlayer = game:GetService("Players").LocalPlayer
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Templates = require(script.Templates)
local Settings = require(script.Parent.LeaderstatConfigs)

local LEADERSTAT_ORDER = Settings.LeaderstatOrder
local LEADERSTAT_PRIMARY = Settings.PrimaryLeaderstat
local TOPBAR_NAME_VISIBLE = if Settings.EnablePlayerNameTopbar ~= nil then Settings.EnablePlayerNameTopbar else true
local PlayerlistAnimation = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local labelBindings = {}
local leaderstatBindings = {}
local events = {}

local HEADER_LABEL, TOPBAR, scrollList
local NEUTRAL_LABEL = Templates:Divider("Neutral", BrickColor.Gray().Color)
local HEADER_LABEL_BINDINGS = {}
local NEUTRAL_LABEL_BINDINGS = {}

local function sort(API)
	local sorted = Util.sort(API, LEADERSTAT_PRIMARY)
	local neutralAppeared = false
	for idx, obj in sorted do
		if obj == "NEUTRAL_TEAM_HEADER" then
			neutralAppeared = true
			NEUTRAL_LABEL.Parent = scrollList
			NEUTRAL_LABEL.LayoutOrder = idx
		else
			local binding = labelBindings[obj]
			if binding then
				binding.LayoutOrder = idx
			end
		end
	end
	
	if not neutralAppeared then NEUTRAL_LABEL.Parent = nil end
	
	scrollList.CanvasSize = UDim2.new(0, 0, 0, scrollList.Layout.AbsoluteContentSize.Y)
end

local function recomputeLeaderstats(listPlayer: Util.ListPlayer|Util.ListTeam, leaderstatOrder: {string}, key: string?)
	-- rerenders entire leaderstat stack (only use this if the leaderstatOrder changes)
	local bindings = leaderstatBindings[listPlayer] or {}
	if next(bindings) then
		for _, v in bindings do
			v:Destroy()
		end
		bindings = {}
	end
	
	local idx, count = 1, 0
	local didIter = false
	for _, k in leaderstatOrder do
		count += 1
		
		local l = listPlayer.Leaderstats[k] or "-"
		local isTeam = listPlayer.ClassName == "ListTeam"
		
		local c = if isTeam then listPlayer.Team.TeamColor.Color else nil
		local label = Templates:Leaderstat(l, isTeam, c)
		label.LayoutOrder = idx
		idx+=1
		
		bindings[k] = label
		label.Parent = labelBindings[listPlayer]
	end
	
	local isStatsShowing = not TOPBAR_NAME_VISIBLE or count > 0
	
	HEADER_LABEL.Visible = isStatsShowing
	scrollList.Position = if isStatsShowing then UDim2.fromOffset(0, 22) else UDim2.fromOffset(0, 2)
	scrollList.Size = if isStatsShowing then UDim2.new(1, 0, 1, -22) else UDim2.new(1, 0, 1, -2)
	
	local topbarX = 170 + (count * 75) + (count * 2)
	TOPBAR.Size = UDim2.fromOffset(topbarX, 40)

	leaderstatBindings[listPlayer] = bindings
end

local function generateHeaderLabels(leaderstatOrder: {string})
	if next(HEADER_LABEL_BINDINGS) then
		for _, v in HEADER_LABEL_BINDINGS do
			v:Destroy()
		end
		HEADER_LABEL_BINDINGS = {}
	end

	for _, k in leaderstatOrder do
		local name = Settings.LeaderstatAliases[k] or k
		local label = Templates:Leaderstat(name, true)
		label.Parent = HEADER_LABEL
		
		table.insert(HEADER_LABEL_BINDINGS, label)
	end
end

local function neutralStatLabels(leaderstatOrder: {string})
	if next(NEUTRAL_LABEL_BINDINGS) then
		for _, v in NEUTRAL_LABEL_BINDINGS do
			v:Destroy()
		end
		NEUTRAL_LABEL_BINDINGS = {}
	end
	
	local idx = 1
	for _, k in leaderstatOrder do
		local label = Templates:Leaderstat("", false, BrickColor.Gray().Color)
		label.LayoutOrder = idx
		label.Parent = NEUTRAL_LABEL
		
		idx+=1
		NEUTRAL_LABEL_BINDINGS[k] = label
	end
end


return function(API: Util.ProviderAPI)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	
	if #LEADERSTAT_ORDER == 0 then
		LEADERSTAT_ORDER = API.AllLeaderstats
	end

	local gui = Templates:BaseGui()
	local listContainer = gui.PlayerListContainer
	HEADER_LABEL = listContainer.PlayersHeader
	TOPBAR = gui.TopbarHeader
	
	TOPBAR.Visible = TOPBAR_NAME_VISIBLE
	scrollList = listContainer.ScrollList
	
	local guiOpenState = true
	local guiInTween = TweenService:Create(listContainer, PlayerlistAnimation, {
		AnchorPoint = Vector2.new(1, 0)
	})
	local guiOutTween = TweenService:Create(listContainer, PlayerlistAnimation, {
		AnchorPoint = Vector2.new(0, 0)
	})

	API.PlayerAdded:Connect(function(player)
		local playerEvents = {}
		events[player] = playerEvents
		
		local listItem = Templates:PlayerListItem(player)
		
		listItem.Parent = scrollList
		labelBindings[player] = listItem
		recomputeLeaderstats(player, LEADERSTAT_ORDER)
		sort(API)
		
		table.insert(playerEvents, player.LeaderstatChanged:Connect(function(p, k, v)
			local binding = leaderstatBindings[p][k]
			if binding then
				binding.StatText.Text = v or "-"
			end
			
			sort(API)
		end))
	end)
	
	API.PlayerRemoving:Connect(function(player)
		local playerEvents = events[player]
		local listItem = labelBindings[player]
		
		for _, v in playerEvents do v() end
		events[player] = nil
		
		listItem:Destroy()
		labelBindings[player] = nil
		leaderstatBindings[player] = nil
		sort(API)
	end)
	
	API.TeamAdded:Connect(function(team)
		local teamEvents = {}
		events[team] = teamEvents
		
		local teamItem = Templates:TeamLabel(team)
		teamItem.Parent = scrollList
		labelBindings[team] = teamItem
		recomputeLeaderstats(team, LEADERSTAT_ORDER)
		sort(API)
		
		table.insert(teamEvents, team.LeaderstatChanged:Connect(function(t, k, v)
			local binding = leaderstatBindings[t][k]
			if binding then
				binding.StatText.Text = v or "-"
			end
			
			sort(API)
		end))
		
		table.insert(teamEvents, team.TeamRenamed:Connect(function()
			teamItem.BGFrame.DividerName.Text = team.Name
			sort(API)
		end))
		
		table.insert(teamEvents, team.MemberAdded:Connect(function()
			sort(API)
		end))
		
		table.insert(teamEvents, team.MemberRemoved:Connect(function()
			sort(API)
		end))
		
		table.insert(teamEvents, team.Team.Changed:Connect(function(prop)
			local propVal = team.Team[prop]
			
			if prop == "TeamColor" then
				teamItem.BGFrame.BackgroundColor3 = propVal.Color
				for _, v in leaderstatBindings[team] do
					v.BackgroundColor3 = propVal.Color
				end
			end
		end))
	end)
	
	API.TeamRemoving:Connect(function(team)
		local teamEvents = events[team]
		local listItem = labelBindings[team]

		for _, v in teamEvents do 
			if type(v) == "function" then 
				v() 
			else 
				v:Disconnect()
			end
		end
		
		events[team] = nil

		listItem:Destroy()
		labelBindings[team] = nil
		leaderstatBindings[team] = nil
		
		sort(API)
	end)
	
	API.AllLeaderstatShapeChanged:Connect(function()
		generateHeaderLabels(LEADERSTAT_ORDER)
		neutralStatLabels(LEADERSTAT_ORDER)
		for _, plr in API:GetPlayers() do
			recomputeLeaderstats(plr, LEADERSTAT_ORDER)
		end
		
		for _, team in API:GetTeams() do
			recomputeLeaderstats(team, LEADERSTAT_ORDER)
		end
		
		sort(API)
	end)
	
	ContextActionService:BindAction("ToggleLeaderboard", function(_, state)
		if state == Enum.UserInputState.End then
			guiOpenState = not guiOpenState
			local t = if guiOpenState then guiInTween else guiOutTween
			t:Play()
		end
	end, false, Enum.KeyCode.Tab)
	
	generateHeaderLabels(LEADERSTAT_ORDER)
	gui.Parent = LocalPlayer.PlayerGui
end
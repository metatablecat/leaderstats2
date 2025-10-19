-- Util: useful functions

-- TYPEDEFS
local Types = require(script.Parent.Parent.InternalAPI.Types)

export type ListPlayer = Types.ListPlayer
export type ListTeam = Types.ListTeam
export type ProviderAPI = {
	PlayerAdded: Types.Signal<ListPlayer>,
	PlayerRemoving: Types.Signal<ListPlayer>,
	TeamAdded: Types.Signal<ListTeam>,
	TeamRemoving: Types.Signal<ListTeam>,
	AllLeaderstatShapeChanged: Types.Signal<>,
	Ready: Types.Signal<>,
	IsReady: boolean,
	AllLeaderstats: {string},
	
	GetPlayers: (ProviderAPI) -> {ListPlayer},
	GetTeams: (ProviderAPI) -> {ListTeam},
	GetPlayerByPlayer: (ProviderAPI, Player) -> ListPlayer,
	GetPlayerByName: (ProviderAPI, string) -> ListPlayer,
	GetTeamByTeam: (ProviderAPI, Team) -> ListTeam,
	GetTeamByName: (ProviderAPI, string) -> ListTeam
}

-- Code
local LocalPlayer = game:GetService("Players").LocalPlayer

local Images = {
	FRIEND_ICON = "rbxasset://textures/ui/icon_friends_16.png",
	ROBLOX_STAFF = "rbxasset://textures/ui/RobloxNameIcon.png",
	ROBLOX_INTERN = "rbxasset://textures/ui/icon_intern-16.png",
	VERIFIED_BADGE = "rbxasset://textures/ui/VerifiedBadgeNameIcon.png",
	PREMIUM_ICON = "rbxasset://textures/ui/icon_premium-16.png",
	CAT = "rbxassetid://12807028788"
}

local Util = {}
Util.Images = Images
Util.ROBLOX_STAFF_GROUP = 1200769
Util.ROBLOX_INTERN_RANK_ID = 25

local function toList(t)
	local o = {}
	for _, v in t do
		table.insert(o, v)
	end
	
	return o
end

local function leaderstatComputationCheck(lhs: ListPlayer|ListTeam, rhs: ListPlayer|ListTeam, key: string?)
	if key then
		local kA = lhs.Leaderstats[key] or ""
		local kB = rhs.Leaderstats[key] or ""
		if kA ~= "" and kB ~= "" then
			return kA > kB
		end
	end

	return lhs.Name < rhs.Name
end

function Util.sort(API: ProviderAPI, SortedLeaderstat: string?): {ListTeam|ListPlayer|string}
	local teams = toList(API:GetTeams())
	local players = toList(API:GetPlayers())

	if not SortedLeaderstat then
		SortedLeaderstat = API.AllLeaderstats[1]
	end

	if #teams > 0 then
		-- todo: clean up this
		local o = {}

		-- sort using team logic
		local neutralPlayers = {}
		for _, plr in players do
			if not plr.Team then
				table.insert(neutralPlayers, plr)
			end
		end

		table.sort(teams, function(a, b)
			return leaderstatComputationCheck(a, b, SortedLeaderstat)
		end)

		table.sort(neutralPlayers, function(a, b)
			return leaderstatComputationCheck(a, b, SortedLeaderstat)
		end)
		table.insert(teams, neutralPlayers)

		for _, team in teams do
			if team == neutralPlayers then
				if #neutralPlayers > 0 then
					table.insert(o, "NEUTRAL_TEAM_HEADER")
					for _, v in neutralPlayers do
						table.insert(o, v)
					end
				end
			else
				table.insert(o, team)
				table.sort(team.Members, function(a, b)
					return leaderstatComputationCheck(a, b, SortedLeaderstat::string)
				end)

				for _, v in team.Members do
					table.insert(o, v)
				end
			end
		end

		return o
	else
		-- just sort by players
		table.sort(players, function(a, b)
			return leaderstatComputationCheck(a, b, SortedLeaderstat::string)
		end)

		return players
	end
end

function Util.setIconAsync(player: Player, image: ImageLabel)
	if player.UserId == 8094244 then
		image.Image = Images.CAT
		return
	end

	local function checkRankHttpSafe(groupID)
		local s, rank = pcall(player.GetRankInGroup, player, groupID)
		if s then return rank end
		return 0
	end

	if LocalPlayer:IsFriendsWith(player.UserId) then
		image.Image = Images.FRIEND_ICON
		return
	end
	
	local ROBLOX_GROUP_RANK = checkRankHttpSafe(Util.ROBLOX_STAFF_GROUP)

	if ROBLOX_GROUP_RANK > 0 then
		if ROBLOX_GROUP_RANK == Util.ROBLOX_INTERN_RANK_ID  then
			image.Image = Images.ROBLOX_INTERN
			return
		end

		image.Image = Images.ROBLOX_STAFF
		return
	end

	if player.HasVerifiedBadge then
		image.Image = Images.VERIFIED_BADGE
		return
	end

	if player.MembershipType == Enum.MembershipType.Premium then
		image.Image = Images.PREMIUM_ICON
		return
	end
end

return Util
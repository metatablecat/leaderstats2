local Types = require(script.Parent.Types)
local Event = require(script.Parent.Event)

local function Team(team: Team): Types.ListTeam
	local t = {}
	t.ClassName = "ListTeam"
	
	-- INTERNAL EVENT BINDINGS
	t._eLeaderstatChanged = Event()
	t._eExtraDataChanged = Event()
	t._eMemberAdded = Event()
	t._eMemberRemoved = Event()
	t._eTeamRenamed = Event()
	
	t.LeaderstatChanged = t._eLeaderstatChanged.Signal
	t.ExtraDataChanged = t._eExtraDataChanged.Signal
	t.MemberAdded = t._eMemberAdded.Signal
	t.MemberRemoved = t._eMemberRemoved.Signal
	t.TeamRenamed = t._eTeamRenamed.Signal

	t.Name = team.Name
	t.Team = team
	t.Members = {}
	t.Leaderstats = {}
	t.ExtraData = {}
	
	function t:RecomputeLeaderstat(key: string)
		local lastval = self.Leaderstats[key]
		local score
		for _, k in self.Members do
			local stat = k.Leaderstats[key]
			if not stat then continue end
			
			if type(stat) == "string" then
				self.Leaderstats[key] = ""
				
				if lastval ~= "" then
					self._eLeaderstatChanged:Fire(self, key, "")
				end
				return
			end
			
			score = if score then score + stat else stat
			
		end

		self.Leaderstats[key] = score
		if lastval ~= score then
			self._eLeaderstatChanged:Fire(self, key, score)
		end
	end
	
	function t:AddMember(player: Types.ListPlayer)
		assert(not table.find(self.Members, player), `{player.Name} is already a member of this team`)
		table.insert(self.Members, player)
		player.Team = self
		self._eMemberAdded:Fire(self, player)
		self:RecomputeAllLeaderstats()
	end
	
	function t:RemoveMember(player: Types.ListPlayer)
		local idx = assert(table.find(self.Members, player), `{player.Name} is not a member of this team`)
		table.remove(self.Members, idx)
		player.Team = nil
		self._eMemberRemoved:Fire(self, player)
		self:RecomputeAllLeaderstats()
	end
	
	function t:RemoveAllMembers()
		for _, player in self.Members do
			self._eMemberRemoved:Fire(self, player)
		end
		
		self:RecomputeAllLeaderstats()
		self.Members = {}
	end
	
	function t:RecomputeAllLeaderstats()
		--FIX: Should check unique leaderstat keys based on members instead of team leaderstats
		local uniqueLeaderstatKeys = {}
		for k in self.Leaderstats do
			if uniqueLeaderstatKeys[k] then continue end
			uniqueLeaderstatKeys[k] = true
		end
		
		for _, player in self.Members do
			for key in player.Leaderstats do
				if uniqueLeaderstatKeys[key] then continue end
				uniqueLeaderstatKeys[key] = true
			end
		end
		
		for k in uniqueLeaderstatKeys do
			self:RecomputeLeaderstat(k)
		end
	end
	
	function t:SetExtraData(key, value)
		self.ExtraData[key] = value
		self._eExtraDataChanged:Fire(self, key, value)
	end
	
	team:GetPropertyChangedSignal("Name"):Connect(function()
		t.Name = team.Name
		t._eTeamRenamed:Fire(t)
	end)
	
	return t
end

return Team
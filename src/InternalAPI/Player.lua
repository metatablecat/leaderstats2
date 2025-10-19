local Types = require(script.Parent.Types)
local Event = require(script.Parent.Event)

local function Player(player: Player): Types.ListPlayer
	local p = {}
	p.ClassName = "ListPlayer"
	p.Name = player.Name
	p.DisplayName = player.DisplayName or p.Name
	p.Verified = player.HasVerifiedBadge
	p.Player = player
	
	p.Team = nil
	p.Leaderstats = {}
	p.ExtraData = {}
	
	p._eLeaderstatChanged = Event()
	p._eExtraDataChanged = Event()
	p._eRemoving = Event()
	p.LeaderstatChanged = p._eLeaderstatChanged.Signal
	p.ExtraDataChanged = p._eExtraDataChanged.Signal
	p.Removing = p._eRemoving.Signal
	
	function p:ChangeLeaderstat(key: string, value: any)
		self.Leaderstats[key] = value
		if self.Team then self.Team:RecomputeLeaderstat(key) end
		self._eLeaderstatChanged:Fire(self, key, value)
	end
	
	function p:SetExtraData(key: string, value: any)
		self.ExtraData[key] = value
		self._eExtraDataChanged:Fire(self, key, value)
	end
	
	function p:Remove()
		if self.Team then
			self.Team:RemoveMember(self)
		end
		
		self._eRemoving:Fire(self)
	end
	
	function p:RemoveLeaderstats()
		for k in self.Leaderstats do
			self:ChangeLeaderstat(k, nil)
		end
	end
	
	return p
end

return Player
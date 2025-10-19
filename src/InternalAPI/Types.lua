local Event = require(script.Parent.Event)

export type Event<T...> = Event.Event<T...>
export type Signal<T...> = Event.Signal<T...>

export type ListPlayer = {
	-- Properties
	Name: string,
	ClassName: "ListPlayer",
	Player: Player,
	Verified: true|false,
	DisplayName: string,
	
	Team: ListTeam?,
	Leaderstats: {[string]: any},
	ExtraData: {[string]: any},
	
	-- Methods
	ChangeLeaderstat: (ListPlayer, Name: string, Value: any) -> (),
	SetExtraData: (ListPlayer, Name: string, Value: any) -> (),
	Remove: (ListPlayer) -> (),
	RemoveLeaderstats: (ListPlayer) -> (),
	
	-- Events
	LeaderstatChanged: Signal<ListPlayer, string, any>,
	ExtraDataChanged: Signal<ListPlayer, string, any>,
	Removing: Signal<ListPlayer>
}

export type ListTeam = {
	-- Properties
	Name: string,
	ClassName: "ListTeam",
	Team: Team,
	
	Members: {ListPlayer},
	Leaderstats: {[string]: any},
	ExtraData: {[string]: any},
	
	-- Methods
	RecomputeLeaderstat: (ListTeam, Key: string) -> (),
	AddMember: (ListTeam, Player: ListPlayer) -> (),
	RemoveMember: (ListTeam, Player: ListPlayer) -> (),
	RemoveAllMembers: (ListTeam) -> (),
	RecomputeAllLeaderstats: (ListTeam) -> (),
	
	-- Events
	LeaderstatChanged: Signal<ListTeam, string, any>,
	ExtraDataChanged: Signal<ListTeam, string, any>,
	MemberAdded: Signal<ListTeam, ListPlayer>,
	MemberRemoved: Signal<ListTeam, ListPlayer>,
	TeamRenamed: Signal<ListTeam>
}

return nil
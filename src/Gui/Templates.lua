local LocalPlayer = game:GetService("Players").LocalPlayer
local Templates = {}

local Create = require(script.Parent.Create)
local Util = require(script.Parent.Util)

function Templates:BaseGui()
	local gui = Create("ScreenGui", {
		Name = "PlayerList",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		Create("Frame", {
			Name = "PlayerListContainer",
			AnchorPoint = Vector2.new(1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 0, 0, 40),
			Size = UDim2.fromScale(0, 0.5),

			Create("ScrollingFrame", {
				Name = "ScrollList",
				AutomaticSize = Enum.AutomaticSize.X, -- Y needs to be computed manually because roblox is 10/10
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				Position = UDim2.fromOffset(0, 2),
				Size = UDim2.new(0, 0, 1, -2),
				ScrollBarThickness = 6,
				BottomImage = "rbxasset://textures/ui/scroll-bottom.png",
				MidImage = "rbxasset://textures/ui/scroll-middle.png",
				TopImage = "rbxasset://textures/ui/scroll-top.png",

				Create("UIListLayout", {
					Name = "Layout",
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
			})
		})
	})
	
	local playersDivider = Templates:Divider("Players", Color3.fromRGB(31, 31, 31))
	playersDivider.Name = "PlayersHeader"
	playersDivider.AutomaticSize = Enum.AutomaticSize.X
	playersDivider.AnchorPoint = Vector2.new(1, 0)
	playersDivider.Position = UDim2.new(1, 0, 0, 2)
	playersDivider.Visible = false
	playersDivider.Parent = gui.PlayerListContainer
	
	local topbar = Templates:Divider(LocalPlayer.Name, Color3.fromRGB(31, 31, 31))
	topbar.Name = "TopbarHeader"
	topbar.AutomaticSize = Enum.AutomaticSize.None
	topbar.AnchorPoint = Vector2.new(1, 0)
	topbar.Size = UDim2.fromOffset(170, 40)
	topbar.BGFrame.Size = UDim2.new(1, 0, 1, 0)
	topbar.Position = UDim2.new(1, 0, 0, 0)
	topbar.BGFrame.DividerName.FontFace = Font.fromEnum(Enum.Font.SourceSansBold)
	topbar.Parent = gui
	
	return gui
end

function Templates:PlayerListItem(listPlayer: Util.ListPlayer)
	local listItem = Create("Frame", {
		Name = listPlayer.Name,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,0,0,24),

		Create("UIListLayout", {
			Name = "Layout",
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal
		}),

		Create("TextButton", {
			Name = "BGFrame",
			AnchorPoint = Vector2.new(0, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(31, 31, 31),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = 0,
			Size = UDim2.new(0, 170, 1, 0),
			Text = "",

			Create("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Name = "MembershipIcon",
				BackgroundTransparency = 1,
				Position = UDim2.new(0.01, 5, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
			}),

			Create("TextLabel", {
				Name = "PlayerName",
				BackgroundTransparency = 1,
				Position = UDim2.new(0.01, 27, 0, 0),
				Size = UDim2.new(-0.01, 143, 1, 0),
				FontFace = Font.fromEnum(Enum.Font.SourceSans),
				Text = listPlayer.DisplayName,
				TextColor3 = Color3.new(1,1,1),
				TextSize = 14,
				TextStrokeColor3 = Color3.fromRGB(34, 34, 34),
				TextStrokeTransparency = 0.75,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		})
	})

	task.spawn(Util.setIconAsync, listPlayer.Player, listItem.BGFrame.MembershipIcon)
	return listItem
end

function Templates:Divider(text: string, color: Color3)
	local listItem = Create("Frame", {
		Name = text,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,0,0,18),

		Create("UIListLayout", {
			Name = "Layout",
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal
		}),

		Create("TextButton", {
			Name = "BGFrame",
			AnchorPoint = Vector2.new(0, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = 0,
			Size = UDim2.new(0, 170, 1, 0),
			Text = "",
			
			Create("TextLabel", {
				Name = "DividerName",
				BackgroundTransparency = 1,
				Position = UDim2.new(0.01, 1, 0, 0),
				Size = UDim2.new(-0.01, 170, 1, 0),
				FontFace = Font.fromEnum(Enum.Font.SourceSans),
				Text = text,
				TextColor3 = Color3.new(1,1,1),
				TextSize = 14,
				TextStrokeColor3 = Color3.fromRGB(34, 34, 34),
				TextStrokeTransparency = 0.75,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		})
	})
	
	return listItem
end

function Templates:TeamLabel(team: Util.ListTeam)
	return Templates:Divider(team.Name, team.Team.TeamColor.Color)
end

function Templates:Leaderstat(initValue: string|number?, bold: boolean?, color: Color3?)
	return Create("Frame", {
		Name = "Value",
		BackgroundColor3 = color or Color3.fromRGB(31, 31, 31),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 75, 1, 0),
		
		Create("TextLabel", {
			Name = "StatText",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1,1),
			FontFace = if bold
				then Font.fromEnum(Enum.Font.SourceSansBold)
				else Font.fromEnum(Enum.Font.SourceSans),
			Text = initValue or "-",
			TextColor3 = Color3.new(1,1,1),
			TextSize = 14,
			TextStrokeColor3 = Color3.fromRGB(34, 34, 34),
			TextStrokeTransparency = 0.75,
			TextTruncate = Enum.TextTruncate.AtEnd
		})
	})
end

return Templates
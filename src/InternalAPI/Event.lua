-- Simple Event Library
-- Usage: CatMeowed = Event<boolean>()

export type Signal<A...> = {
	Connect: (Signal<A...>, func: (A...) -> ()) -> () -> (),
	ConnectedFunctions: {(A...) -> ()},
	Wait: (Signal<A...>) -> A...,
	WaitingThreads: {thread}
}

export type Event<A...> = {
	Signal: Signal<A...>,
	Fire: (Event<A...>, A...) -> (),

	--DEPRECATED, Remove by v0.3 release
	Connect: (Event<A...>, func: (A...) -> ()) -> () -> (),
	Wait: (Event<A...>) -> A...,
}

local function Signal<A...>(): Signal<A...>
	local Signal = {}

	Signal.ConnectedFunctions = {}
	Signal.WaitingThreads = {}

	function Signal.Connect(self: Signal<A...>, func: (A...) -> ()): () -> ()
		local index = #self.ConnectedFunctions + 1
		self.ConnectedFunctions[index] = func

		return function()
			table.remove(self.ConnectedFunctions, index)
		end
	end

	function Signal.Wait(self: Signal<A...>): A...
		local co = coroutine.running()
		table.insert(self.WaitingThreads, co)
		return coroutine.yield(co)
	end

	return Signal
end

return function<A...>(): Event<A...>
	local Event = {}
	Event.Signal = Signal() :: Signal<A...>

	function Event.Connect(self: Event<A...>, func: (A...) -> ()): () -> ()
		warn("Event:Connect is deprecated and will be removed in the near future. Use Event.Signal:Connect instead")
		return self.Signal:Connect(func)
	end

	function Event.Fire(self: Event<A...>, ...: A...)
		local sig = self.Signal
		-- first, handoff callbacks
		-- then release threads
		-- do not rely on this order as it's an implementation detail
		for _, callback: (A...) -> () in sig.ConnectedFunctions do
			task.spawn(callback, ...)
		end

		for _, thread in sig.WaitingThreads do
			coroutine.resume(thread, ...)
		end
	end

	function Event.Wait(self: Event<A...>): A...
		warn("Event:Wait is deprecated and will be removed in the near future. Use Event.Signal:Wait instead")
		return self.Signal:Wait()
	end

	return Event
end
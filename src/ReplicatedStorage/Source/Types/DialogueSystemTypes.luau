--!strict

--[[
    Stores the various types fo the Dialogue System.
]]
local DialogueSystemTypes = {}

export type SpeakerName = string
export type NodeId = string
export type ConversationId = string

export type DialogueStyle = ("Standard" | "Billboard" | string)? -- Allow custom styles

export type DialogueLineData = {
	Speaker: SpeakerName?,
	Text: string,
	-- Can add more properties like PortraitId, AnimationId, SFX, etc. later
}

export type ChoiceData = {
	Id: string,
	Text: string,
	Next: NodeId?,
	End: boolean?, -- If true, this choice ends the conversation
	Condition: ((context: DialogueContext?) -> boolean)?, -- Optional condition for this choice to be visible
	-- Can add more properties if choices have visuals or conditions
}

export type DialogueNode = {
	Speaker: SpeakerName?,
	Text: string?, -- Text can be nil for nodes that only present choices or end
	Choices: { ChoiceData }?,
	Next: NodeId?, -- For linear progression
	End: boolean?, -- If true, this node ends the conversation
	Condition: ((context: DialogueContext?) -> boolean)?, -- Optional condition function for branching
	Fallback: NodeId?, -- Node to jump to if Condition fails
	Action: ((context: DialogueContext?) -> ())?, -- Optional action to run when node is entered
}

export type AdorneeProvider = (context: DialogueContext?) -> { [string]: BasePart }?

export type ConversationData = {
	Id: string,
	StartNode: NodeId,
	Nodes: { [NodeId]: DialogueNode },
	Style: DialogueStyle?, -- UI style for this conversation; defaults to "Standard"
	AdorneeProvider: AdorneeProvider?, -- Optional function to get Adornee for billboard styles
	-- Future: Global variables, custom functions, etc.
}

export type LineChangedEvent = {
	speaker: SpeakerName?,
	text: string,
	choices: { ChoiceData }?,
	style: DialogueStyle?,
	adornees: { [string]: BasePart }?,
}

export type ChoicesPresentedEvent = {
	choices: { ChoiceData },
	style: DialogueStyle?,
	adornees: { [string]: BasePart }?,
}

export type ConversationEndedEvent = {
	conversationId: ConversationId,
	style: DialogueStyle?,
	adornees: { [string]: BasePart }?,
	-- Optional: End state, e.g., "completed", "cancelled"
}

export type DialogueContext = {
	Player: Player,
	Prompt: ProximityPrompt,
	NPC: Model,
}

return DialogueSystemTypes

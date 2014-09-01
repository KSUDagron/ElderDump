-----------------------------------------------------------------------------------------------
-- Client Lua Script for ElderDump
-- Copyright (c) KSUDagron on Curse.com
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
require "GameLib"
 
local ElderDump = {}
local ElderDumpInst = nil
 
function ElderDump:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function ElderDump:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = { }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
function ElderDump:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ElderDump.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ElderDump:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ElderDumpForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
				
	    self.wndMain:Show(false, true)
	
		Apollo.RegisterEventHandler("GuildRoster", "OnGuildRoster", self)
		Apollo.RegisterEventHandler("GuildMemberChange", "OnGuildMemberChange", self)  -- General purpose update method
		Apollo.RegisterEventHandler("GuildRankChange", "OnGuildRankChange", self)
		
		Apollo.RegisterSlashCommand("elderdump", "OnElderDumpOn", self)
		Apollo.RegisterSlashCommand("ed", "OnElderDumpOn", self)
	end
end

function ElderDump:OnElderDumpOn()
	for key, guildData in pairs(GuildLib.GetGuilds()) do
		if guildData:GetType() == GuildLib.GuildType_Guild then
			self.Guild = guildData
		end
	end
	
	self.Guild:RequestMembers()
	
	self.wndMain:Invoke()
end

function ElderDump:OnExport(wndHandler, wndControl, eMouseButton)
	if self.Roster == nil then
		ElderDump:ToSystem("ElderDump: Guild roster not found")
		return
	end
	
	self.Ranks = self.Guild:GetRanks()
	
	local xml = ""
	
	xml = xml .. "<guild name=\"" .. self.Guild:GetName() .. "\">"
	
	local count = 0
	for _ in pairs(self.Roster) do count = count + 1 end
	xml = xml .. "\n    <roster count=\"" .. count .. "\">"
	
	for _, player in pairs(self.Roster) do
		xml = xml .. "\n        <character>"
		xml = xml .. "\n            <name>" .. player.strName .. "</name>"
		xml = xml .. "\n            <rank id=\"" .. player.nRank .. "\">" .. self.Ranks[player.nRank].strName .. "</rank>"
		xml = xml .. "\n            <level>" .. player.nLevel .. "</level>"
		xml = xml .. "\n            <class id=\"" .. player.eClass .. "\">" .. player.strClass .. "</class>"
		xml = xml .. "\n            <path id=\"" .. player.ePathType .. "\">" .. ElderDump:GetPathStr(player.ePathType) .. "</path>"
		xml = xml .. "\n            <note>" .. player.strNote .. "</note>"
		xml = xml .. "\n        </character>"
	end
	
	xml = xml .. "\n    </roster>"
	xml = xml .. "\n</guild>"
	
	self.wndMain:FindChild("XMLDump"):SetText(xml)
end

function ElderDump:OnGuildRoster(guildCurr, tRoster)
	if guildCurr and guildCurr:GetType() == GuildLib.GuildType_Guild then
		table.sort(tRoster, function(a,b) return (a.strName < b.strName) end)
		self.Roster = tRoster
	end
end

function ElderDump:OnCancel( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close()
end

function ElderDump:GetPathStr(nPathType)
	if nPathType == 0 then
		return "Soldier"
	elseif nPathType == 1 then
		return "Settler"
	elseif nPathType == 2 then
		return "Scientist"
	elseif nPathType == 3 then
		return "Explorer"
	else
		return "Unknown"
	end
end

ElderDumpInst = ElderDump:new()
ElderDumpInst:Init()
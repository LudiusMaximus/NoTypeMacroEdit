local folderName = ...


local targetTermsOrder = {
  "[@target]",
  "[@focustarget]",
  "[@focus]",
  "[@targettarget]",
  "[@mouseover]",
}

local targetTerms = {}
for _, v in pairs(targetTermsOrder) do
  targetTerms[v] = true
end




-- Note that this frame must be named for the dropdowns to work.
local targetTermsMenuFrame = CreateFrame("Frame", "ExampleMenuFrame", UIParent, "UIDropDownMenuTemplate")







-- Extract the line or word of the current cursor position.
local function GetSection(text, cursorPosition, delimiter)
  local lineEnd = #text
  for i = cursorPosition + 1, #text do
    local c = strsub(text, i, i)
    if c == "\n" or delimiter and c == delimiter then
      lineEnd = i - 1
      break
    end
  end

  local lineStart = 0
  for i = cursorPosition, 0, -1 do
    local c = strsub(text, i, i)
    if c == "\n" or delimiter and c == delimiter then
      lineStart = i + 1
      break
    end
  end

  return lineStart, lineEnd
end











local function MyReceive(self)
  -- print("MyReceive", self:GetName())
  
  if InCombatLockdown() then
    print("Sorry, cannot do anything while in combat...")
    return
  end
  
  -- Extract the line of the current cursor position.
  local currentText = MacroFrameText:GetText()
  local cursorPosition = MacroFrameText:GetCursorPosition()

  local cursorInfo, _, _, spellId = GetCursorInfo()
  if cursorInfo == "spell" then
    local spellName = GetSpellInfo(spellId)

    -- print("cursor position:", cursorPosition)
    local lineStart, lineEnd = GetSection(currentText, cursorPosition)
    -- print("start, end:", lineStart, lineEnd)
    local currentLine = strsub(currentText, lineStart, lineEnd)
    -- print("current line:", currentLine)


    -- Will replace currentLine in the end.
    local changedLine = currentLine

    -- Check if this line is empty or starts with /cast or /castsequence.
    local firstWord = string.match(currentLine, "([/%w]+)")
    -- print(firstWord)

    -- If we have a blank line, create a new cast line.
    if firstWord == nil then
      changedLine = "/cast [@target] " .. spellName

    -- If we had cast before, change it into castsequence and append the new spell.
    elseif firstWord == "/cast" then
      changedLine = string.gsub(currentLine, "/cast", "/castsequence") .. ", " .. spellName

    -- If we already have castsequence, just append the new spell.
    elseif firstWord == "/castsequence" then
      changedLine = currentLine .. ", " .. spellName

    end

    -- Replace the old text with the new one in which the line has been changed.
    MacroFrameText:SetText(strsub(currentText, 0, lineStart > 0 and lineStart -1 or lineStart) .. changedLine .. strsub(currentText, lineEnd+1))
    MacroFrameText:SetCursorPosition(lineStart + string.len(changedLine) -1)

    ClearCursor()
  
  
  else
  
    -- print("You clicked at", cursorPosition)
    
    -- Check if the user clicker on the target word.
    -- Get current word.
    local wordStart, wordEnd = GetSection(currentText, cursorPosition, " ")
    
    local currentWord = strsub(currentText, wordStart, wordEnd)
    -- print("current word:", currentWord)
    
    if targetTerms[currentWord] then
      
      local menu = { { text = "Select an Option", isTitle = true, notCheckable = true} }
      
      for _, v in pairs(targetTermsOrder) do
      
        local newEntry = {
          text = v,
          checked =
            function()
              return v == currentWord
            end,
          func =
            function() 
              -- print("You clicked", v)
              MacroFrameText:SetText(strsub(currentText, 0, wordStart > 0 and wordStart -1 or wordStart) .. v .. strsub(currentText, wordEnd+1))
              MacroFrameText:SetCursorPosition(wordStart + string.len(v) -1)
            end,
        }
        
        tinsert(menu, newEntry)
        
      end
      
      -- Make the menu appear at the cursor: 
      EasyMenu(menu, targetTermsMenuFrame, "cursor", 0 , 0, "MENU");
    end
    
  end
  
end


local addonLoadedFrame = CreateFrame("Frame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(self, event, arg1, ...)
  if arg1 == "Blizzard_MacroUI" then

    MacroFrameText:HookScript("OnMouseUp", MyReceive)
    MacroFrameText:HookScript("OnReceiveDrag", MyReceive)

    MacroFrameTextBackground:HookScript("OnMouseUp", MyReceive)
    MacroFrameTextBackground:HookScript("OnReceiveDrag", MyReceive)

    MacroFrameTextButton:HookScript("OnMouseUp", MyReceive)
    MacroFrameTextButton:HookScript("OnReceiveDrag", MyReceive)

  end
end)



-- -- For more conveniant testing.
-- local startupFrame = CreateFrame("Frame")
-- startupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- startupFrame:SetScript("OnEvent", function()
  -- C_Timer.After(0.3, function()
    -- ShowMacroFrame()
    -- ToggleSpellBook(BOOKTYPE_SPELL)
  -- end)
-- end)



local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local Alert = require("components.Alert")
local Scrollbar = require("components.Scrollbar")
local BasicText = require("components.BasicText")
local BasicButton = require("components.BasicButton")
local TextInput = require("components.TextInput")
local Select = require("components.Select")
local Toggle = require("components.Toggle")
local Rect = require("components.Rect")
local configHelpers = require("util.configHelpers")
local ConfigValidator = require("core.ConfigValidator")
local useTextCanvas = hooks.useTextCanvas
local schemas = require("core.schemas")
local score = require("util.score")

return Solyd.wrapComponent("ConfigEditor", function(props)
    local canvas = useTextCanvas(props.display, props.width*2, props.height*3)

    local theme = props.theme
    local modal = Solyd.useContext("modal")
    local modalElements = modal[0]
    local setModalElements = modal[1]
    local configDiffs, setConfigDiffs = Solyd.useState({})
    local arrayAdds, setArrayAdds = Solyd.useState({})
    local arrayRemoves, setArrayRemoves = Solyd.useState({})
    local saveModalOpen, setSaveModalOpen = Solyd.useState(false)
    local updates, setUpdates = Solyd.useState(0)
    local errors, setErrors = Solyd.useState(props.errors or {})
    if not props.terminalState.configPath then
        props.terminalState.configPath = ""
    end
    local subConfig = props.config
    local subSchema = props.schema
    local paths = {}
    local unsavedChanges = false
    for k,v in pairs(configDiffs) do
        unsavedChanges = true
        break
    end
    for k,v in pairs(arrayAdds) do
        unsavedChanges = true
        break
    end
    for k,v in pairs(arrayRemoves) do
        unsavedChanges = true
        break
    end
    if arrayAdds[props.terminalState.configPath] or arrayAdds["." .. props.terminalState.configPath] then
        subConfig = {}
    end
    for path in props.terminalState.configPath:gmatch("([^%[?%]?%.?]+)") do
        if path:match("%d+") then
            path = tonumber(path) or path
        end
        if subConfig[path] then
            subConfig = subConfig[path]
        else
            --subConfig[path] = {}
            --subConfig = subConfig[path]
            subConfig = {}
        end
        if subSchema[path] then
            subSchema = subSchema[path]
            if subSchema == "sound" or subSchema == "sound?" then
                subSchema = schemas.soundSchema
            end
        elseif subSchema.__type and subSchema.__type:sub(1,5) == "array" and subSchema.__entry then
            subSchema = subSchema.__entry
        else
            --subSchema[path] = {}
            --subSchema = subSchema[path]
            subSchema = {}
        end
        table.insert(paths, path)
    end
    local elements = {}
    table.insert(elements, Rect {
        key = "bg",
        display = props.display,
        x = (props.x*2)-1,
        y = (props.y*3)-2,
        width = props.width*2,
        height = props.height*3,
        color = theme.bgColor,
    })
    if errors and #errors > 0 then
        table.insert(elements, BasicButton {
            key = "save-error",
            display = props.display,
            x = props.x,
            y = props.y,
            text = "Save(!)",
            onClick = function()
                -- Open modal to confirm
                setSaveModalOpen(true)
            end,
            bg = theme.errorBgColor,
            color = theme.errorTextColor,
        })
    elseif unsavedChanges then
        table.insert(elements, BasicButton {
            key = "save-unsaved",
            display = props.display,
            x = props.x,
            y = props.y,
            text = " Save ",
            onClick = function()
                -- Open modal to confirm
                setSaveModalOpen(true)
            end,
            bg = theme.unsavedChangesColor,
            color = theme.unsavedChangesTextColor,
        })
    else
        table.insert(elements, BasicButton {
            key = "save-disabled",
            display = props.display,
            x = props.x,
            y = props.y,
            text = " Save ",
            onClick = function()
                -- Do nothing, nothing to save
            end,
            bg = theme.inactiveButtonColor,
            color = theme.inactiveButtonTextColor,
        })
    end
    if #paths > 0 then
        table.insert(elements, BasicButton {
            key = "back",
            display = props.display,
            x = props.x + 8,
            y = props.y,
            text = " Back ",
            onClick = function()
                if #paths > 0 then
                    props.terminalState.scroll = 0
                    table.remove(paths)
                    props.terminalState.configPath = table.concat(paths, ".")
                end
            end,
            bg = theme.buttonColor,
            color = theme.buttonTextColor,
        })
        
        table.insert(elements, BasicText {
            key = "path",
            display = props.display,
            x = props.x + 15,
            y = props.y,
            text = props.terminalState.configPath,
            bg = theme.buttonColor,
            color = theme.buttonTextColor,
        })
    end

    local elementY = 0
    local numKeys = 0
    if type(subSchema) == "table" then
        if not subSchema.__type or true then
            local fields = subSchema
            local xOffset = 0
            local isArray = false
            local arrayLabel = nil
            if subSchema.__type and subSchema.__type:sub(1,5) == "array" and subSchema.__entry then
                fields = score.copyDeep(subConfig)
                numKeys = numKeys + 1
                xOffset = 1
                isArray = true
                if subSchema.__label then
                    arrayLabel = subSchema.__label
                end
            end
            for k, _ in pairs(fields) do
                numKeys = numKeys + 1
            end
            if subSchema.__type and subSchema.__type:sub(1,5) == "array" and subSchema.__entry then
                while not fields[numKeys] and arrayAdds[props.terminalState.configPath .. "." .. tostring(numKeys)] do
                    fields[numKeys] = {}
                    numKeys = numKeys + 1
                end
            end

            props.terminalState.maxScroll = math.max(0, (numKeys*3) - props.height)
            local lastSelect = false
            local editorFields = {}
            for k, _ in pairs(fields) do
                table.insert(editorFields, k)
            end
            -- Sort editorFields alphabetically
            table.sort(editorFields, function(a, b)
                -- Return whether the string a should come before b alphabetically
                if type(a) == "number" and type(b) == "number" then
                    return a < b
                elseif type(a) == "number" then
                    return true
                elseif type(b) == "number" then
                    return false
                else
                    return a < b
                end
            end)

            for _, k in pairs(editorFields) do
                v = fields[k]
                lastSelect = false
                local textY = props.y + 1 + elementY - props.terminalState.scroll
                local fullPath = props.terminalState.configPath .. "." .. tostring(k)
                local buttonColor = theme.buttonColor
                local buttonTextColor = theme.buttonTextColor
                if arrayRemoves[fullPath] then
                    buttonColor = theme.inactiveButtonColor
                    buttonTextColor = theme.inactiveButtonTextColor
                    if subSchema.__type and subSchema.__type:sub(1,5) == "array" and subSchema.__entry then
                        v = subSchema.__entry
                        k = tostring(k)
                        if textY >= props.y + 1 and textY <= props.y + props.height then
                            table.insert(elements, BasicButton {
                                key = "restore-" .. k,
                                display = props.display,
                                x = props.x,
                                y = textY,
                                text = "o",
                                color = buttonColor,
                                bg = buttonTextColor,
                                onClick = function()
                                    arrayRemoves[fullPath] = nil
                                    setArrayRemoves(arrayRemoves)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end
                            })
                        end
                        if textY + 1 >= props.y + 1 and textY + 1 <= props.y + props.height then
                            table.insert(elements, BasicButton {
                                key = "restore-spacer-" .. k,
                                display = props.display,
                                x = props.x,
                                y = textY+1,
                                text = " ",
                                color = buttonColor,
                                bg = buttonTextColor,
                                onClick = function()
                                    arrayRemoves[fullPath] = nil
                                    setArrayRemoves(arrayRemoves)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end
                            })
                        end
                    end
                else
                    if subSchema.__type and subSchema.__type:sub(1,5) == "array" and subSchema.__entry then
                        v = subSchema.__entry
                        k = tostring(k)
                        if textY >= props.y + 1 and textY <= props.y + props.height then
                            table.insert(elements, BasicButton {
                                key = "delete-" .. k,
                                display = props.display,
                                x = props.x,
                                y = textY,
                                text = "x",
                                color = theme.errorTextColor,
                                bg = theme.errorBgColor,
                                onClick = function()
                                    arrayRemoves[fullPath] = true
                                    setArrayRemoves(arrayRemoves)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end
                            })
                        end
                        if textY + 1 >= props.y + 1 and textY + 1 <= props.y + props.height then
                            table.insert(elements, BasicButton {
                                key = "delete-spacer-" .. k,
                                display = props.display,
                                x = props.x,
                                y = textY+1,
                                text = " ",
                                color = theme.errorTextColor,
                                bg = theme.errorBgColor,
                                onClick = function()
                                    arrayRemoves[fullPath] = true
                                    setArrayRemoves(arrayRemoves)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end
                            })
                        end
                    end
                end
                if errors and #errors > 0 then
                    for i = 1, #errors do
                        -- error on config.branding.title will trigger for config.branding
                        local pathMatch = props.errorPrefix .. "." .. fullPath
                        if fullPath:sub(1,1) == "." then
                            pathMatch = props.errorPrefix .. fullPath
                        end
                        local errorPath = errors[i].path:gsub("%[(%d+)%]", "%.%1")
                        if  errorPath == pathMatch or errorPath:sub(1, #pathMatch + 1) == pathMatch .. "." then
                            buttonColor = theme.errorBgColor
                            buttonTextColor = theme.errorTextColor
                        end
                    end
                end
                if type(v) == "table" or type(v) == "string" and v:sub(1,5) == "sound" then
                    local label = k
                    if isArray and arrayLabel then
                        local labelPath = fullPath .. "." .. arrayLabel
                        if labelPath:sub(1,1) == "." then
                            labelPath = labelPath:sub(2)
                        end
                        if type(v) == "table" and configDiffs[labelPath] then
                            label = configDiffs[labelPath]
                        elseif type(v) == "table" and subConfig[tonumber(k)] and subConfig[tonumber(k)][arrayLabel] then
                            label = subConfig[tonumber(k)][arrayLabel]
                        end
                    end
                    print(textutils.serialize(configDiffs))
                    if textY >= props.y + 1 and textY <= props.y + props.height then
                        table.insert(elements, BasicButton {
                            key = "config-"..k,
                            display = props.display,
                            align = "left",
                            text = " " .. label .. " ",
                            x = props.x + xOffset,
                            y = textY,
                            color = buttonTextColor,
                            bg = buttonColor,
                            width = math.min(#label+2, props.width - 2) - xOffset,
                            onClick = function()
                                props.terminalState.scroll = 0
                                table.insert(paths, k)
                                props.terminalState.configPath = table.concat(paths, ".")
                            end,
                        })
                    end
                    textY = textY + 1
                    if textY >= props.y + 1 and textY <= props.y + props.height then
                        table.insert(elements, BasicButton {
                            key = "configarrow-"..k,
                            display = props.display,
                            align = "center",
                            text = "-->",
                            x = props.x + xOffset,
                            y = textY,
                            color = buttonTextColor,
                            bg = buttonColor,
                            width = math.min(#label+2, props.width - 2) - xOffset,
                            onClick = function()
                                props.terminalState.scroll = 0
                                table.insert(paths, k)
                                props.terminalState.configPath = table.concat(paths, ".")
                            end,
                        })
                    end
                elseif type(v) == "string" then
                    _, _, typeDef, typeName = v:find("^(%w+<.+>)%??: (.+)$")
                    if textY >= props.y + 1 and textY <= props.y + props.height then
                        local nameText = k .. ": " .. (typeName or v)
                        if fullPath:find("palette") then
                            local field = configHelpers.getColorName(k)
                            nameText = field .. ": color code"
                        end
                        table.insert(elements, BasicButton {
                            key = "config-key-"..k,
                            display = props.display,
                            align = "left",
                            text = nameText,
                            x = props.x + xOffset,
                            y = textY,
                            color = buttonTextColor,
                            bg = buttonColor,
                            width = props.width - 1 - xOffset,
                            onClick = function()
                                -- props.terminalState.scroll = 0
                                -- table.insert(paths, k)
                                -- props.terminalState.configPath = table.concat(paths, ".")
                            end,
                        })
                    end
                    textY = textY + 1
                    if textY >= props.y + 1 and textY <= props.y + props.height then
                        if v:sub(1, 6) == "string" or v:sub(1,5) == "regex" or v:sub(1,4) == "file"
                            or v:sub(1,5) == "modem" or v:sub(1,7) == "speaker" or v:sub(1,5) == "chest" then
                            local inputStateValue = configDiffs[fullPath] or subConfig[k]
                            if inputStateValue == "%nil%" then
                                inputStateValue = nil
                            end
                            table.insert(elements, TextInput {
                                key = "config-value-"..k,
                                display = props.display,
                                align = "left",
                                x = props.x + xOffset,
                                y = textY,
                                color = theme.inputTextColor,
                                bg = theme.inputBgColor,
                                height = 1,
                                width = props.width - 1 - xOffset,
                                inputState = { value = configDiffs[fullPath] or subConfig[k]  },
                                onChange = function(value)
                                    if value == "" or value == nil then
                                        value = "%nil%"
                                    end
                                    configDiffs[fullPath] = value
                                    setConfigDiffs(configDiffs)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end,
                            })
                        elseif v:sub(1, 7) == "boolean" then
                            local toggleStartValue = configDiffs[fullPath]
                            if toggleStartValue == nil then
                                toggleStartValue = subConfig[k]
                            end
                            table.insert(elements, Rect {
                                key = "config-value-" .. k .. "-bg",
                                display = props.display,
                                x = (props.x*2)-1 + xOffset*2,
                                y = (textY*3)-2,
                                color = buttonColor,
                                width = (props.width * 2) - 2,
                                height = 3,
                            })
                            table.insert(elements, Toggle {
                                key = "config-value-"..k,
                                display = props.display,
                                x = (props.x*2)-1 + xOffset,
                                y = (textY*3)-2,
                                color = theme.toggleColor,
                                bg = theme.toggleBgColor,
                                onColor = theme.toggleOnColor,
                                offColor = theme.toggleOffColor,
                                width = 2 * 6,
                                height = 2,
                                inputState = { value = toggleStartValue  },
                                onChange = function(value)
                                    configDiffs[fullPath] = value
                                    setConfigDiffs(configDiffs)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end,
                            })
                        elseif v:sub(1, 6) == "number" then
                            table.insert(elements, Rect {
                                key = "config-value-" .. k .. "-bg",
                                display = props.display,
                                x = (props.x*2)-1 + 12*2 + xOffset*2,
                                y = (textY*3)-2,
                                color = buttonColor,
                                width = (props.width * 2) - 2 - 12*2 -  xOffset*2,
                                height = 3,
                            })
                            local inputType = "number"
                            if fullPath:find("palette") then
                                inputType = "colorpicker"
                            end
                            table.insert(elements, TextInput {
                                key = "config-value-"..k,
                                display = props.display,
                                type = inputType,
                                align = "left",
                                x = props.x + xOffset,
                                y = textY,
                                color = theme.inputTextColor,
                                bg = theme.inputBgColor,
                                height = 1,
                                width = 12,
                                inputState = { value = configDiffs[fullPath] or subConfig[k]  },
                                onChange = function(value)
                                    configDiffs[fullPath] = value
                                    setConfigDiffs(configDiffs)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end,
                            })
                        elseif v:sub(1, 5) == "color" then
                            lastSelect = true
                            table.insert(elements, Select {
                                key = "config-value-"..k,
                                display = props.display,
                                x = props.x + xOffset,
                                y = textY,
                                color = theme.inputTextColor,
                                bg = theme.inputBgColor,
                                scrollbarColor = theme.scrollbarColor,
                                toggleColor = theme.toggleColor,
                                height = props.y + props.height - textY,
                                width = props.width - 1 - xOffset,
                                inputState = { value = configDiffs[fullPath] or subConfig[k] },
                                options = {
                                    { value = colors.black, text = "Black" },
                                    { value = colors.blue, text = "Blue" },
                                    { value = colors.purple, text = "Purple" },
                                    { value = colors.green, text = "Green" },
                                    { value = colors.brown, text = "Brown" },
                                    { value = colors.gray, text = "Gray" },
                                    { value = colors.lightGray, text = "Light Gray" },
                                    { value = colors.red, text = "Red" },
                                    { value = colors.orange, text = "Orange" },
                                    { value = colors.yellow, text = "Yellow" },
                                    { value = colors.lime, text = "Lime" },
                                    { value = colors.cyan, text = "Cyan" },
                                    { value = colors.magenta, text = "Magenta" },
                                    { value = colors.pink, text = "Pink" },
                                    { value = colors.lightBlue, text = "Light Blue" },
                                    { value = colors.white, text = "White" },
                                },
                                onChange = function(value)
                                    configDiffs[fullPath] = value
                                    setConfigDiffs(configDiffs)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end,
                            })
                        elseif typeDef and typeDef:sub(1, 5) == "enum<" and typeDef:sub(-1) == ">" then
                            lastSelect = true
                            local enum = typeDef:sub(6, -2)
                            local options = {}
                            for enumValue in enum:gmatch("[^|]+") do
                                enumValue = enumValue:sub(enumValue:find("'(.*)'")):sub(2, -2)
                                table.insert(options, { value = enumValue, text = enumValue })
                            end
                            table.insert(elements, Select {
                                key = "config-value-"..k,
                                display = props.display,
                                x = props.x + xOffset,
                                y = textY,
                                color = theme.inputTextColor,
                                bg = theme.inputBgColor,
                                scrollbarColor = theme.scrollbarColor,
                                toggleColor = theme.toggleColor,
                                height = props.y + props.height - textY,
                                width = props.width - 1 - xOffset,
                                inputState = { value = configDiffs[fullPath] or subConfig[k] },
                                options = options,
                                onChange = function(value)
                                    configDiffs[fullPath] = value
                                    setConfigDiffs(configDiffs)
                                    setUpdates(updates + 1)
                                    local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                    setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                                end,
                            })
                        end
                    end
                end
                elementY = elementY + 3
                if textY + 1 > props.y + props.height then
                    break
                end
            end
            if subSchema.__type and subSchema.__type:sub(1,5) == "array" and subSchema.__entry then
                if not subSchema.__max or (numKeys-1) < subSchema.__max then
                    -- Show add new button
                    -- (With red exclamation if min not met)
                    local minMet = not subSchema.__min or (numKeys-1) >= subSchema.__min
                    local buttonText = "Add New"
                    if not minMet then
                        buttonText = buttonText .. " (Needs " .. tostring(subSchema.__min - numKeys + 1) .. " more)"
                    end
                    local buttonColor = minMet and theme.buttonColor or theme.errorBgColor
                    local buttonTextColor = minMet and theme.buttonTextColor or theme.errorTextColor
                    textY = props.y + 1 + elementY - props.terminalState.scroll
                    if textY >= props.y + 1 and textY <= props.y + props.height then
                        table.insert(elements, BasicButton {
                            key = "config-add-"..props.terminalState.configPath,
                            display = props.display,
                            x = props.x,
                            y = textY,
                            align = "center",
                            color = buttonTextColor,
                            bg = buttonColor,
                            height = 1,
                            width = #buttonText + 2,
                            text = buttonText,
                            onClick = function()
                                arrayAdds[props.terminalState.configPath .. "." .. tostring(numKeys)] = true
                                setArrayAdds(arrayAdds)
                                setUpdates(updates + 1)
                                local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                            end,
                        })
                    end
                    if textY+1 >= props.y + 1 and textY+1 <= props.y + props.height then
                        table.insert(elements, BasicButton {
                            key = "config-add2-"..props.terminalState.configPath,
                            display = props.display,
                            x = props.x,
                            y = textY+1,
                            align = "center",
                            color = buttonTextColor,
                            bg = buttonColor,
                            height = 1,
                            width = #buttonText + 2,
                            text = "",
                            onClick = function()
                                arrayAdds[props.terminalState.configPath .. "." .. tostring(numKeys)] = true
                                setArrayAdds(arrayAdds)
                                setUpdates(updates + 1)
                                local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                                setErrors(ConfigValidator.validate(newConfig, props.schema, props.errorPrefix))
                            end,
                        })
                    end
                end
            end
            if lastSelect then
                props.terminalState.maxScroll = props.terminalState.maxScroll + 3
            end
            if props.terminalState.maxScroll > 0 then
                table.insert(elements, Scrollbar {
                    key = "sb",
                    display = props.display,
                    x = (props.x + props.width - 1)*2 - 1,
                    y = (props.y*3)-2,
                    width = 2,
                    height = props.height * 3,
                    areaHeight = props.height * 3,
                    scroll = props.terminalState.scroll * 3,
                    maxScroll = props.terminalState.maxScroll * 3,
                    color = theme.scrollbarColor,
                    bg = theme.scrollbarBgColor,
                })
            end
        elseif subSchema.__type == "array" then
            -- Dealing with an array
        end
    end
    if saveModalOpen then
        local modalWidth = math.min(props.width, 30)
        local modalHeight = 6
        local modalText = "Are you sure\nyou want to save?"
        if errors and #errors > 0 then
            modalText = "Your config is incomplete,\nare you sure you want to\nsave?"
        end
        table.insert(elements, Alert {
            key = "save-modal",
            display = props.display,
            x = math.floor(props.x + (props.width/2) - (modalWidth/2)),
            y = math.floor(props.y + (props.height/2) - (modalHeight/2)),
            align = "center",
            width = modalWidth,
            height = modalHeight,
            text = modalText,
            bg = theme.modalBgColor,
            color = theme.modalTextColor,
            buttonColor = theme.inactiveButtonColor,
            buttonTextColor = theme.inactiveButtonTextColor,
            borderColor = theme.modalBorderColor,
            onConfirm = function()
                local newConfig = configHelpers.getNewConfig(props.config, configDiffs, arrayAdds, arrayRemoves)
                setSaveModalOpen(false)
                setArrayAdds({})
                setArrayRemoves({})
                setConfigDiffs({})
                setUpdates(updates + 1)
                if props.onSave then
                    props.onSave(newConfig)
                end
            end,
            onCancel = function()
                setSaveModalOpen(false)
            end,
        })
    end

    -- local logMessageY = props.height
    -- for i = 1, math.min(#props.errors, props.height) do
    --     local logMessage = "[" .. props.errors[i].path .. "] " .. props.errors[i].error
    --     local numLines = math.ceil(#logMessage / props.width)
    --     if logMessageY - numLines + 1 < 0 then
    --         break
    --     end
    --     for j = 1, numLines do
    --         local line = logMessage:sub((j - 1) * props.width + 1, j * props.width)
    --         table.insert(elements, BasicText {
    --             key = "errors-"..tostring(i).."-"..tostring(j),
    --             display = props.display,
    --             align = "left",
    --             text = line,
    --             x = 1,
    --             y = logMessageY - numLines + j + 1,
    --             color = props.buttonTextColor,
    --             bg = props.buttonBgColor,
    --         })
    --     end
    --     logMessageY = logMessageY - numLines
    -- end

    return elements, { canvas = { canvas, props.x*2-1, props.y*3-2 } }
end)

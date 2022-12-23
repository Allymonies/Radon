local _ = require("util.score")
local Solyd = require("modules.solyd")

---@param props { x: integer, y: integer, width: integer, children: SolydElement[] }
return Solyd.wrapComponent("Flex", function(props)
    local remainingWidth = props.width

    local children, flexElCount, flexCount = {}, 0, 0
    for i, child in ipairs(props.children) do
        if type(child) == "table" then
            if child.props.width then
                table.insert(children, { element = child, width = child.props.width })
                remainingWidth = remainingWidth - child.props.width - (i > 1 and 1 or 0)
            else
                local flex = child.props.flex or 1
                table.insert(children, { element = child, flex = flex })
                flexCount = flexCount + flex
                flexElCount = flexElCount + 1
            end
        end
    end

    local x = props.x
    local flexWidth = math.ceil((remainingWidth - flexElCount) / flexCount)

    remainingWidth = props.width
    for i, child in ipairs(children) do
        local width = math.min(remainingWidth, child.width or flexWidth*child.flex)
        child.element.props.width = width
        child.element.props.x = x
        child.element.props.y = props.y
        x = x + width + 1
        remainingWidth = remainingWidth - width - (i > 1 and 1 or 0)
    end

    return _.map(children, function(el) return el.element end)
end)

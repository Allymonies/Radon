---@diagnostic disable: undefined-global

package.path = "/" .. shell.dir() .. "/?.lua;" .. package.path

local base64 = require "util.base64"

local mixin = require "howl.class.mixin"

local CopySource = require "howl.files.CopySource"
local Runner = require "howl.tasks.Runner"
local Task = require "howl.tasks.Task"

local Context = require "howl.tasks.Context"

Options:Default "trace"

Tasks:clean "clean" (function(spec)
    spec:include { "build/*.lua" }
end)

Tasks:clean "cleanIntermediate" (function(spec)
    spec:include { "res/*.lua", "audio/*.lua" }
end)

local SourceTask = Task:subclass("radon.SourceTask")
    :include(mixin.filterable)
    :include(mixin.delegate("sources", {"from", "include", "exclude"}))
    :addOptions { "action" }

function SourceTask:initialize(context, name, dependencies, action)
    Task.initialize(self, name, dependencies)

    self.root = context.root
    self.sources = CopySource()
    self:exclude { ".git", ".svn", ".gitignore" }

    self:description "Runs an action on all files matching a pattern"
end

function SourceTask:runAction(context)
    local files = self.sources:gatherFiles(self.root)

    local action = self.options.action
    if type(action) == "function" then
        for _, input in ipairs(files) do
            action(self, context, input)
        end
    else
        error("No action specified")
    end
end

Runner:include({ sourceTask = function(self, name, taskDepends, taskAction)
    return self:injectTask(SourceTask(self.env, name, taskDepends, taskAction))
end })

local class = require "howl.class"
local MapTask = class("radon.MapTask")
MapTask.__tostring = function(self) return self.output end
function MapTask:initialize(input, output)
    self.input = input
    self.output = output
end

Tasks:injectTask(Tasks:Task "encodeu8" (function(self, context, task)
    local iF = fs.open(task.input.path, "rb")
    task.input.contents = iF.readAll()
    iF.close()

    local oF = fs.open(task.output, "wb")
    oF.write("return \"" .. base64.encode(task.input.contents) .. "\"")
    oF.close()
end))

Tasks:sourceTask "mapBinaries" (function(spec)
    spec:from "audio" {
        include = { "*.u8" },
        exclude = { "*.lua" },
    }

    spec:from "res" {
        include = { "*.rif" },
        exclude = { "*.lua" },
    }

    spec:action(function(self, context, file)
        local output = file.path:gsub("(.*)%.(.*)", "%1.lua")
        if not fs.exists(output) then
            Tasks.tasks["encodeu8"]:Run(Context(Tasks), MapTask(file, output))
        end
    end)
end)

Tasks:minify "minify" {
	input = "build/radon.lua",
	output = "build/radon.min.lua",
}

Tasks:require "main" {
	include = {"components/*.lua", "core/*.lua", "fonts/*.lua", "Krypton/*.lua", "modules/*.lua", "res/*.lua", "util/*.lua", "DefaultLayout.lua", "radon.lua", "profile.lua", "configDefaults.lua"},
	startup = "radon.lua",
	output = "build/radon.lua",
}

Tasks:Task "build" { "mapBinaries", "main", "cleanIntermediate" }

Tasks:Default "build"

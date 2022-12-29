Options:Default "trace"

Tasks:clean()

Tasks:minify "minify" {
	input = "build/radon.lua",
	output = "build/radon.min.lua",
}

Tasks:require "main" {
	include = {"components/*.lua", "core/*.lua", "fonts/*.lua", "Krypton/*.lua", "modules/*.lua", "res/*.lua", "util/*.lua", "radon.lua", "profile.lua"},
	startup = "radon.lua",
	output = "build/radon.lua",
}

Tasks:Task "build" { "clean", "minify" } :Description "Main build task"

--[[Tasks:gist "upload" (function(spec)
	spec:summary "A build system for Lua (http://www.computercraft.info/forums2/index.php?/topic/21254- and https://github.com/SquidDev-CC/Howl)"
	spec:gist "703e2f46ce68c2ca158673ff0ec4208c"
	spec:from "build" {
		include = { "Howl.lua", "Howl.min.lua" }
	}
end) :Requires { "build/Howl.lua", "build/Howl.min.lua" }]]

Tasks:Default "main"
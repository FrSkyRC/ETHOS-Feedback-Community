compile = {}

local arg = {...}
local config = arg[1]
local moduleDir = config.moduleDir

function compile.file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function compile.baseName()
	local baseName
	baseName = config.moduleDir:gsub("/scripts/","")
	baseName = baseName:gsub("/","")
	return baseName
end

function compile.loadScript(script)


	local cachefile
	cachefile = moduleDir .. "compiled/" .. script:gsub("/", "_") .. "c"


    if compile.file_exists("/scripts/" .. compile.baseName() .. ".nocompile" ) == true then
		config.useCompiler = false
	end

    if compile.file_exists("/scripts/nocompile" ) == true then
		config.useCompiler = false
	end

    if config.useCompiler == true then
        if compile.file_exists(cachefile) ~= true then
            system.compile(script)
            os.rename(script .. 'c', cachefile)
        end
        --print("Loading: " .. cachefile)
        return loadfile(cachefile)
    else
        if compile.file_exists(cachefile) == true then
            os.remove(cachefile)
        end		
		--print("Loading: " .. script)
        return loadfile(script)
    end

end

return compile

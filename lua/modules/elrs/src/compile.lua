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

function compile.dir_exists(base,name)
        list = system.listFiles(base)       
        for i,v in pairs(list) do
                if v == name then
                        return true
                end
        end
        return false
end

function compile.baseName()
        local baseName
        baseName = config.moduleDir:gsub("/scripts/", "")
        baseName = baseName:gsub("/", "")
        return baseName
end

function compile.loadScript(script)

        if os.mkdir ~= nil and compile.dir_exists(moduleDir , "compiled") == false then
                        os.mkdir(moduleDir .. "compiled")
                        
        end
        
        local cachefile
        cachefile = moduleDir .. "compiled/" .. script:gsub("/", "_") .. "c"

        if compile.file_exists("/scripts/" .. compile.baseName() .. ".nocompile") == true then config.useCompiler = false end

        if compile.file_exists("/scripts/nocompile") == true then config.useCompiler = false end

        -- do not compile if for some reason the compiler cache folder is missing
        if compile.dir_exists(moduleDir , "compiled") == false then
                config.useCompiler = false
        end

        if config.useCompiler == true then
                if compile.file_exists(cachefile) ~= true then
                        system.compile(script)
                        os.rename(script .. 'c', cachefile)
                end
                return loadfile(cachefile)
        else
                if compile.file_exists(cachefile) == true then os.remove(cachefile) end
                return loadfile(script)
        end

end

return compile

local modules, require_module

    for _, func in getgc(false) do
        if type(func) == "function" and getfenv(func).script and getfenv(func).script.Name == "ClientLoader" then
            require_module = func
            modules = setmetatable({}, {__index = function(self, index)
                return require_module(index)
            end})
            break
        end
    end

for name, module in pairs(modules) do
    print("Module Name:", name, "| Module:", module)
end

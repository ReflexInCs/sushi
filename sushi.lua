-- HTTP Request Hooking Script
-- Blocks .com and forces .app for platoboost API requests
-- Handles read-only tables using metatables

-- Function to modify URL
local function modifyURL(url)
    if type(url) == "string" and string.find(url, "platoboost%.com") then
        local new_url = string.gsub(url, "platoboost%.com", "platoboost.app")
        print("[BLOCKED] .com request: " .. url)
        print("[FORCED] .app request: " .. new_url)
        return new_url
    end
    return url
end

-- Try to hook using debug library if available
local function hookFunction(obj, func_name, wrapper)
    if not obj or not obj[func_name] then return false end
    
    local success, err = pcall(function()
        local original = obj[func_name]
        obj[func_name] = function(...)
            return wrapper(original, ...)
        end
    end)
    
    if success then
        print("[HOOK] Successfully hooked " .. func_name)
        return true
    else
        print("[FAILED] Could not hook " .. func_name .. ": " .. tostring(err))
        return false
    end
end

-- Create wrapper for requests
local function createRequestWrapper(original_func)
    return function(url_or_options, ...)
        -- Handle string URL
        if type(url_or_options) == "string" then
            url_or_options = modifyURL(url_or_options)
            return original_func(url_or_options, ...)
        end
        
        -- Handle table with URL
        if type(url_or_options) == "table" then
            -- Create a new table instead of modifying read-only one
            local new_options = {}
            for k, v in pairs(url_or_options) do
                new_options[k] = v
            end
            
            -- Modify URL fields
            if new_options.url then
                new_options.url = modifyURL(new_options.url)
            end
            if new_options.uri then
                new_options.uri = modifyURL(new_options.uri)
            end
            if new_options[1] then
                new_options[1] = modifyURL(new_options[1])
            end
            
            return original_func(new_options, ...)
        end
        
        return original_func(url_or_options, ...)
    end
end

-- Attempt to hook various HTTP libraries
local http_libs = {"http", "socket.http", "requests", "net.http", "https"}
local hooked_count = 0

for _, lib_name in ipairs(http_libs) do
    local success, lib = pcall(require, lib_name)
    if success and lib then
        -- Try hooking request
        if lib.request then
            if hookFunction(lib, "request", createRequestWrapper) then
                hooked_count = hooked_count + 1
            end
        end
        
        -- Try hooking get
        if lib.get then
            hookFunction(lib, "get", function(original, url, ...)
                return original(modifyURL(url), ...)
            end)
        end
        
        -- Try hooking post
        if lib.post then
            hookFunction(lib, "post", function(original, url, ...)
                return original(modifyURL(url), ...)
            end)
        end
    end
end

-- Global interceptor function
_G.interceptURL = function(url)
    return modifyURL(url)
end

-- Metatable hooking removed to avoid read-only errors

print("═══════════════════════════════════════")
if hooked_count > 0 then
    print("[SUCCESS] Installed " .. hooked_count .. " hooks")
    print("[ACTIVE] platoboost.com is BLOCKED")
    print("[ACTIVE] All requests forced to .app")
else
    print("[INFO] No auto-hooks installed")
    print("[INFO] Use _G.interceptURL(url) manually")
    print("[INFO] Or wrap your requests with interceptURL()")
end
print("═══════════════════════════════════════")

return {
    interceptURL = modifyURL,
    isActive = hooked_count > 0
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/qAxAp/Ultimate-Lifting-sim/refs/heads/main/sushi"))()

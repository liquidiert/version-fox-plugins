---    Copyright 2024 [lihan aooohan@gmail.com]
--
--   Licensed under the Apache License, Version 2.0 (the "License");
--   you may not use this file except in compliance with the License.
--   You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.

local http = require("http")
local html = require("html")
local json = require("json")

OS_TYPE = ""
ARCH_TYPE = ""

GOLANG_URL = "https://go.dev/dl/"

PLUGIN = {
    --- Plugin name
    name = "golang",
    --- Plugin author
    author = "Aooohan",
    --- Plugin version
    version = "0.0.3",
    -- Update URL
    --updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/golang/golang.lua",
    minRuntimeVersion = "0.3.0",
    manifestUrl = "https://github.com/version-fox/vfox-golang/releases/download/manifest/manifest.json"
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local releases = getReleases()
    if version == "latest" then
        return releases[1]
    end
    for _, release in ipairs(releases) do
        if release.version == version then
            return release
        end
    end
    return {}
end

function PLUGIN:PostInstall(ctx)
end

function PLUGIN:Available(ctx)
    return getReleases()
end

function getReleases()
    local result = {}
    local resp, err = http.get({
        url = GOLANG_URL .. "?mode=json"
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("paring release info failed." .. err)
    end
    local body = json.decode(resp.body)
    for _, info in ipairs(body) do
        local v = string.sub(info.version, 3)
        for _, file in ipairs(info.files) do
            if file.kind == "archive" and file.os == OS_TYPE and file.arch == ARCH_TYPE then
                table.insert(result, {
                    version = v,
                    url = GOLANG_URL .. file.filename,
                    note = "stable",
                    sha256 = file.sha256,
                })
            end
        end
    end
    resp, err = http.get({
        url = GOLANG_URL
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("paring release info failed." .. err)
    end
    local type = getOsTypeAndArch()
    local doc = html.parse(resp.body)
    local listDoc = doc:find("div#archive")
    listDoc:find(".toggle"):each(function(i, selection)
        local versionStr = selection:attr("id")
        if versionStr ~= nil then
            selection:find("table.downloadtable tbody tr"):each(function(ti, ts)
                local td = ts:find("td")
                local filename = td:eq(0):text()
                local kind = td:eq(1):text()
                local os = td:eq(2):text()
                local arch = td:eq(3):text()
                local checksum = td:eq(5):text()
                if kind == "Archive" and os == type.osType and arch == type.archType then
                    table.insert(result, {
                        version = string.sub(versionStr, 3),
                        url = GOLANG_URL .. filename,
                        note = "",
                        sha256 = checksum,
                    })
                end
            end)
        end
    end)
    return result
end

function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "macOS"
    elseif OS_TYPE == "linux" then
        osType = "Linux"
    elseif OS_TYPE == "windows" then
        osType = "Windows"
    end
    if ARCH_TYPE == "amd64" then
        archType = "x86-64"
    elseif ARCH_TYPE == "arm64" then
        archType = "ARM64"
    elseif ARCH_TYPE == "386" then
        archType = "x86"
    end
    return {
        osType = osType, archType = archType
    }
end

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    return {
        {
            key = "PATH",
            value = mainPath .. "/bin"
        }
    }
end
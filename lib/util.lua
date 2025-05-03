local http = require("http")
local html = require("html")
local strings = require("vfox.strings")

local util = {}

util.ANDROID_REPO_URL = "https://dl.google.com/android/repository/%s"
util.ANDROID_SDK_SPECS = util.ANDROID_REPO_URL:format("repository2-3.xml")

local function parse_version(v)
    if v == "latest" then return math.huge, math.huge, "zzz" end  -- force to end
    local major, minor, suffix = v:match("^(%d+)%.(%d+)(.-)$")
    return tonumber(major), tonumber(minor), suffix or ""
end

local function GetArchive(package)
    local sha1 = ""
    local fileName = ""

    package:find("archive"):each(function(_, a)
        if a:find("host-os"):text() == util:GetOsName() then
            sha1 = a:find("checksum"):text()
            fileName = a:find("url"):text()
        end
    end)

    return { sha1, fileName }
end

function util:FetchAndroidSdkVersions()
    local response = http.get({
        url = util.ANDROID_SDK_SPECS
    })

    if response.status_code ~= 200 then
        print("❌ Fetching Android SDK versions failed!");
        os.exit(1)
    end

    local doc = html.parse(response.body)
    local versions = {}

    doc:find("remotePackage"):each(function(_, package)
        local splits = strings.split(package:attr("path"), ";")
        local name = splits[1]
        local version = splits[2]
        local packageText = package:text()

        if name == "cmdline-tools" and strings.contains(packageText, "<channelRef ref=\"channel-0\"/>") then
            local archive = GetArchive(package)
            table.insert(versions, {
                version = version,
                sha1 = archive[1],
                fileName = archive[2]
            })
        end
    end)

    table.sort(versions, function(a, b)
        local majA, minA, sufA = parse_version(a.version)
        local majB, minB, sufB = parse_version(b.version)

        if majA ~= majB then return majA > majB end
        if minA ~= minB then return minA > minB end
        return sufA < sufB
    end)

    return versions
end

local osNames = {
    ["windows"] = "windows",
    ["linux"] = "linux",
    ["darwin"] = "macosx",
}

function util:GetOsName()
    return osNames[RUNTIME.osType]
end

return util
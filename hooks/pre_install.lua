local util = require("util")

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local versions = util:FetchAndroidSdkVersions()

    for _, version in ipairs(versions) do
        if version.version == ctx.version then
            return {
                version = version.version,
                url = util.ANDROID_REPO_URL:format(version.fileName),
            }
        end
    end

    print("❌ Invalid version input!")
    os.exit(1)
end

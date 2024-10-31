local config = require "common_paths"
local package_info = require "package_info"

local project_key = "catch2"
project (project_key)
    kind "Utility"  -- This project is not compiling anything, just setting up include paths
    language "C++"
    cppdialect "C++20"
    staticruntime "On"

    location (path.join(config.sln_dir, "build", "projects", "packages"))

    local catch2_version = package_info.packages[project_key].version
    -- Correct include directory based on your provided path
    local catch2_header_dir = path.join(config.package_cache, project_key, catch2_version, "catch2", "single_include")

    config.project_includes[project_key] = catch2_header_dir
    
    print("Catch2 include dir: " .. catch2_header_dir)
    files {
        path.join(catch2_header_dir, "**.hpp"),
    }

    includedirs {
        catch2_header_dir  -- Including the directory where Catch2 headers are located
    }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"
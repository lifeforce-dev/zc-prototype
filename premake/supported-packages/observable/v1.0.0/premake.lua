local config = require "common_paths"
local package_info = require "package_info"

local project_key = "observable"
project (project_key)
    kind "StaticLib"
    language "C++"
    cppdialect "C++20"
    staticruntime "On"

    location (path.join(config.sln_dir, "build", "projects", "packages"))

    targetdir (config.lib_dir)
    print("Output directory for observable: " .. config.lib_dir)
    objdir (path.join(config.obj_dir, project_key))

    local observable_version = package_info.packages[project_key].version
    local observable_package_dir = path.join(config.package_cache, project_key, observable_version, project_key, project_key)

    local include_dir = path.join(observable_package_dir, "include")

    -- Set the include directory in config.project_includes for use in other scripts
    config.project_includes[project_key] = include_dir

    print("observable include dir: " .. include_dir)

    files {
        path.join(include_dir, "**.hpp"),
        path.join(src_dir, "**.cpp")
    }

    includedirs {
        include_dir
    }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"
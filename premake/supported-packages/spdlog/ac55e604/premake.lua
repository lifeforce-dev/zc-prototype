local config = require "common_paths"
local package_info = require "package_info"

local project_key = "spdlog"
project (project_key)
    kind "StaticLib"
    language "C++"
    cppdialect "C++20"
    staticruntime "On"

    defines { "SPDLOG_COMPILED_LIB" }

    location (path.join(config.sln_dir, "build", "projects", "packages"))

    targetdir (config.lib_dir)
    print("Output directory for spdlog: " .. config.lib_dir)
    objdir (path.join(config.obj_dir, project_key))

    local spdlog_version = package_info.packages[project_key].version
    local spdlog_package_dir = path.join(config.package_cache, project_key, spdlog_version, project_key)

    local include_dir = path.join(spdlog_package_dir, "include")
    local src_dir = path.join(spdlog_package_dir, "src")
    
    -- Set the include directory in config.project_includes for use in other scripts
    config.project_includes[project_key] = include_dir

    print("spdlog include dir: " .. include_dir)
    print("spdlog source dir: " .. src_dir)

    files {
        path.join(include_dir, "**.h"),
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
local config = require "common_paths"
local package_info = require "package_info"

local project_key = "asio"
project (project_key)
    kind "Utility"
    language "C++"
    cppdialect "C++20"
    staticruntime "On"

    location (path.join(config.sln_dir, "build", "projects", "packages"))

    targetdir (config.lib_dir)
    print("Output directory for asio: " .. config.lib_dir)
    objdir (path.join(config.obj_dir, project_key))

    local asio_version = package_info.packages[project_key].version
    local asio_json_package_dir = path.join(config.package_cache, project_key, asio_version)

    local include_dir = path.join("asio", "asio", "include")
    local asio_include_dir = path.join(asio_json_package_dir, include_dir)
    config.project_includes[project_key] = asio_include_dir


    local source_dir = path.join("asio", "asio", "src")
    local asio_source_dir = path.join(asio_json_package_dir, source_dir)
    
    print("ASIO include dir: " .. asio_include_dir)
    print("ASIO source dir: " .. asio_source_dir)
    
    files {
        path.join(asio_include_dir, "**.hpp")
    }
        
    includedirs {
        asio_include_dir
    }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"

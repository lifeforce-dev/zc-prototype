local config = require "common_paths"
local package_info = require "package_info"

local sln_dir = _OPTIONS["sln_dir"]
local project_key = "nlohmann"

project (project_key)
    kind "Utility"
    language "C++"
    cppdialect "C++20"
    staticruntime "On"

    defines { "JSON_NOEXCEPTION" }

    location (path.join(config.sln_dir, "build", "projects", "packages"))

    local nlohmann_json_version = package_info.packages[project_key].version
    local nlohmann_json_package_dir = path.join(config.package_cache,
                                               project_key, nlohmann_json_version)
    local include_dir = path.join(nlohmann_json_package_dir, "nlohmann", "single_include")
    local path_to_header = path.join(nlohmann_json_package_dir, include_dir, "json.hpp")
    config.project_includes[project_key] = include_dir
    print("NLOHMANN include dir:" .. path.join(nlohmann_json_package_dir, include_dir))
    print("NLOHMANN source dir" .. path.join(nlohmann_json_package_dir, source_dir))
    files {
        path.join(nlohmann_json_package_dir, path_to_header)
    }

    print("Setting include dir. dir=" .. include_dir)
    includedirs { include_dir }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"

local config = require "common_paths"
local package_info = require "package_info"

local project_key = "glm"
project (project_key)
    kind "Utility"
    language "C++"
    cppdialect "C++20"
    staticruntime "On"

    location (path.join(config.sln_dir, "build", "projects", "packages"))

    targetdir (config.lib_dir)
    print("Output directory for glm: " .. config.lib_dir)
    objdir (path.join(config.obj_dir, project_key))

    local glm_version = package_info.packages[project_key].version
    local glm_json_package_dir = path.join(config.package_cache, project_key, glm_version)

    local include_dir = path.join("glm")
    local glm_include_dir = path.join(glm_json_package_dir, include_dir)
    config.project_includes[project_key] = glm_include_dir

    print("glm include dir: " .. glm_include_dir)
    
    files {
        path.join(glm_include_dir, "**.hpp"),
        path.join(glm_include_dir, "**.cpp")
    }
        
    includedirs {
        glm_include_dir
    }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"

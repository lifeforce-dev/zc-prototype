-- Common project paths that are relevant to any premake file.
local common_paths = require "common_paths"

-- Contains the actual user-selected packages to be included for the project.
local package_info = require "package_info"

-- Commandline option sent to premake.
newoption {
    trigger = "sln_name",
    value = "NAME",
    description = "The name of the solution"
}

-- The commandline option for solution name must be set.
if not _OPTIONS["sln_name"] then
    print("Error: You must provide a solution name.")
    os.exit(1)
end

print("Working directory: " .. os.getcwd())

-- Creates filters and adds user created code to user created project files.
local function recursiveAddFiles(dir)
    vpaths {
        ["Source Files/*"] = {},
        ["Header Files/*"] = {}
    }

    files { path.join(dir, "**.cpp") }
    -- The VS filter for source files
    vpaths { ["Source Files/*"] = { path.join(dir, "**.cpp") } }

    files { path.join(dir, "**.h") }
    -- The VS filter for header files.
    vpaths { ["Header Files/*"] = { path.join(dir, "**.h") } }

    -- Premake call to add the directory to the include path.
    includedirs { dir }
end

-- Folders in here will be treated as projects that should be built as static libs.
-- The folder structure is the same, where _static/<project_name> just as source/<project_name>
-- Currently, all projects will depend on any static lib made in here. Its meant for having something
-- like a "common" lib. Perhaps in the future I'll add more control, for now static libs are global.
local static_folder_name = "_static"

local source_dir = path.join(common_paths.sln_dir, "source")
print("Defined source directory: " .. source_dir)

local static_dir = path.join(source_dir, "_static")
print("Defined static directory: " .. static_dir)

local static_lib_dirs = os.matchdirs(path.join(static_dir, "*")) -- Get all directories in 'static'
print("Defined static lib directories: " .. table.concat(static_lib_dirs, ", "))

local projects = os.matchdirs(path.join(source_dir, "*"))

-- Set your startup project here. If not set, we'll select the first one.
local startup_project_name = ""

-- Sets the startup project to the first user-created project we find.
if startup_project_name == "" and #projects > 0 then
    startup_project_name = path.getname(projects[1])
end

-- Defines a sln
workspace (_OPTIONS["sln_name"])

    architecture "x64"
    configurations { "Debug", "Release" }
    cppdialect "C++20"

    if startup_project_name ~= "" then
        startproject(startup_project_name)
        print("startup project name:" .. startup_project_name)
    end

-- Newly vocal warning with recent VS22 update that is really annoying and I don't care about.
disablewarnings { "4996" }

print("Creating contrib filter...")

-- These are packages that are not included with the binary, but instead exist outside
-- of the project and are simply referenced by other projects.
local external_packages = {}

group "contrib"
for pkg_name, pkg in pairs(package_info.packages) do
    if pkg.include_in_build == true then
        print("Handling " .. pkg_name .. " as normal package.")
        local premake_script_path = path.join(common_paths.sln_dir,
            "premake/supported-packages", pkg_name, pkg.version, "premake.lua")
        print("concatenated premake script path: " .. premake_script_path)
        include(premake_script_path)
    elseif pkg.include_in_build == false then
        print("Handling " .. pkg_name .. " as an external package.")

        local config_script_path = path.join(common_paths.sln_dir,
            "premake/supported-packages", pkg_name, pkg.version, "config.lua")
        print("Loading config script at ".. config_script_path)
        table.insert(external_packages, {
            name = pkg_name,
            path = config_script_path
        })
    else
        print("FOUND THE ELSE" .. pkg_name)
    end
end
group ""

-- Collect directories from contrib packages
local contrib_includes = {}
local contrib_links = {}
local contrib_lib_dirs = {}
local contrib_defines = {}
print("Gathering external package info...")
for _, external_package in pairs(external_packages) do
    pkg_name = external_package.name
    config_path = external_package.path
    print("External Package Config Path="..external_package.path)
    local config = dofile(config_path)
    if type(config.get_dependencies) == "function" then
        local links, lib_dirs, include_dir = config.get_dependencies()
        if include_dir then
            table.insert(contrib_includes, include_dir)
            print("External Package Inlcudes  Added" .. include_dir)
        end
        if links then
            print("External Package Links Added" .. table.concat(links, ", "))
            table.insert(contrib_links, links)
        end
        if lib_dirs then
            print("External package ext lib dirs added" .. table.concat(lib_dirs, ", "))
            table.insert(contrib_lib_dirs, lib_dirs)
        end
    else
        error("Config for package " .. pkg_name .. " does not implement get_dependencies.")
    end
    if type(config.get_defines) == "function" then
        local defines = config.get_defines()
        if defines and type(defines) == "table" then
            print("External package defines added: " .. table.concat(defines, ", "))
            for _, define in ipairs(defines) do
                table.insert(contrib_defines, define)
            end
        end
    else
        error("Config for package " .. pkg_name .. " does not implement get_defines")
    end
end

table.insert(contrib_defines, "_CRT_SECURE_NO_WARNINGS")

print("Gathering list of contrib includes...")

for pkg_name, pkg in pairs(package_info.packages) do
    print("package_name: " .. pkg_name)
    for key, value in pairs(pkg) do
        print("  " .. key .. ": " .. tostring(value))
    end
    if pkg.include_in_build and common_paths.project_includes[pkg_name] then
        table.insert(contrib_includes, common_paths.project_includes[pkg_name])
        -- Print the directory being added to the include path
        print("Adding include directory for package '" .. pkg_name .. "': " .. common_paths.project_includes[pkg_name])
    else
        print("contrib nothing to be included")
    end
end

-- Set up static libraries
for _, lib_dir in ipairs(static_lib_dirs) do
    local lib_name = path.getname(lib_dir)
    project(lib_name)
    kind "StaticLib"
    language "C++"
    location(path.join(common_paths.sln_dir, "build", "projects", "packages"))
    targetdir(common_paths.lib_dir)
    objdir(path.join(common_paths.obj_dir, lib_name))
    includedirs(static_dir)
    includedirs(contrib_includes)
    defines{contrib_defines}

    recursiveAddFiles(lib_dir)
    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"
        runtime "Debug"
        staticruntime "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"
        runtime "Release"
        staticruntime "On"
end

-- Set up other projects excluding static libraries
for _, project_dir in ipairs(projects) do
    local project_name = path.getname(project_dir)

     -- Skip static lib directories
    if project_name ~= "_static" then
        if startup_project_name == "" then
            startup_project_name = project_name
        end
        project(project_name)
        kind "ConsoleApp"
        language "C++"
        location(path.join(common_paths.sln_dir, "build", "projects", "packages"))
        targetdir(common_paths.bin_dir)
        objdir(path.join(common_paths.obj_dir, project_name))

        -- Include directory for all static libs
        includedirs(static_dir)
        includedirs(contrib_includes)
        recursiveAddFiles(project_dir)
        defines{contrib_defines}

        for _, lib_dir in ipairs(contrib_lib_dirs) do
            libdirs{lib_dir}
        end

        -- Link all static libraries
        for _, static_lib_dir in ipairs(static_lib_dirs) do
            table.insert(contrib_links, path.getname(static_lib_dir))
        end

        for _, link_name in ipairs(contrib_links) do
            links{ link_name }
        end

        filter "configurations:Debug"
            defines { "DEBUG" }
            symbols "On"
            runtime "Debug"
            staticruntime "On"


        filter "configurations:Release"
            defines { "NDEBUG" }
            optimize "On"
            runtime "Release"
            staticruntime "On"
    end
end


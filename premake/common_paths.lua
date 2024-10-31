-- Commandline option sent to premake.
newoption {
    trigger = "sln_dir",
    value = "PATH",
    description = "The path to the solution directory"
}

if not _OPTIONS["sln_dir"] then
    print ("Error: You must provide the root dir to your VS .sln")
    os.exit(1)
end

-- Packages are stored in this path. 
local package_cache = os.getenv("PACKAGE_CACHE_PATH")
if not package_cache then
    print ("Error: PACKAGE_CACHE_PATH environment variable must be set.")
    os.exit(1)
end

local project_includes = {}

-- Auto-generated premake related files will be in here.
local generated_dir = path.join(sln_dir, "premake", "generated")

-- Tell lua where generated lua things will be 
package.path = package.path .. ";".. path.join(generated_dir, "?.lua")

-- This is the root solution dir. All paths will be treated as relative to this dir.
local sln_dir = _OPTIONS["sln_dir"]

local base_build_dir = path.join(sln_dir, "build")
local bin_dir = path.join(base_build_dir, "bin", "%{cfg.buildcfg}")
local lib_dir = path.join(base_build_dir, "lib", "%{cfg.buildcfg}")
local obj_dir = path.join(base_build_dir, "obj", "%{cfg.buildcfg}")

-- Referenced from premake files.
return {
    package_cache = package_cache,
    sln_dir = sln_dir,
    base_build_dir = base_build_dir,
    bin_dir = bin_dir,
    lib_dir = lib_dir,
    obj_dir = obj_dir,
    project_includes = project_includes
}

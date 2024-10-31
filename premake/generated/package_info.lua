return {
    packages = {
        spdlog = {
            version = "ac55e604",
            include_in_build = true,
        },
        nlohmann = {
            version = "v3.11.3",
            include_in_build = true,
        },
        asio = {
            version = "asio-1-29-0",
            include_in_build = true,
        },
        glm = {
            version = "0.9.9.8",
            include_in_build = true,
        },
        catch2 = {
            version = "v2.13.7",
            include_in_build = true,
        },
        observable = {
            version = "v1.0.0",
            include_in_build = true,
        },
        sfml = {
            version = "2.6.1",
            modules = {
                "graphics",
                "network",
                "system",
                "window",
            },
            include_in_build = false,
        },
    },
}

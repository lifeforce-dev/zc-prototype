#include <SFML/Graphics.hpp>
#include <imgui.h>
#include <imgui-SFML.h>
#include <chrono>
#include <Common/Test.h>

// Use chrono for time management
using Clock = std::chrono::steady_clock;
using duration = std::chrono::duration<double>;
using time_point = std::chrono::time_point<Clock, duration>;

constexpr double dt = 1.0 / 240.0;  // Fixed timestep for physics updates

class GameObject {
public:
    virtual void integrate(duration dt) = 0;  // Updates state based on time
    virtual void render(sf::RenderWindow& window) const = 0;  // Renders appearance
    virtual ~GameObject() = default;
};

class AnimatedCircle : public GameObject {
private:
    sf::CircleShape shape;
    double startPosition;
    double endPosition;
    double animationDuration;  // Time in seconds to reach the target
    double elapsedTime = 0.0;  // Track time passed in animation
    bool animating = false;    // Track whether animation is active
    bool toggleDirection = false;  // Direction toggle

public:
    AnimatedCircle(float radius, float startPos, float endPos, double duration)
        : startPosition(startPos), endPosition(endPos), animationDuration(duration) {
        shape.setRadius(radius);
        shape.setFillColor(sf::Color::Green);
        shape.setPosition(static_cast<float>(startPosition), 300.0f);
    }

    void startAnimation() {
        animating = true;
        elapsedTime = 0.0;
        // Toggle direction by swapping start and end positions
        std::swap(startPosition, endPosition);
        toggleDirection = !toggleDirection;  // Toggle for next click
    }

    // Behavior update
    void integrate(duration dt) override {
        if (animating) {
            elapsedTime += dt.count();
            double t = elapsedTime / animationDuration;  // Normalize time to [0,1]

            // Clamp t to 1.0 to stop animation at the end position
            if (t >= 1.0) {
                t = 1.0;
                animating = false;
            }

            // Interpolate position between start and end
            double newPosition = startPosition * (1.0 - t) + endPosition * t;
            shape.setPosition(static_cast<float>(newPosition), 300.0f);
        }
    }

    // Appearance rendering
    void render(sf::RenderWindow& window) const override {
        window.draw(shape);
    }
};

int main() {
    Test::PrintTest();
    // Create a simple SFML window
    sf::RenderWindow window(sf::VideoMode(800, 600), "Animated Circle Slide with Frame Rates");
    ImGui::SFML::Init(window);
    window.setFramerateLimit(240);


    // Initialize the animated circle
    float radius = 50.0f;
    AnimatedCircle circle(radius, 50.0f, 750.0f, 1.0);  // Moves from 50 to 750 in 1 second

    // Time-related variables
    time_point currentTime = Clock::now();
    duration accumulator = duration(0.0);

    // Variables for FPS counters
    int physicsFrames = 0;
    int renderFrames = 0;
    int physicsFPS = 0;
    int renderFPS = 0;
    sf::Clock fpsClock;  // SFML clock to reset FPS counters every second

    // Main game loop
    while (window.isOpen()) {
        // Handle SFML events
        sf::Event event;
        while (window.pollEvent(event)) {
            ImGui::SFML::ProcessEvent(event);
            if (event.type == sf::Event::Closed) {
                window.close();
            }
            // Trigger animation on mouse click
            if (event.type == sf::Event::MouseButtonPressed && event.mouseButton.button == sf::Mouse::Left) {
                circle.startAnimation();
            }
        }

        // Calculate frame time
        time_point newTime = Clock::now();
        duration frameTime = newTime - currentTime;
        currentTime = newTime;

        // Cap frameTime to avoid spiral of death on frame drops
        if (frameTime.count() > 0.25) {
            frameTime = duration(0.25);
        }

        // Accumulate time for physics updates
        accumulator += frameTime;

        // Update physics at fixed time steps
        while (accumulator >= duration(dt)) {
            circle.integrate(duration(dt));  // Fixed physics update
            accumulator -= duration(dt);
            physicsFrames++;
        }

        // Reset FPS counters every second
        if (fpsClock.getElapsedTime().asSeconds() >= 1.0f) {
            physicsFPS = physicsFrames;
            renderFPS = renderFrames;
            physicsFrames = 0;
            renderFrames = 0;
            fpsClock.restart();
        }

        // Render
        window.clear(sf::Color::Black);
        circle.render(window);  // Render the circle

        // Update ImGui with FPS information
        ImGui::SFML::Update(window, sf::seconds(dt));
        ImGui::Begin("Frame Rates");
        ImGui::Text("Physics FPS: %d", physicsFPS);
        ImGui::Text("Render FPS: %d", renderFPS);
        ImGui::End();

        // Render ImGui
        ImGui::SFML::Render(window);
        window.display();
        renderFrames++;  // Increment render frame count
    }

    // Cleanup ImGui-SFML
    ImGui::SFML::Shutdown();
    return 0;
}
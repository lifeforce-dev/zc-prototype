#define CATCH_CONFIG_MAIN

#include "Catch2/catch.hpp"

SCENARIO("Test this thing")
{
	GIVEN("A thing we want to test")
	{
		WHEN("That thing happens")
		{
			REQUIRE(true);
		}
	}
}
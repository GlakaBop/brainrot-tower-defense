-- MapData (ModuleScript)
-- The ONLY file you need to edit to change the map layout.
-- Put the path points in order. Enemies walk from the first point to the last,
-- then on to the base.

local MapData = {}

-- Size of the flat ground Part (X, thickness, Z). The top of the ground sits at Y = 0.
MapData.GroundSize = Vector3.new(200, 2, 200)

-- Width of the flat path strips, in studs.
MapData.PathWidth = 8

-- Path waypoints, in walking order. Y = 1 is the height enemies walk at.
MapData.Waypoints = {
	Vector3.new(-80, 1, -60),  -- 1: spawn end of the path
	Vector3.new(-40, 1, -60),  -- 2
	Vector3.new(-40, 1, -20),  -- 3
	Vector3.new(10, 1, -20),   -- 4
	Vector3.new(10, 1, -70),   -- 5
	Vector3.new(60, 1, -70),   -- 6
	Vector3.new(60, 1, -10),   -- 7
	Vector3.new(-10, 1, -10),  -- 8
	Vector3.new(-10, 1, 40),   -- 9
	Vector3.new(-70, 1, 40),   -- 10
	Vector3.new(-70, 1, 75),   -- 11
}

-- Where the base sits. The path continues from the last waypoint to this point.
MapData.BasePosition = Vector3.new(70, 1, 75)

return MapData

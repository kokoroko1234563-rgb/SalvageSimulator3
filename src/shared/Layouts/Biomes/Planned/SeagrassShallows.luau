-- Seagrass Shallows (planned): drawn with the layout kit from tools/kit/plans/seagrass_shallows.py
-- (edit the plan and re-run it, not this file). The card: docs/design/cards/seagrass-shallows.md.
return {
	[1] = {
		Primitives = {
			{
				Kind = "Ridge",
				Path = {
					{ -364, 190 },
					{ -180, 198 },
					{ 0, 184 },
					{ 180, 198 },
					{ 364, 190 },
				},
				Height = 2.4,
				Width = 10,
				Rough = 1,
			},
			{
				Kind = "Ridge",
				Path = {
					{ -364, 410 },
					{ -180, 402 },
					{ 0, 416 },
					{ 180, 402 },
					{ 364, 410 },
				},
				Height = 2.4,
				Width = 10,
				Rough = 1,
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 110 },
					{ -200, 120 },
					{ -40, 102 },
					{ 120, 120 },
					{ 364, 106 },
				},
				Depth = 2,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 300 },
					{ -200, 290 },
					{ -40, 308 },
					{ 120, 290 },
					{ 364, 304 },
				},
				Depth = 2,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 510 },
					{ -200, 520 },
					{ -40, 502 },
					{ 120, 520 },
					{ 364, 506 },
				},
				Depth = 2,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{ Kind = "Flat", At = { -70, 364 }, Radius = 9 },
			{
				Kind = "Paint",
				Area = {
					{ -280, 30 },
					{ -200, 30 },
					{ -200, 90 },
					{ -280, 90 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 150, 25 },
					{ 230, 25 },
					{ 230, 85 },
					{ 150, 85 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -120, 120 },
					{ -40, 120 },
					{ -40, 180 },
					{ -120, 180 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 220, 220 },
					{ 300, 220 },
					{ 300, 280 },
					{ 220, 280 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -290, 320 },
					{ -210, 320 },
					{ -210, 380 },
					{ -290, 380 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 20, 330 },
					{ 100, 330 },
					{ 100, 390 },
					{ 20, 390 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -160, 430 },
					{ -80, 430 },
					{ -80, 490 },
					{ -160, 490 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 210, 430 },
					{ 290, 430 },
					{ 290, 490 },
					{ 210, 490 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -80, 530 },
					{ 0, 530 },
					{ 0, 590 },
					{ -80, 590 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 160, 540 },
					{ 240, 540 },
					{ 240, 600 },
					{ 160, 600 },
				},
				Material = "LeafyGrass",
			},
			{ Kind = "Hollow", At = { -290, 250 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { 280, 350 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { -230, 480 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { 300, 556 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
		},
		Loot = {
			{ At = { -70, 326 }, Radius = 6, Weight = 2 },
			{ At = { -290, 250 }, Radius = 5, Weight = 1 },
			{ At = { 280, 350 }, Radius = 5, Weight = 2 },
			{ At = { -230, 480 }, Radius = 5, Weight = 3 },
			{ At = { 300, 556 }, Radius = 5, Weight = 4 },
		},
		Entrances = {
			{ -70, 364 },
		},
		Decor = {
			{
				Kind = "Kelp",
				Path = {
					{ -330, 122 },
					{ 330, 106 },
				},
				Count = 5,
			},
			{
				Kind = "Kelp",
				Path = {
					{ -330, 312 },
					{ 330, 296 },
				},
				Count = 5,
			},
			{
				Kind = "Kelp",
				Path = {
					{ -330, 522 },
					{ 330, 506 },
				},
				Count = 5,
			},
			{
				Kind = "Timber",
				Path = {
					{ -70, 240 },
					{ -70, 340 },
				},
				Count = 9,
			},
			{
				Kind = "Timber",
				Path = {
					{ -78, 246 },
					{ -78, 334 },
				},
				Count = 5,
				Scale = 1.5,
				Yaw = 90,
			},
			{
				Kind = "Timber",
				Path = {
					{ -62, 246 },
					{ -62, 334 },
				},
				Count = 5,
				Scale = 1.5,
				Yaw = 90,
			},
			{
				Kind = "Timber",
				Area = {
					{ -95, 240 },
					{ -45, 240 },
					{ -45, 340 },
					{ -95, 340 },
				},
				Count = 6,
			},
			{ Kind = "Chain", At = { -56, 330 }, Yaw = 40 },
			{ Kind = "Crate", At = { -86, 254 }, Yaw = 20 },
			{ Kind = "Starfish", At = { -60, 374 } },
			{
				Kind = "Weed",
				Area = {
					{ -280, 30 },
					{ -200, 30 },
					{ -200, 90 },
					{ -280, 90 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -264, 42 },
					{ -216, 42 },
					{ -216, 78 },
					{ -264, 78 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 150, 25 },
					{ 230, 25 },
					{ 230, 85 },
					{ 150, 85 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 166, 37 },
					{ 214, 37 },
					{ 214, 73 },
					{ 166, 73 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -120, 120 },
					{ -40, 120 },
					{ -40, 180 },
					{ -120, 180 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -104, 132 },
					{ -56, 132 },
					{ -56, 168 },
					{ -104, 168 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 220, 220 },
					{ 300, 220 },
					{ 300, 280 },
					{ 220, 280 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 236, 232 },
					{ 284, 232 },
					{ 284, 268 },
					{ 236, 268 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -290, 320 },
					{ -210, 320 },
					{ -210, 380 },
					{ -290, 380 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -274, 332 },
					{ -226, 332 },
					{ -226, 368 },
					{ -274, 368 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 20, 330 },
					{ 100, 330 },
					{ 100, 390 },
					{ 20, 390 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 36, 342 },
					{ 84, 342 },
					{ 84, 378 },
					{ 36, 378 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -160, 430 },
					{ -80, 430 },
					{ -80, 490 },
					{ -160, 490 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -144, 442 },
					{ -96, 442 },
					{ -96, 478 },
					{ -144, 478 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 210, 430 },
					{ 290, 430 },
					{ 290, 490 },
					{ 210, 490 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 226, 442 },
					{ 274, 442 },
					{ 274, 478 },
					{ 226, 478 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -80, 530 },
					{ 0, 530 },
					{ 0, 590 },
					{ -80, 590 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -64, 542 },
					{ -16, 542 },
					{ -16, 578 },
					{ -64, 578 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 160, 540 },
					{ 240, 540 },
					{ 240, 600 },
					{ 160, 600 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 176, 552 },
					{ 224, 552 },
					{ 224, 588 },
					{ 176, 588 },
				},
				Count = 2,
			},
			{
				Kind = "Pebbles",
				Area = {
					{ -350, 284 },
					{ 350, 284 },
					{ 350, 324 },
					{ -350, 324 },
				},
				Count = 6,
			},
			{
				Kind = "Driftwood",
				Area = {
					{ -350, 264 },
					{ 350, 264 },
					{ 350, 344 },
					{ -350, 344 },
				},
				Count = 4,
			},
			{
				Kind = "Shells",
				Area = {
					{ -350, 520 },
					{ 350, 520 },
					{ 350, 600 },
					{ -350, 600 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ -302, 238 },
					{ -278, 238 },
					{ -278, 262 },
					{ -302, 262 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ 268, 338 },
					{ 292, 338 },
					{ 292, 362 },
					{ 268, 362 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ -242, 468 },
					{ -218, 468 },
					{ -218, 492 },
					{ -242, 492 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ 288, 544 },
					{ 312, 544 },
					{ 312, 568 },
					{ 288, 568 },
				},
				Count = 6,
			},
		},
		Name = "Seagrass Shallows",
		Crossings = {
			{
				Name = "Seagrass trail",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 0, 0 },
							{ 0, 70 },
							{ -140, 170 },
							{ -140, 215 },
							{ -30, 300 },
							{ 140, 380 },
							{ 140, 435 },
							{ 70, 520 },
							{ 0, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { -70, 130 }, Radius = 10 },
					{ Type = "Slow", At = { 60, 262 }, Radius = 10 },
					{ Type = "Slow", At = { 110, 470 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ -78, 122 },
							{ -62, 122 },
							{ -62, 138 },
							{ -78, 138 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 52, 254 },
							{ 68, 254 },
							{ 68, 270 },
							{ 52, 270 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 102, 462 },
							{ 118, 462 },
							{ 118, 478 },
							{ 102, 478 },
						},
						Count = 7,
					},
					{
						Kind = "Timber",
						Path = {
							{ -20, 14 },
							{ 20, 14 },
						},
						Count = 3,
						Scale = 1.4,
						Yaw = 90,
					},
					{ Kind = "Weed", At = { 0, 26 }, Scale = 1.4 },
				},
			},
			{
				Name = "Reed track",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -150, 0 },
							{ -150, 70 },
							{ 130, 170 },
							{ 130, 215 },
							{ 40, 300 },
							{ -130, 380 },
							{ -130, 435 },
							{ -75, 520 },
							{ -20, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { 120, 120 }, Radius = 10 },
					{ Type = "Slow", At = { -60, 340 }, Radius = 10 },
					{ Type = "Slow", At = { -130, 540 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ 112, 112 },
							{ 128, 112 },
							{ 128, 128 },
							{ 112, 128 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -68, 332 },
							{ -52, 332 },
							{ -52, 348 },
							{ -68, 348 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -138, 532 },
							{ -122, 532 },
							{ -122, 548 },
							{ -138, 548 },
						},
						Count = 7,
					},
					{ Kind = "Chain", At = { -150, 16 }, Yaw = 60 },
					{ Kind = "Crate", At = { -136, 10 }, Yaw = 30 },
				},
			},
			{
				Name = "Mud-flat way",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 150, 0 },
							{ 150, 70 },
							{ -60, 170 },
							{ -60, 215 },
							{ -150, 300 },
							{ 70, 380 },
							{ 70, 435 },
							{ 100, 520 },
							{ 130, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { 30, 60 }, Radius = 10 },
					{ Type = "Slow", At = { -120, 250 }, Radius = 10 },
					{ Type = "Slow", At = { 80, 470 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ 22, 52 },
							{ 38, 52 },
							{ 38, 68 },
							{ 22, 68 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -128, 242 },
							{ -112, 242 },
							{ -112, 258 },
							{ -128, 258 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 72, 462 },
							{ 88, 462 },
							{ 88, 478 },
							{ 72, 478 },
						},
						Count = 7,
					},
					{
						Kind = "Kelp",
						Path = {
							{ 134, 14 },
							{ 166, 14 },
						},
						Count = 3,
						Scale = 1.3,
					},
					{ Kind = "Starfish", At = { 150, 28 } },
				},
			},
		},
	},
	[2] = {
		Primitives = {
			{
				Kind = "Ridge",
				Path = {
					{ -364, 190 },
					{ -180, 198 },
					{ 0, 184 },
					{ 180, 198 },
					{ 364, 190 },
				},
				Height = 4.4,
				Width = 14,
				Rough = 1,
			},
			{
				Kind = "Ridge",
				Path = {
					{ -364, 410 },
					{ -180, 402 },
					{ 0, 416 },
					{ 180, 402 },
					{ 364, 410 },
				},
				Height = 4.4,
				Width = 14,
				Rough = 1,
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 110 },
					{ -200, 120 },
					{ -40, 102 },
					{ 120, 120 },
					{ 364, 106 },
				},
				Depth = 3,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 300 },
					{ -200, 290 },
					{ -40, 308 },
					{ 120, 290 },
					{ 364, 304 },
				},
				Depth = 3,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 510 },
					{ -200, 520 },
					{ -40, 502 },
					{ 120, 520 },
					{ 364, 506 },
				},
				Depth = 3,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{ Kind = "Flat", At = { 90, 364 }, Radius = 9 },
			{
				Kind = "Paint",
				Area = {
					{ -280, 30 },
					{ -200, 30 },
					{ -200, 90 },
					{ -280, 90 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 150, 25 },
					{ 230, 25 },
					{ 230, 85 },
					{ 150, 85 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -120, 120 },
					{ -40, 120 },
					{ -40, 180 },
					{ -120, 180 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 220, 220 },
					{ 300, 220 },
					{ 300, 280 },
					{ 220, 280 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -290, 320 },
					{ -210, 320 },
					{ -210, 380 },
					{ -290, 380 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 20, 330 },
					{ 100, 330 },
					{ 100, 390 },
					{ 20, 390 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -160, 430 },
					{ -80, 430 },
					{ -80, 490 },
					{ -160, 490 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 210, 430 },
					{ 290, 430 },
					{ 290, 490 },
					{ 210, 490 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -80, 530 },
					{ 0, 530 },
					{ 0, 590 },
					{ -80, 590 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 160, 540 },
					{ 240, 540 },
					{ 240, 600 },
					{ 160, 600 },
				},
				Material = "LeafyGrass",
			},
			{ Kind = "Hollow", At = { -300, 240 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { -60, 360 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { 250, 470 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { -290, 560 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
		},
		Loot = {
			{ At = { 90, 326 }, Radius = 6, Weight = 2 },
			{ At = { -300, 240 }, Radius = 5, Weight = 1 },
			{ At = { -60, 360 }, Radius = 5, Weight = 2 },
			{ At = { 250, 470 }, Radius = 5, Weight = 3 },
			{ At = { -290, 560 }, Radius = 5, Weight = 4 },
		},
		Entrances = {
			{ 90, 364 },
		},
		Decor = {
			{
				Kind = "Kelp",
				Path = {
					{ -330, 122 },
					{ 330, 106 },
				},
				Count = 5,
			},
			{
				Kind = "Kelp",
				Path = {
					{ -330, 312 },
					{ 330, 296 },
				},
				Count = 5,
			},
			{
				Kind = "Kelp",
				Path = {
					{ -330, 522 },
					{ 330, 506 },
				},
				Count = 5,
			},
			{
				Kind = "Timber",
				Path = {
					{ 90, 240 },
					{ 90, 340 },
				},
				Count = 9,
			},
			{
				Kind = "Timber",
				Path = {
					{ 82, 246 },
					{ 82, 334 },
				},
				Count = 5,
				Scale = 1.5,
				Yaw = 90,
			},
			{
				Kind = "Timber",
				Path = {
					{ 98, 246 },
					{ 98, 334 },
				},
				Count = 5,
				Scale = 1.5,
				Yaw = 90,
			},
			{
				Kind = "Timber",
				Area = {
					{ 65, 240 },
					{ 115, 240 },
					{ 115, 340 },
					{ 65, 340 },
				},
				Count = 6,
			},
			{ Kind = "Chain", At = { 104, 330 }, Yaw = 40 },
			{ Kind = "Crate", At = { 74, 254 }, Yaw = 20 },
			{ Kind = "Starfish", At = { 100, 374 } },
			{
				Kind = "Weed",
				Area = {
					{ -280, 30 },
					{ -200, 30 },
					{ -200, 90 },
					{ -280, 90 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -264, 42 },
					{ -216, 42 },
					{ -216, 78 },
					{ -264, 78 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 150, 25 },
					{ 230, 25 },
					{ 230, 85 },
					{ 150, 85 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 166, 37 },
					{ 214, 37 },
					{ 214, 73 },
					{ 166, 73 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -120, 120 },
					{ -40, 120 },
					{ -40, 180 },
					{ -120, 180 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -104, 132 },
					{ -56, 132 },
					{ -56, 168 },
					{ -104, 168 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 220, 220 },
					{ 300, 220 },
					{ 300, 280 },
					{ 220, 280 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 236, 232 },
					{ 284, 232 },
					{ 284, 268 },
					{ 236, 268 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -290, 320 },
					{ -210, 320 },
					{ -210, 380 },
					{ -290, 380 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -274, 332 },
					{ -226, 332 },
					{ -226, 368 },
					{ -274, 368 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 20, 330 },
					{ 100, 330 },
					{ 100, 390 },
					{ 20, 390 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 36, 342 },
					{ 84, 342 },
					{ 84, 378 },
					{ 36, 378 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -160, 430 },
					{ -80, 430 },
					{ -80, 490 },
					{ -160, 490 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -144, 442 },
					{ -96, 442 },
					{ -96, 478 },
					{ -144, 478 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 210, 430 },
					{ 290, 430 },
					{ 290, 490 },
					{ 210, 490 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 226, 442 },
					{ 274, 442 },
					{ 274, 478 },
					{ 226, 478 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -80, 530 },
					{ 0, 530 },
					{ 0, 590 },
					{ -80, 590 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -64, 542 },
					{ -16, 542 },
					{ -16, 578 },
					{ -64, 578 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 160, 540 },
					{ 240, 540 },
					{ 240, 600 },
					{ 160, 600 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 176, 552 },
					{ 224, 552 },
					{ 224, 588 },
					{ 176, 588 },
				},
				Count = 2,
			},
			{
				Kind = "Pebbles",
				Area = {
					{ -350, 284 },
					{ 350, 284 },
					{ 350, 324 },
					{ -350, 324 },
				},
				Count = 6,
			},
			{
				Kind = "Driftwood",
				Area = {
					{ -350, 264 },
					{ 350, 264 },
					{ 350, 344 },
					{ -350, 344 },
				},
				Count = 4,
			},
			{
				Kind = "Shells",
				Area = {
					{ -350, 520 },
					{ 350, 520 },
					{ 350, 600 },
					{ -350, 600 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ -312, 228 },
					{ -288, 228 },
					{ -288, 252 },
					{ -312, 252 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ -72, 348 },
					{ -48, 348 },
					{ -48, 372 },
					{ -72, 372 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ 238, 458 },
					{ 262, 458 },
					{ 262, 482 },
					{ 238, 482 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ -302, 548 },
					{ -278, 548 },
					{ -278, 572 },
					{ -302, 572 },
				},
				Count = 6,
			},
		},
		Name = "Seagrass Shallows",
		Crossings = {
			{
				Name = "Seagrass trail",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 0, 0 },
							{ 0, 70 },
							{ 140, 170 },
							{ 140, 215 },
							{ 20, 300 },
							{ -140, 380 },
							{ -140, 435 },
							{ -70, 520 },
							{ 0, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { -80, 140 }, Radius = 10 },
					{ Type = "Slow", At = { -60, 270 }, Radius = 10 },
					{ Type = "Slow", At = { 100, 480 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ -88, 132 },
							{ -72, 132 },
							{ -72, 148 },
							{ -88, 148 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -68, 262 },
							{ -52, 262 },
							{ -52, 278 },
							{ -68, 278 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 92, 472 },
							{ 108, 472 },
							{ 108, 488 },
							{ 92, 488 },
						},
						Count = 7,
					},
					{
						Kind = "Timber",
						Path = {
							{ -20, 14 },
							{ 20, 14 },
						},
						Count = 3,
						Scale = 1.4,
						Yaw = 90,
					},
					{ Kind = "Weed", At = { 0, 26 }, Scale = 1.4 },
				},
			},
			{
				Name = "Reed track",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 140, 0 },
							{ 140, 70 },
							{ -130, 170 },
							{ -130, 215 },
							{ -50, 300 },
							{ 130, 380 },
							{ 130, 435 },
							{ 75, 520 },
							{ 20, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { -100, 100 }, Radius = 10 },
					{ Type = "Slow", At = { 130, 330 }, Radius = 10 },
					{ Type = "Slow", At = { -110, 560 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ -108, 92 },
							{ -92, 92 },
							{ -92, 108 },
							{ -108, 108 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 122, 322 },
							{ 138, 322 },
							{ 138, 338 },
							{ 122, 338 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -118, 552 },
							{ -102, 552 },
							{ -102, 568 },
							{ -118, 568 },
						},
						Count = 7,
					},
					{ Kind = "Chain", At = { 140, 16 }, Yaw = 60 },
					{ Kind = "Crate", At = { 154, 10 }, Yaw = 30 },
				},
			},
			{
				Name = "Mud-flat way",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -150, 0 },
							{ -150, 70 },
							{ 60, 170 },
							{ 60, 215 },
							{ 150, 300 },
							{ -70, 380 },
							{ -70, 435 },
							{ -95, 520 },
							{ -120, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { -30, 60 }, Radius = 10 },
					{ Type = "Slow", At = { 210, 250 }, Radius = 10 },
					{ Type = "Slow", At = { -30, 480 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ -38, 52 },
							{ -22, 52 },
							{ -22, 68 },
							{ -38, 68 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 202, 242 },
							{ 218, 242 },
							{ 218, 258 },
							{ 202, 258 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -38, 472 },
							{ -22, 472 },
							{ -22, 488 },
							{ -38, 488 },
						},
						Count = 7,
					},
					{
						Kind = "Kelp",
						Path = {
							{ -166, 14 },
							{ -134, 14 },
						},
						Count = 3,
						Scale = 1.3,
					},
					{ Kind = "Starfish", At = { -150, 28 } },
				},
			},
		},
	},
	[3] = {
		Primitives = {
			{
				Kind = "Ridge",
				Path = {
					{ -364, 190 },
					{ -180, 198 },
					{ 0, 184 },
					{ 180, 198 },
					{ 364, 190 },
				},
				Height = 6.4,
				Width = 18,
				Rough = 1,
			},
			{
				Kind = "Ridge",
				Path = {
					{ -364, 410 },
					{ -180, 402 },
					{ 0, 416 },
					{ 180, 402 },
					{ 364, 410 },
				},
				Height = 6.4,
				Width = 18,
				Rough = 1,
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 110 },
					{ -200, 120 },
					{ -40, 102 },
					{ 120, 120 },
					{ 364, 106 },
				},
				Depth = 3,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 300 },
					{ -200, 290 },
					{ -40, 308 },
					{ 120, 290 },
					{ 364, 304 },
				},
				Depth = 3,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{
				Kind = "Channel",
				Path = {
					{ -364, 510 },
					{ -200, 520 },
					{ -40, 502 },
					{ 120, 520 },
					{ 364, 506 },
				},
				Depth = 3,
				Width = 14,
				Rough = 1,
				Material = "Mud",
			},
			{ Kind = "Flat", At = { -110, 364 }, Radius = 9 },
			{
				Kind = "Paint",
				Area = {
					{ -280, 30 },
					{ -200, 30 },
					{ -200, 90 },
					{ -280, 90 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 150, 25 },
					{ 230, 25 },
					{ 230, 85 },
					{ 150, 85 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -120, 120 },
					{ -40, 120 },
					{ -40, 180 },
					{ -120, 180 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 220, 220 },
					{ 300, 220 },
					{ 300, 280 },
					{ 220, 280 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -290, 320 },
					{ -210, 320 },
					{ -210, 380 },
					{ -290, 380 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 20, 330 },
					{ 100, 330 },
					{ 100, 390 },
					{ 20, 390 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -160, 430 },
					{ -80, 430 },
					{ -80, 490 },
					{ -160, 490 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 210, 430 },
					{ 290, 430 },
					{ 290, 490 },
					{ 210, 490 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ -80, 530 },
					{ 0, 530 },
					{ 0, 590 },
					{ -80, 590 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Paint",
				Area = {
					{ 160, 540 },
					{ 240, 540 },
					{ 240, 600 },
					{ 160, 600 },
				},
				Material = "LeafyGrass",
			},
			{ Kind = "Hollow", At = { 290, 230 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { 60, 350 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { -260, 470 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
			{ Kind = "Hollow", At = { 280, 560 }, Radius = 10, Depth = 2, Rough = 2, Material = "Mud" },
		},
		Loot = {
			{ At = { -110, 326 }, Radius = 6, Weight = 2 },
			{ At = { 290, 230 }, Radius = 5, Weight = 1 },
			{ At = { 60, 350 }, Radius = 5, Weight = 2 },
			{ At = { -260, 470 }, Radius = 5, Weight = 3 },
			{ At = { 280, 560 }, Radius = 5, Weight = 4 },
		},
		Entrances = {
			{ -110, 364 },
		},
		Decor = {
			{
				Kind = "Kelp",
				Path = {
					{ -330, 122 },
					{ 330, 106 },
				},
				Count = 5,
			},
			{
				Kind = "Kelp",
				Path = {
					{ -330, 312 },
					{ 330, 296 },
				},
				Count = 5,
			},
			{
				Kind = "Kelp",
				Path = {
					{ -330, 522 },
					{ 330, 506 },
				},
				Count = 5,
			},
			{
				Kind = "Timber",
				Path = {
					{ -110, 240 },
					{ -110, 340 },
				},
				Count = 9,
			},
			{
				Kind = "Timber",
				Path = {
					{ -118, 246 },
					{ -118, 334 },
				},
				Count = 5,
				Scale = 1.5,
				Yaw = 90,
			},
			{
				Kind = "Timber",
				Path = {
					{ -102, 246 },
					{ -102, 334 },
				},
				Count = 5,
				Scale = 1.5,
				Yaw = 90,
			},
			{
				Kind = "Timber",
				Area = {
					{ -135, 240 },
					{ -85, 240 },
					{ -85, 340 },
					{ -135, 340 },
				},
				Count = 6,
			},
			{ Kind = "Chain", At = { -96, 330 }, Yaw = 40 },
			{ Kind = "Crate", At = { -126, 254 }, Yaw = 20 },
			{ Kind = "Starfish", At = { -100, 374 } },
			{
				Kind = "Weed",
				Area = {
					{ -280, 30 },
					{ -200, 30 },
					{ -200, 90 },
					{ -280, 90 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -264, 42 },
					{ -216, 42 },
					{ -216, 78 },
					{ -264, 78 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 150, 25 },
					{ 230, 25 },
					{ 230, 85 },
					{ 150, 85 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 166, 37 },
					{ 214, 37 },
					{ 214, 73 },
					{ 166, 73 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -120, 120 },
					{ -40, 120 },
					{ -40, 180 },
					{ -120, 180 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -104, 132 },
					{ -56, 132 },
					{ -56, 168 },
					{ -104, 168 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 220, 220 },
					{ 300, 220 },
					{ 300, 280 },
					{ 220, 280 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 236, 232 },
					{ 284, 232 },
					{ 284, 268 },
					{ 236, 268 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -290, 320 },
					{ -210, 320 },
					{ -210, 380 },
					{ -290, 380 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -274, 332 },
					{ -226, 332 },
					{ -226, 368 },
					{ -274, 368 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 20, 330 },
					{ 100, 330 },
					{ 100, 390 },
					{ 20, 390 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 36, 342 },
					{ 84, 342 },
					{ 84, 378 },
					{ 36, 378 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -160, 430 },
					{ -80, 430 },
					{ -80, 490 },
					{ -160, 490 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -144, 442 },
					{ -96, 442 },
					{ -96, 478 },
					{ -144, 478 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 210, 430 },
					{ 290, 430 },
					{ 290, 490 },
					{ 210, 490 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 226, 442 },
					{ 274, 442 },
					{ 274, 478 },
					{ 226, 478 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ -80, 530 },
					{ 0, 530 },
					{ 0, 590 },
					{ -80, 590 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -64, 542 },
					{ -16, 542 },
					{ -16, 578 },
					{ -64, 578 },
				},
				Count = 2,
			},
			{
				Kind = "Weed",
				Area = {
					{ 160, 540 },
					{ 240, 540 },
					{ 240, 600 },
					{ 160, 600 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ 176, 552 },
					{ 224, 552 },
					{ 224, 588 },
					{ 176, 588 },
				},
				Count = 2,
			},
			{
				Kind = "Pebbles",
				Area = {
					{ -350, 284 },
					{ 350, 284 },
					{ 350, 324 },
					{ -350, 324 },
				},
				Count = 6,
			},
			{
				Kind = "Driftwood",
				Area = {
					{ -350, 264 },
					{ 350, 264 },
					{ 350, 344 },
					{ -350, 344 },
				},
				Count = 4,
			},
			{
				Kind = "Shells",
				Area = {
					{ -350, 520 },
					{ 350, 520 },
					{ 350, 600 },
					{ -350, 600 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ 278, 218 },
					{ 302, 218 },
					{ 302, 242 },
					{ 278, 242 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ 48, 338 },
					{ 72, 338 },
					{ 72, 362 },
					{ 48, 362 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ -272, 458 },
					{ -248, 458 },
					{ -248, 482 },
					{ -272, 482 },
				},
				Count = 6,
			},
			{
				Kind = "Weed",
				Area = {
					{ 268, 548 },
					{ 292, 548 },
					{ 292, 572 },
					{ 268, 572 },
				},
				Count = 6,
			},
		},
		Name = "Seagrass Shallows",
		Crossings = {
			{
				Name = "Seagrass trail",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 0, 0 },
							{ 0, 70 },
							{ -140, 170 },
							{ -140, 215 },
							{ 0, 300 },
							{ 140, 380 },
							{ 140, 435 },
							{ 70, 520 },
							{ 0, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { 80, 140 }, Radius = 10 },
					{ Type = "Slow", At = { -120, 260 }, Radius = 10 },
					{ Type = "Slow", At = { 60, 480 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ 72, 132 },
							{ 88, 132 },
							{ 88, 148 },
							{ 72, 148 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -128, 252 },
							{ -112, 252 },
							{ -112, 268 },
							{ -128, 268 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 52, 472 },
							{ 68, 472 },
							{ 68, 488 },
							{ 52, 488 },
						},
						Count = 7,
					},
					{
						Kind = "Timber",
						Path = {
							{ -20, 14 },
							{ 20, 14 },
						},
						Count = 3,
						Scale = 1.4,
						Yaw = 90,
					},
					{ Kind = "Weed", At = { 0, 26 }, Scale = 1.4 },
				},
			},
			{
				Name = "Reed track",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -140, 0 },
							{ -140, 70 },
							{ 140, 170 },
							{ 140, 215 },
							{ 60, 300 },
							{ -120, 380 },
							{ -120, 435 },
							{ -40, 520 },
							{ 40, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { -90, 110 }, Radius = 10 },
					{ Type = "Slow", At = { -30, 340 }, Radius = 10 },
					{ Type = "Slow", At = { 110, 560 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ -98, 102 },
							{ -82, 102 },
							{ -82, 118 },
							{ -98, 118 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -38, 332 },
							{ -22, 332 },
							{ -22, 348 },
							{ -38, 348 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 102, 552 },
							{ 118, 552 },
							{ 118, 568 },
							{ 102, 568 },
						},
						Count = 7,
					},
					{ Kind = "Chain", At = { -140, 16 }, Yaw = 60 },
					{ Kind = "Crate", At = { -126, 10 }, Yaw = 30 },
				},
			},
			{
				Name = "Mud-flat way",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 140, 0 },
							{ 140, 70 },
							{ -40, 170 },
							{ -40, 215 },
							{ -140, 300 },
							{ 60, 380 },
							{ 60, 435 },
							{ 100, 520 },
							{ 140, 608 },
						},
						Width = 16,
					},
				},
				Hazards = {
					{ Type = "Slow", At = { 60, 60 }, Radius = 10 },
					{ Type = "Slow", At = { 150, 260 }, Radius = 10 },
					{ Type = "Slow", At = { -60, 470 }, Radius = 10 },
				},
				Decor = {
					{
						Kind = "Weed",
						Area = {
							{ 52, 52 },
							{ 68, 52 },
							{ 68, 68 },
							{ 52, 68 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 142, 252 },
							{ 158, 252 },
							{ 158, 268 },
							{ 142, 268 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -68, 462 },
							{ -52, 462 },
							{ -52, 478 },
							{ -68, 478 },
						},
						Count = 7,
					},
					{
						Kind = "Kelp",
						Path = {
							{ 124, 14 },
							{ 156, 14 },
						},
						Count = 3,
						Scale = 1.3,
					},
					{ Kind = "Starfish", At = { 140, 28 } },
				},
			},
		},
	},
	[4] = {
		Primitives = {
			{
				Kind = "Wall",
				Area = {
					{ -380, -12 },
					{ 380, -12 },
					{ 380, 620 },
					{ -380, 620 },
				},
				Height = 10,
			},
			{
				Kind = "Flat",
				Area = {
					{ -260, -12 },
					{ 260, -12 },
					{ 260, 24 },
					{ -260, 24 },
				},
			},
			{
				Kind = "Paint",
				Area = {
					{ -260, -12 },
					{ 260, -12 },
					{ 260, 24 },
					{ -260, 24 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Flat",
				Area = {
					{ -260, 584 },
					{ 260, 584 },
					{ 260, 620 },
					{ -260, 620 },
				},
			},
			{
				Kind = "Paint",
				Area = {
					{ -260, 584 },
					{ 260, 584 },
					{ 260, 620 },
					{ -260, 620 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Flat",
				Area = {
					{ -48, 272 },
					{ 48, 272 },
					{ 48, 352 },
					{ -48, 352 },
				},
			},
			{
				Kind = "Paint",
				Area = {
					{ -48, 272 },
					{ 48, 272 },
					{ 48, 352 },
					{ -48, 352 },
				},
				Material = "LeafyGrass",
			},
			{
				Kind = "Hollow",
				At = { 0, 330 },
				Radius = 8,
				Depth = 2,
				Rough = 3,
				Material = "Mud",
				Over = true,
			},
			{
				Kind = "Flat",
				Area = {
					{ -296, 158 },
					{ -272, 158 },
					{ -272, 146 },
					{ -296, 146 },
				},
			},
			{ Kind = "Flat", At = { -296, 152 }, Radius = 6 },
			{ Kind = "Flat", At = { -272, 152 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -272, 158 },
					{ -224, 158 },
					{ -224, 146 },
					{ -272, 146 },
				},
			},
			{ Kind = "Flat", At = { -272, 152 }, Radius = 6 },
			{ Kind = "Flat", At = { -224, 152 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 296, 182 },
					{ 272, 182 },
					{ 272, 194 },
					{ 296, 194 },
				},
			},
			{ Kind = "Flat", At = { 296, 188 }, Radius = 6 },
			{ Kind = "Flat", At = { 272, 188 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 272, 182 },
					{ 224, 182 },
					{ 224, 194 },
					{ 272, 194 },
				},
			},
			{ Kind = "Flat", At = { 272, 188 }, Radius = 6 },
			{ Kind = "Flat", At = { 224, 188 }, Radius = 6 },
		},
		Loot = {
			{ At = { 0, 322 }, Radius = 6, Weight = 2 },
		},
		Entrances = {
			{ 0, 322 },
		},
		Decor = {
			{
				Kind = "Weed",
				Area = {
					{ -240, -6 },
					{ 240, -6 },
					{ 240, 18 },
					{ -240, 18 },
				},
				Count = 10,
			},
			{
				Kind = "Shells",
				Area = {
					{ -240, 588 },
					{ 240, 588 },
					{ 240, 612 },
					{ -240, 612 },
				},
				Count = 6,
			},
			{
				Kind = "Timber",
				Path = {
					{ 0, 280 },
					{ 0, 340 },
				},
				Count = 9,
			},
			{
				Kind = "Timber",
				Path = {
					{ -8, 286 },
					{ -8, 334 },
				},
				Count = 5,
				Scale = 1.5,
				Yaw = 90,
			},
			{
				Kind = "Timber",
				Path = {
					{ 8, 286 },
					{ 8, 334 },
				},
				Count = 5,
				Scale = 1.5,
				Yaw = 90,
			},
			{
				Kind = "Timber",
				Area = {
					{ -25, 280 },
					{ 25, 280 },
					{ 25, 340 },
					{ -25, 340 },
				},
				Count = 6,
			},
			{ Kind = "Chain", At = { 14, 330 }, Yaw = 40 },
			{ Kind = "Crate", At = { -16, 294 }, Yaw = 20 },
			{ Kind = "Starfish", At = { -24, 340 } },
		},
		Name = "Seagrass Shallows",
		Crossings = {
			{
				Name = "Reed maze",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 96, 0 },
							{ 96, 100 },
							{ 224, 100 },
							{ 224, 200 },
							{ 96, 200 },
							{ 96, 300 },
							{ 224, 300 },
							{ 224, 400 },
							{ 96, 400 },
							{ 96, 500 },
							{ 224, 500 },
							{ 224, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ -102, 0 },
							{ -102, 148 },
							{ -90, 148 },
							{ -90, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -96, 142 },
							{ -224, 142 },
							{ -224, 154 },
							{ -96, 154 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -230, 148 },
							{ -230, 300 },
							{ -218, 300 },
							{ -218, 148 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -224, 306 },
							{ -96, 306 },
							{ -96, 294 },
							{ -224, 294 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -102, 300 },
							{ -102, 448 },
							{ -90, 448 },
							{ -90, 300 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -96, 442 },
							{ -224, 442 },
							{ -224, 454 },
							{ -96, 454 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -230, 448 },
							{ -230, 608 },
							{ -218, 608 },
							{ -218, 448 },
						},
					},
					{ Kind = "Flat", At = { -96, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -96, 148 }, Radius = 6 },
					{ Kind = "Flat", At = { -224, 148 }, Radius = 6 },
					{ Kind = "Flat", At = { -224, 300 }, Radius = 6 },
					{ Kind = "Flat", At = { -96, 300 }, Radius = 6 },
					{ Kind = "Flat", At = { -96, 448 }, Radius = 6 },
					{ Kind = "Flat", At = { -224, 448 }, Radius = 6 },
					{ Kind = "Flat", At = { -224, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ -96, 148 },
							{ -224, 148 },
						},
						Depth = 3,
						Width = 10,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
					{
						Kind = "Channel",
						Path = {
							{ -96, 448 },
							{ -224, 448 },
						},
						Depth = 3,
						Width = 10,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
					{
						Kind = "Flat",
						Area = {
							{ 96, 294 },
							{ 48, 294 },
							{ 48, 306 },
							{ 96, 306 },
						},
					},
					{ Kind = "Flat", At = { 96, 300 }, Radius = 6 },
					{ Kind = "Flat", At = { 48, 300 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -96, 306 },
							{ -48, 306 },
							{ -48, 294 },
							{ -96, 294 },
						},
					},
					{ Kind = "Flat", At = { -96, 300 }, Radius = 6 },
					{ Kind = "Flat", At = { -48, 300 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 224, 358 },
							{ 292, 358 },
							{ 292, 346 },
							{ 224, 346 },
						},
					},
					{ Kind = "Flat", At = { 224, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 292, 352 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 136, 78 },
							{ 184, 78 },
							{ 184, 122 },
							{ 136, 122 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 136, 278 },
							{ 184, 278 },
							{ 184, 322 },
							{ 136, 322 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 136, 478 },
							{ 184, 478 },
							{ 184, 522 },
							{ 136, 522 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -184, 426 },
							{ -136, 426 },
							{ -136, 470 },
							{ -184, 470 },
						},
					},
				},
				Loot = {
					{ At = { 292, 352 }, Radius = 5, Weight = 2 },
				},
				Hazards = {
					{ Type = "Slow", At = { 168, 100 }, Radius = 8 },
					{ Type = "Slow", At = { 152, 300 }, Radius = 8 },
					{ Type = "Slow", At = { 168, 500 }, Radius = 8 },
					{ Type = "Slow", At = { -168, 448 }, Radius = 8 },
				},
				Decor = {
					{
						Kind = "Kelp",
						Path = {
							{ -96, 148 },
							{ -224, 148 },
						},
						Count = 3,
					},
					{
						Kind = "Kelp",
						Path = {
							{ -96, 448 },
							{ -224, 448 },
						},
						Count = 3,
					},
					{
						Kind = "Weed",
						Area = {
							{ 280, 340 },
							{ 304, 340 },
							{ 304, 364 },
							{ 280, 364 },
						},
						Count = 4,
					},
					{
						Kind = "Weed",
						Area = {
							{ 161.6, 93.6 },
							{ 174.4, 93.6 },
							{ 174.4, 106.4 },
							{ 161.6, 106.4 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 145.6, 293.6 },
							{ 158.4, 293.6 },
							{ 158.4, 306.4 },
							{ 145.6, 306.4 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 161.6, 493.6 },
							{ 174.4, 493.6 },
							{ 174.4, 506.4 },
							{ 161.6, 506.4 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -174.4, 441.6 },
							{ -161.6, 441.6 },
							{ -161.6, 454.4 },
							{ -174.4, 454.4 },
						},
						Count = 7,
					},
					{
						Kind = "Timber",
						Path = {
							{ 88, 14 },
							{ 104, 14 },
						},
						Count = 3,
						Scale = 1.4,
						Yaw = 90,
					},
					{ Kind = "Weed", At = { 96, 28 }, Scale = 1.4 },
					{
						Kind = "Kelp",
						Path = {
							{ -104, 14 },
							{ -88, 14 },
						},
						Count = 2,
						Scale = 1.3,
					},
				},
			},
			{
				Name = "Net rows",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -96, 0 },
							{ -96, 92 },
							{ -224, 92 },
							{ -224, 188 },
							{ -96, 188 },
							{ -96, 300 },
							{ -224, 300 },
							{ -224, 412 },
							{ -96, 412 },
							{ -96, 508 },
							{ -224, 508 },
							{ -224, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 90, 0 },
							{ 90, 132 },
							{ 102, 132 },
							{ 102, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 96, 138 },
							{ 224, 138 },
							{ 224, 126 },
							{ 96, 126 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 218, 132 },
							{ 218, 300 },
							{ 230, 300 },
							{ 230, 132 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 224, 294 },
							{ 96, 294 },
							{ 96, 306 },
							{ 224, 306 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 90, 300 },
							{ 90, 468 },
							{ 102, 468 },
							{ 102, 300 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 96, 474 },
							{ 224, 474 },
							{ 224, 462 },
							{ 96, 462 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 218, 468 },
							{ 218, 608 },
							{ 230, 608 },
							{ 230, 468 },
						},
					},
					{ Kind = "Flat", At = { 96, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 96, 132 }, Radius = 6 },
					{ Kind = "Flat", At = { 224, 132 }, Radius = 6 },
					{ Kind = "Flat", At = { 224, 300 }, Radius = 6 },
					{ Kind = "Flat", At = { 96, 300 }, Radius = 6 },
					{ Kind = "Flat", At = { 96, 468 }, Radius = 6 },
					{ Kind = "Flat", At = { 224, 468 }, Radius = 6 },
					{ Kind = "Flat", At = { 224, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 96, 132 },
							{ 224, 132 },
						},
						Depth = 3,
						Width = 10,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
					{
						Kind = "Channel",
						Path = {
							{ 96, 468 },
							{ 224, 468 },
						},
						Depth = 3,
						Width = 10,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
					{
						Kind = "Flat",
						Area = {
							{ -96, 306 },
							{ -48, 306 },
							{ -48, 294 },
							{ -96, 294 },
						},
					},
					{ Kind = "Flat", At = { -96, 300 }, Radius = 6 },
					{ Kind = "Flat", At = { -48, 300 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 96, 294 },
							{ 48, 294 },
							{ 48, 306 },
							{ 96, 306 },
						},
					},
					{ Kind = "Flat", At = { 96, 300 }, Radius = 6 },
					{ Kind = "Flat", At = { 48, 300 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -224, 346 },
							{ -292, 346 },
							{ -292, 358 },
							{ -224, 358 },
						},
					},
					{ Kind = "Flat", At = { -224, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { -292, 352 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -184, 70 },
							{ -136, 70 },
							{ -136, 114 },
							{ -184, 114 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -184, 278 },
							{ -136, 278 },
							{ -136, 322 },
							{ -184, 322 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -184, 486 },
							{ -136, 486 },
							{ -136, 530 },
							{ -184, 530 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 136, 446 },
							{ 184, 446 },
							{ 184, 490 },
							{ 136, 490 },
						},
					},
				},
				Loot = {
					{ At = { -292, 352 }, Radius = 5, Weight = 2 },
				},
				Hazards = {
					{ Type = "Slow", At = { -168, 92 }, Radius = 8 },
					{ Type = "Slow", At = { -152, 300 }, Radius = 8 },
					{ Type = "Slow", At = { -168, 508 }, Radius = 8 },
					{ Type = "Slow", At = { 168, 468 }, Radius = 8 },
				},
				Decor = {
					{
						Kind = "Kelp",
						Path = {
							{ 96, 132 },
							{ 224, 132 },
						},
						Count = 3,
					},
					{
						Kind = "Kelp",
						Path = {
							{ 96, 468 },
							{ 224, 468 },
						},
						Count = 3,
					},
					{
						Kind = "Weed",
						Area = {
							{ -304, 340 },
							{ -280, 340 },
							{ -280, 364 },
							{ -304, 364 },
						},
						Count = 4,
					},
					{
						Kind = "Weed",
						Area = {
							{ -174.4, 85.6 },
							{ -161.6, 85.6 },
							{ -161.6, 98.4 },
							{ -174.4, 98.4 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -158.4, 293.6 },
							{ -145.6, 293.6 },
							{ -145.6, 306.4 },
							{ -158.4, 306.4 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ -174.4, 501.6 },
							{ -161.6, 501.6 },
							{ -161.6, 514.4 },
							{ -174.4, 514.4 },
						},
						Count = 7,
					},
					{
						Kind = "Weed",
						Area = {
							{ 161.6, 461.6 },
							{ 174.4, 461.6 },
							{ 174.4, 474.4 },
							{ 161.6, 474.4 },
						},
						Count = 7,
					},
					{ Kind = "Chain", At = { -96, 16 }, Yaw = 60 },
					{ Kind = "Crate", At = { -84, 10 }, Yaw = 30 },
					{ Kind = "Chain", At = { 96, 16 }, Yaw = 100 },
				},
			},
		},
		Slots = {
			{
				Name = "Grass pockets",
				At = { -360, 102 },
				Size = { 72, 96 },
				Rooms = {
					{
						Name = "Reed pocket",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 72, 42 },
									{ 36, 42 },
									{ 36, 54 },
									{ 72, 54 },
								},
							},
							{ Kind = "Flat", At = { 72, 48 }, Radius = 6 },
							{ Kind = "Flat", At = { 36, 48 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 64, 8 },
									{ 64, 88 },
									{ 8, 88 },
								},
							},
							{
								Kind = "Hollow",
								At = { 36, 64 },
								Radius = 10,
								Depth = 2,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 36, 64 }, Radius = 5, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Weed",
								Area = {
									{ 12, 12 },
									{ 60, 12 },
									{ 60, 84 },
									{ 12, 84 },
								},
								Count = 8,
							},
						},
					},
					{
						Name = "Silted cove",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 72, 42 },
									{ 36, 42 },
									{ 36, 54 },
									{ 72, 54 },
								},
							},
							{ Kind = "Flat", At = { 72, 48 }, Radius = 6 },
							{ Kind = "Flat", At = { 36, 48 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 64, 8 },
									{ 64, 88 },
									{ 8, 88 },
								},
							},
							{
								Kind = "Hollow",
								At = { 22, 24 },
								Radius = 9,
								Depth = 3,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 22, 24 }, Radius = 5, Weight = 4 },
						},
						Decor = {
							{
								Kind = "Kelp",
								Area = {
									{ 20, 20 },
									{ 60, 20 },
									{ 60, 80 },
									{ 20, 80 },
								},
								Count = 4,
							},
						},
					},
				},
			},
			{
				Name = "Jetty cellars",
				At = { 288, 140 },
				Size = { 72, 96 },
				Rooms = {
					{
						Name = "Net store",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 0, 54 },
									{ 36, 54 },
									{ 36, 42 },
									{ 0, 42 },
								},
							},
							{ Kind = "Flat", At = { 0, 48 }, Radius = 6 },
							{ Kind = "Flat", At = { 36, 48 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 8, 8 },
									{ 64, 8 },
									{ 64, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 54 },
									{ 8, 42 },
									{ 30, 42 },
									{ 30, 54 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 42, 54 },
									{ 42, 42 },
									{ 64, 42 },
									{ 64, 54 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 54 },
									{ 64, 54 },
									{ 64, 88 },
									{ 8, 88 },
								},
							},
						},
						Loot = {
							{ At = { 20, 76 }, Radius = 5, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 16, 13 },
									{ 56, 13 },
									{ 56, 83 },
									{ 16, 83 },
								},
								Count = 3,
							},
							{ Kind = "Chain", At = { 24, 20 }, Yaw = 70 },
						},
					},
					{
						Name = "Under the pier",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 0, 54 },
									{ 36, 54 },
									{ 36, 42 },
									{ 0, 42 },
								},
							},
							{ Kind = "Flat", At = { 0, 48 }, Radius = 6 },
							{ Kind = "Flat", At = { 36, 48 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 64, 8 },
									{ 64, 88 },
									{ 8, 88 },
								},
							},
						},
						Loot = {
							{ At = { 36, 80 }, Radius = 5, Weight = 4 },
						},
						Decor = {
							{
								Kind = "Timber",
								Path = {
									{ 36, 12 },
									{ 36, 84 },
								},
								Count = 6,
							},
						},
					},
				},
			},
		},
	},
}

-- Shipwreck Shallows: drawn with the layout kit from tools/kit/plans/shipwreck_shallows.py
-- (edit the plan and re-run it, not this file). The card: docs/design/cards/shipwreck-shallows.md.
return {
	[2] = {
		Primitives = {
			{
				Kind = "Ridge",
				Path = {
					{ -330, 84 },
					{ -200, 96 },
					{ -60, 88 },
					{ 60, 100 },
					{ 160, 86 },
				},
				Height = 4.4,
				Width = 14,
				Rough = 1,
				Material = "Pavement",
			},
			{ Kind = "Flat", At = { -100, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { -20, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 60, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 120, 30 }, Radius = 10 },
			{
				Kind = "Channel",
				Path = {
					{ -180, 100 },
					{ -180, 200 },
					{ -210, 300 },
					{ -210, 420 },
				},
				Depth = 2.4,
				Width = 10,
				Rough = 1,
				Material = "Pavement",
			},
			{
				Kind = "Channel",
				Path = {
					{ 110, 106 },
					{ 110, 210 },
					{ 140, 330 },
					{ 140, 430 },
				},
				Depth = 2.4,
				Width = 10,
				Rough = 1,
				Material = "Pavement",
			},
			{
				Kind = "Channel",
				Path = {
					{ -330, 360 },
					{ -150, 372 },
					{ 20, 356 },
					{ 200, 372 },
					{ 340, 360 },
				},
				Depth = 2,
				Width = 10,
				Rough = 1,
				Material = "Mud",
			},
			{ Kind = "Mound", At = { -60, 220 }, Radius = 11, Height = 2.4, Rock = false },
			{ Kind = "Mound", At = { 60, 250 }, Radius = 11, Height = 2.8, Rock = false },
			{ Kind = "Mound", At = { -250, 160 }, Radius = 11, Height = 2.4, Rock = false },
			{ Kind = "Mound", At = { 250, 190 }, Radius = 11, Height = 2.8, Rock = false },
			{ Kind = "Mound", At = { -40, 480 }, Radius = 11, Height = 2.6, Rock = false },
			{ Kind = "Mound", At = { 220, 500 }, Radius = 11, Height = 2.6, Rock = false },
			{ Kind = "Mound", At = { -280, 520 }, Radius = 11, Height = 2.4, Rock = false },
		},
		Entrances = {
			{ -20, 30 },
		},
		Decor = {
			{ Kind = "WreckRibs", At = { -120, 92 }, Scale = 1.8, Yaw = 90 },
			{ Kind = "WreckRibs", At = { 20, 94 }, Scale = 1.5, Yaw = 80 },
			{
				Kind = "Timber",
				Path = {
					{ -320, 80 },
					{ 150, 84 },
				},
				Count = 9,
			},
			{ Kind = "Anchor", At = { -250, 70 }, Yaw = 30 },
			{
				Kind = "Chain",
				Path = {
					{ -90, 110 },
					{ -60, 118 },
				},
				Count = 2,
			},
			{ Kind = "Crate", At = { -20, 46 }, Yaw = 10 },
			{ Kind = "Chain", At = { -8, 40 } },
			{
				Kind = "Timber",
				Path = {
					{ -180, 100 },
					{ -180, 200 },
					{ -210, 300 },
					{ -210, 420 },
				},
				Count = 3,
			},
			{
				Kind = "Timber",
				Path = {
					{ 110, 106 },
					{ 110, 210 },
					{ 140, 330 },
					{ 140, 430 },
				},
				Count = 3,
			},
			{
				Kind = "Timber",
				Area = {
					{ -66, 217 },
					{ -26, 217 },
					{ -26, 247 },
					{ -66, 247 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { -38, 226 }, Yaw = 44 },
			{
				Kind = "Timber",
				Area = {
					{ 54, 247 },
					{ 94, 247 },
					{ 94, 277 },
					{ 54, 277 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { 82, 256 }, Yaw = 74 },
			{
				Kind = "Timber",
				Area = {
					{ -256, 157 },
					{ -216, 157 },
					{ -216, 187 },
					{ -256, 187 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { -228, 166 }, Yaw = 34 },
			{
				Kind = "Timber",
				Area = {
					{ 244, 187 },
					{ 284, 187 },
					{ 284, 217 },
					{ 244, 217 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { 272, 196 }, Yaw = 84 },
			{
				Kind = "Timber",
				Area = {
					{ -46, 477 },
					{ -6, 477 },
					{ -6, 507 },
					{ -46, 507 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { -18, 486 }, Yaw = 64 },
			{
				Kind = "Timber",
				Area = {
					{ 214, 497 },
					{ 254, 497 },
					{ 254, 527 },
					{ 214, 527 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { 242, 506 }, Yaw = 54 },
			{
				Kind = "Timber",
				Area = {
					{ -286, 517 },
					{ -246, 517 },
					{ -246, 547 },
					{ -286, 547 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { -258, 526 }, Yaw = 4 },
			{
				Kind = "Rocks",
				Area = {
					{ -300, 550 },
					{ 300, 550 },
					{ 300, 590 },
					{ -300, 590 },
				},
				Count = 5,
			},
			{ Kind = "Driftwood", At = { -300, 440 }, Yaw = 60 },
			{
				Kind = "Pebbles",
				Area = {
					{ -320, 585 },
					{ 320, 585 },
					{ 320, 615 },
					{ -320, 615 },
				},
				Count = 5,
			},
		},
		Name = "Shipwreck Shallows",
		Crossings = {
			{
				Name = "Gully run",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 130, 0 },
							{ 130, 120 },
							{ -100, 250 },
							{ -100, 420 },
							{ 90, 500 },
							{ 90, 608 },
						},
						Width = 20,
					},
					{
						Kind = "Channel",
						Path = {
							{ -60, 366 },
							{ 60, 360 },
						},
						Depth = 2,
						Width = 12,
						Rough = 1,
						Material = "Mud",
					},
				},
				Hazards = {
					{
						Type = "Roller",
						Path = {
							{ -180, 100 },
							{ -180, 200 },
							{ -210, 300 },
							{ -210, 420 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ -60, 366 },
							{ 60, 360 },
						},
						Width = 12,
					},
					{ Type = "Pit", At = { -30, 190 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 200, 440 }, Radius = 4, Covered = false },
				},
				Decor = {
					{ Kind = "Crate", At = { -170, 94 }, Yaw = 30 },
					{ Kind = "Chain", At = { -190, 96 } },
					{ Kind = "Timber", At = { -23, 190 }, Yaw = 40 },
					{ Kind = "Timber", At = { 207, 440 }, Yaw = 40 },
					{ Kind = "Chain", At = { 193, 442 } },
					{ Kind = "Crate", At = { 120, 12 }, Yaw = 10 },
					{
						Kind = "Chain",
						Path = {
							{ 140, 10 },
							{ 150, 20 },
						},
						Count = 2,
					},
				},
			},
			{
				Name = "Port side",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -170, 0 },
							{ -170, 120 },
							{ 0, 230 },
							{ 0, 440 },
							{ -140, 520 },
							{ -140, 608 },
						},
						Width = 20,
					},
					{
						Kind = "Channel",
						Path = {
							{ 120, 366 },
							{ 190, 366 },
						},
						Depth = 2,
						Width = 12,
						Rough = 1,
						Material = "Mud",
					},
				},
				Hazards = {
					{
						Type = "Roller",
						Path = {
							{ 110, 106 },
							{ 110, 210 },
							{ 140, 330 },
							{ 140, 430 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 120, 366 },
							{ 190, 366 },
						},
						Width = 12,
					},
					{ Type = "Pit", At = { 90, 200 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -250, 380 }, Radius = 4, Covered = false },
				},
				Decor = {
					{ Kind = "Crate", At = { 120, 100 }, Yaw = 30 },
					{ Kind = "Chain", At = { 100, 102 } },
					{ Kind = "Timber", At = { 97, 200 }, Yaw = 40 },
					{ Kind = "Timber", At = { -243, 380 }, Yaw = 40 },
					{ Kind = "Chain", At = { -257, 382 } },
					{ Kind = "Timber", At = { -160, 12 }, Yaw = 80 },
					{ Kind = "Anchor", At = { -190, 14 }, Yaw = 200 },
				},
			},
			{
				Name = "Under the stern",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 10, 0 },
							{ 10, 150 },
							{ -160, 260 },
							{ -160, 450 },
							{ 40, 510 },
							{ 40, 608 },
						},
						Width = 20,
					},
					{
						Kind = "Channel",
						Path = {
							{ -300, 366 },
							{ -230, 366 },
						},
						Depth = 2,
						Width = 12,
						Rough = 1,
						Material = "Mud",
					},
				},
				Hazards = {
					{
						Type = "Roller",
						Path = {
							{ -180, 100 },
							{ -180, 200 },
							{ -210, 300 },
							{ -210, 420 },
						},
					},
					{
						Type = "Roller",
						Path = {
							{ 110, 106 },
							{ 110, 210 },
							{ 140, 330 },
							{ 140, 430 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ -300, 366 },
							{ -230, 366 },
						},
						Width = 12,
					},
					{ Type = "Pit", At = { 150, 260 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -80, 300 }, Radius = 4, Covered = false },
				},
				Decor = {
					{ Kind = "Crate", At = { -170, 94 }, Yaw = 30 },
					{ Kind = "Chain", At = { -190, 96 } },
					{ Kind = "Crate", At = { 120, 100 }, Yaw = 30 },
					{ Kind = "Chain", At = { 100, 102 } },
					{ Kind = "Timber", At = { 157, 260 }, Yaw = 40 },
					{ Kind = "Timber", At = { -73, 300 }, Yaw = 40 },
					{ Kind = "Chain", At = { -87, 302 } },
					{
						Kind = "Chain",
						Path = {
							{ -4, 12 },
							{ 24, 12 },
						},
						Count = 3,
					},
					{ Kind = "Crate", At = { 30, 16 }, Yaw = 60 },
				},
			},
		},
	},
	[3] = {
		Primitives = {
			{
				Kind = "Ridge",
				Path = {
					{ -330, 84 },
					{ -200, 96 },
					{ -60, 88 },
					{ 60, 100 },
					{ 160, 86 },
				},
				Height = 6.4,
				Width = 18,
				Rough = 1,
				Material = "Pavement",
			},
			{ Kind = "Flat", At = { -100, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { -20, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 60, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 120, 30 }, Radius = 10 },
			{
				Kind = "Channel",
				Path = {
					{ -100, 106 },
					{ -100, 220 },
					{ -140, 320 },
					{ -140, 440 },
				},
				Depth = 3,
				Width = 10,
				Rough = 1,
				Material = "Pavement",
			},
			{
				Kind = "Channel",
				Path = {
					{ 190, 110 },
					{ 190, 230 },
					{ 160, 340 },
					{ 160, 450 },
				},
				Depth = 3,
				Width = 10,
				Rough = 1,
				Material = "Pavement",
			},
			{
				Kind = "Channel",
				Path = {
					{ -330, 330 },
					{ -120, 344 },
					{ 60, 326 },
					{ 240, 344 },
					{ 340, 330 },
				},
				Depth = 2.4,
				Width = 10,
				Rough = 1,
				Material = "Mud",
			},
			{ Kind = "Mound", At = { -20, 210 }, Radius = 12, Height = 3.4, Rock = false },
			{ Kind = "Mound", At = { -260, 200 }, Radius = 12, Height = 3.2, Rock = false },
			{ Kind = "Mound", At = { 300, 220 }, Radius = 12, Height = 3.4, Rock = false },
			{ Kind = "Mound", At = { 30, 440 }, Radius = 12, Height = 3.6, Rock = false },
			{ Kind = "Mound", At = { -240, 480 }, Radius = 12, Height = 3.4, Rock = false },
			{ Kind = "Mound", At = { 260, 500 }, Radius = 12, Height = 3.2, Rock = false },
		},
		Entrances = {
			{ -20, 30 },
		},
		Decor = {
			{ Kind = "WreckRibs", At = { -120, 92 }, Scale = 1.8, Yaw = 90 },
			{ Kind = "WreckRibs", At = { 20, 94 }, Scale = 1.5, Yaw = 80 },
			{
				Kind = "Timber",
				Path = {
					{ -320, 80 },
					{ 150, 84 },
				},
				Count = 9,
			},
			{ Kind = "Anchor", At = { -250, 70 }, Yaw = 30 },
			{
				Kind = "Chain",
				Path = {
					{ -90, 110 },
					{ -60, 118 },
				},
				Count = 2,
			},
			{ Kind = "Crate", At = { -20, 46 }, Yaw = 10 },
			{ Kind = "Chain", At = { -8, 40 } },
			{
				Kind = "Timber",
				Path = {
					{ -100, 106 },
					{ -100, 220 },
					{ -140, 320 },
					{ -140, 440 },
				},
				Count = 3,
			},
			{
				Kind = "Timber",
				Path = {
					{ 190, 110 },
					{ 190, 230 },
					{ 160, 340 },
					{ 160, 450 },
				},
				Count = 3,
			},
			{
				Kind = "Timber",
				Area = {
					{ -26, 207 },
					{ 14, 207 },
					{ 14, 237 },
					{ -26, 237 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { 2, 216 }, Yaw = 84 },
			{
				Kind = "Timber",
				Area = {
					{ -266, 197 },
					{ -226, 197 },
					{ -226, 227 },
					{ -266, 227 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { -238, 206 }, Yaw = 24 },
			{
				Kind = "Timber",
				Area = {
					{ 294, 217 },
					{ 334, 217 },
					{ 334, 247 },
					{ 294, 247 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { 322, 226 }, Yaw = 44 },
			{
				Kind = "Timber",
				Area = {
					{ 24, 437 },
					{ 64, 437 },
					{ 64, 467 },
					{ 24, 467 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { 52, 446 }, Yaw = 44 },
			{
				Kind = "Timber",
				Area = {
					{ -246, 477 },
					{ -206, 477 },
					{ -206, 507 },
					{ -246, 507 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { -218, 486 }, Yaw = 44 },
			{
				Kind = "Timber",
				Area = {
					{ 254, 497 },
					{ 294, 497 },
					{ 294, 527 },
					{ 254, 527 },
				},
				Count = 4,
			},
			{ Kind = "Crate", At = { 282, 506 }, Yaw = 4 },
			{
				Kind = "Rocks",
				Area = {
					{ -300, 550 },
					{ 300, 550 },
					{ 300, 590 },
					{ -300, 590 },
				},
				Count = 5,
			},
			{ Kind = "Driftwood", At = { 300, 420 }, Yaw = 100 },
			{
				Kind = "Pebbles",
				Area = {
					{ -320, 585 },
					{ 320, 585 },
					{ 320, 615 },
					{ -320, 615 },
				},
				Count = 5,
			},
		},
		Name = "Shipwreck Shallows",
		Crossings = {
			{
				Name = "Deck run",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -180, 0 },
							{ -180, 140 },
							{ 50, 240 },
							{ 50, 440 },
							{ -200, 520 },
							{ -200, 608 },
						},
						Width = 20,
					},
					{
						Kind = "Channel",
						Path = {
							{ -60, 336 },
							{ 30, 332 },
						},
						Depth = 2,
						Width = 12,
						Rough = 1,
						Material = "Mud",
					},
				},
				Hazards = {
					{
						Type = "Roller",
						Path = {
							{ -100, 106 },
							{ -100, 220 },
							{ -140, 320 },
							{ -140, 440 },
						},
					},
					{
						Type = "Roller",
						Path = {
							{ 190, 110 },
							{ 190, 230 },
							{ 160, 340 },
							{ 160, 450 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ -60, 336 },
							{ 30, 332 },
						},
						Width = 12,
					},
					{ Type = "Pit", At = { -20, 120 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -260, 400 }, Radius = 4, Covered = false },
					{ Type = "Pit", At = { 270, 380 }, Radius = 4, Covered = true },
				},
				Decor = {
					{ Kind = "Crate", At = { -90, 100 }, Yaw = 30 },
					{ Kind = "Chain", At = { -110, 102 } },
					{ Kind = "Crate", At = { 200, 104 }, Yaw = 30 },
					{ Kind = "Chain", At = { 180, 106 } },
					{ Kind = "Timber", At = { -13, 120 }, Yaw = 40 },
					{ Kind = "Timber", At = { -253, 400 }, Yaw = 40 },
					{ Kind = "Chain", At = { -267, 402 } },
					{ Kind = "Timber", At = { 277, 380 }, Yaw = 40 },
					{ Kind = "Anchor", At = { -190, 14 }, Yaw = 10 },
					{ Kind = "Crate", At = { -170, 12 }, Yaw = 40 },
				},
			},
			{
				Name = "Starboard way",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 240, 0 },
							{ 240, 150 },
							{ 10, 250 },
							{ 10, 450 },
							{ 230, 520 },
							{ 230, 608 },
						},
						Width = 20,
					},
					{
						Kind = "Channel",
						Path = {
							{ 120, 336 },
							{ 200, 340 },
						},
						Depth = 2,
						Width = 12,
						Rough = 1,
						Material = "Mud",
					},
				},
				Hazards = {
					{
						Type = "Roller",
						Path = {
							{ -100, 106 },
							{ -100, 220 },
							{ -140, 320 },
							{ -140, 440 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 120, 336 },
							{ 200, 340 },
						},
						Width = 12,
					},
					{ Type = "Pit", At = { -60, 290 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 100, 200 }, Radius = 4, Covered = false },
					{ Type = "Pit", At = { -260, 400 }, Radius = 4, Covered = true },
				},
				Decor = {
					{ Kind = "Crate", At = { -90, 100 }, Yaw = 30 },
					{ Kind = "Chain", At = { -110, 102 } },
					{ Kind = "Timber", At = { -53, 290 }, Yaw = 40 },
					{ Kind = "Timber", At = { 107, 200 }, Yaw = 40 },
					{ Kind = "Chain", At = { 93, 202 } },
					{ Kind = "Timber", At = { -253, 400 }, Yaw = 40 },
					{ Kind = "Timber", At = { 230, 12 }, Yaw = 70 },
					{
						Kind = "Chain",
						Path = {
							{ 250, 10 },
							{ 262, 22 },
						},
						Count = 2,
					},
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
				Height = 14,
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, -12 },
					{ 360, -12 },
					{ 360, 46 },
					{ -360, 46 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, 592 },
					{ 360, 592 },
					{ 360, 620 },
					{ -360, 620 },
				},
			},
			{ Kind = "Flat", At = { -100, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { -20, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 60, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 120, 30 }, Radius = 10 },
			{
				Kind = "Flat",
				Area = {
					{ -26, 44 },
					{ -26, 136 },
					{ -14, 136 },
					{ -14, 44 },
				},
			},
			{ Kind = "Flat", At = { -20, 44 }, Radius = 6 },
			{ Kind = "Flat", At = { -20, 136 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -56, 114 },
					{ -32, 114 },
					{ -32, 102 },
					{ -56, 102 },
				},
			},
			{ Kind = "Flat", At = { -56, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { -32, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 56, 102 },
					{ 32, 102 },
					{ 32, 114 },
					{ 56, 114 },
				},
			},
			{ Kind = "Flat", At = { 56, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { 32, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 32, 102 },
					{ -20, 102 },
					{ -20, 114 },
					{ 32, 114 },
				},
			},
			{ Kind = "Flat", At = { 32, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { -20, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -286, 568 },
					{ -286, 592 },
					{ -274, 592 },
					{ -274, 568 },
				},
			},
			{ Kind = "Flat", At = { -280, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { -280, 592 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -6, 568 },
					{ -6, 592 },
					{ 6, 592 },
					{ 6, 568 },
				},
			},
			{ Kind = "Flat", At = { 0, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { 0, 592 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 274, 568 },
					{ 274, 592 },
					{ 286, 592 },
					{ 286, 568 },
				},
			},
			{ Kind = "Flat", At = { 280, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { 280, 592 }, Radius = 6 },
		},
		Entrances = {
			{ -20, 30 },
		},
		Decor = {
			{
				Kind = "Timber",
				Area = {
					{ -320, -2 },
					{ 320, -2 },
					{ 320, 14 },
					{ -320, 14 },
				},
				Count = 8,
			},
			{
				Kind = "Rocks",
				Area = {
					{ -320, 598 },
					{ 320, 598 },
					{ 320, 614 },
					{ -320, 614 },
				},
				Count = 6,
			},
			{
				Kind = "Starfish",
				Area = {
					{ -320, 596 },
					{ 320, 596 },
					{ 320, 612 },
					{ -320, 612 },
				},
				Count = 3,
			},
			{ Kind = "Chain", At = { -34, 38 } },
			{ Kind = "Crate", At = { -6, 38 }, Yaw = 20 },
			{ Kind = "WreckRibs", At = { -20, 18 }, Scale = 1.8, Yaw = 0 },
			{ Kind = "WreckRibs", At = { -170, 30 }, Scale = 1.6, Yaw = 90 },
			{ Kind = "WreckRibs", At = { 150, 30 }, Scale = 1.6, Yaw = 90 },
			{ Kind = "Anchor", At = { -230, 26 }, Yaw = 40 },
			{
				Kind = "Timber",
				Path = {
					{ -200, 34 },
					{ 200, 34 },
				},
				Count = 6,
			},
			{
				Kind = "Chain",
				Path = {
					{ 60, 36 },
					{ 110, 36 },
				},
				Count = 3,
			},
		},
		Name = "Shipwreck Shallows",
		Crossings = {
			{
				Name = "Gully run",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 132 },
							{ -340, 132 },
							{ -340, 192 },
							{ -150, 192 },
							{ -150, 262 },
							{ -340, 262 },
							{ -340, 302 },
							{ -150, 302 },
							{ -150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ -178, 170 },
							{ -122, 170 },
							{ -122, 214 },
							{ -178, 214 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 132 },
							{ 222, 132 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 138 },
							{ 340, 138 },
							{ 340, 126 },
							{ 216, 126 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 132 },
							{ 334, 192 },
							{ 346, 192 },
							{ 346, 132 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 192 },
							{ 334, 256 },
							{ 346, 256 },
							{ 346, 192 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 250 },
							{ 216, 250 },
							{ 216, 262 },
							{ 340, 262 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 256 },
							{ 210, 296 },
							{ 222, 296 },
							{ 222, 256 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 302 },
							{ 340, 302 },
							{ 340, 290 },
							{ 216, 290 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 296 },
							{ 334, 336 },
							{ 346, 336 },
							{ 346, 296 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 330 },
							{ 216, 330 },
							{ 216, 342 },
							{ 340, 342 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 336 },
							{ 210, 376 },
							{ 222, 376 },
							{ 222, 336 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 382 },
							{ 340, 382 },
							{ 340, 370 },
							{ 216, 370 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 376 },
							{ 334, 416 },
							{ 346, 416 },
							{ 346, 376 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 410 },
							{ 216, 410 },
							{ 216, 422 },
							{ 340, 422 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 410 },
							{ 192, 410 },
							{ 192, 422 },
							{ 216, 422 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 186, 416 },
							{ 186, 608 },
							{ 198, 608 },
							{ 198, 416 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 132 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 132 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 192 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 256 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 256 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 296 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 296 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 336 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 336 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 376 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 376 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { -164, 184 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -134, 206 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ -150, 178 },
							{ -150, 254 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { -170, 182 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { -132, 196 }, Yaw = 0 },
					{ Kind = "Crate", At = { -164, 202 }, Yaw = 30 },
					{ Kind = "Timber", At = { -157, 184 }, Yaw = 40 },
					{ Kind = "Timber", At = { -127, 206 }, Yaw = 40 },
					{ Kind = "Chain", At = { -141, 208 } },
					{ Kind = "Crate", At = { -140, 172 }, Yaw = 30 },
					{ Kind = "Chain", At = { -160, 174 } },
					{ Kind = "Weed", At = { 202, 548 } },
					{ Kind = "Anchor", At = { -300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ -286, 8 },
							{ -270, 16 },
						},
						Count = 2,
					},
					{
						Kind = "Timber",
						Path = {
							{ 286, 12 },
							{ 314, 12 },
						},
						Count = 3,
					},
				},
			},
			{
				Name = "Through the hatch",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 340, 0 },
							{ 340, 84 },
							{ 214, 84 },
							{ 214, 132 },
							{ 340, 132 },
							{ 340, 192 },
							{ 150, 192 },
							{ 150, 262 },
							{ 340, 262 },
							{ 340, 302 },
							{ 150, 302 },
							{ 150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 122, 170 },
							{ 178, 170 },
							{ 178, 214 },
							{ 122, 214 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 128 },
							{ -26, 216 },
							{ -14, 216 },
							{ -14, 128 },
						},
					},
					{ Kind = "Flat", At = { -20, 128 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 216 }, Radius = 6 },
					{
						Kind = "Roof",
						Area = {
							{ -36, 56 },
							{ -36, 90 },
							{ -4, 90 },
							{ -4, 56 },
						},
						Clearance = 12,
						Thickness = 6,
					},
					{
						Kind = "Roof",
						Area = {
							{ -36, 126 },
							{ -36, 166 },
							{ -4, 166 },
							{ -4, 126 },
						},
						Clearance = 12,
						Thickness = 6,
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 0 },
							{ -26, 216 },
							{ -14, 216 },
							{ -14, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -20, 222 },
							{ 88, 222 },
							{ 88, 210 },
							{ -20, 210 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 216 },
							{ 82, 256 },
							{ 94, 256 },
							{ 94, 216 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 250 },
							{ -88, 250 },
							{ -88, 262 },
							{ 88, 262 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 256 },
							{ -94, 296 },
							{ -82, 296 },
							{ -82, 256 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 302 },
							{ 88, 302 },
							{ 88, 290 },
							{ -88, 290 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 296 },
							{ 82, 336 },
							{ 94, 336 },
							{ 94, 296 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 330 },
							{ -88, 330 },
							{ -88, 342 },
							{ 88, 342 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 336 },
							{ -94, 376 },
							{ -82, 376 },
							{ -82, 336 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 382 },
							{ 88, 382 },
							{ 88, 370 },
							{ -88, 370 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 376 },
							{ 82, 416 },
							{ 94, 416 },
							{ 94, 376 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 410 },
							{ -88, 410 },
							{ -88, 422 },
							{ 88, 422 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 416 },
							{ -94, 456 },
							{ -82, 456 },
							{ -82, 416 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 462 },
							{ 88, 462 },
							{ 88, 450 },
							{ -88, 450 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 462 },
							{ 104, 462 },
							{ 104, 450 },
							{ 88, 450 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 98, 456 },
							{ 98, 608 },
							{ 110, 608 },
							{ 110, 456 },
						},
					},
					{ Kind = "Flat", At = { -20, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 216 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 216 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 256 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 256 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 296 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 296 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 336 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 336 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 376 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 376 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 456 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 456 }, Radius = 6 },
					{ Kind = "Flat", At = { 104, 456 }, Radius = 6 },
					{ Kind = "Flat", At = { 104, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 94, 540 },
							{ 114, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 184 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 206 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 178 },
							{ 150, 254 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 94, 540 },
							{ 114, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 182 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 196 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 202 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 184 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 206 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 208 } },
					{ Kind = "Crate", At = { 160, 172 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 174 } },
					{ Kind = "Weed", At = { 116, 548 } },
					{ Kind = "WreckRibs", At = { 300, 12 }, Scale = 1.1, Yaw = 90 },
					{ Kind = "Crate", At = { -20, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -8, 20 }, Yaw = 60 },
				},
			},
			{
				Name = "The long gully",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 132 },
							{ -340, 132 },
							{ -340, 192 },
						},
						Width = 16,
					},
					{
						Kind = "Ramp",
						Path = {
							{ -340, 192 },
							{ 150, 192 },
						},
						Width = 16,
					},
					{
						Kind = "Ramp",
						Path = {
							{ 150, 192 },
							{ 150, 262 },
							{ 340, 262 },
							{ 340, 302 },
							{ 150, 302 },
							{ 150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 122, 170 },
							{ 178, 170 },
							{ 178, 214 },
							{ 122, 214 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 152, 546 },
							{ 184, 546 },
							{ 184, 534 },
							{ 152, 534 },
						},
					},
					{ Kind = "Flat", At = { 152, 540 }, Radius = 6 },
					{ Kind = "Flat", At = { 184, 540 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 166, 540 },
							{ 186, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Loot = {
					{ At = { 186, 540 }, Radius = 3, Weight = 1 },
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 184 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 206 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 178 },
							{ 150, 254 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 166, 540 },
							{ 186, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 182 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 196 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 202 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 184 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 206 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 208 } },
					{ Kind = "Crate", At = { 160, 172 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 174 } },
					{ Kind = "Weed", At = { 188, 548 } },
					{ Kind = "Anchor", At = { -300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ -286, 8 },
							{ -270, 16 },
						},
						Count = 2,
					},
					{ Kind = "Crate", At = { -280, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -268, 20 }, Yaw = 60 },
				},
			},
			{
				Name = "Three ways",
				Paths = 3,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 132 },
							{ -340, 132 },
							{ -340, 192 },
							{ -150, 192 },
							{ -150, 262 },
							{ -340, 262 },
							{ -340, 302 },
							{ -150, 302 },
							{ -150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ -178, 170 },
							{ -122, 170 },
							{ -122, 214 },
							{ -178, 214 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 128 },
							{ -26, 216 },
							{ -14, 216 },
							{ -14, 128 },
						},
					},
					{ Kind = "Flat", At = { -20, 128 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 216 }, Radius = 6 },
					{
						Kind = "Roof",
						Area = {
							{ -36, 56 },
							{ -36, 90 },
							{ -4, 90 },
							{ -4, 56 },
						},
						Clearance = 12,
						Thickness = 6,
					},
					{
						Kind = "Roof",
						Area = {
							{ -36, 126 },
							{ -36, 166 },
							{ -4, 166 },
							{ -4, 126 },
						},
						Clearance = 12,
						Thickness = 6,
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 0 },
							{ -26, 216 },
							{ -14, 216 },
							{ -14, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -20, 222 },
							{ 88, 222 },
							{ 88, 210 },
							{ -20, 210 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 216 },
							{ 82, 256 },
							{ 94, 256 },
							{ 94, 216 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 250 },
							{ -88, 250 },
							{ -88, 262 },
							{ 88, 262 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 256 },
							{ -94, 296 },
							{ -82, 296 },
							{ -82, 256 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 302 },
							{ 88, 302 },
							{ 88, 290 },
							{ -88, 290 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 296 },
							{ 82, 336 },
							{ 94, 336 },
							{ 94, 296 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 330 },
							{ -88, 330 },
							{ -88, 342 },
							{ 88, 342 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 336 },
							{ -94, 376 },
							{ -82, 376 },
							{ -82, 336 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 382 },
							{ 88, 382 },
							{ 88, 370 },
							{ -88, 370 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 376 },
							{ 82, 416 },
							{ 94, 416 },
							{ 94, 376 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 410 },
							{ -88, 410 },
							{ -88, 422 },
							{ 88, 422 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 416 },
							{ -94, 456 },
							{ -82, 456 },
							{ -82, 416 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 462 },
							{ 88, 462 },
							{ 88, 450 },
							{ -88, 450 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 462 },
							{ 104, 462 },
							{ 104, 450 },
							{ 88, 450 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 98, 456 },
							{ 98, 608 },
							{ 110, 608 },
							{ 110, 456 },
						},
					},
					{ Kind = "Flat", At = { -20, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 216 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 216 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 256 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 256 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 296 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 296 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 336 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 336 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 376 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 376 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 456 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 456 }, Radius = 6 },
					{ Kind = "Flat", At = { 104, 456 }, Radius = 6 },
					{ Kind = "Flat", At = { 104, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 94, 540 },
							{ 114, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 132 },
							{ 222, 132 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 138 },
							{ 340, 138 },
							{ 340, 126 },
							{ 216, 126 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 132 },
							{ 334, 192 },
							{ 346, 192 },
							{ 346, 132 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 192 },
							{ 334, 256 },
							{ 346, 256 },
							{ 346, 192 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 250 },
							{ 216, 250 },
							{ 216, 262 },
							{ 340, 262 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 256 },
							{ 210, 296 },
							{ 222, 296 },
							{ 222, 256 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 302 },
							{ 340, 302 },
							{ 340, 290 },
							{ 216, 290 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 296 },
							{ 334, 336 },
							{ 346, 336 },
							{ 346, 296 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 330 },
							{ 216, 330 },
							{ 216, 342 },
							{ 340, 342 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 336 },
							{ 210, 376 },
							{ 222, 376 },
							{ 222, 336 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 382 },
							{ 340, 382 },
							{ 340, 370 },
							{ 216, 370 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 376 },
							{ 334, 416 },
							{ 346, 416 },
							{ 346, 376 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 410 },
							{ 216, 410 },
							{ 216, 422 },
							{ 340, 422 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 410 },
							{ 192, 410 },
							{ 192, 422 },
							{ 216, 422 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 186, 416 },
							{ 186, 608 },
							{ 198, 608 },
							{ 198, 416 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 132 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 132 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 192 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 256 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 256 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 296 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 296 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 336 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 336 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 376 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 376 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 416 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { -164, 184 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -134, 206 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ -150, 178 },
							{ -150, 254 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 94, 540 },
							{ 114, 540 },
						},
						Width = 12,
					},
					{
						Type = "Undertow",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { -170, 182 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { -132, 196 }, Yaw = 0 },
					{ Kind = "Crate", At = { -164, 202 }, Yaw = 30 },
					{ Kind = "Timber", At = { -157, 184 }, Yaw = 40 },
					{ Kind = "Timber", At = { -127, 206 }, Yaw = 40 },
					{ Kind = "Chain", At = { -141, 208 } },
					{ Kind = "Crate", At = { -140, 172 }, Yaw = 30 },
					{ Kind = "Chain", At = { -160, 174 } },
					{ Kind = "Weed", At = { 116, 548 } },
					{ Kind = "Weed", At = { 202, 548 } },
					{
						Kind = "Timber",
						Path = {
							{ -314, 12 },
							{ -286, 12 },
						},
						Count = 3,
					},
					{ Kind = "WreckRibs", At = { 300, 12 }, Scale = 1.1, Yaw = 90 },
				},
			},
			{
				Name = "Scour round",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 132 },
							{ -340, 132 },
							{ -340, 192 },
							{ -340, 258 },
							{ -214, 258 },
							{ -214, 298 },
							{ -340, 298 },
							{ -340, 338 },
							{ -214, 338 },
							{ -214, 378 },
							{ -340, 378 },
							{ -340, 418 },
							{ -214, 418 },
							{ -190, 418 },
							{ -190, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 132 },
							{ 222, 132 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 138 },
							{ 340, 138 },
							{ 340, 126 },
							{ 216, 126 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 132 },
							{ 334, 192 },
							{ 346, 192 },
							{ 346, 132 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 186 },
							{ 152, 186 },
							{ 152, 198 },
							{ 340, 198 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 146, 192 },
							{ 146, 264 },
							{ 158, 264 },
							{ 158, 192 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 152, 270 },
							{ 340, 270 },
							{ 340, 258 },
							{ 152, 258 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 264 },
							{ 334, 304 },
							{ 346, 304 },
							{ 346, 264 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 298 },
							{ 152, 298 },
							{ 152, 310 },
							{ 340, 310 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 146, 304 },
							{ 146, 608 },
							{ 158, 608 },
							{ 158, 304 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 132 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 132 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 192 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 192 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 264 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 264 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 122, 170 },
							{ 178, 170 },
							{ 178, 214 },
							{ 122, 214 },
						},
					},
					{
						Kind = "Channel",
						Path = {
							{ 140, 540 },
							{ 160, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 184 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 206 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 178 },
							{ 150, 254 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 140, 540 },
							{ 160, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 182 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 196 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 202 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 184 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 206 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 208 } },
					{ Kind = "Crate", At = { 160, 172 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 174 } },
					{ Kind = "Weed", At = { 162, 548 } },
					{ Kind = "Crate", At = { -300, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -288, 20 }, Yaw = 60 },
					{ Kind = "Anchor", At = { 300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ 314, 8 },
							{ 330, 16 },
						},
						Count = 2,
					},
				},
			},
		},
		Slots = {
			{
				Name = "The port hold",
				At = { -150, 72 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Cargo hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 104, 30 },
									{ 52, 30 },
									{ 52, 42 },
									{ 104, 42 },
								},
							},
							{ Kind = "Flat", At = { 104, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 30 },
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 30 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 8, 30 },
									{ 46, 30 },
									{ 46, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 58, 42 },
									{ 58, 30 },
									{ 96, 30 },
									{ 96, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 96, 42 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Wall",
								Area = {
									{ 46, 30 },
									{ 58, 30 },
									{ 58, 42 },
									{ 46, 42 },
								},
								Height = 14,
								Over = true,
							},
						},
						Loot = {
							{ At = { 12, 36 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 6,
							},
							{
								Kind = "Timber",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
					{
						Name = "Flooded hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 104, 30 },
									{ 52, 30 },
									{ 52, 42 },
									{ 104, 42 },
								},
							},
							{ Kind = "Flat", At = { 104, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 12, 36 },
								Radius = 24,
								Depth = 3,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 12, 36 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Chain",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "The bell hold",
				At = { 46, 72 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Ship's bell",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 0, 42 },
									{ 92, 42 },
									{ 92, 30 },
									{ 0, 30 },
								},
							},
							{ Kind = "Flat", At = { 0, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 86, 36 },
									{ 86, 56 },
									{ 98, 56 },
									{ 98, 36 },
								},
							},
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 56 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 98, 36 },
									{ 98, 16 },
									{ 86, 16 },
									{ 86, 36 },
								},
							},
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 16 }, Radius = 6 },
						},
						Loot = {
							{ At = { 92, 58 }, Radius = 3, Weight = 1 },
							{ At = { 92, 14 }, Radius = 3, Weight = 1 },
							{ At = { 92, 36 }, Radius = 4, Weight = 5 },
						},
						Hazards = {
							{ Type = "Pit", At = { 92, 36 }, Radius = 4, Covered = true },
						},
						Decor = {
							{ Kind = "Chain", At = { 100, 44 } },
							{ Kind = "Crate", At = { 84, 28 } },
						},
					},
					{
						Name = "Lower hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 0, 42 },
									{ 52, 42 },
									{ 52, 30 },
									{ 0, 30 },
								},
							},
							{ Kind = "Flat", At = { 0, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 30 },
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 30 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 8, 30 },
									{ 46, 30 },
									{ 46, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 58, 42 },
									{ 58, 30 },
									{ 96, 30 },
									{ 96, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 96, 42 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Wall",
								Area = {
									{ 46, 30 },
									{ 58, 30 },
									{ 58, 42 },
									{ 46, 42 },
								},
								Height = 14,
								Over = true,
							},
						},
						Loot = {
							{ At = { 92, 36 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 6,
							},
							{
								Kind = "Timber",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "Cargo west",
				At = { -330, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Spilled cargo",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
					{
						Name = "Sunken stores",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 3,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Chain",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "The scour hole",
				At = { -52, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Scour hole",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 4,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 4 },
						},
						Decor = {
							{
								Kind = "Kelp",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 4,
							},
						},
					},
					{
						Name = "Cargo heap",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
				},
			},
			{
				Name = "Cargo east",
				At = { 226, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Wrecked stores",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
					{
						Name = "Flooded scour",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 4,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Kelp",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 4,
							},
						},
					},
				},
			},
		},
	},
	[5] = {
		Primitives = {
			{
				Kind = "Wall",
				Area = {
					{ -380, -12 },
					{ 380, -12 },
					{ 380, 620 },
					{ -380, 620 },
				},
				Height = 16,
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, -12 },
					{ 360, -12 },
					{ 360, 46 },
					{ -360, 46 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, 592 },
					{ 360, 592 },
					{ 360, 620 },
					{ -360, 620 },
				},
			},
			{ Kind = "Flat", At = { -100, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { -20, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 60, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 120, 30 }, Radius = 10 },
			{
				Kind = "Flat",
				Area = {
					{ -26, 44 },
					{ -26, 164 },
					{ -14, 164 },
					{ -14, 44 },
				},
			},
			{ Kind = "Flat", At = { -20, 44 }, Radius = 6 },
			{ Kind = "Flat", At = { -20, 164 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -56, 114 },
					{ -32, 114 },
					{ -32, 102 },
					{ -56, 102 },
				},
			},
			{ Kind = "Flat", At = { -56, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { -32, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 56, 102 },
					{ 32, 102 },
					{ 32, 114 },
					{ 56, 114 },
				},
			},
			{ Kind = "Flat", At = { 56, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { 32, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 32, 102 },
					{ -20, 102 },
					{ -20, 114 },
					{ 32, 114 },
				},
			},
			{ Kind = "Flat", At = { 32, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { -20, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -286, 568 },
					{ -286, 592 },
					{ -274, 592 },
					{ -274, 568 },
				},
			},
			{ Kind = "Flat", At = { -280, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { -280, 592 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -6, 568 },
					{ -6, 592 },
					{ 6, 592 },
					{ 6, 568 },
				},
			},
			{ Kind = "Flat", At = { 0, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { 0, 592 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 274, 568 },
					{ 274, 592 },
					{ 286, 592 },
					{ 286, 568 },
				},
			},
			{ Kind = "Flat", At = { 280, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { 280, 592 }, Radius = 6 },
		},
		Entrances = {
			{ -20, 30 },
		},
		Decor = {
			{
				Kind = "Timber",
				Area = {
					{ -320, -2 },
					{ 320, -2 },
					{ 320, 14 },
					{ -320, 14 },
				},
				Count = 8,
			},
			{
				Kind = "Rocks",
				Area = {
					{ -320, 598 },
					{ 320, 598 },
					{ 320, 614 },
					{ -320, 614 },
				},
				Count = 6,
			},
			{
				Kind = "Starfish",
				Area = {
					{ -320, 596 },
					{ 320, 596 },
					{ 320, 612 },
					{ -320, 612 },
				},
				Count = 3,
			},
			{ Kind = "Chain", At = { -34, 38 } },
			{ Kind = "Crate", At = { -6, 38 }, Yaw = 20 },
			{ Kind = "WreckRibs", At = { -20, 18 }, Scale = 1.8, Yaw = 0 },
			{ Kind = "WreckRibs", At = { -170, 30 }, Scale = 1.6, Yaw = 90 },
			{ Kind = "WreckRibs", At = { 150, 30 }, Scale = 1.6, Yaw = 90 },
			{ Kind = "Anchor", At = { -230, 26 }, Yaw = 40 },
			{
				Kind = "Timber",
				Path = {
					{ -200, 34 },
					{ 200, 34 },
				},
				Count = 6,
			},
			{
				Kind = "Chain",
				Path = {
					{ 60, 36 },
					{ 110, 36 },
				},
				Count = 3,
			},
		},
		Name = "Shipwreck Shallows",
		Crossings = {
			{
				Name = "Gully run",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 126 },
							{ -340, 126 },
							{ -340, 168 },
							{ -214, 168 },
							{ -214, 222 },
							{ -150, 222 },
							{ -150, 310 },
							{ -340, 310 },
							{ -340, 350 },
							{ -150, 350 },
							{ -150, 390 },
							{ -340, 390 },
							{ -340, 430 },
							{ -150, 430 },
							{ -150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ -178, 200 },
							{ -122, 200 },
							{ -122, 244 },
							{ -178, 244 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 128 },
							{ 222, 128 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 134 },
							{ 340, 134 },
							{ 340, 122 },
							{ 216, 122 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 128 },
							{ 334, 168 },
							{ 346, 168 },
							{ 346, 128 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 162 },
							{ 216, 162 },
							{ 216, 174 },
							{ 340, 174 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 168 },
							{ 210, 224 },
							{ 222, 224 },
							{ 222, 168 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 224 },
							{ 210, 288 },
							{ 222, 288 },
							{ 222, 224 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 294 },
							{ 340, 294 },
							{ 340, 282 },
							{ 216, 282 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 288 },
							{ 334, 328 },
							{ 346, 328 },
							{ 346, 288 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 322 },
							{ 216, 322 },
							{ 216, 334 },
							{ 340, 334 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 328 },
							{ 210, 368 },
							{ 222, 368 },
							{ 222, 328 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 374 },
							{ 340, 374 },
							{ 340, 362 },
							{ 216, 362 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 368 },
							{ 334, 408 },
							{ 346, 408 },
							{ 346, 368 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 402 },
							{ 216, 402 },
							{ 216, 414 },
							{ 340, 414 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 408 },
							{ 210, 448 },
							{ 222, 448 },
							{ 222, 408 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 454 },
							{ 340, 454 },
							{ 340, 442 },
							{ 216, 442 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 442 },
							{ 192, 442 },
							{ 192, 454 },
							{ 340, 454 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 186, 448 },
							{ 186, 608 },
							{ 198, 608 },
							{ 198, 448 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 128 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 128 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 168 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 168 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 224 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 288 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 288 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 368 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 368 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 448 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 448 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 448 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { -164, 214 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -134, 236 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ -150, 208 },
							{ -150, 302 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { -170, 212 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { -132, 226 }, Yaw = 0 },
					{ Kind = "Crate", At = { -164, 232 }, Yaw = 30 },
					{ Kind = "Timber", At = { -157, 214 }, Yaw = 40 },
					{ Kind = "Timber", At = { -127, 236 }, Yaw = 40 },
					{ Kind = "Chain", At = { -141, 238 } },
					{ Kind = "Crate", At = { -140, 202 }, Yaw = 30 },
					{ Kind = "Chain", At = { -160, 204 } },
					{ Kind = "Weed", At = { 202, 548 } },
					{ Kind = "Anchor", At = { -300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ -286, 8 },
							{ -270, 16 },
						},
						Count = 2,
					},
					{
						Kind = "Timber",
						Path = {
							{ 286, 12 },
							{ 314, 12 },
						},
						Count = 3,
					},
				},
			},
			{
				Name = "Through the hatch",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 340, 0 },
							{ 340, 84 },
							{ 214, 84 },
							{ 214, 126 },
							{ 340, 126 },
							{ 340, 168 },
							{ 214, 168 },
							{ 214, 222 },
							{ 150, 222 },
							{ 150, 310 },
							{ 340, 310 },
							{ 340, 350 },
							{ 150, 350 },
							{ 150, 390 },
							{ 340, 390 },
							{ 340, 430 },
							{ 150, 430 },
							{ 150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 122, 200 },
							{ 178, 200 },
							{ 178, 244 },
							{ 122, 244 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 160 },
							{ -26, 244 },
							{ -14, 244 },
							{ -14, 160 },
						},
					},
					{ Kind = "Flat", At = { -20, 160 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 244 }, Radius = 6 },
					{
						Kind = "Roof",
						Area = {
							{ -36, 56 },
							{ -36, 90 },
							{ -4, 90 },
							{ -4, 56 },
						},
						Clearance = 14,
						Thickness = 6,
					},
					{
						Kind = "Roof",
						Area = {
							{ -36, 126 },
							{ -36, 196 },
							{ -4, 196 },
							{ -4, 126 },
						},
						Clearance = 14,
						Thickness = 6,
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 0 },
							{ -26, 244 },
							{ -14, 244 },
							{ -14, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -20, 250 },
							{ 88, 250 },
							{ 88, 238 },
							{ -20, 238 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 244 },
							{ 82, 284 },
							{ 94, 284 },
							{ 94, 244 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 278 },
							{ -88, 278 },
							{ -88, 290 },
							{ 88, 290 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 284 },
							{ -94, 324 },
							{ -82, 324 },
							{ -82, 284 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 330 },
							{ 88, 330 },
							{ 88, 318 },
							{ -88, 318 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 324 },
							{ 82, 364 },
							{ 94, 364 },
							{ 94, 324 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 358 },
							{ -88, 358 },
							{ -88, 370 },
							{ 88, 370 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 364 },
							{ -94, 404 },
							{ -82, 404 },
							{ -82, 364 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 410 },
							{ 88, 410 },
							{ 88, 398 },
							{ -88, 398 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 404 },
							{ 82, 444 },
							{ 94, 444 },
							{ 94, 404 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 438 },
							{ -88, 438 },
							{ -88, 450 },
							{ 88, 450 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 444 },
							{ -94, 484 },
							{ -82, 484 },
							{ -82, 444 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 490 },
							{ 88, 490 },
							{ 88, 478 },
							{ -88, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 490 },
							{ 104, 490 },
							{ 104, 478 },
							{ 88, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 98, 484 },
							{ 98, 608 },
							{ 110, 608 },
							{ 110, 484 },
						},
					},
					{ Kind = "Flat", At = { -20, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 244 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 244 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 284 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 284 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 324 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 324 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 364 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 364 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 404 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 404 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 444 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 444 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 484 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 484 }, Radius = 6 },
					{ Kind = "Flat", At = { 104, 484 }, Radius = 6 },
					{ Kind = "Flat", At = { 104, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 94, 540 },
							{ 114, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 214 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 236 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 208 },
							{ 150, 302 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 94, 540 },
							{ 114, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 212 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 226 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 232 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 214 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 236 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 238 } },
					{ Kind = "Crate", At = { 160, 202 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 204 } },
					{ Kind = "Weed", At = { 116, 548 } },
					{ Kind = "WreckRibs", At = { 300, 12 }, Scale = 1.1, Yaw = 90 },
					{ Kind = "Crate", At = { -20, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -8, 20 }, Yaw = 60 },
				},
			},
			{
				Name = "The long gully",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 126 },
							{ -340, 126 },
							{ -340, 168 },
							{ -214, 168 },
							{ -214, 222 },
						},
						Width = 16,
					},
					{
						Kind = "Ramp",
						Path = {
							{ -214, 222 },
							{ 150, 222 },
						},
						Width = 16,
					},
					{
						Kind = "Ramp",
						Path = {
							{ 150, 222 },
							{ 150, 310 },
							{ 340, 310 },
							{ 340, 350 },
							{ 150, 350 },
							{ 150, 390 },
							{ 340, 390 },
							{ 340, 430 },
							{ 150, 430 },
							{ 150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 122, 200 },
							{ 178, 200 },
							{ 178, 244 },
							{ 122, 244 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 152, 546 },
							{ 184, 546 },
							{ 184, 534 },
							{ 152, 534 },
						},
					},
					{ Kind = "Flat", At = { 152, 540 }, Radius = 6 },
					{ Kind = "Flat", At = { 184, 540 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 166, 540 },
							{ 186, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Loot = {
					{ At = { 186, 540 }, Radius = 3, Weight = 1 },
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 214 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 236 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 208 },
							{ 150, 302 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 166, 540 },
							{ 186, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 212 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 226 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 232 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 214 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 236 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 238 } },
					{ Kind = "Crate", At = { 160, 202 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 204 } },
					{ Kind = "Weed", At = { 188, 548 } },
					{ Kind = "Anchor", At = { -300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ -286, 8 },
							{ -270, 16 },
						},
						Count = 2,
					},
					{ Kind = "Crate", At = { -280, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -268, 20 }, Yaw = 60 },
				},
			},
			{
				Name = "Three ways",
				Paths = 3,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 126 },
							{ -340, 126 },
							{ -340, 168 },
							{ -214, 168 },
							{ -214, 222 },
							{ -150, 222 },
							{ -150, 310 },
							{ -340, 310 },
							{ -340, 350 },
							{ -150, 350 },
							{ -150, 390 },
							{ -340, 390 },
							{ -340, 430 },
							{ -150, 430 },
							{ -150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ -178, 200 },
							{ -122, 200 },
							{ -122, 244 },
							{ -178, 244 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 160 },
							{ -26, 244 },
							{ -14, 244 },
							{ -14, 160 },
						},
					},
					{ Kind = "Flat", At = { -20, 160 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 244 }, Radius = 6 },
					{
						Kind = "Roof",
						Area = {
							{ -36, 56 },
							{ -36, 90 },
							{ -4, 90 },
							{ -4, 56 },
						},
						Clearance = 14,
						Thickness = 6,
					},
					{
						Kind = "Roof",
						Area = {
							{ -36, 126 },
							{ -36, 196 },
							{ -4, 196 },
							{ -4, 126 },
						},
						Clearance = 14,
						Thickness = 6,
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 0 },
							{ -26, 244 },
							{ -14, 244 },
							{ -14, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -20, 250 },
							{ 88, 250 },
							{ 88, 238 },
							{ -20, 238 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 244 },
							{ 82, 284 },
							{ 94, 284 },
							{ 94, 244 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 278 },
							{ -88, 278 },
							{ -88, 290 },
							{ 88, 290 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 284 },
							{ -94, 324 },
							{ -82, 324 },
							{ -82, 284 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 330 },
							{ 88, 330 },
							{ 88, 318 },
							{ -88, 318 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 324 },
							{ 82, 364 },
							{ 94, 364 },
							{ 94, 324 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 358 },
							{ -88, 358 },
							{ -88, 370 },
							{ 88, 370 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 364 },
							{ -94, 404 },
							{ -82, 404 },
							{ -82, 364 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 410 },
							{ 88, 410 },
							{ 88, 398 },
							{ -88, 398 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 404 },
							{ 82, 444 },
							{ 94, 444 },
							{ 94, 404 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 438 },
							{ -88, 438 },
							{ -88, 450 },
							{ 88, 450 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 444 },
							{ -94, 484 },
							{ -82, 484 },
							{ -82, 444 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 490 },
							{ 88, 490 },
							{ 88, 478 },
							{ -88, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 490 },
							{ 104, 490 },
							{ 104, 478 },
							{ 88, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 98, 484 },
							{ 98, 608 },
							{ 110, 608 },
							{ 110, 484 },
						},
					},
					{ Kind = "Flat", At = { -20, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 244 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 244 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 284 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 284 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 324 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 324 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 364 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 364 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 404 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 404 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 444 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 444 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 484 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 484 }, Radius = 6 },
					{ Kind = "Flat", At = { 104, 484 }, Radius = 6 },
					{ Kind = "Flat", At = { 104, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 94, 540 },
							{ 114, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 128 },
							{ 222, 128 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 134 },
							{ 340, 134 },
							{ 340, 122 },
							{ 216, 122 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 128 },
							{ 334, 168 },
							{ 346, 168 },
							{ 346, 128 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 162 },
							{ 216, 162 },
							{ 216, 174 },
							{ 340, 174 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 168 },
							{ 210, 224 },
							{ 222, 224 },
							{ 222, 168 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 224 },
							{ 210, 288 },
							{ 222, 288 },
							{ 222, 224 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 294 },
							{ 340, 294 },
							{ 340, 282 },
							{ 216, 282 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 288 },
							{ 334, 328 },
							{ 346, 328 },
							{ 346, 288 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 322 },
							{ 216, 322 },
							{ 216, 334 },
							{ 340, 334 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 328 },
							{ 210, 368 },
							{ 222, 368 },
							{ 222, 328 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 374 },
							{ 340, 374 },
							{ 340, 362 },
							{ 216, 362 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 368 },
							{ 334, 408 },
							{ 346, 408 },
							{ 346, 368 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 402 },
							{ 216, 402 },
							{ 216, 414 },
							{ 340, 414 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 408 },
							{ 210, 448 },
							{ 222, 448 },
							{ 222, 408 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 454 },
							{ 340, 454 },
							{ 340, 442 },
							{ 216, 442 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 442 },
							{ 192, 442 },
							{ 192, 454 },
							{ 340, 454 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 186, 448 },
							{ 186, 608 },
							{ 198, 608 },
							{ 198, 448 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 128 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 128 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 168 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 168 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 224 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 288 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 288 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 368 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 368 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 448 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 448 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 448 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { -164, 214 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -134, 236 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ -150, 208 },
							{ -150, 302 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 94, 540 },
							{ 114, 540 },
						},
						Width = 12,
					},
					{
						Type = "Undertow",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { -170, 212 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { -132, 226 }, Yaw = 0 },
					{ Kind = "Crate", At = { -164, 232 }, Yaw = 30 },
					{ Kind = "Timber", At = { -157, 214 }, Yaw = 40 },
					{ Kind = "Timber", At = { -127, 236 }, Yaw = 40 },
					{ Kind = "Chain", At = { -141, 238 } },
					{ Kind = "Crate", At = { -140, 202 }, Yaw = 30 },
					{ Kind = "Chain", At = { -160, 204 } },
					{ Kind = "Weed", At = { 116, 548 } },
					{ Kind = "Weed", At = { 202, 548 } },
					{
						Kind = "Timber",
						Path = {
							{ -314, 12 },
							{ -286, 12 },
						},
						Count = 3,
					},
					{ Kind = "WreckRibs", At = { 300, 12 }, Scale = 1.1, Yaw = 90 },
				},
			},
			{
				Name = "Scour round",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 126 },
							{ -340, 126 },
							{ -340, 168 },
							{ -214, 168 },
							{ -214, 222 },
							{ -214, 288 },
							{ -340, 288 },
							{ -340, 328 },
							{ -214, 328 },
							{ -214, 368 },
							{ -340, 368 },
							{ -340, 408 },
							{ -214, 408 },
							{ -214, 448 },
							{ -340, 448 },
							{ -190, 448 },
							{ -190, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 128 },
							{ 222, 128 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 134 },
							{ 340, 134 },
							{ 340, 122 },
							{ 216, 122 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 128 },
							{ 334, 168 },
							{ 346, 168 },
							{ 346, 128 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 162 },
							{ 216, 162 },
							{ 216, 174 },
							{ 340, 174 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 168 },
							{ 210, 224 },
							{ 222, 224 },
							{ 222, 168 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 218 },
							{ 152, 218 },
							{ 152, 230 },
							{ 216, 230 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 146, 224 },
							{ 146, 312 },
							{ 158, 312 },
							{ 158, 224 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 152, 318 },
							{ 340, 318 },
							{ 340, 306 },
							{ 152, 306 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 312 },
							{ 334, 352 },
							{ 346, 352 },
							{ 346, 312 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 346 },
							{ 152, 346 },
							{ 152, 358 },
							{ 340, 358 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 146, 352 },
							{ 146, 392 },
							{ 158, 392 },
							{ 158, 352 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 152, 398 },
							{ 340, 398 },
							{ 340, 386 },
							{ 152, 386 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 392 },
							{ 334, 432 },
							{ 346, 432 },
							{ 346, 392 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 426 },
							{ 152, 426 },
							{ 152, 438 },
							{ 340, 438 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 146, 432 },
							{ 146, 608 },
							{ 158, 608 },
							{ 158, 432 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 128 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 128 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 168 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 168 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 224 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 224 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 122, 200 },
							{ 178, 200 },
							{ 178, 244 },
							{ 122, 244 },
						},
					},
					{
						Kind = "Channel",
						Path = {
							{ 140, 540 },
							{ 160, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 214 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 236 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 208 },
							{ 150, 302 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 140, 540 },
							{ 160, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 212 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 226 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 232 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 214 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 236 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 238 } },
					{ Kind = "Crate", At = { 160, 202 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 204 } },
					{ Kind = "Weed", At = { 162, 548 } },
					{ Kind = "Crate", At = { -300, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -288, 20 }, Yaw = 60 },
					{ Kind = "Anchor", At = { 300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ 314, 8 },
							{ 330, 16 },
						},
						Count = 2,
					},
				},
			},
		},
		Slots = {
			{
				Name = "The port hold",
				At = { -150, 72 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Cargo hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 104, 30 },
									{ 52, 30 },
									{ 52, 42 },
									{ 104, 42 },
								},
							},
							{ Kind = "Flat", At = { 104, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 30 },
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 30 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 8, 30 },
									{ 46, 30 },
									{ 46, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 58, 42 },
									{ 58, 30 },
									{ 96, 30 },
									{ 96, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 96, 42 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Wall",
								Area = {
									{ 46, 30 },
									{ 58, 30 },
									{ 58, 42 },
									{ 46, 42 },
								},
								Height = 16,
								Over = true,
							},
						},
						Loot = {
							{ At = { 12, 36 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 6,
							},
							{
								Kind = "Timber",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
					{
						Name = "Flooded hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 104, 30 },
									{ 52, 30 },
									{ 52, 42 },
									{ 104, 42 },
								},
							},
							{ Kind = "Flat", At = { 104, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 12, 36 },
								Radius = 24,
								Depth = 3,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 12, 36 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Chain",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "The bell hold",
				At = { 46, 72 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Ship's bell",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 0, 42 },
									{ 92, 42 },
									{ 92, 30 },
									{ 0, 30 },
								},
							},
							{ Kind = "Flat", At = { 0, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 86, 36 },
									{ 86, 56 },
									{ 98, 56 },
									{ 98, 36 },
								},
							},
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 56 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 98, 36 },
									{ 98, 16 },
									{ 86, 16 },
									{ 86, 36 },
								},
							},
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 16 }, Radius = 6 },
						},
						Loot = {
							{ At = { 92, 58 }, Radius = 3, Weight = 1 },
							{ At = { 92, 14 }, Radius = 3, Weight = 1 },
							{ At = { 92, 36 }, Radius = 4, Weight = 5 },
						},
						Hazards = {
							{ Type = "Pit", At = { 92, 36 }, Radius = 4, Covered = true },
						},
						Decor = {
							{ Kind = "Chain", At = { 100, 44 } },
							{ Kind = "Crate", At = { 84, 28 } },
						},
					},
					{
						Name = "Lower hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 0, 42 },
									{ 52, 42 },
									{ 52, 30 },
									{ 0, 30 },
								},
							},
							{ Kind = "Flat", At = { 0, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 30 },
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 30 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 8, 30 },
									{ 46, 30 },
									{ 46, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 58, 42 },
									{ 58, 30 },
									{ 96, 30 },
									{ 96, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 96, 42 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Wall",
								Area = {
									{ 46, 30 },
									{ 58, 30 },
									{ 58, 42 },
									{ 46, 42 },
								},
								Height = 16,
								Over = true,
							},
						},
						Loot = {
							{ At = { 92, 36 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 6,
							},
							{
								Kind = "Timber",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "Cargo west",
				At = { -330, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Spilled cargo",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
					{
						Name = "Sunken stores",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 3,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Chain",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "The scour hole",
				At = { -52, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Scour hole",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 4,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 4 },
						},
						Decor = {
							{
								Kind = "Kelp",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 4,
							},
						},
					},
					{
						Name = "Cargo heap",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
				},
			},
			{
				Name = "Cargo east",
				At = { 226, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Wrecked stores",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
					{
						Name = "Flooded scour",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 4,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Kelp",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 4,
							},
						},
					},
				},
			},
		},
	},
	[6] = {
		Primitives = {
			{
				Kind = "Wall",
				Area = {
					{ -380, -12 },
					{ 380, -12 },
					{ 380, 620 },
					{ -380, 620 },
				},
				Height = 20,
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, -12 },
					{ 360, -12 },
					{ 360, 46 },
					{ -360, 46 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, 592 },
					{ 360, 592 },
					{ 360, 620 },
					{ -360, 620 },
				},
			},
			{ Kind = "Flat", At = { -100, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { -20, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 60, 30 }, Radius = 10 },
			{ Kind = "Flat", At = { 120, 30 }, Radius = 10 },
			{
				Kind = "Flat",
				Area = {
					{ -26, 44 },
					{ -26, 192 },
					{ -14, 192 },
					{ -14, 44 },
				},
			},
			{ Kind = "Flat", At = { -20, 44 }, Radius = 6 },
			{ Kind = "Flat", At = { -20, 192 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -56, 114 },
					{ -32, 114 },
					{ -32, 102 },
					{ -56, 102 },
				},
			},
			{ Kind = "Flat", At = { -56, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { -32, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 56, 102 },
					{ 32, 102 },
					{ 32, 114 },
					{ 56, 114 },
				},
			},
			{ Kind = "Flat", At = { 56, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { 32, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 32, 102 },
					{ -20, 102 },
					{ -20, 114 },
					{ 32, 114 },
				},
			},
			{ Kind = "Flat", At = { 32, 108 }, Radius = 6 },
			{ Kind = "Flat", At = { -20, 108 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -286, 568 },
					{ -286, 592 },
					{ -274, 592 },
					{ -274, 568 },
				},
			},
			{ Kind = "Flat", At = { -280, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { -280, 592 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ -6, 568 },
					{ -6, 592 },
					{ 6, 592 },
					{ 6, 568 },
				},
			},
			{ Kind = "Flat", At = { 0, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { 0, 592 }, Radius = 6 },
			{
				Kind = "Flat",
				Area = {
					{ 274, 568 },
					{ 274, 592 },
					{ 286, 592 },
					{ 286, 568 },
				},
			},
			{ Kind = "Flat", At = { 280, 568 }, Radius = 6 },
			{ Kind = "Flat", At = { 280, 592 }, Radius = 6 },
		},
		Entrances = {
			{ -20, 30 },
		},
		Decor = {
			{
				Kind = "Timber",
				Area = {
					{ -320, -2 },
					{ 320, -2 },
					{ 320, 14 },
					{ -320, 14 },
				},
				Count = 8,
			},
			{
				Kind = "Rocks",
				Area = {
					{ -320, 598 },
					{ 320, 598 },
					{ 320, 614 },
					{ -320, 614 },
				},
				Count = 6,
			},
			{
				Kind = "Starfish",
				Area = {
					{ -320, 596 },
					{ 320, 596 },
					{ 320, 612 },
					{ -320, 612 },
				},
				Count = 3,
			},
			{ Kind = "Chain", At = { -34, 38 } },
			{ Kind = "Crate", At = { -6, 38 }, Yaw = 20 },
			{ Kind = "WreckRibs", At = { -20, 18 }, Scale = 1.8, Yaw = 0 },
			{ Kind = "WreckRibs", At = { -170, 30 }, Scale = 1.6, Yaw = 90 },
			{ Kind = "WreckRibs", At = { 150, 30 }, Scale = 1.6, Yaw = 90 },
			{ Kind = "Anchor", At = { -230, 26 }, Yaw = 40 },
			{
				Kind = "Timber",
				Path = {
					{ -200, 34 },
					{ 200, 34 },
				},
				Count = 6,
			},
			{
				Kind = "Chain",
				Path = {
					{ 60, 36 },
					{ 110, 36 },
				},
				Count = 3,
			},
		},
		Name = "Shipwreck Shallows",
		Crossings = {
			{
				Name = "Gully run",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 124 },
							{ -340, 124 },
							{ -340, 164 },
							{ -214, 164 },
							{ -214, 204 },
							{ -340, 204 },
							{ -340, 252 },
							{ -150, 252 },
							{ -150, 358 },
							{ -340, 358 },
							{ -340, 398 },
							{ -150, 398 },
							{ -150, 438 },
							{ -340, 438 },
							{ -340, 478 },
							{ -150, 478 },
							{ -150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ -178, 230 },
							{ -122, 230 },
							{ -122, 274 },
							{ -178, 274 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 124 },
							{ 222, 124 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 130 },
							{ 340, 130 },
							{ 340, 118 },
							{ 216, 118 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 124 },
							{ 334, 164 },
							{ 346, 164 },
							{ 346, 124 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 158 },
							{ 216, 158 },
							{ 216, 170 },
							{ 340, 170 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 164 },
							{ 210, 204 },
							{ 222, 204 },
							{ 222, 164 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 210 },
							{ 340, 210 },
							{ 340, 198 },
							{ 216, 198 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 204 },
							{ 334, 252 },
							{ 346, 252 },
							{ 346, 204 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 252 },
							{ 334, 320 },
							{ 346, 320 },
							{ 346, 252 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 314 },
							{ 216, 314 },
							{ 216, 326 },
							{ 340, 326 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 320 },
							{ 210, 360 },
							{ 222, 360 },
							{ 222, 320 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 366 },
							{ 340, 366 },
							{ 340, 354 },
							{ 216, 354 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 360 },
							{ 334, 400 },
							{ 346, 400 },
							{ 346, 360 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 394 },
							{ 216, 394 },
							{ 216, 406 },
							{ 340, 406 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 400 },
							{ 210, 440 },
							{ 222, 440 },
							{ 222, 400 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 446 },
							{ 340, 446 },
							{ 340, 434 },
							{ 216, 434 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 440 },
							{ 334, 480 },
							{ 346, 480 },
							{ 346, 440 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 474 },
							{ 216, 474 },
							{ 216, 486 },
							{ 340, 486 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 474 },
							{ 192, 474 },
							{ 192, 486 },
							{ 216, 486 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 186, 480 },
							{ 186, 608 },
							{ 198, 608 },
							{ 198, 480 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 124 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 124 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 164 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 164 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 204 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 204 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 252 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 320 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 320 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 360 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 360 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 400 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 400 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 440 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 440 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 480 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 480 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 480 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { -164, 244 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -134, 266 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ -150, 238 },
							{ -150, 350 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { -170, 242 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { -132, 256 }, Yaw = 0 },
					{ Kind = "Crate", At = { -164, 262 }, Yaw = 30 },
					{ Kind = "Timber", At = { -157, 244 }, Yaw = 40 },
					{ Kind = "Timber", At = { -127, 266 }, Yaw = 40 },
					{ Kind = "Chain", At = { -141, 268 } },
					{ Kind = "Crate", At = { -140, 232 }, Yaw = 30 },
					{ Kind = "Chain", At = { -160, 234 } },
					{ Kind = "Weed", At = { 202, 548 } },
					{ Kind = "Anchor", At = { -300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ -286, 8 },
							{ -270, 16 },
						},
						Count = 2,
					},
					{
						Kind = "Timber",
						Path = {
							{ 286, 12 },
							{ 314, 12 },
						},
						Count = 3,
					},
				},
			},
			{
				Name = "Through the hatch",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 340, 0 },
							{ 340, 84 },
							{ 214, 84 },
							{ 214, 124 },
							{ 340, 124 },
							{ 340, 164 },
							{ 214, 164 },
							{ 214, 204 },
							{ 340, 204 },
							{ 340, 252 },
							{ 150, 252 },
							{ 150, 358 },
							{ 340, 358 },
							{ 340, 398 },
							{ 150, 398 },
							{ 150, 438 },
							{ 340, 438 },
							{ 340, 478 },
							{ 150, 478 },
							{ 150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 122, 230 },
							{ 178, 230 },
							{ 178, 274 },
							{ 122, 274 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 192 },
							{ -26, 272 },
							{ -14, 272 },
							{ -14, 192 },
						},
					},
					{ Kind = "Flat", At = { -20, 192 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 272 }, Radius = 6 },
					{
						Kind = "Roof",
						Area = {
							{ -36, 56 },
							{ -36, 90 },
							{ -4, 90 },
							{ -4, 56 },
						},
						Clearance = 18,
						Thickness = 6,
					},
					{
						Kind = "Roof",
						Area = {
							{ -36, 126 },
							{ -36, 226 },
							{ -4, 226 },
							{ -4, 126 },
						},
						Clearance = 18,
						Thickness = 6,
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 0 },
							{ -26, 272 },
							{ -14, 272 },
							{ -14, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -20, 278 },
							{ 88, 278 },
							{ 88, 266 },
							{ -20, 266 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 272 },
							{ 82, 312 },
							{ 94, 312 },
							{ 94, 272 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 306 },
							{ -88, 306 },
							{ -88, 318 },
							{ 88, 318 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 312 },
							{ -94, 352 },
							{ -82, 352 },
							{ -82, 312 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 358 },
							{ 88, 358 },
							{ 88, 346 },
							{ -88, 346 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 352 },
							{ 82, 392 },
							{ 94, 392 },
							{ 94, 352 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 386 },
							{ -88, 386 },
							{ -88, 398 },
							{ 88, 398 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 392 },
							{ -94, 432 },
							{ -82, 432 },
							{ -82, 392 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 438 },
							{ 88, 438 },
							{ 88, 426 },
							{ -88, 426 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 432 },
							{ 82, 472 },
							{ 94, 472 },
							{ 94, 432 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 466 },
							{ -88, 466 },
							{ -88, 478 },
							{ 88, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 466 },
							{ -104, 466 },
							{ -104, 478 },
							{ -88, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -110, 472 },
							{ -110, 608 },
							{ -98, 608 },
							{ -98, 472 },
						},
					},
					{ Kind = "Flat", At = { -20, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { -104, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { -104, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ -114, 540 },
							{ -94, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 244 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 266 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 238 },
							{ 150, 350 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ -114, 540 },
							{ -94, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 242 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 256 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 262 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 244 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 266 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 268 } },
					{ Kind = "Crate", At = { 160, 232 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 234 } },
					{ Kind = "Weed", At = { -92, 548 } },
					{ Kind = "WreckRibs", At = { 300, 12 }, Scale = 1.1, Yaw = 90 },
					{ Kind = "Crate", At = { -20, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -8, 20 }, Yaw = 60 },
				},
			},
			{
				Name = "The long gully",
				Paths = 1,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 124 },
							{ -340, 124 },
							{ -340, 164 },
							{ -214, 164 },
							{ -214, 204 },
							{ -340, 204 },
							{ -340, 252 },
						},
						Width = 16,
					},
					{
						Kind = "Ramp",
						Path = {
							{ -340, 252 },
							{ 150, 252 },
						},
						Width = 16,
					},
					{
						Kind = "Ramp",
						Path = {
							{ 150, 252 },
							{ 150, 358 },
							{ 340, 358 },
							{ 340, 398 },
							{ 150, 398 },
							{ 150, 438 },
							{ 340, 438 },
							{ 340, 478 },
							{ 150, 478 },
							{ 150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 122, 230 },
							{ 178, 230 },
							{ 178, 274 },
							{ 122, 274 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 152, 546 },
							{ 184, 546 },
							{ 184, 534 },
							{ 152, 534 },
						},
					},
					{ Kind = "Flat", At = { 152, 540 }, Radius = 6 },
					{ Kind = "Flat", At = { 184, 540 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 166, 540 },
							{ 186, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Loot = {
					{ At = { 186, 540 }, Radius = 3, Weight = 1 },
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 244 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 266 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 238 },
							{ 150, 350 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 166, 540 },
							{ 186, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 242 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 256 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 262 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 244 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 266 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 268 } },
					{ Kind = "Crate", At = { 160, 232 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 234 } },
					{ Kind = "Weed", At = { 188, 548 } },
					{ Kind = "Anchor", At = { -300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ -286, 8 },
							{ -270, 16 },
						},
						Count = 2,
					},
					{ Kind = "Crate", At = { -280, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -268, 20 }, Yaw = 60 },
				},
			},
			{
				Name = "Three ways",
				Paths = 3,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 124 },
							{ -340, 124 },
							{ -340, 164 },
							{ -214, 164 },
							{ -214, 204 },
							{ -340, 204 },
							{ -340, 252 },
							{ -150, 252 },
							{ -150, 358 },
							{ -340, 358 },
							{ -340, 398 },
							{ -150, 398 },
							{ -150, 438 },
							{ -340, 438 },
							{ -340, 478 },
							{ -150, 478 },
							{ -150, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ -178, 230 },
							{ -122, 230 },
							{ -122, 274 },
							{ -178, 274 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 192 },
							{ -26, 272 },
							{ -14, 272 },
							{ -14, 192 },
						},
					},
					{ Kind = "Flat", At = { -20, 192 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 272 }, Radius = 6 },
					{
						Kind = "Roof",
						Area = {
							{ -36, 56 },
							{ -36, 90 },
							{ -4, 90 },
							{ -4, 56 },
						},
						Clearance = 18,
						Thickness = 6,
					},
					{
						Kind = "Roof",
						Area = {
							{ -36, 126 },
							{ -36, 226 },
							{ -4, 226 },
							{ -4, 126 },
						},
						Clearance = 18,
						Thickness = 6,
					},
					{
						Kind = "Flat",
						Area = {
							{ -26, 0 },
							{ -26, 272 },
							{ -14, 272 },
							{ -14, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -20, 278 },
							{ 88, 278 },
							{ 88, 266 },
							{ -20, 266 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 272 },
							{ 82, 312 },
							{ 94, 312 },
							{ 94, 272 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 306 },
							{ -88, 306 },
							{ -88, 318 },
							{ 88, 318 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 312 },
							{ -94, 352 },
							{ -82, 352 },
							{ -82, 312 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 358 },
							{ 88, 358 },
							{ 88, 346 },
							{ -88, 346 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 352 },
							{ 82, 392 },
							{ 94, 392 },
							{ 94, 352 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 386 },
							{ -88, 386 },
							{ -88, 398 },
							{ 88, 398 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -94, 392 },
							{ -94, 432 },
							{ -82, 432 },
							{ -82, 392 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 438 },
							{ 88, 438 },
							{ 88, 426 },
							{ -88, 426 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 82, 432 },
							{ 82, 472 },
							{ 94, 472 },
							{ 94, 432 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 88, 466 },
							{ -88, 466 },
							{ -88, 478 },
							{ 88, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -88, 466 },
							{ -104, 466 },
							{ -104, 478 },
							{ -88, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -110, 472 },
							{ -110, 608 },
							{ -98, 608 },
							{ -98, 472 },
						},
					},
					{ Kind = "Flat", At = { -20, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -20, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 88, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { -88, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { -104, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { -104, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ -114, 540 },
							{ -94, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 124 },
							{ 222, 124 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 130 },
							{ 340, 130 },
							{ 340, 118 },
							{ 216, 118 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 124 },
							{ 334, 164 },
							{ 346, 164 },
							{ 346, 124 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 158 },
							{ 216, 158 },
							{ 216, 170 },
							{ 340, 170 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 164 },
							{ 210, 204 },
							{ 222, 204 },
							{ 222, 164 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 210 },
							{ 340, 210 },
							{ 340, 198 },
							{ 216, 198 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 204 },
							{ 334, 252 },
							{ 346, 252 },
							{ 346, 204 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 252 },
							{ 334, 320 },
							{ 346, 320 },
							{ 346, 252 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 314 },
							{ 216, 314 },
							{ 216, 326 },
							{ 340, 326 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 320 },
							{ 210, 360 },
							{ 222, 360 },
							{ 222, 320 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 366 },
							{ 340, 366 },
							{ 340, 354 },
							{ 216, 354 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 360 },
							{ 334, 400 },
							{ 346, 400 },
							{ 346, 360 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 394 },
							{ 216, 394 },
							{ 216, 406 },
							{ 340, 406 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 400 },
							{ 210, 440 },
							{ 222, 440 },
							{ 222, 400 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 446 },
							{ 340, 446 },
							{ 340, 434 },
							{ 216, 434 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 440 },
							{ 334, 480 },
							{ 346, 480 },
							{ 346, 440 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 474 },
							{ 216, 474 },
							{ 216, 486 },
							{ 340, 486 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 474 },
							{ 192, 474 },
							{ 192, 486 },
							{ 216, 486 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 186, 480 },
							{ 186, 608 },
							{ 198, 608 },
							{ 198, 480 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 124 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 124 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 164 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 164 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 204 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 204 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 252 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 320 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 320 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 360 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 360 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 400 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 400 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 440 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 440 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 480 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 480 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 480 }, Radius = 6 },
					{ Kind = "Flat", At = { 192, 608 }, Radius = 6 },
					{
						Kind = "Channel",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { -164, 244 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { -134, 266 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ -150, 238 },
							{ -150, 350 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ -114, 540 },
							{ -94, 540 },
						},
						Width = 12,
					},
					{
						Type = "Undertow",
						Path = {
							{ 180, 540 },
							{ 200, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { -170, 242 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { -132, 256 }, Yaw = 0 },
					{ Kind = "Crate", At = { -164, 262 }, Yaw = 30 },
					{ Kind = "Timber", At = { -157, 244 }, Yaw = 40 },
					{ Kind = "Timber", At = { -127, 266 }, Yaw = 40 },
					{ Kind = "Chain", At = { -141, 268 } },
					{ Kind = "Crate", At = { -140, 232 }, Yaw = 30 },
					{ Kind = "Chain", At = { -160, 234 } },
					{ Kind = "Weed", At = { -92, 548 } },
					{ Kind = "Weed", At = { 202, 548 } },
					{
						Kind = "Timber",
						Path = {
							{ -314, 12 },
							{ -286, 12 },
						},
						Count = 3,
					},
					{ Kind = "WreckRibs", At = { 300, 12 }, Scale = 1.1, Yaw = 90 },
				},
			},
			{
				Name = "Scour round",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -340, 0 },
							{ -340, 84 },
							{ -214, 84 },
							{ -214, 124 },
							{ -340, 124 },
							{ -340, 164 },
							{ -214, 164 },
							{ -214, 204 },
							{ -340, 204 },
							{ -340, 252 },
							{ -340, 318 },
							{ -214, 318 },
							{ -214, 358 },
							{ -340, 358 },
							{ -340, 398 },
							{ -214, 398 },
							{ -214, 438 },
							{ -340, 438 },
							{ -340, 478 },
							{ -214, 478 },
							{ -190, 478 },
							{ -190, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 0 },
							{ 334, 84 },
							{ 346, 84 },
							{ 346, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 78 },
							{ 216, 78 },
							{ 216, 90 },
							{ 340, 90 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 84 },
							{ 210, 124 },
							{ 222, 124 },
							{ 222, 84 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 130 },
							{ 340, 130 },
							{ 340, 118 },
							{ 216, 118 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 124 },
							{ 334, 164 },
							{ 346, 164 },
							{ 346, 124 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 158 },
							{ 216, 158 },
							{ 216, 170 },
							{ 340, 170 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 210, 164 },
							{ 210, 204 },
							{ 222, 204 },
							{ 222, 164 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 216, 210 },
							{ 340, 210 },
							{ 340, 198 },
							{ 216, 198 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 204 },
							{ 334, 252 },
							{ 346, 252 },
							{ 346, 204 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 246 },
							{ 152, 246 },
							{ 152, 258 },
							{ 340, 258 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 146, 252 },
							{ 146, 360 },
							{ 158, 360 },
							{ 158, 252 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 152, 366 },
							{ 340, 366 },
							{ 340, 354 },
							{ 152, 354 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 360 },
							{ 334, 400 },
							{ 346, 400 },
							{ 346, 360 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 394 },
							{ 152, 394 },
							{ 152, 406 },
							{ 340, 406 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 146, 400 },
							{ 146, 440 },
							{ 158, 440 },
							{ 158, 400 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 152, 446 },
							{ 340, 446 },
							{ 340, 434 },
							{ 152, 434 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 334, 440 },
							{ 334, 480 },
							{ 346, 480 },
							{ 346, 440 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 340, 474 },
							{ 152, 474 },
							{ 152, 486 },
							{ 340, 486 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 146, 480 },
							{ 146, 608 },
							{ 158, 608 },
							{ 158, 480 },
						},
					},
					{ Kind = "Flat", At = { 340, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 84 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 124 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 124 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 164 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 164 }, Radius = 6 },
					{ Kind = "Flat", At = { 216, 204 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 204 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 252 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 252 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 360 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 360 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 400 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 400 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 440 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 440 }, Radius = 6 },
					{ Kind = "Flat", At = { 340, 480 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 480 }, Radius = 6 },
					{ Kind = "Flat", At = { 152, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 122, 230 },
							{ 178, 230 },
							{ 178, 274 },
							{ 122, 274 },
						},
					},
					{
						Kind = "Channel",
						Path = {
							{ 140, 540 },
							{ 160, 540 },
						},
						Depth = 1.8,
						Width = 12,
						Rough = 0,
						Material = "Mud",
						Over = true,
					},
				},
				Hazards = {
					{ Type = "Pit", At = { 164, 244 }, Radius = 4, Covered = true },
					{ Type = "Pit", At = { 134, 266 }, Radius = 4, Covered = false },
					{
						Type = "Roller",
						Path = {
							{ 150, 238 },
							{ 150, 350 },
						},
					},
					{
						Type = "Undertow",
						Path = {
							{ 140, 540 },
							{ 160, 540 },
						},
						Width = 12,
					},
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 170, 242 }, Scale = 1, Yaw = 90 },
					{ Kind = "Chain", At = { 132, 256 }, Yaw = 0 },
					{ Kind = "Crate", At = { 164, 262 }, Yaw = 30 },
					{ Kind = "Timber", At = { 171, 244 }, Yaw = 40 },
					{ Kind = "Timber", At = { 141, 266 }, Yaw = 40 },
					{ Kind = "Chain", At = { 127, 268 } },
					{ Kind = "Crate", At = { 160, 232 }, Yaw = 30 },
					{ Kind = "Chain", At = { 140, 234 } },
					{ Kind = "Weed", At = { 162, 548 } },
					{ Kind = "Crate", At = { -300, 12 }, Yaw = 10 },
					{ Kind = "Crate", At = { -288, 20 }, Yaw = 60 },
					{ Kind = "Anchor", At = { 300, 14 }, Yaw = 20 },
					{
						Kind = "Chain",
						Path = {
							{ 314, 8 },
							{ 330, 16 },
						},
						Count = 2,
					},
				},
			},
		},
		Slots = {
			{
				Name = "The port hold",
				At = { -150, 72 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Cargo hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 104, 30 },
									{ 52, 30 },
									{ 52, 42 },
									{ 104, 42 },
								},
							},
							{ Kind = "Flat", At = { 104, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 30 },
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 30 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 8, 30 },
									{ 46, 30 },
									{ 46, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 58, 42 },
									{ 58, 30 },
									{ 96, 30 },
									{ 96, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 96, 42 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Wall",
								Area = {
									{ 46, 30 },
									{ 58, 30 },
									{ 58, 42 },
									{ 46, 42 },
								},
								Height = 20,
								Over = true,
							},
						},
						Loot = {
							{ At = { 12, 36 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 6,
							},
							{
								Kind = "Timber",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
					{
						Name = "Flooded hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 104, 30 },
									{ 52, 30 },
									{ 52, 42 },
									{ 104, 42 },
								},
							},
							{ Kind = "Flat", At = { 104, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 12, 36 },
								Radius = 24,
								Depth = 3,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 12, 36 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Chain",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "The bell hold",
				At = { 46, 72 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Ship's bell",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 0, 42 },
									{ 92, 42 },
									{ 92, 30 },
									{ 0, 30 },
								},
							},
							{ Kind = "Flat", At = { 0, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 86, 36 },
									{ 86, 56 },
									{ 98, 56 },
									{ 98, 36 },
								},
							},
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 56 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 98, 36 },
									{ 98, 16 },
									{ 86, 16 },
									{ 86, 36 },
								},
							},
							{ Kind = "Flat", At = { 92, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 92, 16 }, Radius = 6 },
						},
						Loot = {
							{ At = { 92, 58 }, Radius = 3, Weight = 1 },
							{ At = { 92, 14 }, Radius = 3, Weight = 1 },
							{ At = { 92, 36 }, Radius = 4, Weight = 5 },
						},
						Hazards = {
							{ Type = "Pit", At = { 92, 36 }, Radius = 4, Covered = true },
						},
						Decor = {
							{ Kind = "Chain", At = { 100, 44 } },
							{ Kind = "Crate", At = { 84, 28 } },
						},
					},
					{
						Name = "Lower hold",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 0, 42 },
									{ 52, 42 },
									{ 52, 30 },
									{ 0, 30 },
								},
							},
							{ Kind = "Flat", At = { 0, 36 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 30 },
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 30 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 8, 30 },
									{ 46, 30 },
									{ 46, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 58, 42 },
									{ 58, 30 },
									{ 96, 30 },
									{ 96, 42 },
								},
							},
							{
								Kind = "Flat",
								Area = {
									{ 8, 42 },
									{ 96, 42 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Wall",
								Area = {
									{ 46, 30 },
									{ 58, 30 },
									{ 58, 42 },
									{ 46, 42 },
								},
								Height = 20,
								Over = true,
							},
						},
						Loot = {
							{ At = { 92, 36 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 6,
							},
							{
								Kind = "Timber",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "Cargo west",
				At = { -330, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Spilled cargo",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
					{
						Name = "Sunken stores",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 3,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Chain",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 3,
							},
						},
					},
				},
			},
			{
				Name = "The scour hole",
				At = { -52, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Scour hole",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 4,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 4 },
						},
						Decor = {
							{
								Kind = "Kelp",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 4,
							},
						},
					},
					{
						Name = "Cargo heap",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
				},
			},
			{
				Name = "Cargo east",
				At = { 226, 504 },
				Size = { 104, 72 },
				Rooms = {
					{
						Name = "Wrecked stores",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Mound",
								At = { 31, 29 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 73, 36 },
								Radius = 7,
								Height = 5,
								Rock = true,
								Over = true,
							},
							{
								Kind = "Mound",
								At = { 47, 50 },
								Radius = 7,
								Height = 4,
								Rock = true,
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 2 },
						},
						Decor = {
							{
								Kind = "Crate",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 5,
							},
						},
					},
					{
						Name = "Flooded scour",
						Primitives = {
							{
								Kind = "Flat",
								Area = {
									{ 58, 72 },
									{ 58, 36 },
									{ 46, 36 },
									{ 46, 72 },
								},
							},
							{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
							{ Kind = "Flat", At = { 52, 36 }, Radius = 6 },
							{
								Kind = "Flat",
								Area = {
									{ 8, 8 },
									{ 96, 8 },
									{ 96, 64 },
									{ 8, 64 },
								},
							},
							{
								Kind = "Hollow",
								At = { 52, 12 },
								Radius = 24,
								Depth = 4,
								Rough = 3,
								Material = "Mud",
								Over = true,
							},
						},
						Loot = {
							{ At = { 52, 12 }, Radius = 4, Weight = 3 },
						},
						Decor = {
							{
								Kind = "Kelp",
								Area = {
									{ 14, 14 },
									{ 90, 14 },
									{ 90, 58 },
									{ 14, 58 },
								},
								Count = 4,
							},
						},
					},
				},
			},
		},
	},
}

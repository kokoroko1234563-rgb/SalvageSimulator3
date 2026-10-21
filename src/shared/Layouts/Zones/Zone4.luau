-- Zone 4, The Outer Shore: drawn with the layout kit from tools/kit/plans/zone4.py (edit
-- the plan and re-run it, not this file). Its card: docs/design/cards/zone4.md.
return {
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
				{ 360, 20 },
				{ -360, 20 },
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
		{
			Kind = "Flat",
			Area = {
				{ 232, 46 },
				{ 280, 46 },
				{ 280, 94 },
				{ 232, 94 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 250, 12 },
				{ 250, 52 },
				{ 262, 52 },
				{ 262, 12 },
			},
		},
		{ Kind = "Flat", At = { 256, 12 }, Radius = 6 },
		{ Kind = "Flat", At = { 256, 52 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ -280, 190 },
				{ -184, 190 },
				{ -184, 300 },
				{ -280, 300 },
			},
		},
		{
			Kind = "Wall",
			Path = {
				{ -288, 252 },
				{ -228, 252 },
			},
			Width = 28,
			Height = 16,
			Over = true,
		},
		{
			Kind = "Wall",
			Area = {
				{ -242, 252 },
				{ -214, 252 },
				{ -214, 268 },
				{ -242, 268 },
			},
			Height = 16,
			Over = true,
		},
		{
			Kind = "Flat",
			Area = {
				{ -48, 214 },
				{ 48, 214 },
				{ 48, 254 },
				{ -48, 254 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -10, 256 },
				{ -10, 344 },
				{ 10, 344 },
				{ 10, 256 },
			},
		},
		{ Kind = "Flat", At = { 0, 256 }, Radius = 10 },
		{ Kind = "Flat", At = { 0, 344 }, Radius = 10 },
		{
			Kind = "Roof",
			Area = {
				{ -20, 266 },
				{ -20, 334 },
				{ 20, 334 },
				{ 20, 266 },
			},
			Clearance = 14,
			Thickness = 6,
		},
		{
			Kind = "Flat",
			Area = {
				{ -48, 346 },
				{ 48, 346 },
				{ 48, 386 },
				{ -48, 386 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 176, 346 },
				{ 176, 320 },
				{ 280, 320 },
				{ 280, 346 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 176, 358 },
				{ 176, 346 },
				{ 226, 346 },
				{ 226, 358 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 238, 358 },
				{ 238, 346 },
				{ 258, 346 },
				{ 258, 358 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 270, 358 },
				{ 270, 346 },
				{ 280, 346 },
				{ 280, 358 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 176, 394 },
				{ 176, 358 },
				{ 280, 358 },
				{ 280, 394 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 176, 406 },
				{ 176, 394 },
				{ 226, 394 },
				{ 226, 406 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 238, 406 },
				{ 238, 394 },
				{ 258, 394 },
				{ 258, 406 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 270, 406 },
				{ 270, 394 },
				{ 280, 394 },
				{ 280, 406 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 176, 406 },
				{ 280, 406 },
				{ 280, 410 },
				{ 176, 410 },
			},
		},
		{
			Kind = "Wall",
			Area = {
				{ 226, 346 },
				{ 238, 346 },
				{ 238, 358 },
				{ 226, 358 },
			},
			Height = 16,
			Over = true,
		},
		{
			Kind = "Wall",
			Area = {
				{ 258, 346 },
				{ 270, 346 },
				{ 270, 358 },
				{ 258, 358 },
			},
			Height = 16,
			Over = true,
		},
		{
			Kind = "Wall",
			Area = {
				{ 226, 394 },
				{ 238, 394 },
				{ 238, 406 },
				{ 226, 406 },
			},
			Height = 16,
			Over = true,
		},
		{
			Kind = "Wall",
			Area = {
				{ 258, 394 },
				{ 270, 394 },
				{ 270, 406 },
				{ 258, 406 },
			},
			Height = 16,
			Over = true,
		},
		{
			Kind = "Flat",
			Area = {
				{ -294, 44 },
				{ -294, 20 },
				{ -306, 20 },
				{ -306, 44 },
			},
		},
		{ Kind = "Flat", At = { -300, 44 }, Radius = 6 },
		{ Kind = "Flat", At = { -300, 20 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ 304, 70 },
				{ 280, 70 },
				{ 280, 82 },
				{ 304, 82 },
			},
		},
		{ Kind = "Flat", At = { 304, 76 }, Radius = 6 },
		{ Kind = "Flat", At = { 280, 76 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ -238, 324 },
				{ -238, 300 },
				{ -250, 300 },
				{ -250, 324 },
			},
		},
		{ Kind = "Flat", At = { -244, 324 }, Radius = 6 },
		{ Kind = "Flat", At = { -244, 300 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ 304, 378 },
				{ 280, 378 },
				{ 280, 390 },
				{ 304, 390 },
			},
		},
		{ Kind = "Flat", At = { 304, 384 }, Radius = 6 },
		{ Kind = "Flat", At = { 280, 384 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ -306, 568 },
				{ -306, 592 },
				{ -294, 592 },
				{ -294, 568 },
			},
		},
		{ Kind = "Flat", At = { -300, 568 }, Radius = 6 },
		{ Kind = "Flat", At = { -300, 592 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ 242, 568 },
				{ 242, 592 },
				{ 254, 592 },
				{ 254, 568 },
			},
		},
		{ Kind = "Flat", At = { 248, 568 }, Radius = 6 },
		{ Kind = "Flat", At = { 248, 592 }, Radius = 6 },
	},
	Loot = {
		{ At = { 240, 84 }, Radius = 4, Weight = 1 },
		{ At = { -262, 284 }, Radius = 5, Weight = 2 },
		{ At = { -30, 366 }, Radius = 4, Weight = 3 },
		{ At = { 248, 380 }, Radius = 4, Weight = 2 },
	},
	Hazards = {
		{ Type = "Rockfall", At = { 0, 300 }, Radius = 14 },
	},
	Decor = {
		{
			Kind = "Kelp",
			Area = {
				{ 236, 50 },
				{ 252, 50 },
				{ 252, 90 },
				{ 236, 90 },
			},
			Count = 3,
		},
		{ Kind = "Starfish", At = { 242, 58 } },
		{ Kind = "WreckRibs", At = { -262, 218 }, Scale = 1.2, Yaw = 70 },
		{
			Kind = "Kelp",
			Area = {
				{ -274, 276 },
				{ -250, 276 },
				{ -250, 296 },
				{ -274, 296 },
			},
			Count = 3,
		},
		{
			Kind = "Timber",
			Area = {
				{ -216, 270 },
				{ -190, 270 },
				{ -190, 296 },
				{ -216, 296 },
			},
			Count = 3,
		},
		{ Kind = "Bones", At = { -30, 234 }, Scale = 1.5, Yaw = 0 },
		{
			Kind = "Chain",
			Path = {
				{ -8, 268 },
				{ -8, 332 },
			},
			Count = 2,
		},
		{
			Kind = "Barnacles",
			Area = {
				{ -30, 268 },
				{ -14, 268 },
				{ -14, 332 },
				{ -30, 332 },
			},
			Count = 4,
		},
		{ Kind = "Timber", At = { 30, 372 }, Scale = 1, Yaw = 40 },
		{ Kind = "WreckRibs", At = { 250, 330 }, Scale = 1.6, Yaw = 20 },
		{
			Kind = "Timber",
			Area = {
				{ 180, 326 },
				{ 226, 326 },
				{ 226, 406 },
				{ 180, 406 },
			},
			Count = 4,
		},
		{ Kind = "Crate", At = { 190, 400 } },
		{ Kind = "Anchor", At = { 270, 404 }, Yaw = 200 },
		{
			Kind = "Barnacles",
			Area = {
				{ 226, 344 },
				{ 270, 344 },
				{ 270, 404 },
				{ 226, 404 },
			},
			Count = 5,
		},
		{
			Kind = "Weed",
			Area = {
				{ -30, 150 },
				{ 30, 150 },
				{ 30, 196 },
				{ -30, 196 },
			},
			Count = 4,
		},
	},
	Name = "Outer Shore",
	Crossings = {
		{
			Name = "Rib doors",
			Paths = 2,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ 100, 0 },
						{ 100, 60 },
						{ 192, 60 },
						{ 192, 104 },
						{ 100, 104 },
						{ 100, 448 },
						{ 160, 448 },
						{ 160, 500 },
						{ 60, 500 },
						{ 60, 552 },
						{ 160, 552 },
						{ 160, 608 },
					},
					Width = 20,
				},
				{
					Kind = "Roof",
					Area = {
						{ 80, 276 },
						{ 80, 316 },
						{ 120, 316 },
						{ 120, 276 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Hollow",
					Area = {
						{ 60, 578 },
						{ 160, 578 },
						{ 160, 526 },
						{ 60, 526 },
					},
					Width = 16,
					Depth = 3,
					Over = true,
					Material = "Mud",
				},
				{
					Kind = "Flat",
					Area = {
						{ 100, 226 },
						{ 48, 226 },
						{ 48, 238 },
						{ 100, 238 },
					},
				},
				{ Kind = "Flat", At = { 100, 232 }, Radius = 6 },
				{ Kind = "Flat", At = { 48, 232 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 100, 386 },
						{ 176, 386 },
						{ 176, 374 },
						{ 100, 374 },
					},
				},
				{ Kind = "Flat", At = { 100, 380 }, Radius = 6 },
				{ Kind = "Flat", At = { 176, 380 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 100, 402 },
						{ 64, 402 },
						{ 64, 414 },
						{ 100, 414 },
					},
				},
				{ Kind = "Flat", At = { 100, 408 }, Radius = 6 },
				{ Kind = "Flat", At = { 64, 408 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -206, 0 },
						{ -206, 60 },
						{ -194, 60 },
						{ -194, 0 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -200, 66 },
						{ -100, 66 },
						{ -100, 54 },
						{ -200, 54 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -106, 60 },
						{ -106, 104 },
						{ -94, 104 },
						{ -94, 60 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -100, 98 },
						{ -200, 98 },
						{ -200, 110 },
						{ -100, 110 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -206, 104 },
						{ -206, 228 },
						{ -194, 228 },
						{ -194, 104 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -200, 234 },
						{ -140, 234 },
						{ -140, 222 },
						{ -200, 222 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -146, 228 },
						{ -146, 448 },
						{ -134, 448 },
						{ -134, 228 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -140, 454 },
						{ -60, 454 },
						{ -60, 442 },
						{ -140, 442 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -66, 448 },
						{ -66, 500 },
						{ -54, 500 },
						{ -54, 448 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -60, 494 },
						{ -180, 494 },
						{ -180, 506 },
						{ -60, 506 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -186, 500 },
						{ -186, 552 },
						{ -174, 552 },
						{ -174, 500 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -180, 558 },
						{ -60, 558 },
						{ -60, 546 },
						{ -180, 546 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -66, 552 },
						{ -66, 608 },
						{ -54, 608 },
						{ -54, 552 },
					},
				},
				{ Kind = "Flat", At = { -200, 0 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 60 }, Radius = 6 },
				{ Kind = "Flat", At = { -100, 60 }, Radius = 6 },
				{ Kind = "Flat", At = { -100, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 228 }, Radius = 6 },
				{ Kind = "Flat", At = { -140, 228 }, Radius = 6 },
				{ Kind = "Flat", At = { -140, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { -180, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { -180, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 608 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -180, 114 },
						{ -120, 114 },
						{ -120, 94 },
						{ -180, 94 },
					},
				},
				{ Kind = "Flat", At = { -180, 104 }, Radius = 10 },
				{ Kind = "Flat", At = { -120, 104 }, Radius = 10 },
				{
					Kind = "Roof",
					Area = {
						{ -156, 290 },
						{ -156, 330 },
						{ -124, 330 },
						{ -124, 290 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Flat",
					Area = {
						{ -146, 352 },
						{ -146, 420 },
						{ -134, 420 },
						{ -134, 352 },
					},
				},
				{ Kind = "Flat", At = { -140, 352 }, Radius = 6 },
				{ Kind = "Flat", At = { -140, 420 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ -140, 366 },
						{ -140, 404 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ -160, 552 },
						{ -80, 552 },
					},
					Depth = 2,
					Width = 12,
					Rough = 2,
					Material = "Mud",
					Over = true,
				},
			},
			Loot = {
				{ At = { 64, 408 }, Radius = 5, Weight = 2 },
			},
			Hazards = {
				{ Type = "Rockfall", At = { 100, 296 }, Radius = 12 },
				{
					Type = "Undertow",
					Path = {
						{ 60, 552 },
						{ 160, 552 },
					},
					Width = 20,
				},
				{ Type = "Pit", At = { 64, 408 }, Radius = 4, Covered = true },
				{ Type = "Pit", At = { -150, 104 }, Radius = 4, Covered = false },
				{ Type = "Rockfall", At = { -140, 310 }, Radius = 12 },
				{
					Type = "Undertow",
					Path = {
						{ -160, 552 },
						{ -80, 552 },
					},
					Width = 12,
				},
			},
			Decor = {
				{ Kind = "WreckRibs", At = { -20, 8 }, Scale = 1.1, Yaw = 90 },
				{ Kind = "Timber", At = { -4, 6 }, Yaw = 20 },
			},
		},
		{
			Name = "The long way round",
			Paths = 1,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ -200, 0 },
						{ -200, 60 },
						{ -100, 60 },
						{ -100, 104 },
						{ -200, 104 },
						{ -200, 148 },
						{ 0, 148 },
						{ 0, 448 },
						{ 120, 448 },
						{ 120, 500 },
						{ 40, 500 },
						{ 40, 552 },
						{ 120, 552 },
						{ 120, 608 },
					},
					Width = 20,
				},
				{
					Kind = "Hollow",
					Area = {
						{ 40, 578 },
						{ 120, 578 },
						{ 120, 526 },
						{ 40, 526 },
					},
					Width = 16,
					Depth = 3,
					Over = true,
					Material = "Mud",
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 104 },
						{ -158, 148 },
						{ -146, 148 },
						{ -146, 104 },
					},
				},
				{ Kind = "Flat", At = { -152, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 148 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ -150, 120 },
						{ -150, 132 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ 54, 448 },
						{ 54, 500 },
						{ 66, 500 },
						{ 66, 448 },
					},
				},
				{ Kind = "Flat", At = { 60, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { 60, 500 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ 60, 464 },
						{ 60, 484 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -206, 148 },
						{ -206, 192 },
						{ -194, 192 },
						{ -194, 148 },
					},
				},
				{ Kind = "Flat", At = { -200, 148 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 192 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 120, 454 },
						{ 228, 454 },
						{ 228, 442 },
						{ 120, 442 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 234, 448 },
						{ 234, 408 },
						{ 222, 408 },
						{ 222, 448 },
					},
				},
				{ Kind = "Flat", At = { 120, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { 228, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { 228, 408 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 458 },
						{ 192, 458 },
						{ 192, 438 },
						{ 152, 438 },
					},
				},
				{ Kind = "Flat", At = { 152, 448 }, Radius = 10 },
				{ Kind = "Flat", At = { 192, 448 }, Radius = 10 },
			},
			Hazards = {
				{
					Type = "Undertow",
					Path = {
						{ 40, 552 },
						{ 120, 552 },
					},
					Width = 20,
				},
				{ Type = "Pit", At = { 170, 448 }, Radius = 4, Covered = false },
				{ Type = "Pit", At = { -30, 366 }, Radius = 4, Covered = true },
			},
			Decor = {
				{ Kind = "Bones", At = { -160, 8 }, Scale = 1.3, Yaw = 0 },
				{ Kind = "Barnacles", At = { -140, 6 } },
			},
		},
		{
			Name = "Stack and Bend",
			Paths = 2,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ -200, 0 },
						{ -200, 60 },
						{ -100, 60 },
						{ -100, 104 },
						{ -200, 104 },
						{ -200, 228 },
						{ -140, 228 },
						{ -140, 448 },
						{ -60, 448 },
						{ -60, 500 },
						{ -180, 500 },
						{ -180, 552 },
						{ -60, 552 },
						{ -60, 608 },
					},
					Width = 20,
				},
				{
					Kind = "Roof",
					Area = {
						{ -160, 300 },
						{ -160, 340 },
						{ -120, 340 },
						{ -120, 300 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Hollow",
					Area = {
						{ -180, 578 },
						{ -60, 578 },
						{ -60, 526 },
						{ -180, 526 },
					},
					Width = 16,
					Depth = 3,
					Over = true,
					Material = "Mud",
				},
				{
					Kind = "Flat",
					Area = {
						{ -140, 234 },
						{ -48, 234 },
						{ -48, 222 },
						{ -140, 222 },
					},
				},
				{ Kind = "Flat", At = { -140, 228 }, Radius = 6 },
				{ Kind = "Flat", At = { -48, 228 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -140, 414 },
						{ -208, 414 },
						{ -208, 426 },
						{ -140, 426 },
					},
				},
				{ Kind = "Flat", At = { -140, 420 }, Radius = 6 },
				{ Kind = "Flat", At = { -208, 420 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 94, 0 },
						{ 94, 60 },
						{ 106, 60 },
						{ 106, 0 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 100, 66 },
						{ 196, 66 },
						{ 196, 54 },
						{ 100, 54 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 190, 60 },
						{ 190, 104 },
						{ 202, 104 },
						{ 202, 60 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 196, 98 },
						{ 100, 98 },
						{ 100, 110 },
						{ 196, 110 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 94, 104 },
						{ 94, 148 },
						{ 106, 148 },
						{ 106, 104 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 100, 154 },
						{ 196, 154 },
						{ 196, 142 },
						{ 100, 142 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 190, 148 },
						{ 190, 448 },
						{ 202, 448 },
						{ 202, 148 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 196, 442 },
						{ 152, 442 },
						{ 152, 454 },
						{ 196, 454 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 448 },
						{ 146, 500 },
						{ 158, 500 },
						{ 158, 448 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 152, 494 },
						{ 60, 494 },
						{ 60, 506 },
						{ 152, 506 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 54, 500 },
						{ 54, 552 },
						{ 66, 552 },
						{ 66, 500 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 60, 558 },
						{ 152, 558 },
						{ 152, 546 },
						{ 60, 546 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 552 },
						{ 146, 608 },
						{ 158, 608 },
						{ 158, 552 },
					},
				},
				{ Kind = "Flat", At = { 100, 0 }, Radius = 6 },
				{ Kind = "Flat", At = { 100, 60 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 60 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { 100, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { 100, 148 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 148 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { 60, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { 60, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 608 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 128, 158 },
						{ 168, 158 },
						{ 168, 138 },
						{ 128, 138 },
					},
				},
				{ Kind = "Flat", At = { 128, 148 }, Radius = 10 },
				{ Kind = "Flat", At = { 168, 148 }, Radius = 10 },
				{
					Kind = "Roof",
					Area = {
						{ 180, 190 },
						{ 180, 230 },
						{ 212, 230 },
						{ 212, 190 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Flat",
					Area = {
						{ 190, 264 },
						{ 190, 320 },
						{ 202, 320 },
						{ 202, 264 },
					},
				},
				{ Kind = "Flat", At = { 196, 264 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 320 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ 196, 278 },
						{ 196, 306 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ 80, 552 },
						{ 130, 552 },
					},
					Depth = 2,
					Width = 12,
					Rough = 2,
					Material = "Mud",
					Over = true,
				},
			},
			Loot = {
				{ At = { -210, 420 }, Radius = 5, Weight = 2 },
			},
			Hazards = {
				{ Type = "Rockfall", At = { -140, 320 }, Radius = 12 },
				{
					Type = "Undertow",
					Path = {
						{ -180, 552 },
						{ -60, 552 },
					},
					Width = 20,
				},
				{ Type = "Pit", At = { -210, 420 }, Radius = 4, Covered = true },
				{ Type = "Pit", At = { 150, 148 }, Radius = 4, Covered = false },
				{ Type = "Rockfall", At = { 196, 210 }, Radius = 12 },
				{
					Type = "Undertow",
					Path = {
						{ 80, 552 },
						{ 130, 552 },
					},
					Width = 12,
				},
			},
			Decor = {
				{ Kind = "Anchor", At = { -150, 8 }, Yaw = 40 },
				{
					Kind = "Chain",
					Path = {
						{ -140, 8 },
						{ -110, 8 },
					},
					Count = 2,
				},
			},
		},
		{
			Name = "Three ways",
			Paths = 3,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ -88, 0 },
						{ -88, 60 },
						{ 20, 60 },
						{ 20, 104 },
						{ -88, 104 },
						{ -88, 448 },
						{ 0, 448 },
						{ 0, 500 },
						{ -88, 500 },
						{ -88, 552 },
						{ 0, 552 },
						{ 0, 608 },
					},
					Width = 20,
				},
				{
					Kind = "Roof",
					Area = {
						{ -108, 300 },
						{ -108, 340 },
						{ -68, 340 },
						{ -68, 300 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Hollow",
					Area = {
						{ -88, 578 },
						{ 0, 578 },
						{ 0, 526 },
						{ -88, 526 },
					},
					Width = 16,
					Depth = 3,
					Over = true,
					Material = "Mud",
				},
				{
					Kind = "Flat",
					Area = {
						{ -88, 238 },
						{ -48, 238 },
						{ -48, 226 },
						{ -88, 226 },
					},
				},
				{ Kind = "Flat", At = { -88, 232 }, Radius = 6 },
				{ Kind = "Flat", At = { -48, 232 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 94, 0 },
						{ 94, 60 },
						{ 106, 60 },
						{ 106, 0 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 100, 66 },
						{ 196, 66 },
						{ 196, 54 },
						{ 100, 54 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 190, 60 },
						{ 190, 104 },
						{ 202, 104 },
						{ 202, 60 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 196, 98 },
						{ 100, 98 },
						{ 100, 110 },
						{ 196, 110 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 94, 104 },
						{ 94, 148 },
						{ 106, 148 },
						{ 106, 104 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 100, 154 },
						{ 196, 154 },
						{ 196, 142 },
						{ 100, 142 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 190, 148 },
						{ 190, 448 },
						{ 202, 448 },
						{ 202, 148 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 196, 442 },
						{ 152, 442 },
						{ 152, 454 },
						{ 196, 454 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 448 },
						{ 146, 500 },
						{ 158, 500 },
						{ 158, 448 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 152, 494 },
						{ 60, 494 },
						{ 60, 506 },
						{ 152, 506 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 54, 500 },
						{ 54, 552 },
						{ 66, 552 },
						{ 66, 500 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 60, 558 },
						{ 152, 558 },
						{ 152, 546 },
						{ 60, 546 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 552 },
						{ 146, 608 },
						{ 158, 608 },
						{ 158, 552 },
					},
				},
				{ Kind = "Flat", At = { 100, 0 }, Radius = 6 },
				{ Kind = "Flat", At = { 100, 60 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 60 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { 100, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { 100, 148 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 148 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { 60, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { 60, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 608 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 128, 158 },
						{ 168, 158 },
						{ 168, 138 },
						{ 128, 138 },
					},
				},
				{ Kind = "Flat", At = { 128, 148 }, Radius = 10 },
				{ Kind = "Flat", At = { 168, 148 }, Radius = 10 },
				{
					Kind = "Roof",
					Area = {
						{ 180, 190 },
						{ 180, 230 },
						{ 212, 230 },
						{ 212, 190 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Flat",
					Area = {
						{ 190, 264 },
						{ 190, 320 },
						{ 202, 320 },
						{ 202, 264 },
					},
				},
				{ Kind = "Flat", At = { 196, 264 }, Radius = 6 },
				{ Kind = "Flat", At = { 196, 320 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ 196, 278 },
						{ 196, 306 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ 80, 552 },
						{ 130, 552 },
					},
					Depth = 2,
					Width = 12,
					Rough = 2,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -206, 0 },
						{ -206, 136 },
						{ -194, 136 },
						{ -194, 0 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -200, 130 },
						{ -336, 130 },
						{ -336, 142 },
						{ -200, 142 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -342, 136 },
						{ -342, 448 },
						{ -330, 448 },
						{ -330, 136 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -336, 454 },
						{ -192, 454 },
						{ -192, 442 },
						{ -336, 442 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -198, 448 },
						{ -198, 500 },
						{ -186, 500 },
						{ -186, 448 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -192, 506 },
						{ -128, 506 },
						{ -128, 494 },
						{ -192, 494 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -134, 500 },
						{ -134, 552 },
						{ -122, 552 },
						{ -122, 500 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -128, 546 },
						{ -192, 546 },
						{ -192, 558 },
						{ -128, 558 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -198, 552 },
						{ -198, 608 },
						{ -186, 608 },
						{ -186, 552 },
					},
				},
				{ Kind = "Flat", At = { -200, 0 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 136 }, Radius = 6 },
				{ Kind = "Flat", At = { -336, 136 }, Radius = 6 },
				{ Kind = "Flat", At = { -336, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { -192, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { -192, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { -128, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { -128, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { -192, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { -192, 608 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -206, 136 },
						{ -206, 192 },
						{ -194, 192 },
						{ -194, 136 },
					},
				},
				{ Kind = "Flat", At = { -200, 136 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 192 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -352, 188 },
						{ -314, 188 },
						{ -314, 252 },
						{ -352, 252 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -352, 384 },
						{ -314, 384 },
						{ -314, 440 },
						{ -352, 440 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -342, 272 },
						{ -342, 368 },
						{ -330, 368 },
						{ -330, 272 },
					},
				},
				{ Kind = "Flat", At = { -336, 272 }, Radius = 6 },
				{ Kind = "Flat", At = { -336, 368 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ -336, 286 },
						{ -336, 354 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Roof",
					Area = {
						{ -300, 152 },
						{ -240, 152 },
						{ -240, 120 },
						{ -300, 120 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Flat",
					Area = {
						{ -288, 458 },
						{ -232, 458 },
						{ -232, 438 },
						{ -288, 438 },
					},
				},
				{ Kind = "Flat", At = { -288, 448 }, Radius = 10 },
				{ Kind = "Flat", At = { -232, 448 }, Radius = 10 },
				{
					Kind = "Channel",
					Path = {
						{ -184, 552 },
						{ -136, 552 },
					},
					Depth = 2,
					Width = 12,
					Rough = 2,
					Material = "Mud",
					Over = true,
				},
			},
			Loot = {
				{ At = { -340, 220 }, Radius = 4, Weight = 2 },
				{ At = { -340, 412 }, Radius = 4, Weight = 3 },
			},
			Hazards = {
				{ Type = "Rockfall", At = { -88, 320 }, Radius = 12 },
				{
					Type = "Undertow",
					Path = {
						{ -88, 552 },
						{ 0, 552 },
					},
					Width = 20,
				},
				{ Type = "Pit", At = { 150, 148 }, Radius = 4, Covered = false },
				{ Type = "Rockfall", At = { 196, 210 }, Radius = 12 },
				{
					Type = "Undertow",
					Path = {
						{ 80, 552 },
						{ 130, 552 },
					},
					Width = 12,
				},
				{ Type = "Pit", At = { -340, 412 }, Radius = 4, Covered = true },
				{ Type = "Rockfall", At = { -270, 136 }, Radius = 12 },
				{ Type = "Pit", At = { -260, 448 }, Radius = 4, Covered = false },
				{
					Type = "Undertow",
					Path = {
						{ -184, 552 },
						{ -136, 552 },
					},
					Width = 12,
				},
			},
			Decor = {
				{ Kind = "Timber", At = { -60, 8 }, Yaw = 70 },
				{ Kind = "Crate", At = { -44, 8 } },
				{
					Kind = "Kelp",
					Area = {
						{ -348, 192 },
						{ -318, 192 },
						{ -318, 248 },
						{ -348, 248 },
					},
					Count = 3,
				},
				{
					Kind = "Barnacles",
					Area = {
						{ -348, 388 },
						{ -318, 388 },
						{ -318, 436 },
						{ -348, 436 },
					},
					Count = 3,
				},
			},
		},
		{
			Name = "Back door",
			Paths = 2,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ 100, 0 },
						{ 100, 60 },
						{ 196, 60 },
						{ 196, 104 },
						{ 100, 104 },
						{ 100, 148 },
						{ 196, 148 },
						{ 196, 448 },
						{ 110, 448 },
						{ 110, 500 },
						{ 30, 500 },
						{ 30, 552 },
						{ 110, 552 },
						{ 110, 608 },
					},
					Width = 20,
				},
				{
					Kind = "Roof",
					Area = {
						{ 176, 190 },
						{ 176, 230 },
						{ 216, 230 },
						{ 216, 190 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Hollow",
					Area = {
						{ 30, 578 },
						{ 110, 578 },
						{ 110, 526 },
						{ 30, 526 },
					},
					Width = 16,
					Depth = 3,
					Over = true,
					Material = "Mud",
				},
				{
					Kind = "Flat",
					Area = {
						{ 196, 374 },
						{ 152, 374 },
						{ 152, 386 },
						{ 196, 386 },
					},
				},
				{ Kind = "Flat", At = { 196, 380 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 380 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -206, 0 },
						{ -206, 60 },
						{ -194, 60 },
						{ -194, 0 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -200, 66 },
						{ -100, 66 },
						{ -100, 54 },
						{ -200, 54 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -106, 60 },
						{ -106, 104 },
						{ -94, 104 },
						{ -94, 60 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -100, 98 },
						{ -200, 98 },
						{ -200, 110 },
						{ -100, 110 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -206, 104 },
						{ -206, 228 },
						{ -194, 228 },
						{ -194, 104 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -200, 234 },
						{ -140, 234 },
						{ -140, 222 },
						{ -200, 222 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -146, 228 },
						{ -146, 448 },
						{ -134, 448 },
						{ -134, 228 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -140, 454 },
						{ -60, 454 },
						{ -60, 442 },
						{ -140, 442 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -66, 448 },
						{ -66, 500 },
						{ -54, 500 },
						{ -54, 448 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -60, 494 },
						{ -180, 494 },
						{ -180, 506 },
						{ -60, 506 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -186, 500 },
						{ -186, 552 },
						{ -174, 552 },
						{ -174, 500 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -180, 558 },
						{ -60, 558 },
						{ -60, 546 },
						{ -180, 546 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -66, 552 },
						{ -66, 608 },
						{ -54, 608 },
						{ -54, 552 },
					},
				},
				{ Kind = "Flat", At = { -200, 0 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 60 }, Radius = 6 },
				{ Kind = "Flat", At = { -100, 60 }, Radius = 6 },
				{ Kind = "Flat", At = { -100, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 104 }, Radius = 6 },
				{ Kind = "Flat", At = { -200, 228 }, Radius = 6 },
				{ Kind = "Flat", At = { -140, 228 }, Radius = 6 },
				{ Kind = "Flat", At = { -140, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 448 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { -180, 500 }, Radius = 6 },
				{ Kind = "Flat", At = { -180, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 552 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 608 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -140, 234 },
						{ -48, 234 },
						{ -48, 222 },
						{ -140, 222 },
					},
				},
				{ Kind = "Flat", At = { -140, 228 }, Radius = 6 },
				{ Kind = "Flat", At = { -48, 228 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -180, 114 },
						{ -120, 114 },
						{ -120, 94 },
						{ -180, 94 },
					},
				},
				{ Kind = "Flat", At = { -180, 104 }, Radius = 10 },
				{ Kind = "Flat", At = { -120, 104 }, Radius = 10 },
				{
					Kind = "Roof",
					Area = {
						{ -156, 290 },
						{ -156, 330 },
						{ -124, 330 },
						{ -124, 290 },
					},
					Clearance = 14,
					Thickness = 6,
				},
				{
					Kind = "Flat",
					Area = {
						{ -146, 352 },
						{ -146, 420 },
						{ -134, 420 },
						{ -134, 352 },
					},
				},
				{ Kind = "Flat", At = { -140, 352 }, Radius = 6 },
				{ Kind = "Flat", At = { -140, 420 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ -140, 366 },
						{ -140, 404 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ -160, 552 },
						{ -80, 552 },
					},
					Depth = 2,
					Width = 12,
					Rough = 2,
					Material = "Mud",
					Over = true,
				},
			},
			Loot = {
				{ At = { 150, 380 }, Radius = 5, Weight = 2 },
			},
			Hazards = {
				{ Type = "Rockfall", At = { 196, 210 }, Radius = 12 },
				{
					Type = "Undertow",
					Path = {
						{ 30, 552 },
						{ 110, 552 },
					},
					Width = 20,
				},
				{ Type = "Pit", At = { 150, 380 }, Radius = 4, Covered = true },
				{ Type = "Pit", At = { -150, 104 }, Radius = 4, Covered = false },
				{ Type = "Rockfall", At = { -140, 310 }, Radius = 12 },
				{
					Type = "Undertow",
					Path = {
						{ -160, 552 },
						{ -80, 552 },
					},
					Width = 12,
				},
			},
			Decor = {
				{ Kind = "DeadCoral", At = { 40, 8 }, Scale = 1.3 },
				{ Kind = "Driftwood", At = { 60, 8 } },
			},
		},
	},
	Slots = {
		{
			Name = "Barnacle caves",
			At = { -352, 36 },
			Size = { 104, 72 },
			Rooms = {
				{
					Name = "Cave under the rib",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 46, 0 },
								{ 46, 60 },
								{ 58, 60 },
								{ 58, 0 },
							},
						},
						{ Kind = "Flat", At = { 52, 0 }, Radius = 6 },
						{ Kind = "Flat", At = { 52, 60 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 52, 26 },
								{ 96, 26 },
								{ 96, 14 },
								{ 52, 14 },
							},
						},
						{ Kind = "Flat", At = { 52, 20 }, Radius = 6 },
						{ Kind = "Flat", At = { 96, 20 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 52, 34 },
								{ 8, 34 },
								{ 8, 46 },
								{ 52, 46 },
							},
						},
						{ Kind = "Flat", At = { 52, 40 }, Radius = 6 },
						{ Kind = "Flat", At = { 8, 40 }, Radius = 6 },
					},
					Loot = {
						{ At = { 94, 20 }, Radius = 3, Weight = 1 },
						{ At = { 10, 42 }, Radius = 3, Weight = 1 },
						{ At = { 52, 60 }, Radius = 4, Weight = 3 },
					},
					Hazards = {
						{ Type = "Pit", At = { 52, 60 }, Radius = 4, Covered = true },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 96, 8 },
								{ 96, 64 },
								{ 8, 64 },
							},
							Count = 6,
						},
					},
				},
				{
					Name = "Fallen stacks",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 46, 0 },
								{ 46, 36 },
								{ 58, 36 },
								{ 58, 0 },
							},
						},
						{ Kind = "Flat", At = { 52, 0 }, Radius = 6 },
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
						{ Kind = "Mound", At = { 31, 25 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 73, 36 }, Radius = 7, Height = 6, Rock = true, Over = true },
						{ Kind = "Mound", At = { 42, 50 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 68, 18 }, Radius = 7, Height = 6, Rock = true, Over = true },
					},
					Loot = {
						{ At = { 52, 60 }, Radius = 4, Weight = 1 },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 12, 12 },
								{ 92, 12 },
								{ 92, 60 },
								{ 12, 60 },
							},
							Count = 3,
						},
					},
				},
			},
		},
		{
			Name = "The drift",
			At = { 296, 36 },
			Size = { 64, 80 },
			Rooms = {
				{
					Name = "Tide pool",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 46 },
								{ 32, 46 },
								{ 32, 34 },
								{ 0, 34 },
							},
						},
						{ Kind = "Flat", At = { 0, 40 }, Radius = 6 },
						{ Kind = "Flat", At = { 32, 40 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 56, 8 },
								{ 56, 72 },
								{ 8, 72 },
							},
						},
						{
							Kind = "Hollow",
							At = { 52, 40 },
							Radius = 20,
							Depth = 3,
							Rough = 3,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 52, 40 }, Radius = 4, Weight = 2 },
					},
					Decor = {
						{
							Kind = "Kelp",
							Area = {
								{ 12, 12 },
								{ 52, 12 },
								{ 52, 68 },
								{ 12, 68 },
							},
							Count = 5,
						},
						{ Kind = "Starfish", At = { 32, 40 } },
					},
				},
				{
					Name = "Timber drift",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 46 },
								{ 32, 46 },
								{ 32, 34 },
								{ 0, 34 },
							},
						},
						{ Kind = "Flat", At = { 0, 40 }, Radius = 6 },
						{ Kind = "Flat", At = { 32, 40 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 56, 8 },
								{ 56, 72 },
								{ 8, 72 },
							},
						},
					},
					Loot = {
						{ At = { 52, 40 }, Radius = 4, Weight = 1 },
					},
					Decor = {
						{
							Kind = "Timber",
							Area = {
								{ 12, 12 },
								{ 52, 12 },
								{ 52, 68 },
								{ 12, 68 },
							},
							Count = 6,
						},
						{
							Kind = "Crate",
							Area = {
								{ 12, 12 },
								{ 52, 12 },
								{ 52, 68 },
								{ 12, 68 },
							},
							Count = 4,
						},
						{ Kind = "WreckRibs", At = { 32, 40 }, Scale = 0.9, Yaw = 30 },
						{ Kind = "Chain", At = { 52, 40 } },
					},
				},
			},
		},
		{
			Name = "The rib hall",
			At = { -296, 316 },
			Size = { 104, 72 },
			Rooms = {
				{
					Name = "Ring under the rib",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 16, 22 },
								{ 88, 22 },
								{ 88, 10 },
								{ 16, 10 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 82, 16 },
								{ 82, 56 },
								{ 94, 56 },
								{ 94, 16 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 88, 50 },
								{ 16, 50 },
								{ 16, 62 },
								{ 88, 62 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 22, 56 },
								{ 22, 16 },
								{ 10, 16 },
								{ 10, 56 },
							},
						},
						{ Kind = "Flat", At = { 16, 16 }, Radius = 6 },
						{ Kind = "Flat", At = { 88, 16 }, Radius = 6 },
						{ Kind = "Flat", At = { 88, 56 }, Radius = 6 },
						{ Kind = "Flat", At = { 16, 56 }, Radius = 6 },
						{ Kind = "Flat", At = { 16, 16 }, Radius = 6 },
						{
							Kind = "Roof",
							Area = {
								{ 14, 0 },
								{ 14, 30 },
								{ 90, 30 },
								{ 90, 0 },
							},
							Clearance = 14,
							Thickness = 6,
						},
						{
							Kind = "Roof",
							Area = {
								{ 104, 14 },
								{ 74, 14 },
								{ 74, 58 },
								{ 104, 58 },
							},
							Clearance = 14,
							Thickness = 6,
						},
						{
							Kind = "Roof",
							Area = {
								{ 90, 72 },
								{ 90, 42 },
								{ 14, 42 },
								{ 14, 72 },
							},
							Clearance = 14,
							Thickness = 6,
						},
						{
							Kind = "Roof",
							Area = {
								{ 0, 58 },
								{ 30, 58 },
								{ 30, 14 },
								{ 0, 14 },
							},
							Clearance = 14,
							Thickness = 6,
						},
						{
							Kind = "Flat",
							Area = {
								{ 46, 0 },
								{ 46, 16 },
								{ 58, 16 },
								{ 58, 0 },
							},
						},
						{ Kind = "Flat", At = { 52, 0 }, Radius = 6 },
						{ Kind = "Flat", At = { 52, 16 }, Radius = 6 },
					},
					Loot = {
						{ At = { 52, 60 }, Radius = 3, Weight = 3 },
					},
					Decor = {
						{ Kind = "Barnacles", At = { 52, 60 } },
					},
				},
				{
					Name = "Drowned pocket",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 46, 0 },
								{ 46, 36 },
								{ 58, 36 },
								{ 58, 0 },
							},
						},
						{ Kind = "Flat", At = { 52, 0 }, Radius = 6 },
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
							At = { 52, 60 },
							Radius = 24,
							Depth = 3,
							Rough = 3,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 52, 60 }, Radius = 4, Weight = 2 },
					},
					Decor = {
						{
							Kind = "Kelp",
							Area = {
								{ 12, 12 },
								{ 92, 12 },
								{ 92, 60 },
								{ 12, 60 },
							},
							Count = 5,
						},
						{ Kind = "Starfish", At = { 52, 36 } },
					},
				},
			},
		},
		{
			Name = "Stack caves",
			At = { 296, 336 },
			Size = { 64, 96 },
			Rooms = {
				{
					Name = "Stack chamber",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 54 },
								{ 32, 54 },
								{ 32, 42 },
								{ 0, 42 },
							},
						},
						{ Kind = "Flat", At = { 0, 48 }, Radius = 6 },
						{ Kind = "Flat", At = { 32, 48 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 22 },
								{ 8, 8 },
								{ 56, 8 },
								{ 56, 22 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 8, 34 },
								{ 8, 22 },
								{ 22, 22 },
								{ 22, 34 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 34, 34 },
								{ 34, 22 },
								{ 56, 22 },
								{ 56, 34 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 8, 50 },
								{ 8, 34 },
								{ 56, 34 },
								{ 56, 50 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 8, 62 },
								{ 8, 50 },
								{ 22, 50 },
								{ 22, 62 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 34, 62 },
								{ 34, 50 },
								{ 56, 50 },
								{ 56, 62 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 8, 62 },
								{ 56, 62 },
								{ 56, 88 },
								{ 8, 88 },
							},
						},
						{
							Kind = "Wall",
							Area = {
								{ 22, 22 },
								{ 34, 22 },
								{ 34, 34 },
								{ 22, 34 },
							},
							Height = 16,
							Over = true,
						},
						{
							Kind = "Wall",
							Area = {
								{ 22, 50 },
								{ 34, 50 },
								{ 34, 62 },
								{ 22, 62 },
							},
							Height = 16,
							Over = true,
						},
						{
							Kind = "Roof",
							Area = {
								{ 2.86, 96 },
								{ 2.86, 0 },
								{ 61.14, 0 },
								{ 61.14, 96 },
							},
							Clearance = 14,
							Thickness = 6,
						},
					},
					Loot = {
						{ At = { 52, 48 }, Radius = 4, Weight = 2 },
					},
					Hazards = {
						{ Type = "Rockfall", At = { 32, 48 }, Radius = 12 },
					},
					Decor = {
						{ Kind = "Pebbles", At = { 32, 48 }, Scale = 1.2 },
					},
				},
				{
					Name = "Boulder choke",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 54 },
								{ 32, 54 },
								{ 32, 42 },
								{ 0, 42 },
							},
						},
						{ Kind = "Flat", At = { 0, 48 }, Radius = 6 },
						{ Kind = "Flat", At = { 32, 48 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 56, 8 },
								{ 56, 88 },
								{ 8, 88 },
							},
						},
						{ Kind = "Mound", At = { 19, 34 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 45, 48 }, Radius = 7, Height = 6, Rock = true, Over = true },
						{ Kind = "Mound", At = { 26, 67 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 42, 24 }, Radius = 7, Height = 6, Rock = true, Over = true },
					},
					Loot = {
						{ At = { 52, 48 }, Radius = 4, Weight = 2 },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 12, 12 },
								{ 52, 12 },
								{ 52, 84 },
								{ 12, 84 },
							},
							Count = 3,
						},
					},
				},
			},
		},
		{
			Name = "The wreck yard",
			At = { -352, 504 },
			Size = { 104, 72 },
			Rooms = {
				{
					Name = "Wreck yard",
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
					},
					Loot = {
						{ At = { 52, 12 }, Radius = 4, Weight = 2 },
					},
					Decor = {
						{
							Kind = "Timber",
							Area = {
								{ 12, 12 },
								{ 92, 12 },
								{ 92, 60 },
								{ 12, 60 },
							},
							Count = 6,
						},
						{
							Kind = "Crate",
							Area = {
								{ 12, 12 },
								{ 92, 12 },
								{ 92, 60 },
								{ 12, 60 },
							},
							Count = 4,
						},
						{ Kind = "WreckRibs", At = { 52, 36 }, Scale = 0.9, Yaw = 30 },
						{ Kind = "Chain", At = { 52, 12 } },
					},
				},
				{
					Name = "Deep cave",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 58, 72 },
								{ 58, 12 },
								{ 46, 12 },
								{ 46, 72 },
							},
						},
						{ Kind = "Flat", At = { 52, 72 }, Radius = 6 },
						{ Kind = "Flat", At = { 52, 12 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 52, 46 },
								{ 8, 46 },
								{ 8, 58 },
								{ 52, 58 },
							},
						},
						{ Kind = "Flat", At = { 52, 52 }, Radius = 6 },
						{ Kind = "Flat", At = { 8, 52 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 52, 38 },
								{ 96, 38 },
								{ 96, 26 },
								{ 52, 26 },
							},
						},
						{ Kind = "Flat", At = { 52, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
					},
					Loot = {
						{ At = { 10, 52 }, Radius = 3, Weight = 1 },
						{ At = { 94, 30 }, Radius = 3, Weight = 1 },
						{ At = { 52, 12 }, Radius = 4, Weight = 4 },
					},
					Hazards = {
						{ Type = "Pit", At = { 52, 12 }, Radius = 4, Covered = true },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 96, 8 },
								{ 96, 64 },
								{ 8, 64 },
							},
							Count = 6,
						},
					},
				},
			},
		},
		{
			Name = "The shingle",
			At = { 192, 504 },
			Size = { 112, 72 },
			Rooms = {
				{
					Name = "Rib chapel",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 62, 72 },
								{ 62, 36 },
								{ 50, 36 },
								{ 50, 72 },
							},
						},
						{ Kind = "Flat", At = { 56, 72 }, Radius = 6 },
						{ Kind = "Flat", At = { 56, 36 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 22 },
								{ 8, 8 },
								{ 104, 8 },
								{ 104, 22 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 8, 34 },
								{ 8, 22 },
								{ 22, 22 },
								{ 22, 34 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 34, 34 },
								{ 34, 22 },
								{ 50, 22 },
								{ 50, 34 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 62, 34 },
								{ 62, 22 },
								{ 78, 22 },
								{ 78, 34 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 90, 34 },
								{ 90, 22 },
								{ 104, 22 },
								{ 104, 34 },
							},
						},
						{
							Kind = "Flat",
							Area = {
								{ 8, 34 },
								{ 104, 34 },
								{ 104, 64 },
								{ 8, 64 },
							},
						},
						{
							Kind = "Wall",
							Area = {
								{ 22, 22 },
								{ 34, 22 },
								{ 34, 34 },
								{ 22, 34 },
							},
							Height = 16,
							Over = true,
						},
						{
							Kind = "Wall",
							Area = {
								{ 50, 22 },
								{ 62, 22 },
								{ 62, 34 },
								{ 50, 34 },
							},
							Height = 16,
							Over = true,
						},
						{
							Kind = "Wall",
							Area = {
								{ 78, 22 },
								{ 90, 22 },
								{ 90, 34 },
								{ 78, 34 },
							},
							Height = 16,
							Over = true,
						},
						{
							Kind = "Roof",
							Area = {
								{ 0, 2.96 },
								{ 112, 2.96 },
								{ 112, 69.04 },
								{ 0, 69.04 },
							},
							Clearance = 14,
							Thickness = 6,
						},
					},
					Loot = {
						{ At = { 56, 12 }, Radius = 4, Weight = 2 },
					},
					Hazards = {
						{ Type = "Rockfall", At = { 56, 36 }, Radius = 12 },
					},
					Decor = {
						{ Kind = "Pebbles", At = { 56, 36 }, Scale = 1.2 },
					},
				},
				{
					Name = "Sea pool",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 62, 72 },
								{ 62, 36 },
								{ 50, 36 },
								{ 50, 72 },
							},
						},
						{ Kind = "Flat", At = { 56, 72 }, Radius = 6 },
						{ Kind = "Flat", At = { 56, 36 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 104, 8 },
								{ 104, 64 },
								{ 8, 64 },
							},
						},
						{
							Kind = "Hollow",
							At = { 56, 12 },
							Radius = 24,
							Depth = 3,
							Rough = 3,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 56, 12 }, Radius = 4, Weight = 4 },
					},
					Decor = {
						{
							Kind = "Kelp",
							Area = {
								{ 12, 12 },
								{ 100, 12 },
								{ 100, 60 },
								{ 12, 60 },
							},
							Count = 5,
						},
						{ Kind = "Starfish", At = { 56, 36 } },
					},
				},
			},
		},
	},
}

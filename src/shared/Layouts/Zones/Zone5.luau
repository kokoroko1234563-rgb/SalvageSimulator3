-- Zone 5, The Shoals: drawn with the layout kit from tools/kit/plans/zone5.py (edit the plan
-- and re-run it, not this file). Its card: docs/design/cards/zone5.md.
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
			Height = 14,
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
				{ -96, 306 },
				{ -96, 286 },
				{ 96, 286 },
				{ 96, 306 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -96, 318 },
				{ -96, 306 },
				{ -78, 306 },
				{ -78, 318 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -66, 318 },
				{ -66, 306 },
				{ -42, 306 },
				{ -42, 318 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -30, 318 },
				{ -30, 306 },
				{ 30, 306 },
				{ 30, 318 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 42, 318 },
				{ 42, 306 },
				{ 66, 306 },
				{ 66, 318 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 78, 318 },
				{ 78, 306 },
				{ 96, 306 },
				{ 96, 318 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -96, 318 },
				{ 96, 318 },
				{ 96, 334 },
				{ -96, 334 },
			},
		},
		{
			Kind = "Wall",
			Area = {
				{ -78, 306 },
				{ -66, 306 },
				{ -66, 318 },
				{ -78, 318 },
			},
			Height = 14,
			Over = true,
		},
		{
			Kind = "Wall",
			Area = {
				{ -42, 306 },
				{ -30, 306 },
				{ -30, 318 },
				{ -42, 318 },
			},
			Height = 14,
			Over = true,
		},
		{
			Kind = "Wall",
			Area = {
				{ 30, 306 },
				{ 42, 306 },
				{ 42, 318 },
				{ 30, 318 },
			},
			Height = 14,
			Over = true,
		},
		{
			Kind = "Wall",
			Area = {
				{ 66, 306 },
				{ 78, 306 },
				{ 78, 318 },
				{ 66, 318 },
			},
			Height = 14,
			Over = true,
		},
		{
			Kind = "Roof",
			Area = {
				{ -105.7, 283.57 },
				{ 105.7, 283.57 },
				{ 105.7, 336.43 },
				{ -105.7, 336.43 },
			},
			Clearance = 12,
			Thickness = 6,
		},
		{
			Kind = "Flat",
			Area = {
				{ -240, 58 },
				{ -184, 58 },
				{ -184, 126 },
				{ -240, 126 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -240, 178 },
				{ -184, 178 },
				{ -184, 246 },
				{ -240, 246 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -240, 282 },
				{ -184, 282 },
				{ -184, 350 },
				{ -240, 350 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -240, 398 },
				{ -184, 398 },
				{ -184, 466 },
				{ -240, 466 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 184, 150 },
				{ 240, 150 },
				{ 240, 218 },
				{ 184, 218 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 184, 274 },
				{ 240, 274 },
				{ 240, 342 },
				{ 184, 342 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ 184, 398 },
				{ 240, 398 },
				{ 240, 466 },
				{ 184, 466 },
			},
		},
		{
			Kind = "Flat",
			Area = {
				{ -264, 98 },
				{ -240, 98 },
				{ -240, 86 },
				{ -264, 86 },
			},
		},
		{ Kind = "Flat", At = { -264, 92 }, Radius = 6 },
		{ Kind = "Flat", At = { -240, 92 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ -264, 218 },
				{ -240, 218 },
				{ -240, 206 },
				{ -264, 206 },
			},
		},
		{ Kind = "Flat", At = { -264, 212 }, Radius = 6 },
		{ Kind = "Flat", At = { -240, 212 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ -264, 322 },
				{ -240, 322 },
				{ -240, 310 },
				{ -264, 310 },
			},
		},
		{ Kind = "Flat", At = { -264, 316 }, Radius = 6 },
		{ Kind = "Flat", At = { -240, 316 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ -264, 438 },
				{ -240, 438 },
				{ -240, 426 },
				{ -264, 426 },
			},
		},
		{ Kind = "Flat", At = { -264, 432 }, Radius = 6 },
		{ Kind = "Flat", At = { -240, 432 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ 264, 178 },
				{ 240, 178 },
				{ 240, 190 },
				{ 264, 190 },
			},
		},
		{ Kind = "Flat", At = { 264, 184 }, Radius = 6 },
		{ Kind = "Flat", At = { 240, 184 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ 264, 302 },
				{ 240, 302 },
				{ 240, 314 },
				{ 264, 314 },
			},
		},
		{ Kind = "Flat", At = { 264, 308 }, Radius = 6 },
		{ Kind = "Flat", At = { 240, 308 }, Radius = 6 },
		{
			Kind = "Flat",
			Area = {
				{ 264, 426 },
				{ 240, 426 },
				{ 240, 438 },
				{ 264, 438 },
			},
		},
		{ Kind = "Flat", At = { 264, 432 }, Radius = 6 },
		{ Kind = "Flat", At = { 240, 432 }, Radius = 6 },
	},
	Loot = {
		{ At = { 0, 324 }, Radius = 6, Weight = 3 },
	},
	Decor = {
		{
			Kind = "Weed",
			Area = {
				{ -340, 2 },
				{ 340, 2 },
				{ 340, 16 },
				{ -340, 16 },
			},
			Count = 10,
		},
		{ Kind = "GlowShells", At = { -60, 296 } },
		{ Kind = "GlowShells", At = { 60, 328 } },
		{ Kind = "Starfish", At = { -20, 296 }, Scale = 0.9 },
		{ Kind = "Urchins", At = { 24, 296 }, Scale = 0.9 },
		{
			Kind = "Weed",
			Area = {
				{ -90, 290 },
				{ 90, 290 },
				{ 90, 330 },
				{ -90, 330 },
			},
			Count = 5,
		},
		{
			Kind = "Pebbles",
			Area = {
				{ -236, 62 },
				{ -188, 62 },
				{ -188, 122 },
				{ -236, 122 },
			},
			Count = 4,
		},
		{
			Kind = "Weed",
			Area = {
				{ -236, 62 },
				{ -188, 62 },
				{ -188, 122 },
				{ -236, 122 },
			},
			Count = 2,
		},
		{
			Kind = "Pebbles",
			Area = {
				{ -236, 182 },
				{ -188, 182 },
				{ -188, 242 },
				{ -236, 242 },
			},
			Count = 4,
		},
		{
			Kind = "Weed",
			Area = {
				{ -236, 182 },
				{ -188, 182 },
				{ -188, 242 },
				{ -236, 242 },
			},
			Count = 2,
		},
		{
			Kind = "Pebbles",
			Area = {
				{ -236, 286 },
				{ -188, 286 },
				{ -188, 346 },
				{ -236, 346 },
			},
			Count = 4,
		},
		{
			Kind = "Weed",
			Area = {
				{ -236, 286 },
				{ -188, 286 },
				{ -188, 346 },
				{ -236, 346 },
			},
			Count = 2,
		},
		{
			Kind = "Pebbles",
			Area = {
				{ -236, 402 },
				{ -188, 402 },
				{ -188, 462 },
				{ -236, 462 },
			},
			Count = 4,
		},
		{
			Kind = "Weed",
			Area = {
				{ -236, 402 },
				{ -188, 402 },
				{ -188, 462 },
				{ -236, 462 },
			},
			Count = 2,
		},
		{
			Kind = "Pebbles",
			Area = {
				{ 188, 154 },
				{ 236, 154 },
				{ 236, 214 },
				{ 188, 214 },
			},
			Count = 4,
		},
		{
			Kind = "Weed",
			Area = {
				{ 188, 154 },
				{ 236, 154 },
				{ 236, 214 },
				{ 188, 214 },
			},
			Count = 2,
		},
		{
			Kind = "Pebbles",
			Area = {
				{ 188, 278 },
				{ 236, 278 },
				{ 236, 338 },
				{ 188, 338 },
			},
			Count = 4,
		},
		{
			Kind = "Weed",
			Area = {
				{ 188, 278 },
				{ 236, 278 },
				{ 236, 338 },
				{ 188, 338 },
			},
			Count = 2,
		},
		{
			Kind = "Pebbles",
			Area = {
				{ 188, 402 },
				{ 236, 402 },
				{ 236, 462 },
				{ 188, 462 },
			},
			Count = 4,
		},
		{
			Kind = "Weed",
			Area = {
				{ 188, 402 },
				{ 236, 402 },
				{ 236, 462 },
				{ 188, 462 },
			},
			Count = 2,
		},
	},
	Name = "The Shoals",
	Crossings = {
		{
			Name = "Mussel run",
			Paths = 2,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ 148, 0 },
						{ 148, 52 },
						{ -112, 52 },
						{ -112, 92 },
						{ 148, 92 },
						{ 148, 144 },
						{ -112, 144 },
						{ -112, 184 },
						{ 148, 184 },
						{ 148, 392 },
						{ 40, 392 },
						{ 40, 432 },
						{ 148, 432 },
						{ 148, 608 },
					},
					Width = 16,
				},
				{
					Kind = "Flat",
					Area = {
						{ -66, 12 },
						{ -66, 52 },
						{ -54, 52 },
						{ -54, 12 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -60, 46 },
						{ -152, 46 },
						{ -152, 58 },
						{ -60, 58 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 52 },
						{ -158, 392 },
						{ -146, 392 },
						{ -146, 52 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 398 },
						{ -40, 398 },
						{ -40, 386 },
						{ -152, 386 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -46, 392 },
						{ -46, 432 },
						{ -34, 432 },
						{ -34, 392 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -40, 426 },
						{ -152, 426 },
						{ -152, 438 },
						{ -40, 438 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 432 },
						{ -158, 472 },
						{ -146, 472 },
						{ -146, 432 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 478 },
						{ -40, 478 },
						{ -40, 466 },
						{ -152, 466 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -46, 472 },
						{ -46, 516 },
						{ -34, 516 },
						{ -34, 472 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -40, 510 },
						{ -152, 510 },
						{ -152, 522 },
						{ -40, 522 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 516 },
						{ -158, 608 },
						{ -146, 608 },
						{ -146, 516 },
					},
				},
				{ Kind = "Flat", At = { -60, 12 }, Radius = 6 },
				{ Kind = "Flat", At = { -60, 52 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 52 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 392 }, Radius = 6 },
				{ Kind = "Flat", At = { -40, 392 }, Radius = 6 },
				{ Kind = "Flat", At = { -40, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 472 }, Radius = 6 },
				{ Kind = "Flat", At = { -40, 472 }, Radius = 6 },
				{ Kind = "Flat", At = { -40, 516 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 516 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 608 }, Radius = 6 },
				{
					Kind = "Channel",
					Path = {
						{ -152, 104 },
						{ -152, 144 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 118 },
						{ -152, 130 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 80 },
						{ -158, 96 },
						{ -130, 96 },
						{ -130, 80 },
					},
				},
				{ Kind = "Flat", At = { -144, 80 }, Radius = 14 },
				{ Kind = "Flat", At = { -144, 96 }, Radius = 14 },
				{
					Kind = "Channel",
					Path = {
						{ -152, 228 },
						{ -152, 268 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 242 },
						{ -152, 254 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 200 },
						{ -158, 220 },
						{ -130, 220 },
						{ -130, 200 },
					},
				},
				{ Kind = "Flat", At = { -144, 200 }, Radius = 14 },
				{ Kind = "Flat", At = { -144, 220 }, Radius = 14 },
				{
					Kind = "Channel",
					Path = {
						{ -152, 352 },
						{ -152, 392 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 366 },
						{ -152, 378 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ -40, 476 },
						{ -40, 516 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -40, 490 },
						{ -40, 502 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 66 },
						{ -184, 66 },
						{ -184, 78 },
						{ -152, 78 },
					},
				},
				{ Kind = "Flat", At = { -152, 72 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 72 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 226 },
						{ -184, 226 },
						{ -184, 238 },
						{ -152, 238 },
					},
				},
				{ Kind = "Flat", At = { -152, 232 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 232 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 310 },
						{ -184, 310 },
						{ -184, 322 },
						{ -152, 322 },
					},
				},
				{ Kind = "Flat", At = { -152, 316 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 316 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 426 },
						{ -184, 426 },
						{ -184, 438 },
						{ -152, 438 },
					},
				},
				{ Kind = "Flat", At = { -152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 432 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 190 },
						{ 184, 190 },
						{ 184, 178 },
						{ 152, 178 },
					},
				},
				{ Kind = "Flat", At = { 152, 184 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 184 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 314 },
						{ 184, 314 },
						{ 184, 302 },
						{ 152, 302 },
					},
				},
				{ Kind = "Flat", At = { 152, 308 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 308 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 438 },
						{ 184, 438 },
						{ 184, 426 },
						{ 152, 426 },
					},
				},
				{ Kind = "Flat", At = { 152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 432 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 302 },
						{ -96, 302 },
						{ -96, 290 },
						{ -152, 290 },
					},
				},
				{ Kind = "Flat", At = { -152, 296 }, Radius = 6 },
				{ Kind = "Flat", At = { -96, 296 }, Radius = 6 },
			},
			Hazards = {
				{
					Type = "Undertow",
					Path = {
						{ -152, 100 },
						{ -152, 148 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 62 }, Radius = 9 },
				{ Type = "Pit", At = { -136, 86 }, Radius = 4, Covered = false },
				{
					Type = "Undertow",
					Path = {
						{ -152, 224 },
						{ -152, 272 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 186 }, Radius = 9 },
				{ Type = "Pit", At = { -136, 210 }, Radius = 4, Covered = false },
				{
					Type = "Undertow",
					Path = {
						{ -152, 348 },
						{ -152, 396 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 336 }, Radius = 9 },
				{
					Type = "Undertow",
					Path = {
						{ -40, 472 },
						{ -40, 520 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -40, 472 }, Radius = 9 },
			},
			Decor = {
				{ Kind = "Pebbles", At = { 137, 45 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 92, 63 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 2, 41 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -88, 63 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -23, 103 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 67, 81 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 37, 133 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -53, 155 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 21, 195 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 111, 173 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 137, 339 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 159, 598 }, Scale = 1.1 },
				{ Kind = "Timber", At = { -157, 100 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 100 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 100 },
						{ -148, 100 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 106 },
						{ -147, 106 },
						{ -147, 142 },
						{ -157, 142 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -157, 224 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 224 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 224 },
						{ -148, 224 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 230 },
						{ -147, 230 },
						{ -147, 266 },
						{ -157, 266 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -157, 348 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 348 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 348 },
						{ -148, 348 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 354 },
						{ -147, 354 },
						{ -147, 390 },
						{ -157, 390 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -45, 472 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -35, 472 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -44, 472 },
						{ -36, 472 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -45, 478 },
						{ -35, 478 },
						{ -35, 514 },
						{ -45, 514 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -160, 8 }, Yaw = 80 },
				{ Kind = "Timber", At = { -136, 8 }, Yaw = 80 },
				{
					Kind = "Chain",
					Path = {
						{ -160, 8 },
						{ -136, 8 },
					},
					Count = 2,
				},
			},
		},
		{
			Name = "Reed bank",
			Paths = 2,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ -148, 0 },
						{ -148, 392 },
						{ 70, 392 },
						{ 70, 432 },
						{ -148, 432 },
						{ -148, 472 },
						{ 70, 472 },
						{ 70, 516 },
						{ -148, 516 },
						{ -148, 556 },
						{ 70, 556 },
						{ 70, 608 },
					},
					Width = 16,
				},
				{
					Kind = "Flat",
					Area = {
						{ 14, 12 },
						{ 14, 52 },
						{ 26, 52 },
						{ 26, 12 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 20, 58 },
						{ 152, 58 },
						{ 152, 46 },
						{ 20, 46 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 52 },
						{ 146, 92 },
						{ 158, 92 },
						{ 158, 52 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 152, 86 },
						{ 20, 86 },
						{ 20, 98 },
						{ 152, 98 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 14, 92 },
						{ 14, 144 },
						{ 26, 144 },
						{ 26, 92 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 20, 150 },
						{ 152, 150 },
						{ 152, 138 },
						{ 20, 138 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 144 },
						{ 146, 184 },
						{ 158, 184 },
						{ 158, 144 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 152, 178 },
						{ 20, 178 },
						{ 20, 190 },
						{ 152, 190 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 14, 184 },
						{ 14, 224 },
						{ 26, 224 },
						{ 26, 184 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 20, 230 },
						{ 152, 230 },
						{ 152, 218 },
						{ 20, 218 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 224 },
						{ 146, 420 },
						{ 158, 420 },
						{ 158, 224 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 152, 414 },
						{ 112, 414 },
						{ 112, 426 },
						{ 152, 426 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 106, 420 },
						{ 106, 460 },
						{ 118, 460 },
						{ 118, 420 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 112, 466 },
						{ 152, 466 },
						{ 152, 454 },
						{ 112, 454 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 460 },
						{ 146, 608 },
						{ 158, 608 },
						{ 158, 460 },
					},
				},
				{ Kind = "Flat", At = { 20, 12 }, Radius = 6 },
				{ Kind = "Flat", At = { 20, 52 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 52 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 92 }, Radius = 6 },
				{ Kind = "Flat", At = { 20, 92 }, Radius = 6 },
				{ Kind = "Flat", At = { 20, 144 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 144 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 184 }, Radius = 6 },
				{ Kind = "Flat", At = { 20, 184 }, Radius = 6 },
				{ Kind = "Flat", At = { 20, 224 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 224 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 420 }, Radius = 6 },
				{ Kind = "Flat", At = { 112, 420 }, Radius = 6 },
				{ Kind = "Flat", At = { 112, 460 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 460 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 608 }, Radius = 6 },
				{
					Kind = "Channel",
					Path = {
						{ 20, 104 },
						{ 20, 144 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ 20, 118 },
						{ 20, 130 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ 152, 228 },
						{ 152, 268 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ 152, 242 },
						{ 152, 254 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ 130, 200 },
						{ 130, 220 },
						{ 158, 220 },
						{ 158, 200 },
					},
				},
				{ Kind = "Flat", At = { 144, 200 }, Radius = 14 },
				{ Kind = "Flat", At = { 144, 220 }, Radius = 14 },
				{
					Kind = "Channel",
					Path = {
						{ 152, 352 },
						{ 152, 392 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ 152, 366 },
						{ 152, 378 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ 130, 328 },
						{ 130, 344 },
						{ 158, 344 },
						{ 158, 328 },
					},
				},
				{ Kind = "Flat", At = { 144, 328 }, Radius = 14 },
				{ Kind = "Flat", At = { 144, 344 }, Radius = 14 },
				{
					Kind = "Channel",
					Path = {
						{ 152, 476 },
						{ 152, 516 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ 152, 490 },
						{ 152, 502 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 66 },
						{ -184, 66 },
						{ -184, 78 },
						{ -152, 78 },
					},
				},
				{ Kind = "Flat", At = { -152, 72 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 72 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 226 },
						{ -184, 226 },
						{ -184, 238 },
						{ -152, 238 },
					},
				},
				{ Kind = "Flat", At = { -152, 232 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 232 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 310 },
						{ -184, 310 },
						{ -184, 322 },
						{ -152, 322 },
					},
				},
				{ Kind = "Flat", At = { -152, 316 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 316 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 426 },
						{ -184, 426 },
						{ -184, 438 },
						{ -152, 438 },
					},
				},
				{ Kind = "Flat", At = { -152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 432 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 190 },
						{ 184, 190 },
						{ 184, 178 },
						{ 152, 178 },
					},
				},
				{ Kind = "Flat", At = { 152, 184 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 184 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 314 },
						{ 184, 314 },
						{ 184, 302 },
						{ 152, 302 },
					},
				},
				{ Kind = "Flat", At = { 152, 308 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 308 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 438 },
						{ 184, 438 },
						{ 184, 426 },
						{ 152, 426 },
					},
				},
				{ Kind = "Flat", At = { 152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 432 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 290 },
						{ 96, 290 },
						{ 96, 302 },
						{ 152, 302 },
					},
				},
				{ Kind = "Flat", At = { 152, 296 }, Radius = 6 },
				{ Kind = "Flat", At = { 96, 296 }, Radius = 6 },
			},
			Hazards = {
				{
					Type = "Undertow",
					Path = {
						{ 20, 100 },
						{ 20, 148 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { 20, 96 }, Radius = 9 },
				{
					Type = "Undertow",
					Path = {
						{ 152, 224 },
						{ 152, 272 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { 152, 186 }, Radius = 9 },
				{ Type = "Pit", At = { 136, 210 }, Radius = 4, Covered = false },
				{
					Type = "Undertow",
					Path = {
						{ 152, 348 },
						{ 152, 396 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { 152, 336 }, Radius = 9 },
				{ Type = "Pit", At = { 136, 334 }, Radius = 4, Covered = false },
				{
					Type = "Undertow",
					Path = {
						{ 152, 472 },
						{ 152, 520 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { 152, 460 }, Radius = 9 },
			},
			Decor = {
				{ Kind = "Pebbles", At = { -159, 45 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -137, 135 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -159, 225 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -137, 315 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -59, 403 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 31, 381 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -41, 421 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -131, 443 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -15, 483 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -74, 527 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 7, 567 }, Scale = 1.1 },
				{ Kind = "Timber", At = { 15, 100 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { 25, 100 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ 16, 100 },
						{ 24, 100 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ 15, 106 },
						{ 25, 106 },
						{ 25, 142 },
						{ 15, 142 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { 147, 224 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { 157, 224 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ 148, 224 },
						{ 156, 224 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ 147, 230 },
						{ 157, 230 },
						{ 157, 266 },
						{ 147, 266 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { 147, 348 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { 157, 348 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ 148, 348 },
						{ 156, 348 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ 147, 354 },
						{ 157, 354 },
						{ 157, 390 },
						{ 147, 390 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { 147, 472 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { 157, 472 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ 148, 472 },
						{ 156, 472 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ 147, 478 },
						{ 157, 478 },
						{ 157, 514 },
						{ 147, 514 },
					},
					Count = 3,
				},
				{ Kind = "Anchor", At = { -160, 8 }, Yaw = 120 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 14 },
						{ -140, 8 },
					},
					Count = 2,
				},
			},
		},
		{
			Name = "Three lanes",
			Paths = 3,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ -112, 0 },
						{ -112, 52 },
						{ 112, 52 },
						{ 112, 92 },
						{ -112, 92 },
						{ -112, 144 },
						{ 112, 144 },
						{ 112, 184 },
						{ -112, 184 },
						{ -112, 224 },
						{ 0, 224 },
						{ 0, 608 },
					},
					Width = 16,
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 12 },
						{ -158, 392 },
						{ -146, 392 },
						{ -146, 12 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 398 },
						{ -40, 398 },
						{ -40, 386 },
						{ -152, 386 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -46, 392 },
						{ -46, 432 },
						{ -34, 432 },
						{ -34, 392 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -40, 426 },
						{ -152, 426 },
						{ -152, 438 },
						{ -40, 438 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 432 },
						{ -158, 472 },
						{ -146, 472 },
						{ -146, 432 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 478 },
						{ -40, 478 },
						{ -40, 466 },
						{ -152, 466 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -46, 472 },
						{ -46, 516 },
						{ -34, 516 },
						{ -34, 472 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -40, 510 },
						{ -152, 510 },
						{ -152, 522 },
						{ -40, 522 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 516 },
						{ -158, 608 },
						{ -146, 608 },
						{ -146, 516 },
					},
				},
				{ Kind = "Flat", At = { -152, 12 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 392 }, Radius = 6 },
				{ Kind = "Flat", At = { -40, 392 }, Radius = 6 },
				{ Kind = "Flat", At = { -40, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 472 }, Radius = 6 },
				{ Kind = "Flat", At = { -40, 472 }, Radius = 6 },
				{ Kind = "Flat", At = { -40, 516 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 516 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 608 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 146, 12 },
						{ 146, 392 },
						{ 158, 392 },
						{ 158, 12 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 152, 386 },
						{ 40, 386 },
						{ 40, 398 },
						{ 152, 398 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 34, 392 },
						{ 34, 432 },
						{ 46, 432 },
						{ 46, 392 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 40, 438 },
						{ 152, 438 },
						{ 152, 426 },
						{ 40, 426 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 432 },
						{ 146, 472 },
						{ 158, 472 },
						{ 158, 432 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 152, 466 },
						{ 40, 466 },
						{ 40, 478 },
						{ 152, 478 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 34, 472 },
						{ 34, 516 },
						{ 46, 516 },
						{ 46, 472 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 40, 522 },
						{ 152, 522 },
						{ 152, 510 },
						{ 40, 510 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 146, 516 },
						{ 146, 556 },
						{ 158, 556 },
						{ 158, 516 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 152, 550 },
						{ 40, 550 },
						{ 40, 562 },
						{ 152, 562 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ 34, 556 },
						{ 34, 608 },
						{ 46, 608 },
						{ 46, 556 },
					},
				},
				{ Kind = "Flat", At = { 152, 12 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 392 }, Radius = 6 },
				{ Kind = "Flat", At = { 40, 392 }, Radius = 6 },
				{ Kind = "Flat", At = { 40, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 472 }, Radius = 6 },
				{ Kind = "Flat", At = { 40, 472 }, Radius = 6 },
				{ Kind = "Flat", At = { 40, 516 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 516 }, Radius = 6 },
				{ Kind = "Flat", At = { 152, 556 }, Radius = 6 },
				{ Kind = "Flat", At = { 40, 556 }, Radius = 6 },
				{ Kind = "Flat", At = { 40, 608 }, Radius = 6 },
				{
					Kind = "Channel",
					Path = {
						{ -152, 104 },
						{ -152, 144 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 118 },
						{ -152, 130 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ -152, 228 },
						{ -152, 268 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 242 },
						{ -152, 254 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 200 },
						{ -158, 220 },
						{ -130, 220 },
						{ -130, 200 },
					},
				},
				{ Kind = "Flat", At = { -144, 200 }, Radius = 14 },
				{ Kind = "Flat", At = { -144, 220 }, Radius = 14 },
				{
					Kind = "Channel",
					Path = {
						{ -152, 352 },
						{ -152, 392 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 366 },
						{ -152, 378 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ -40, 476 },
						{ -40, 516 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -40, 490 },
						{ -40, 502 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ 110, 472 },
						{ 70, 472 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 66 },
						{ -184, 66 },
						{ -184, 78 },
						{ -152, 78 },
					},
				},
				{ Kind = "Flat", At = { -152, 72 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 72 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 226 },
						{ -184, 226 },
						{ -184, 238 },
						{ -152, 238 },
					},
				},
				{ Kind = "Flat", At = { -152, 232 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 232 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 310 },
						{ -184, 310 },
						{ -184, 322 },
						{ -152, 322 },
					},
				},
				{ Kind = "Flat", At = { -152, 316 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 316 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 426 },
						{ -184, 426 },
						{ -184, 438 },
						{ -152, 438 },
					},
				},
				{ Kind = "Flat", At = { -152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 432 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 190 },
						{ 184, 190 },
						{ 184, 178 },
						{ 152, 178 },
					},
				},
				{ Kind = "Flat", At = { 152, 184 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 184 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 314 },
						{ 184, 314 },
						{ 184, 302 },
						{ 152, 302 },
					},
				},
				{ Kind = "Flat", At = { 152, 308 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 308 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 438 },
						{ 184, 438 },
						{ 184, 426 },
						{ 152, 426 },
					},
				},
				{ Kind = "Flat", At = { 152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 432 }, Radius = 6 },
			},
			Hazards = {
				{
					Type = "Undertow",
					Path = {
						{ -152, 100 },
						{ -152, 148 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 62 }, Radius = 9 },
				{
					Type = "Undertow",
					Path = {
						{ -152, 224 },
						{ -152, 272 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 186 }, Radius = 9 },
				{ Type = "Pit", At = { -136, 210 }, Radius = 4, Covered = false },
				{
					Type = "Undertow",
					Path = {
						{ -152, 348 },
						{ -152, 396 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 336 }, Radius = 9 },
				{
					Type = "Undertow",
					Path = {
						{ -40, 472 },
						{ -40, 520 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -40, 472 }, Radius = 9 },
				{
					Type = "Undertow",
					Path = {
						{ 110, 472 },
						{ 70, 472 },
					},
					Width = 12,
				},
			},
			Decor = {
				{ Kind = "Pebbles", At = { -123, 45 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -56, 41 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 34, 63 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 34, 103 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -56, 81 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -12, 133 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 78, 155 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -10, 195 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -100, 173 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 11, 368 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -11, 458 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 11, 548 }, Scale = 1.1 },
				{ Kind = "Timber", At = { -157, 100 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 100 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 100 },
						{ -148, 100 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 106 },
						{ -147, 106 },
						{ -147, 142 },
						{ -157, 142 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -157, 224 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 224 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 224 },
						{ -148, 224 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 230 },
						{ -147, 230 },
						{ -147, 266 },
						{ -157, 266 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -157, 348 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 348 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 348 },
						{ -148, 348 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 354 },
						{ -147, 354 },
						{ -147, 390 },
						{ -157, 390 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -45, 472 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -35, 472 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -44, 472 },
						{ -36, 472 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -45, 478 },
						{ -35, 478 },
						{ -35, 514 },
						{ -45, 514 },
					},
					Count = 3,
				},
				{
					Kind = "Weed",
					Path = {
						{ 110, 472 },
						{ 70, 472 },
					},
					Count = 3,
				},
				{ Kind = "Bones", At = { -8, 8 }, Scale = 1.3 },
				{ Kind = "GlowShells", At = { 8, 14 } },
			},
		},
		{
			Name = "The Grotto way",
			Paths = 1,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ -112, 0 },
						{ -112, 52 },
						{ 112, 52 },
						{ 112, 92 },
						{ -112, 92 },
						{ -112, 144 },
						{ 112, 144 },
						{ 112, 184 },
						{ -112, 184 },
						{ -112, 224 },
						{ 0, 224 },
						{ 0, 608 },
					},
					Width = 16,
				},
				{
					Kind = "Flat",
					Area = {
						{ -6, 52 },
						{ -6, 92 },
						{ 6, 92 },
						{ 6, 52 },
					},
				},
				{ Kind = "Flat", At = { 0, 52 }, Radius = 6 },
				{ Kind = "Flat", At = { 0, 92 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ 0, 68 },
						{ 0, 76 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -6, 144 },
						{ -6, 184 },
						{ 6, 184 },
						{ 6, 144 },
					},
				},
				{ Kind = "Flat", At = { 0, 144 }, Radius = 6 },
				{ Kind = "Flat", At = { 0, 184 }, Radius = 6 },
				{
					Kind = "Ridge",
					Path = {
						{ 0, 160 },
						{ 0, 168 },
					},
					Height = 2.5,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -96, 290 },
						{ -184, 290 },
						{ -184, 302 },
						{ -96, 302 },
					},
				},
				{ Kind = "Flat", At = { -96, 296 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 296 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 96, 302 },
						{ 184, 302 },
						{ 184, 290 },
						{ 96, 290 },
					},
				},
				{ Kind = "Flat", At = { 96, 296 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 296 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -112, 86 },
						{ -184, 86 },
						{ -184, 98 },
						{ -112, 98 },
					},
				},
				{ Kind = "Flat", At = { -112, 92 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 92 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -112, 178 },
						{ -184, 178 },
						{ -184, 190 },
						{ -112, 190 },
					},
				},
				{ Kind = "Flat", At = { -112, 184 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 184 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 112, 190 },
						{ 184, 190 },
						{ 184, 178 },
						{ 112, 178 },
					},
				},
				{ Kind = "Flat", At = { 112, 184 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 184 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -184, 438 },
						{ 184, 438 },
						{ 184, 426 },
						{ -184, 426 },
					},
				},
				{ Kind = "Flat", At = { -184, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 432 }, Radius = 6 },
			},
			Decor = {
				{ Kind = "Pebbles", At = { -123, 45 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -56, 41 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 34, 63 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 34, 103 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -56, 81 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -12, 133 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 78, 155 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -10, 195 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -100, 173 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 11, 368 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { -11, 458 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 11, 548 }, Scale = 1.1 },
				{ Kind = "LanternPost", At = { -12, 8 } },
				{ Kind = "LanternPost", At = { 12, 8 } },
			},
		},
		{
			Name = "Sandbar loop",
			Paths = 2,
			Primitives = {
				{
					Kind = "Ramp",
					Path = {
						{ 148, 0 },
						{ 148, 52 },
						{ 0, 52 },
						{ 0, 92 },
						{ 148, 92 },
						{ 148, 144 },
						{ 0, 144 },
						{ 0, 184 },
						{ 148, 184 },
						{ 148, 392 },
						{ 0, 392 },
						{ 0, 432 },
						{ 148, 432 },
						{ 148, 472 },
						{ 0, 472 },
						{ 0, 516 },
						{ 148, 516 },
						{ 148, 608 },
					},
					Width = 16,
				},
				{
					Kind = "Flat",
					Area = {
						{ -58, 12 },
						{ -58, 52 },
						{ -46, 52 },
						{ -46, 12 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -52, 46 },
						{ -152, 46 },
						{ -152, 58 },
						{ -52, 58 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 52 },
						{ -158, 92 },
						{ -146, 92 },
						{ -146, 52 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 98 },
						{ -52, 98 },
						{ -52, 86 },
						{ -152, 86 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -58, 92 },
						{ -58, 144 },
						{ -46, 144 },
						{ -46, 92 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -52, 138 },
						{ -152, 138 },
						{ -152, 150 },
						{ -52, 150 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 144 },
						{ -158, 392 },
						{ -146, 392 },
						{ -146, 144 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -152, 398 },
						{ -52, 398 },
						{ -52, 386 },
						{ -152, 386 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -58, 392 },
						{ -58, 432 },
						{ -46, 432 },
						{ -46, 392 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -52, 426 },
						{ -152, 426 },
						{ -152, 438 },
						{ -52, 438 },
					},
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 432 },
						{ -158, 608 },
						{ -146, 608 },
						{ -146, 432 },
					},
				},
				{ Kind = "Flat", At = { -52, 12 }, Radius = 6 },
				{ Kind = "Flat", At = { -52, 52 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 52 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 92 }, Radius = 6 },
				{ Kind = "Flat", At = { -52, 92 }, Radius = 6 },
				{ Kind = "Flat", At = { -52, 144 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 144 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 392 }, Radius = 6 },
				{ Kind = "Flat", At = { -52, 392 }, Radius = 6 },
				{ Kind = "Flat", At = { -52, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -152, 608 }, Radius = 6 },
				{
					Kind = "Channel",
					Path = {
						{ -52, 104 },
						{ -52, 144 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -52, 118 },
						{ -52, 130 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ -152, 228 },
						{ -152, 268 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 242 },
						{ -152, 254 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 200 },
						{ -158, 220 },
						{ -130, 220 },
						{ -130, 200 },
					},
				},
				{ Kind = "Flat", At = { -144, 200 }, Radius = 14 },
				{ Kind = "Flat", At = { -144, 220 }, Radius = 14 },
				{
					Kind = "Channel",
					Path = {
						{ -152, 352 },
						{ -152, 392 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 366 },
						{ -152, 378 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Channel",
					Path = {
						{ -152, 476 },
						{ -152, 516 },
					},
					Depth = 3,
					Width = 12,
					Rough = 1,
					Material = "Mud",
					Over = true,
				},
				{
					Kind = "Ridge",
					Path = {
						{ -152, 490 },
						{ -152, 502 },
					},
					Height = 3,
					Width = 12,
					Rough = 0,
					Over = true,
				},
				{
					Kind = "Flat",
					Area = {
						{ -158, 448 },
						{ -158, 468 },
						{ -130, 468 },
						{ -130, 448 },
					},
				},
				{ Kind = "Flat", At = { -144, 448 }, Radius = 14 },
				{ Kind = "Flat", At = { -144, 468 }, Radius = 14 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 66 },
						{ -184, 66 },
						{ -184, 78 },
						{ -152, 78 },
					},
				},
				{ Kind = "Flat", At = { -152, 72 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 72 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 226 },
						{ -184, 226 },
						{ -184, 238 },
						{ -152, 238 },
					},
				},
				{ Kind = "Flat", At = { -152, 232 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 232 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 310 },
						{ -184, 310 },
						{ -184, 322 },
						{ -152, 322 },
					},
				},
				{ Kind = "Flat", At = { -152, 316 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 316 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ -152, 426 },
						{ -184, 426 },
						{ -184, 438 },
						{ -152, 438 },
					},
				},
				{ Kind = "Flat", At = { -152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { -184, 432 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 190 },
						{ 184, 190 },
						{ 184, 178 },
						{ 152, 178 },
					},
				},
				{ Kind = "Flat", At = { 152, 184 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 184 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 314 },
						{ 184, 314 },
						{ 184, 302 },
						{ 152, 302 },
					},
				},
				{ Kind = "Flat", At = { 152, 308 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 308 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 438 },
						{ 184, 438 },
						{ 184, 426 },
						{ 152, 426 },
					},
				},
				{ Kind = "Flat", At = { 152, 432 }, Radius = 6 },
				{ Kind = "Flat", At = { 184, 432 }, Radius = 6 },
				{
					Kind = "Flat",
					Area = {
						{ 152, 290 },
						{ 96, 290 },
						{ 96, 302 },
						{ 152, 302 },
					},
				},
				{ Kind = "Flat", At = { 152, 296 }, Radius = 6 },
				{ Kind = "Flat", At = { 96, 296 }, Radius = 6 },
			},
			Hazards = {
				{
					Type = "Undertow",
					Path = {
						{ -52, 100 },
						{ -52, 148 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -52, 96 }, Radius = 9 },
				{
					Type = "Undertow",
					Path = {
						{ -152, 224 },
						{ -152, 272 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 186 }, Radius = 9 },
				{ Type = "Pit", At = { -136, 210 }, Radius = 4, Covered = false },
				{
					Type = "Undertow",
					Path = {
						{ -152, 348 },
						{ -152, 396 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 336 }, Radius = 9 },
				{
					Type = "Undertow",
					Path = {
						{ -152, 472 },
						{ -152, 520 },
					},
					Width = 12,
				},
				{ Type = "Sink", At = { -152, 450 }, Radius = 9 },
				{ Type = "Pit", At = { -136, 458 }, Radius = 4, Covered = false },
			},
			Decor = {
				{ Kind = "Pebbles", At = { 137, 45 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 92, 63 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 2, 41 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 78, 81 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 59, 133 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 100, 173 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 137, 295 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 159, 385 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 15, 381 }, Scale = 1.1 },
				{ Kind = "Pebbles", At = { 144, 421 }, Scale = 1.1 },
				{ Kind = "Timber", At = { -57, 100 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -47, 100 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -56, 100 },
						{ -48, 100 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -57, 106 },
						{ -47, 106 },
						{ -47, 142 },
						{ -57, 142 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -157, 224 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 224 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 224 },
						{ -148, 224 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 230 },
						{ -147, 230 },
						{ -147, 266 },
						{ -157, 266 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -157, 348 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 348 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 348 },
						{ -148, 348 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 354 },
						{ -147, 354 },
						{ -147, 390 },
						{ -157, 390 },
					},
					Count = 3,
				},
				{ Kind = "Timber", At = { -157, 472 }, Yaw = 90, Scale = 0.8 },
				{ Kind = "Timber", At = { -147, 472 }, Yaw = 90, Scale = 0.8 },
				{
					Kind = "Chain",
					Path = {
						{ -156, 472 },
						{ -148, 472 },
					},
					Count = 2,
				},
				{
					Kind = "Weed",
					Area = {
						{ -157, 478 },
						{ -147, 478 },
						{ -147, 514 },
						{ -157, 514 },
					},
					Count = 3,
				},
				{ Kind = "Urchins", At = { -60, 8 } },
				{ Kind = "Starfish", At = { -40, 10 } },
				{ Kind = "Starfish", At = { -50, 4 }, Scale = 1.2 },
			},
		},
	},
	Slots = {
		{
			Name = "Weed cove",
			At = { -352, 60 },
			Size = { 96, 64 },
			Rooms = {
				{
					Name = "Drowned pool",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 96, 26 },
								{ 48, 26 },
								{ 48, 38 },
								{ 96, 38 },
							},
						},
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{
							Kind = "Hollow",
							At = { 12, 32 },
							Radius = 20,
							Depth = 4,
							Rough = 3,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 12, 32 }, Radius = 4, Weight = 4 },
					},
					Decor = {
						{
							Kind = "Starfish",
							Area = {
								{ 14, 14 },
								{ 82, 14 },
								{ 82, 50 },
								{ 14, 50 },
							},
							Count = 3,
						},
						{
							Kind = "Urchins",
							Area = {
								{ 14, 14 },
								{ 82, 14 },
								{ 82, 50 },
								{ 14, 50 },
							},
							Count = 3,
						},
						{
							Kind = "Weed",
							Area = {
								{ 12, 12 },
								{ 84, 12 },
								{ 84, 52 },
								{ 12, 52 },
							},
							Count = 4,
						},
					},
				},
				{
					Name = "Dead-end cave",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 96, 26 },
								{ 12, 26 },
								{ 12, 38 },
								{ 96, 38 },
							},
						},
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 12, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 82, 32 },
								{ 82, 8 },
								{ 70, 8 },
								{ 70, 32 },
							},
						},
						{ Kind = "Flat", At = { 76, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 76, 8 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 50, 32 },
								{ 50, 56 },
								{ 62, 56 },
								{ 62, 32 },
							},
						},
						{ Kind = "Flat", At = { 56, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 56, 56 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 38, 32 },
								{ 38, 8 },
								{ 26, 8 },
								{ 26, 32 },
							},
						},
						{ Kind = "Flat", At = { 32, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 32, 8 }, Radius = 6 },
					},
					Loot = {
						{ At = { 76, 10 }, Radius = 3, Weight = 1 },
						{ At = { 54, 54 }, Radius = 3, Weight = 1 },
						{ At = { 32, 10 }, Radius = 3, Weight = 1 },
						{ At = { 12, 32 }, Radius = 4, Weight = 3 },
					},
					Hazards = {
						{ Type = "Pit", At = { 12, 32 }, Radius = 4, Covered = true },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
							Count = 6,
						},
					},
				},
			},
		},
		{
			Name = "Fallen stacks",
			At = { -352, 180 },
			Size = { 96, 64 },
			Rooms = {
				{
					Name = "Boulder scramble",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 96, 26 },
								{ 48, 26 },
								{ 48, 38 },
								{ 96, 38 },
							},
						},
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{ Kind = "Mound", At = { 29, 22 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 67, 32 }, Radius = 7, Height = 6, Rock = true, Over = true },
						{ Kind = "Mound", At = { 38, 45 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 62, 16 }, Radius = 7, Height = 6, Rock = true, Over = true },
					},
					Loot = {
						{ At = { 12, 32 }, Radius = 4, Weight = 2 },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
							Count = 4,
						},
					},
				},
				{
					Name = "Weed channel",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 96, 26 },
								{ 48, 26 },
								{ 48, 38 },
								{ 96, 38 },
							},
						},
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{
							Kind = "Channel",
							Path = {
								{ 82, 32 },
								{ 12, 32 },
							},
							Depth = 3,
							Width = 12,
							Rough = 2,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 12, 32 }, Radius = 4, Weight = 2 },
					},
					Hazards = {
						{
							Type = "Undertow",
							Path = {
								{ 82, 32 },
								{ 12, 32 },
							},
							Width = 12,
						},
					},
					Decor = {
						{
							Kind = "Weed",
							Path = {
								{ 82, 32 },
								{ 12, 32 },
							},
							Count = 8,
						},
						{
							Kind = "Kelp",
							Area = {
								{ 12, 12 },
								{ 84, 12 },
								{ 84, 52 },
								{ 12, 52 },
							},
							Count = 3,
						},
					},
				},
			},
		},
		{
			Name = "Reef cave",
			At = { -352, 284 },
			Size = { 96, 64 },
			Rooms = {
				{
					Name = "Reef cave",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 96, 26 },
								{ 12, 26 },
								{ 12, 38 },
								{ 96, 38 },
							},
						},
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 12, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 82, 32 },
								{ 82, 8 },
								{ 70, 8 },
								{ 70, 32 },
							},
						},
						{ Kind = "Flat", At = { 76, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 76, 8 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 50, 32 },
								{ 50, 56 },
								{ 62, 56 },
								{ 62, 32 },
							},
						},
						{ Kind = "Flat", At = { 56, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 56, 56 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 38, 32 },
								{ 38, 8 },
								{ 26, 8 },
								{ 26, 32 },
							},
						},
						{ Kind = "Flat", At = { 32, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 32, 8 }, Radius = 6 },
					},
					Loot = {
						{ At = { 76, 10 }, Radius = 3, Weight = 1 },
						{ At = { 54, 54 }, Radius = 3, Weight = 1 },
						{ At = { 32, 10 }, Radius = 3, Weight = 1 },
						{ At = { 12, 32 }, Radius = 4, Weight = 4 },
					},
					Hazards = {
						{ Type = "Pit", At = { 12, 32 }, Radius = 4, Covered = true },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
							Count = 6,
						},
					},
				},
				{
					Name = "Sunk pool",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 96, 26 },
								{ 48, 26 },
								{ 48, 38 },
								{ 96, 38 },
							},
						},
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{
							Kind = "Hollow",
							At = { 12, 32 },
							Radius = 20,
							Depth = 4,
							Rough = 3,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 12, 32 }, Radius = 4, Weight = 3 },
					},
					Decor = {
						{
							Kind = "Starfish",
							Area = {
								{ 14, 14 },
								{ 82, 14 },
								{ 82, 50 },
								{ 14, 50 },
							},
							Count = 3,
						},
						{
							Kind = "Urchins",
							Area = {
								{ 14, 14 },
								{ 82, 14 },
								{ 82, 50 },
								{ 14, 50 },
							},
							Count = 3,
						},
						{
							Kind = "Weed",
							Area = {
								{ 12, 12 },
								{ 84, 12 },
								{ 84, 52 },
								{ 12, 52 },
							},
							Count = 4,
						},
					},
				},
			},
		},
		{
			Name = "Outer hollow",
			At = { -352, 400 },
			Size = { 96, 64 },
			Rooms = {
				{
					Name = "Weed channel",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 96, 26 },
								{ 48, 26 },
								{ 48, 38 },
								{ 96, 38 },
							},
						},
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{
							Kind = "Channel",
							Path = {
								{ 82, 32 },
								{ 12, 32 },
							},
							Depth = 3,
							Width = 12,
							Rough = 2,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 12, 32 }, Radius = 4, Weight = 2 },
					},
					Hazards = {
						{
							Type = "Undertow",
							Path = {
								{ 82, 32 },
								{ 12, 32 },
							},
							Width = 12,
						},
					},
					Decor = {
						{
							Kind = "Weed",
							Path = {
								{ 82, 32 },
								{ 12, 32 },
							},
							Count = 8,
						},
						{
							Kind = "Kelp",
							Area = {
								{ 12, 12 },
								{ 84, 12 },
								{ 84, 52 },
								{ 12, 52 },
							},
							Count = 3,
						},
					},
				},
				{
					Name = "Boulder scramble",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 96, 26 },
								{ 48, 26 },
								{ 48, 38 },
								{ 96, 38 },
							},
						},
						{ Kind = "Flat", At = { 96, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{ Kind = "Mound", At = { 29, 22 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 67, 32 }, Radius = 7, Height = 6, Rock = true, Over = true },
						{ Kind = "Mound", At = { 38, 45 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 62, 16 }, Radius = 7, Height = 6, Rock = true, Over = true },
					},
					Loot = {
						{ At = { 12, 32 }, Radius = 4, Weight = 2 },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
							Count = 4,
						},
					},
				},
			},
		},
		{
			Name = "Eastern shelf",
			At = { 256, 152 },
			Size = { 96, 64 },
			Rooms = {
				{
					Name = "Drowned pool",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 38 },
								{ 48, 38 },
								{ 48, 26 },
								{ 0, 26 },
							},
						},
						{ Kind = "Flat", At = { 0, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{
							Kind = "Hollow",
							At = { 84, 32 },
							Radius = 20,
							Depth = 4,
							Rough = 3,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 84, 32 }, Radius = 4, Weight = 4 },
					},
					Decor = {
						{
							Kind = "Starfish",
							Area = {
								{ 14, 14 },
								{ 82, 14 },
								{ 82, 50 },
								{ 14, 50 },
							},
							Count = 3,
						},
						{
							Kind = "Urchins",
							Area = {
								{ 14, 14 },
								{ 82, 14 },
								{ 82, 50 },
								{ 14, 50 },
							},
							Count = 3,
						},
						{
							Kind = "Weed",
							Area = {
								{ 12, 12 },
								{ 84, 12 },
								{ 84, 52 },
								{ 12, 52 },
							},
							Count = 4,
						},
					},
				},
				{
					Name = "Weed channel",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 38 },
								{ 48, 38 },
								{ 48, 26 },
								{ 0, 26 },
							},
						},
						{ Kind = "Flat", At = { 0, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{
							Kind = "Channel",
							Path = {
								{ 14, 32 },
								{ 84, 32 },
							},
							Depth = 3,
							Width = 12,
							Rough = 2,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 84, 32 }, Radius = 4, Weight = 2 },
					},
					Hazards = {
						{
							Type = "Undertow",
							Path = {
								{ 14, 32 },
								{ 84, 32 },
							},
							Width = 12,
						},
					},
					Decor = {
						{
							Kind = "Weed",
							Path = {
								{ 14, 32 },
								{ 84, 32 },
							},
							Count = 8,
						},
						{
							Kind = "Kelp",
							Area = {
								{ 12, 12 },
								{ 84, 12 },
								{ 84, 52 },
								{ 12, 52 },
							},
							Count = 3,
						},
					},
				},
			},
		},
		{
			Name = "Stack gallery",
			At = { 256, 276 },
			Size = { 96, 64 },
			Rooms = {
				{
					Name = "Dead-end cave",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 38 },
								{ 84, 38 },
								{ 84, 26 },
								{ 0, 26 },
							},
						},
						{ Kind = "Flat", At = { 0, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 84, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 14, 32 },
								{ 14, 56 },
								{ 26, 56 },
								{ 26, 32 },
							},
						},
						{ Kind = "Flat", At = { 20, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 20, 56 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 46, 32 },
								{ 46, 8 },
								{ 34, 8 },
								{ 34, 32 },
							},
						},
						{ Kind = "Flat", At = { 40, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 40, 8 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 58, 32 },
								{ 58, 56 },
								{ 70, 56 },
								{ 70, 32 },
							},
						},
						{ Kind = "Flat", At = { 64, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 64, 56 }, Radius = 6 },
					},
					Loot = {
						{ At = { 20, 54 }, Radius = 3, Weight = 1 },
						{ At = { 42, 10 }, Radius = 3, Weight = 1 },
						{ At = { 64, 54 }, Radius = 3, Weight = 1 },
						{ At = { 84, 32 }, Radius = 4, Weight = 4 },
					},
					Hazards = {
						{ Type = "Pit", At = { 84, 32 }, Radius = 4, Covered = true },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
							Count = 6,
						},
					},
				},
				{
					Name = "Boulder scramble",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 38 },
								{ 48, 38 },
								{ 48, 26 },
								{ 0, 26 },
							},
						},
						{ Kind = "Flat", At = { 0, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{ Kind = "Mound", At = { 29, 22 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 67, 32 }, Radius = 7, Height = 6, Rock = true, Over = true },
						{ Kind = "Mound", At = { 38, 45 }, Radius = 7, Height = 5, Rock = true, Over = true },
						{ Kind = "Mound", At = { 62, 16 }, Radius = 7, Height = 6, Rock = true, Over = true },
					},
					Loot = {
						{ At = { 84, 32 }, Radius = 4, Weight = 2 },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
							Count = 4,
						},
					},
				},
			},
		},
		{
			Name = "Outer cove",
			At = { 256, 400 },
			Size = { 96, 64 },
			Rooms = {
				{
					Name = "Drowned pool",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 38 },
								{ 48, 38 },
								{ 48, 26 },
								{ 0, 26 },
							},
						},
						{ Kind = "Flat", At = { 0, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 48, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
						},
						{
							Kind = "Hollow",
							At = { 84, 32 },
							Radius = 20,
							Depth = 4,
							Rough = 3,
							Material = "Mud",
							Over = true,
						},
					},
					Loot = {
						{ At = { 84, 32 }, Radius = 4, Weight = 4 },
					},
					Decor = {
						{
							Kind = "Starfish",
							Area = {
								{ 14, 14 },
								{ 82, 14 },
								{ 82, 50 },
								{ 14, 50 },
							},
							Count = 3,
						},
						{
							Kind = "Urchins",
							Area = {
								{ 14, 14 },
								{ 82, 14 },
								{ 82, 50 },
								{ 14, 50 },
							},
							Count = 3,
						},
						{
							Kind = "Weed",
							Area = {
								{ 12, 12 },
								{ 84, 12 },
								{ 84, 52 },
								{ 12, 52 },
							},
							Count = 4,
						},
					},
				},
				{
					Name = "Dead-end cave",
					Primitives = {
						{
							Kind = "Flat",
							Area = {
								{ 0, 38 },
								{ 84, 38 },
								{ 84, 26 },
								{ 0, 26 },
							},
						},
						{ Kind = "Flat", At = { 0, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 84, 32 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 14, 32 },
								{ 14, 56 },
								{ 26, 56 },
								{ 26, 32 },
							},
						},
						{ Kind = "Flat", At = { 20, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 20, 56 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 46, 32 },
								{ 46, 8 },
								{ 34, 8 },
								{ 34, 32 },
							},
						},
						{ Kind = "Flat", At = { 40, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 40, 8 }, Radius = 6 },
						{
							Kind = "Flat",
							Area = {
								{ 58, 32 },
								{ 58, 56 },
								{ 70, 56 },
								{ 70, 32 },
							},
						},
						{ Kind = "Flat", At = { 64, 32 }, Radius = 6 },
						{ Kind = "Flat", At = { 64, 56 }, Radius = 6 },
					},
					Loot = {
						{ At = { 20, 54 }, Radius = 3, Weight = 1 },
						{ At = { 42, 10 }, Radius = 3, Weight = 1 },
						{ At = { 64, 54 }, Radius = 3, Weight = 1 },
						{ At = { 84, 32 }, Radius = 4, Weight = 3 },
					},
					Hazards = {
						{ Type = "Pit", At = { 84, 32 }, Radius = 4, Covered = true },
					},
					Decor = {
						{
							Kind = "Barnacles",
							Area = {
								{ 8, 8 },
								{ 88, 8 },
								{ 88, 56 },
								{ 8, 56 },
							},
							Count = 6,
						},
					},
				},
			},
		},
	},
}

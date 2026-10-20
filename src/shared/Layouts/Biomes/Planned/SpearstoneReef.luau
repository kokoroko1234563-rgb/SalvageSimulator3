-- Spearstone Reef: drawn with the layout kit from tools/kit/plans/spearstone_reef.py
-- (edit the plan and re-run it, not this file). Card: docs/design/cards/spearstone-reef.md.
return {
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
				Height = 18,
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, -12 },
					{ 360, -12 },
					{ 360, 12 },
					{ -360, 12 },
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
					{ -160, 120 },
					{ 160, 120 },
					{ 160, 192 },
					{ -160, 192 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -228, 252 },
					{ -112, 252 },
					{ -112, 352 },
					{ -228, 352 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ 112, 252 },
					{ 228, 252 },
					{ 228, 352 },
					{ 112, 352 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -72, 372 },
					{ 72, 372 },
					{ 72, 476 },
					{ -72, 476 },
				},
			},
		},
		Loot = {
			{ At = { 148, 156 }, Radius = 5, Weight = 2 },
			{ At = { -170, 302 }, Radius = 5, Weight = 3 },
			{ At = { 170, 302 }, Radius = 5, Weight = 3 },
			{ At = { 0, 424 }, Radius = 4, Weight = 5 },
		},
		Entrances = {
			{ -152, 130 },
		},
		Hazards = {
			{ Type = "Spears", At = { -100, 156 }, Radius = 34, Pattern = "Wave", Damage = 35 },
			{ Type = "Spears", At = { 0, 156 }, Radius = 34, Pattern = "Wave", Damage = 35 },
			{ Type = "Spears", At = { 100, 156 }, Radius = 34, Pattern = "Wave", Damage = 35 },
			{ Type = "Spears", At = { -170, 302 }, Radius = 44, Pattern = "Checker", Damage = 35 },
			{ Type = "Spears", At = { 150, 302 }, Radius = 40, Pattern = "Wave", Damage = 35 },
			{ Type = "Spears", At = { 190, 302 }, Radius = 40, Pattern = "Checker", Damage = 35 },
			{ Type = "Spears", At = { 0, 424 }, Radius = 44, Pattern = "Ring", Damage = 35 },
			{ Type = "Spears", At = { 0, 424 }, Radius = 26, Pattern = "Ring", Damage = 35 },
		},
		Decor = {
			{
				Kind = "Rocks",
				Area = {
					{ -150, 126 },
					{ 150, 126 },
					{ 150, 186 },
					{ -150, 186 },
				},
				Count = 6,
			},
			{ Kind = "Bones", At = { -148, 156 }, Scale = 1.1, Yaw = 20 },
			{
				Kind = "Barnacles",
				Area = {
					{ -220, 257 },
					{ -120, 257 },
					{ -120, 347 },
					{ -220, 347 },
				},
				Count = 5,
			},
			{ Kind = "Rocks", At = { -208, 340 }, Scale = 1.2, Yaw = 70 },
			{ Kind = "Bones", At = { 212, 262 }, Scale = 1.2, Yaw = 120 },
			{
				Kind = "Barnacles",
				Area = {
					{ 120, 257 },
					{ 220, 257 },
					{ 220, 347 },
					{ 120, 347 },
				},
				Count = 4,
			},
			{
				Kind = "Rocks",
				Area = {
					{ -65, 379 },
					{ 65, 379 },
					{ 65, 469 },
					{ -65, 469 },
				},
				Count = 5,
			},
			{ Kind = "Bones", At = { 52, 392 }, Scale = 1.3, Yaw = 300 },
		},
		Name = "Outer Spearstone",
		Crossings = {
			{
				Name = "Crossed fields",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -300, 0 },
							{ -300, 48 },
							{ 300, 48 },
							{ 300, 302 },
							{ 0, 302 },
							{ 0, 424 },
							{ 0, 512 },
							{ 0, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 54, 0 },
							{ 54, 88 },
							{ 66, 88 },
							{ 66, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 60, 82 },
							{ -336, 82 },
							{ -336, 94 },
							{ 60, 94 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -342, 88 },
							{ -342, 248 },
							{ -330, 248 },
							{ -330, 88 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -336, 254 },
							{ -264, 254 },
							{ -264, 242 },
							{ -336, 242 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -270, 248 },
							{ -270, 328 },
							{ -258, 328 },
							{ -258, 248 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -264, 322 },
							{ -336, 322 },
							{ -336, 334 },
							{ -264, 334 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -342, 328 },
							{ -342, 408 },
							{ -330, 408 },
							{ -330, 328 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -336, 414 },
							{ -264, 414 },
							{ -264, 402 },
							{ -336, 402 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -270, 408 },
							{ -270, 552 },
							{ -258, 552 },
							{ -258, 408 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -264, 558 },
							{ 0, 558 },
							{ 0, 546 },
							{ -264, 546 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -6, 552 },
							{ -6, 608 },
							{ 6, 608 },
							{ 6, 552 },
						},
					},
					{ Kind = "Flat", At = { 60, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 60, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 0, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 0, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -264, 310 },
							{ -200, 310 },
							{ -200, 298 },
							{ -264, 298 },
						},
					},
					{ Kind = "Flat", At = { -264, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { -200, 304 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -106, 88 },
							{ -106, 140 },
							{ -94, 140 },
							{ -94, 88 },
						},
					},
					{ Kind = "Flat", At = { -100, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -100, 140 }, Radius = 6 },
				},
				Decor = {
					{ Kind = "Rocks", At = { -288, 6 }, Scale = 1.4, Yaw = 30 },
					{ Kind = "Rocks", At = { -312, 6 }, Scale = 1.1, Yaw = 100 },
				},
			},
			{
				Name = "Checker hop",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 60, 0 },
							{ 60, 156 },
							{ -300, 156 },
							{ -300, 302 },
							{ 0, 302 },
							{ 0, 424 },
							{ 0, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 0 },
							{ 330, 232 },
							{ 342, 232 },
							{ 342, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 226 },
							{ 264, 226 },
							{ 264, 238 },
							{ 336, 238 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 232 },
							{ 258, 272 },
							{ 270, 272 },
							{ 270, 232 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 278 },
							{ 336, 278 },
							{ 336, 266 },
							{ 264, 266 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 272 },
							{ 330, 312 },
							{ 342, 312 },
							{ 342, 272 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 306 },
							{ 264, 306 },
							{ 264, 318 },
							{ 336, 318 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 312 },
							{ 258, 352 },
							{ 270, 352 },
							{ 270, 312 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 358 },
							{ 336, 358 },
							{ 336, 346 },
							{ 264, 346 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 352 },
							{ 330, 392 },
							{ 342, 392 },
							{ 342, 352 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 386 },
							{ 264, 386 },
							{ 264, 398 },
							{ 336, 398 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 392 },
							{ 258, 432 },
							{ 270, 432 },
							{ 270, 392 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 438 },
							{ 336, 438 },
							{ 336, 426 },
							{ 264, 426 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 432 },
							{ 330, 472 },
							{ 342, 472 },
							{ 342, 432 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 466 },
							{ 264, 466 },
							{ 264, 478 },
							{ 336, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 472 },
							{ 258, 512 },
							{ 270, 512 },
							{ 270, 472 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 518 },
							{ 336, 518 },
							{ 336, 506 },
							{ 264, 506 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 512 },
							{ 330, 552 },
							{ 342, 552 },
							{ 342, 512 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 546 },
							{ 264, 546 },
							{ 264, 558 },
							{ 336, 558 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 546 },
							{ 0, 546 },
							{ 0, 558 },
							{ 264, 558 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -6, 552 },
							{ -6, 608 },
							{ 6, 608 },
							{ 6, 552 },
						},
					},
					{ Kind = "Flat", At = { 336, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 232 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 232 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 512 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 512 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 0, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 0, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 0, 310 },
							{ 128, 310 },
							{ 128, 298 },
							{ 0, 298 },
						},
					},
					{ Kind = "Flat", At = { 0, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { 128, 304 }, Radius = 6 },
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 70, 8 }, Scale = 0.8, Yaw = 90 },
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
				Height = 18,
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, -12 },
					{ 360, -12 },
					{ 360, 12 },
					{ -360, 12 },
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
					{ -160, 120 },
					{ 160, 120 },
					{ 160, 192 },
					{ -160, 192 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -228, 252 },
					{ -112, 252 },
					{ -112, 352 },
					{ -228, 352 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ 112, 252 },
					{ 228, 252 },
					{ 228, 352 },
					{ 112, 352 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -72, 372 },
					{ 72, 372 },
					{ 72, 476 },
					{ -72, 476 },
				},
			},
		},
		Loot = {
			{ At = { 148, 156 }, Radius = 5, Weight = 2 },
			{ At = { -170, 302 }, Radius = 5, Weight = 3 },
			{ At = { 170, 302 }, Radius = 5, Weight = 3 },
			{ At = { 0, 424 }, Radius = 4, Weight = 5 },
		},
		Entrances = {
			{ 222, 262 },
		},
		Hazards = {
			{ Type = "Spears", At = { -100, 156 }, Radius = 34, Pattern = "Wave", Damage = 60 },
			{ Type = "Spears", At = { 0, 156 }, Radius = 34, Pattern = "Wave", Damage = 60 },
			{ Type = "Spears", At = { 100, 156 }, Radius = 34, Pattern = "Wave", Damage = 60 },
			{ Type = "Spears", At = { -170, 302 }, Radius = 44, Pattern = "Checker", Damage = 60 },
			{ Type = "Spears", At = { 150, 302 }, Radius = 40, Pattern = "Wave", Damage = 60 },
			{ Type = "Spears", At = { 190, 302 }, Radius = 40, Pattern = "Checker", Damage = 60 },
			{ Type = "Spears", At = { 0, 424 }, Radius = 44, Pattern = "Ring", Damage = 60 },
			{ Type = "Spears", At = { 0, 424 }, Radius = 26, Pattern = "Ring", Damage = 60 },
		},
		Decor = {
			{
				Kind = "Rocks",
				Area = {
					{ -150, 126 },
					{ 150, 126 },
					{ 150, 186 },
					{ -150, 186 },
				},
				Count = 6,
			},
			{ Kind = "Bones", At = { -148, 156 }, Scale = 1.1, Yaw = 20 },
			{
				Kind = "Barnacles",
				Area = {
					{ -220, 257 },
					{ -120, 257 },
					{ -120, 347 },
					{ -220, 347 },
				},
				Count = 5,
			},
			{ Kind = "Rocks", At = { -208, 340 }, Scale = 1.2, Yaw = 70 },
			{ Kind = "Bones", At = { 212, 262 }, Scale = 1.2, Yaw = 120 },
			{
				Kind = "Barnacles",
				Area = {
					{ 120, 257 },
					{ 220, 257 },
					{ 220, 347 },
					{ 120, 347 },
				},
				Count = 4,
			},
			{
				Kind = "Rocks",
				Area = {
					{ -65, 379 },
					{ 65, 379 },
					{ 65, 469 },
					{ -65, 469 },
				},
				Count = 5,
			},
			{ Kind = "Bones", At = { 52, 392 }, Scale = 1.3, Yaw = 300 },
		},
		Name = "Spearstone Shoals",
		Crossings = {
			{
				Name = "Crossed fields",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -300, 0 },
							{ -300, 48 },
							{ 336, 48 },
							{ 336, 88 },
							{ 264, 88 },
							{ 264, 128 },
							{ 336, 128 },
							{ 336, 168 },
							{ 264, 168 },
							{ 264, 208 },
							{ 336, 208 },
							{ 336, 302 },
							{ 0, 302 },
							{ 0, 424 },
							{ 0, 512 },
							{ 300, 512 },
							{ 300, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 54, 0 },
							{ 54, 88 },
							{ 66, 88 },
							{ 66, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 60, 82 },
							{ -336, 82 },
							{ -336, 94 },
							{ 60, 94 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -342, 88 },
							{ -342, 248 },
							{ -330, 248 },
							{ -330, 88 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -336, 254 },
							{ -264, 254 },
							{ -264, 242 },
							{ -336, 242 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -270, 248 },
							{ -270, 328 },
							{ -258, 328 },
							{ -258, 248 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -264, 322 },
							{ -336, 322 },
							{ -336, 334 },
							{ -264, 334 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -342, 328 },
							{ -342, 408 },
							{ -330, 408 },
							{ -330, 328 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -336, 414 },
							{ -264, 414 },
							{ -264, 402 },
							{ -336, 402 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -270, 408 },
							{ -270, 552 },
							{ -258, 552 },
							{ -258, 408 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -264, 558 },
							{ 240, 558 },
							{ 240, 546 },
							{ -264, 546 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 234, 552 },
							{ 234, 608 },
							{ 246, 608 },
							{ 246, 552 },
						},
					},
					{ Kind = "Flat", At = { 60, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 60, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 240, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 240, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -264, 310 },
							{ -200, 310 },
							{ -200, 298 },
							{ -264, 298 },
						},
					},
					{ Kind = "Flat", At = { -264, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { -200, 304 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -106, 88 },
							{ -106, 140 },
							{ -94, 140 },
							{ -94, 88 },
						},
					},
					{ Kind = "Flat", At = { -100, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -100, 140 }, Radius = 6 },
				},
				Hazards = {
					{ Type = "Spears", At = { 60, 512 }, Radius = 12, Pattern = "Wave", Damage = 60 },
					{ Type = "Spears", At = { 110, 512 }, Radius = 12, Pattern = "Checker", Damage = 60 },
					{ Type = "Spears", At = { 160, 512 }, Radius = 12, Pattern = "Wave", Damage = 60 },
					{ Type = "Spears", At = { 210, 512 }, Radius = 12, Pattern = "Checker", Damage = 60 },
				},
				Decor = {
					{ Kind = "Rocks", At = { -288, 6 }, Scale = 1.4, Yaw = 30 },
					{ Kind = "Rocks", At = { -312, 6 }, Scale = 1.1, Yaw = 100 },
				},
			},
			{
				Name = "Checker hop",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 60, 0 },
							{ 60, 156 },
							{ -300, 156 },
							{ -300, 302 },
							{ 0, 302 },
							{ 0, 424 },
							{ 0, 512 },
							{ 0, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 0 },
							{ 330, 232 },
							{ 342, 232 },
							{ 342, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 226 },
							{ 264, 226 },
							{ 264, 238 },
							{ 336, 238 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 232 },
							{ 258, 272 },
							{ 270, 272 },
							{ 270, 232 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 278 },
							{ 336, 278 },
							{ 336, 266 },
							{ 264, 266 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 272 },
							{ 330, 312 },
							{ 342, 312 },
							{ 342, 272 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 306 },
							{ 264, 306 },
							{ 264, 318 },
							{ 336, 318 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 312 },
							{ 258, 352 },
							{ 270, 352 },
							{ 270, 312 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 358 },
							{ 336, 358 },
							{ 336, 346 },
							{ 264, 346 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 352 },
							{ 330, 392 },
							{ 342, 392 },
							{ 342, 352 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 386 },
							{ 264, 386 },
							{ 264, 398 },
							{ 336, 398 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 392 },
							{ 258, 432 },
							{ 270, 432 },
							{ 270, 392 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 438 },
							{ 336, 438 },
							{ 336, 426 },
							{ 264, 426 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 432 },
							{ 330, 472 },
							{ 342, 472 },
							{ 342, 432 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 466 },
							{ 264, 466 },
							{ 264, 478 },
							{ 336, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 472 },
							{ 258, 512 },
							{ 270, 512 },
							{ 270, 472 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 518 },
							{ 336, 518 },
							{ 336, 506 },
							{ 264, 506 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 512 },
							{ 330, 552 },
							{ 342, 552 },
							{ 342, 512 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 546 },
							{ 264, 546 },
							{ 264, 558 },
							{ 336, 558 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 546 },
							{ -100, 546 },
							{ -100, 558 },
							{ 264, 558 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -106, 552 },
							{ -106, 608 },
							{ -94, 608 },
							{ -94, 552 },
						},
					},
					{ Kind = "Flat", At = { 336, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 232 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 232 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 512 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 512 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { -100, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { -100, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 0, 310 },
							{ 128, 310 },
							{ 128, 298 },
							{ 0, 298 },
						},
					},
					{ Kind = "Flat", At = { 0, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { 128, 304 }, Radius = 6 },
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 70, 8 }, Scale = 0.8, Yaw = 90 },
				},
			},
			{
				Name = "Spear corridor",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -300, 0 },
							{ -300, 48 },
							{ 0, 48 },
							{ 0, 424 },
							{ 0, 512 },
							{ 200, 512 },
							{ 200, 556 },
							{ -300, 556 },
							{ -300, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 0, 298 },
							{ -128, 298 },
							{ -128, 310 },
							{ 0, 310 },
						},
					},
					{ Kind = "Flat", At = { 0, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { -128, 304 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 0, 310 },
							{ 128, 310 },
							{ 128, 298 },
							{ 0, 298 },
						},
					},
					{ Kind = "Flat", At = { 0, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { 128, 304 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -126, 0 },
							{ -126, 88 },
							{ -114, 88 },
							{ -114, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -120, 94 },
							{ 336, 94 },
							{ 336, 82 },
							{ -120, 82 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 88 },
							{ 330, 248 },
							{ 342, 248 },
							{ 342, 88 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 242 },
							{ 264, 242 },
							{ 264, 254 },
							{ 336, 254 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 248 },
							{ 258, 328 },
							{ 270, 328 },
							{ 270, 248 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 334 },
							{ 336, 334 },
							{ 336, 322 },
							{ 264, 322 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 328 },
							{ 330, 408 },
							{ 342, 408 },
							{ 342, 328 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 402 },
							{ 264, 402 },
							{ 264, 414 },
							{ 336, 414 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 408 },
							{ 258, 472 },
							{ 270, 472 },
							{ 270, 408 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 478 },
							{ 336, 478 },
							{ 336, 466 },
							{ 264, 466 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 472 },
							{ 330, 596 },
							{ 342, 596 },
							{ 342, 472 },
						},
					},
					{ Kind = "Flat", At = { -120, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -120, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 596 }, Radius = 6 },
				},
				Hazards = {
					{ Type = "Spears", At = { 0, 214 }, Radius = 12, Pattern = "Wave", Damage = 60 },
					{ Type = "Spears", At = { 0, 246 }, Radius = 12, Pattern = "Checker", Damage = 60 },
					{ Type = "Spears", At = { 0, 278 }, Radius = 12, Pattern = "Wave", Damage = 60 },
					{ Type = "Spears", At = { 0, 334 }, Radius = 12, Pattern = "Ring", Damage = 60 },
				},
				Decor = {
					{
						Kind = "Chain",
						Path = {
							{ -310, 8 },
							{ -290, 8 },
						},
						Count = 2,
					},
					{ Kind = "Rocks", At = { -270, 8 }, Scale = 1.5, Yaw = 200 },
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
				Height = 18,
			},
			{
				Kind = "Flat",
				Area = {
					{ -360, -12 },
					{ 360, -12 },
					{ 360, 12 },
					{ -360, 12 },
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
					{ -160, 120 },
					{ 160, 120 },
					{ 160, 192 },
					{ -160, 192 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -228, 252 },
					{ -112, 252 },
					{ -112, 352 },
					{ -228, 352 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ 112, 252 },
					{ 228, 252 },
					{ 228, 352 },
					{ 112, 352 },
				},
			},
			{
				Kind = "Flat",
				Area = {
					{ -72, 372 },
					{ 72, 372 },
					{ 72, 476 },
					{ -72, 476 },
				},
			},
		},
		Loot = {
			{ At = { 148, 156 }, Radius = 5, Weight = 2 },
			{ At = { -170, 302 }, Radius = 5, Weight = 3 },
			{ At = { 170, 302 }, Radius = 5, Weight = 3 },
			{ At = { 0, 424 }, Radius = 4, Weight = 5 },
		},
		Entrances = {
			{ -64, 380 },
		},
		Hazards = {
			{ Type = "Spears", At = { -100, 156 }, Radius = 34, Pattern = "Wave", Damage = 100 },
			{ Type = "Spears", At = { 0, 156 }, Radius = 34, Pattern = "Wave", Damage = 100 },
			{ Type = "Spears", At = { 100, 156 }, Radius = 34, Pattern = "Wave", Damage = 100 },
			{ Type = "Spears", At = { -170, 302 }, Radius = 44, Pattern = "Checker", Damage = 100 },
			{ Type = "Spears", At = { 150, 302 }, Radius = 40, Pattern = "Wave", Damage = 100 },
			{ Type = "Spears", At = { 190, 302 }, Radius = 40, Pattern = "Checker", Damage = 100 },
			{ Type = "Spears", At = { 0, 424 }, Radius = 44, Pattern = "Ring", Damage = 100 },
			{ Type = "Spears", At = { 0, 424 }, Radius = 26, Pattern = "Ring", Damage = 100 },
		},
		Decor = {
			{
				Kind = "Rocks",
				Area = {
					{ -150, 126 },
					{ 150, 126 },
					{ 150, 186 },
					{ -150, 186 },
				},
				Count = 6,
			},
			{ Kind = "Bones", At = { -148, 156 }, Scale = 1.1, Yaw = 20 },
			{
				Kind = "Barnacles",
				Area = {
					{ -220, 257 },
					{ -120, 257 },
					{ -120, 347 },
					{ -220, 347 },
				},
				Count = 5,
			},
			{ Kind = "Rocks", At = { -208, 340 }, Scale = 1.2, Yaw = 70 },
			{ Kind = "Bones", At = { 212, 262 }, Scale = 1.2, Yaw = 120 },
			{
				Kind = "Barnacles",
				Area = {
					{ 120, 257 },
					{ 220, 257 },
					{ 220, 347 },
					{ 120, 347 },
				},
				Count = 4,
			},
			{
				Kind = "Rocks",
				Area = {
					{ -65, 379 },
					{ 65, 379 },
					{ 65, 469 },
					{ -65, 469 },
				},
				Count = 5,
			},
			{ Kind = "Bones", At = { 52, 392 }, Scale = 1.3, Yaw = 300 },
		},
		Name = "Spearstone Deep",
		Crossings = {
			{
				Name = "Crossed fields",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -300, 0 },
							{ -300, 48 },
							{ 336, 48 },
							{ 336, 88 },
							{ 264, 88 },
							{ 264, 128 },
							{ 336, 128 },
							{ 336, 168 },
							{ 264, 168 },
							{ 264, 208 },
							{ 336, 208 },
							{ 336, 302 },
							{ 0, 302 },
							{ 0, 424 },
							{ 0, 512 },
							{ 300, 512 },
							{ 300, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 54, 0 },
							{ 54, 88 },
							{ 66, 88 },
							{ 66, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 60, 82 },
							{ -336, 82 },
							{ -336, 94 },
							{ 60, 94 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -342, 88 },
							{ -342, 248 },
							{ -330, 248 },
							{ -330, 88 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -336, 254 },
							{ -264, 254 },
							{ -264, 242 },
							{ -336, 242 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -270, 248 },
							{ -270, 328 },
							{ -258, 328 },
							{ -258, 248 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -264, 322 },
							{ -336, 322 },
							{ -336, 334 },
							{ -264, 334 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -342, 328 },
							{ -342, 408 },
							{ -330, 408 },
							{ -330, 328 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -336, 414 },
							{ -264, 414 },
							{ -264, 402 },
							{ -336, 402 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -270, 408 },
							{ -270, 552 },
							{ -258, 552 },
							{ -258, 408 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -264, 558 },
							{ 240, 558 },
							{ 240, 546 },
							{ -264, 546 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 234, 552 },
							{ 234, 608 },
							{ 246, 608 },
							{ 246, 552 },
						},
					},
					{ Kind = "Flat", At = { 60, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 60, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { -264, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 240, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 240, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -264, 310 },
							{ -200, 310 },
							{ -200, 298 },
							{ -264, 298 },
						},
					},
					{ Kind = "Flat", At = { -264, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { -200, 304 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -106, 88 },
							{ -106, 140 },
							{ -94, 140 },
							{ -94, 88 },
						},
					},
					{ Kind = "Flat", At = { -100, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { -100, 140 }, Radius = 6 },
				},
				Hazards = {
					{ Type = "Spears", At = { 60, 512 }, Radius = 12, Pattern = "Wave", Damage = 100 },
					{ Type = "Spears", At = { 110, 512 }, Radius = 12, Pattern = "Checker", Damage = 100 },
					{ Type = "Spears", At = { 160, 512 }, Radius = 12, Pattern = "Wave", Damage = 100 },
					{ Type = "Spears", At = { 210, 512 }, Radius = 12, Pattern = "Checker", Damage = 100 },
				},
				Decor = {
					{ Kind = "Rocks", At = { -288, 6 }, Scale = 1.4, Yaw = 30 },
					{ Kind = "Rocks", At = { -312, 6 }, Scale = 1.1, Yaw = 100 },
				},
			},
			{
				Name = "Checker hop",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ 60, 0 },
							{ 60, 156 },
							{ -300, 156 },
							{ -300, 302 },
							{ 0, 302 },
							{ 0, 424 },
							{ 0, 512 },
							{ -300, 512 },
							{ -300, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 0 },
							{ 330, 232 },
							{ 342, 232 },
							{ 342, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 226 },
							{ 264, 226 },
							{ 264, 238 },
							{ 336, 238 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 232 },
							{ 258, 272 },
							{ 270, 272 },
							{ 270, 232 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 278 },
							{ 336, 278 },
							{ 336, 266 },
							{ 264, 266 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 272 },
							{ 330, 312 },
							{ 342, 312 },
							{ 342, 272 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 306 },
							{ 264, 306 },
							{ 264, 318 },
							{ 336, 318 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 312 },
							{ 258, 352 },
							{ 270, 352 },
							{ 270, 312 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 358 },
							{ 336, 358 },
							{ 336, 346 },
							{ 264, 346 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 352 },
							{ 330, 392 },
							{ 342, 392 },
							{ 342, 352 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 386 },
							{ 264, 386 },
							{ 264, 398 },
							{ 336, 398 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 392 },
							{ 258, 432 },
							{ 270, 432 },
							{ 270, 392 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 438 },
							{ 336, 438 },
							{ 336, 426 },
							{ 264, 426 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 432 },
							{ 330, 472 },
							{ 342, 472 },
							{ 342, 432 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 466 },
							{ 264, 466 },
							{ 264, 478 },
							{ 336, 478 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 472 },
							{ 258, 512 },
							{ 270, 512 },
							{ 270, 472 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 518 },
							{ 336, 518 },
							{ 336, 506 },
							{ 264, 506 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 512 },
							{ 330, 552 },
							{ 342, 552 },
							{ 342, 512 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 546 },
							{ 264, 546 },
							{ 264, 558 },
							{ 336, 558 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 546 },
							{ -240, 546 },
							{ -240, 558 },
							{ 264, 558 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -246, 552 },
							{ -246, 608 },
							{ -234, 608 },
							{ -234, 552 },
						},
					},
					{ Kind = "Flat", At = { 336, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 232 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 232 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 272 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 312 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 352 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 392 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 432 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 512 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 512 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { -240, 552 }, Radius = 6 },
					{ Kind = "Flat", At = { -240, 608 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 0, 310 },
							{ 128, 310 },
							{ 128, 298 },
							{ 0, 298 },
						},
					},
					{ Kind = "Flat", At = { 0, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { 128, 304 }, Radius = 6 },
				},
				Decor = {
					{ Kind = "WreckRibs", At = { 70, 8 }, Scale = 0.8, Yaw = 90 },
				},
			},
			{
				Name = "Spear corridor",
				Paths = 2,
				Primitives = {
					{
						Kind = "Ramp",
						Path = {
							{ -300, 0 },
							{ -300, 48 },
							{ 0, 48 },
							{ 0, 424 },
							{ 0, 512 },
							{ 200, 512 },
							{ 200, 556 },
							{ -300, 556 },
							{ -300, 608 },
						},
						Width = 16,
					},
					{
						Kind = "Flat",
						Area = {
							{ 0, 298 },
							{ -128, 298 },
							{ -128, 310 },
							{ 0, 310 },
						},
					},
					{ Kind = "Flat", At = { 0, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { -128, 304 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ 0, 310 },
							{ 128, 310 },
							{ 128, 298 },
							{ 0, 298 },
						},
					},
					{ Kind = "Flat", At = { 0, 304 }, Radius = 6 },
					{ Kind = "Flat", At = { 128, 304 }, Radius = 6 },
					{
						Kind = "Flat",
						Area = {
							{ -342, 0 },
							{ -342, 88 },
							{ -330, 88 },
							{ -330, 0 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ -336, 94 },
							{ 336, 94 },
							{ 336, 82 },
							{ -336, 82 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 88 },
							{ 330, 248 },
							{ 342, 248 },
							{ 342, 88 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 242 },
							{ 264, 242 },
							{ 264, 254 },
							{ 336, 254 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 248 },
							{ 258, 328 },
							{ 270, 328 },
							{ 270, 248 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 334 },
							{ 336, 334 },
							{ 336, 322 },
							{ 264, 322 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 328 },
							{ 330, 408 },
							{ 342, 408 },
							{ 342, 328 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 336, 402 },
							{ 264, 402 },
							{ 264, 414 },
							{ 336, 414 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 258, 408 },
							{ 258, 472 },
							{ 270, 472 },
							{ 270, 408 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 264, 478 },
							{ 336, 478 },
							{ 336, 466 },
							{ 264, 466 },
						},
					},
					{
						Kind = "Flat",
						Area = {
							{ 330, 472 },
							{ 330, 596 },
							{ 342, 596 },
							{ 342, 472 },
						},
					},
					{ Kind = "Flat", At = { -336, 0 }, Radius = 6 },
					{ Kind = "Flat", At = { -336, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 88 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 248 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 328 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 408 }, Radius = 6 },
					{ Kind = "Flat", At = { 264, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 472 }, Radius = 6 },
					{ Kind = "Flat", At = { 336, 596 }, Radius = 6 },
				},
				Hazards = {
					{ Type = "Spears", At = { 0, 214 }, Radius = 12, Pattern = "Wave", Damage = 100 },
					{ Type = "Spears", At = { 0, 246 }, Radius = 12, Pattern = "Checker", Damage = 100 },
					{ Type = "Spears", At = { 0, 278 }, Radius = 12, Pattern = "Wave", Damage = 100 },
					{ Type = "Spears", At = { 0, 334 }, Radius = 12, Pattern = "Ring", Damage = 100 },
				},
				Decor = {
					{
						Kind = "Chain",
						Path = {
							{ -310, 8 },
							{ -290, 8 },
						},
						Count = 2,
					},
					{ Kind = "Rocks", At = { -270, 8 }, Scale = 1.5, Yaw = 200 },
				},
			},
		},
	},
}

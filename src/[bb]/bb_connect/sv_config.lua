
--[[
  Southland RP: Character Creation Configuration (CLIENT)
  Created by Michael Harris (mike@harrisonline.us)
  03/26/2019
  
  This file stores commonly used values in a convenient location.
  
  Permission denied to edit, redistribute, or otherwise use this script.
--]]

-- Hash key's used for storing indexes and comparing
maleHash	 = GetHashKey("mp_m_freemode_01")
femaleHash = GetHashKey("mp_f_freemode_01")

-- Camera Coordinates for joining/create char/switch character
cams = {
	ped = { -- The ped's standing location
		beach 		= {x = -1730.05, y = -1008.15, z = 4.61, h = 300.82},
    vine      = {x = 713.87, y = 1216.69, z = 327.56, h = 0.0},
		clothes 	= {x = 428.66, y = -803.69, z = 29.49, h = 324.15},
    sel       = {x = -1042.00, y = -2743.11, z = 21.35, h = 320.0}
	},
	scr = { -- The screen position
		beach 		= {x = -1819.49, y = -1037.82, z = 45.00, h = 273.78},
    vine      = {x = 774.08, y = 1032.07, z = 350.0, h = 0.0},
		clothes 	= {x = 428.66, y = -803.69, z = 29.49, h = 324.15},
    sel       = {x = -1041.9, y = -2737.25, z = 21.07, h = 165.0}
	}
}

-- Eligible clothing items for new players
newbClothes = {
  shirt = {
    choices = {
      ["M"]   = {
        curr = 1,
        text = {[1] = 0, [2] = 1, [3] = 34, [4] = 44, [5] = 73, [6] = 91, [7] = 117, [8] = 226},
        draw = {[1] = 0, [2] = 5, [3] = 0,  [4] = 0,  [5] = 8,  [6] = 0,  [7] = 2,   [8] = 0}
      },
      ["F"] = {
        curr = 1,
        text = {[1] = 0, [2] = 2, [3] = 3, [4] = 16, [5] = 9, [6] = 23, [7] = 109, [8] = 118, [9] = 169, [10] = 212},
        draw = {[1] = 0, [2] = 8, [3] = 1, [4] = 4,  [5] = 9, [6] = 2,  [7] = 0,   [8] = 2,   [9] = 0,   [10] = 3}
      }
    },
  },
  pants = {
    choices = {
      ["M"]   = {
        curr = 1,
        text = {[1] = 0, [2] = 1, [3] = 4, [4] = 15, [5] = 86, [6] = 90, [7] = 103},
        draw = {[1] = 0, [2] = 0, [3] = 1, [4] = 3,  [5] = 3,  [6] = 0,  [7] = 6}
      },
      ["F"] = {
        curr = 1,
        text = {[1] = 0, [2] = 2, [3] = 5, [4] = 12, [5] = 16, [6] = 25, [7] = 74, [8] = 91, [9] = 110},
        draw = {[1] = 0, [2] = 2, [3] = 8, [4] = 1,  [5] = 11, [6] = 0,  [7] = 5,  [8] = 3,  [9] = 0}
      }
    },
  },
  shoes = {
    choices = {
      ["M"]   = {
        curr = 1,
        text = {[1] = 3, [2] = 5, [3] = 9, [4] = 12, [5] = 34},
        draw = {[1] = 0, [2] = 2, [3] = 0, [4] = 0,  [5] = 0}
      },
      ["F"] = {
        curr = 1,
        text = {[1] = 3, [2] = 5, [3] = 13, [4] = 14, [5] = 24, [6] = 35, [7] = 42},
        draw = {[1] = 0, [2] = 0, [3] = 0,  [4] = 0,  [5] = 0,  [6] = 0,  [7] = 2}
      }
    }
  }
}


--[[--------------------------------------------------------------------
  HARD CODED VALUES; NOT TO BE MODIFIED
--]]---
overlaySet	= {
  ["M"] = {
	  [0]   = {index = 255, col1 = 0, col2 = 0, max = 23},
	  [1]	  = {index = 255, col1 = 0, col2 = 0, max = 28},
	  [2]	  = {index = 255, col1 = 0, col2 = 0, max = 33},
	  [3]   = {index = 255, col1 = 0, col2 = 0, max = 14},
	  [4]	  = {index = 255, col1 = 0, col2 = 0, max = 74},
	  [5]	  = {index = 255, col1 = 0, col2 = 0, max = 6},
	  [6]   = {index = 255, col1 = 0, col2 = 0, max = 11},
	  [7]   = {index = 255, col1 = 0, col2 = 0, max = 10},
	  [8]	  = {index = 255, col1 = 0, col2 = 0, max = 9},
	  [9]   = {index = 255, col1 = 0, col2 = 0, max = 17},
	  [10]  = {index = 255, col1 = 0, col2 = 0, max = 16},
	  [11]	= {index = 255, col1 = 0, col2 = 0, max = 11},
	  [12]	= {index = 255, col1 = 0, col2 = 0, max = 1}
  },
  ["F"] = {
	  [0]   = {index = 255, col1 = 0, col2 = 0, max = 23},
	  [1]	  = {index = 255, col1 = 0, col2 = 0, max = 28},
	  [2]	  = {index = 255, col1 = 0, col2 = 0, max = 33},
	  [3]   = {index = 255, col1 = 0, col2 = 0, max = 14},
	  [4]	  = {index = 255, col1 = 0, col2 = 0, max = 74},
	  [5]	  = {index = 255, col1 = 0, col2 = 0, max = 6},
	  [6]   = {index = 255, col1 = 0, col2 = 0, max = 11},
	  [7]   = {index = 255, col1 = 0, col2 = 0, max = 10},
	  [8]	  = {index = 255, col1 = 0, col2 = 0, max = 9},
	  [9]   = {index = 255, col1 = 0, col2 = 0, max = 17},
	  [10]  = {index = 255, col1 = 0, col2 = 0, max = 16},
	  [11]	= {index = 255, col1 = 0, col2 = 0, max = 11},
	  [12]	= {index = 255, col1 = 0, col2 = 0, max = 1}
  }
}
faceFeats = {
  ["M"] = {
	  [0]  = 0, [1]  = 0, [2]  = 0, [3]  = 0,
	  [4]  = 0, [5]  = 0,	[6]  = 0,	[7]  = 0,
	  [8]  = 0,	[9]  = 0,	[10] = 0,	[11] = 0,
	  [12] = 0,	[13] = 0,	[14] = 0,	[15] = 0
  },
  ["F"] = {
	  [0]  = 0, [1]  = 0, [2]  = 0, [3]  = 0,
	  [4]  = 0, [5]  = 0,	[6]  = 0,	[7]  = 0,
	  [8]  = 0,	[9]  = 0,	[10] = 0,	[11] = 0,
	  [12] = 0,	[13] = 0,	[14] = 0,	[15] = 0
  }
}
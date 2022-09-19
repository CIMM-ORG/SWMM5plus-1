module define_xsect_tables

    implicit none
    !==========================================================================
    ! Circular Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull
    integer, parameter :: NYCirc = 51
    real(8), dimension(NYCirc) :: YCirc = (/0.0, 0.05236, 0.08369, 0.11025, 0.13423, 0.15643,    &
        0.17755, 0.19772, 0.21704, 0.23581, 0.25412, 0.27194, 0.28948, 0.30653, 0.32349,      &
        0.34017, 0.35666, 0.37298, 0.38915, 0.40521, 0.42117, 0.43704, 0.45284, 0.46858,      &
        0.48430, 0.50000, 0.51572, 0.53146, 0.54723, 0.56305, 0.57892, 0.59487, 0.61093,      &
        0.62710, 0.64342, 0.65991, 0.67659, 0.69350, 0.71068, 0.72816, 0.74602, 0.76424,      &
        0.78297, 0.80235, 0.82240, 0.84353, 0.86563, 0.88970, 0.91444, 0.94749, 1.000 /)
    !% A/Afull v. Y/Yfull
    integer, parameter :: NACirc = 51
    real(8), dimension(NACirc) :: ACirc = (/0.0, 0.00471, 0.0134, 0.024446, 0.0374, 0.05208,     &
        0.0680, 0.08505, 0.1033, 0.12236, 0.1423, 0.16310, 0.1845, 0.20665, 0.2292, 0.25236,  &
        0.2759, 0.29985, 0.3242, 0.34874, 0.3736, 0.39878, 0.4237, 0.44907, 0.4745, 0.50000,  &
        0.5255, 0.55093, 0.5763, 0.60135, 0.6264, 0.65126, 0.6758, 0.70015, 0.7241, 0.74764,  &
        0.7708, 0.79335, 0.8154, 0.8369,  0.8576, 0.87764, 0.8967, 0.91495, 0.9320, 0.94792,  &
        0.9626, 0.97555, 0.9866, 0.9947,  1.000/)
    !% R/Rfull v. Y/Yfull
    integer, parameter :: NRCirc = 51
    real(8), dimension(NRCirc) :: RCirc = (/0.01, 0.0528, 0.1048, 0.1556, 0.2052, 0.2540,        &
        0.3016, 0.3484, 0.3944, 0.4388, 0.4824, 0.5248, 0.5664, 0.6064, 0.6456, 0.6836,       &
        0.7204, 0.7564, 0.7912, 0.8244, 0.8568, 0.8880, 0.9176, 0.9464, 0.9736, 1.0000,       &
        1.0240, 1.0480, 1.0700, 1.0912, 1.1100, 1.1272, 1.1440, 1.1596, 1.1740, 1.1848,       &
        1.1940, 1.2024, 1.2100, 1.2148, 1.2170, 1.2172, 1.2150, 1.2104, 1.2030, 1.1920,       &
        1.1780, 1.1584, 1.1320, 1.0940, 1.000/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTCirc = 51
    real(8), dimension(NTCirc) :: TCirc = (/0.0, 0.2800, 0.3919, 0.4750, 0.5426, 0.6000, 0.6499, &
        0.6940, 0.7332, 0.7684, 0.8000, 0.8285, 0.8542, 0.8773, 0.8980, 0.9165, 0.9330,       &
        0.9474, 0.9600, 0.9708, 0.9798, 0.9871, 0.9928, 0.9968, 0.9992, 1.0000, 0.9992,       &
        0.9968, 0.9928, 0.9871, 0.9798, 0.9708, 0.9600, 0.9474, 0.9330, 0.9165, 0.8980,       &
        0.8773, 0.8542, 0.8285, 0.8000, 0.7684, 0.7332, 0.6940, 0.6499, 0.6000, 0.5426,       &
        0.4750, 0.3919, 0.2800, 0.0/)
    
    !==========================================================================
    ! Basket Handle Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull
    integer, parameter :: NYBasketHandle = 51
    real(8), dimension(NYBasketHandle) :: YBasketHandle = (/0.0, 0.04112, 0.0738,  0.1,     0.12236, &
        0.14141, 0.15857, 0.17462, 0.18946, 0.20315, 0.21557, 0.22833, 0.2423,  0.25945, 0.27936, &
        0.3,     0.3204,  0.34034, 0.35892, 0.37595, 0.39214, 0.40802, 0.42372, 0.43894, 0.45315, &
        0.46557, 0.47833, 0.4923,  0.50945, 0.52936, 0.55,    0.57,    0.59,    0.61023, 0.63045, &
        0.65,    0.66756, 0.68413, 0.7,     0.71481, 0.72984, 0.74579, 0.76417, 0.78422, 0.80477, &
        0.82532, 0.85,    0.88277, 0.915,   0.95,    1.0/)
    !% A/Afull v. Y/Yfull
    integer, parameter :: NABasketHandle = 26
    real(8), dimension(NABasketHandle) :: ABasketHandle = (/0.0000, 0.0173, 0.0457, 0.0828, &
        0.1271, 0.1765, 0.2270, 0.2775, 0.3280, 0.3780, 0.4270, 0.4765, 0.5260, 0.5740, &
        0.6220, 0.6690, 0.7160, 0.7610, 0.8030, 0.8390, 0.8770, 0.9110, 0.9410, 0.9680, &
        0.9880, 1.000/)
    !% R/Rfull v. Y/Yfull
    integer, parameter :: NRBasketHandle = 26
    real(8), dimension(NRBasketHandle) :: RBasketHandle = (/0.0100, 0.0952, 0.1890, 0.2730, &
        0.3690, 0.4630, 0.5600, 0.6530, 0.7430, 0.8220, 0.8830, 0.9490, 0.9990, 1.055, &
        1.095,  1.141,  1.161,  1.188,  1.206,  1.206,  1.206,  1.205,  1.196,  1.168, &
        1.127,  1.000/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTBasketHandle = 26
    real(8), dimension(NTBasketHandle) :: TBasketHandle = (/0.0, 0.49, 0.667, 0.82,  0.93,  &
        1.00,  1.00,  1.00,  0.997, 0.994, 0.988, 0.982, 0.967, 0.948, 0.928, 0.904, 0.874, &
        0.842, 0.798, 0.75,  0.697, 0.637, 0.567, 0.467, 0.342, 0.0/)
    
    !==========================================================================
    ! Egg Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull
    integer, parameter :: NYEGG = 51
    real(8), dimension(NYEGG) :: YEgg = (/0.0, 0.04912, 0.08101, 0.11128, 0.14161, 0.16622, &
        0.18811, 0.21356, 0.23742, 0.25742, 0.27742, 0.29741, 0.31742, 0.33742, 0.35747, &
        0.37364, 0.4,     0.41697, 0.43372, 0.45,    0.46374, 0.47747, 0.49209, 0.50989, &
        0.53015, 0.55,    0.56429, 0.57675, 0.58834, 0.6,     0.61441, 0.62967, 0.64582, &
        0.66368, 0.68209, 0.7,     0.71463, 0.72807, 0.74074, 0.75296, 0.765,   0.77784, &
        0.79212, 0.80945, 0.82936, 0.85,    0.86731, 0.88769, 0.914,   0.95,    1.0/)
    !% A/Afull v. Y/Yfull
    integer, parameter :: NAEgg = 26
    real(8), dimension(NAEgg) :: AEgg = (/0.0000, 0.0150, 0.0400, 0.0550, 0.0850, 0.1200, &
        0.1555, 0.1900, 0.2250, 0.2750, 0.3200, 0.3700, 0.4200, 0.4700, 0.5150, 0.5700, &
        0.6200, 0.6800, 0.7300, 0.7800, 0.8350, 0.8850, 0.9250, 0.9550, 0.9800, 1.000/)
    !% R/Rfull v. Y/Yfull
    integer, parameter :: NREgg = 26
    real(8), dimension(NREgg) :: REgg = (/0.0100, 0.0970, 0.2160, 0.3020, 0.3860, 0.4650, &
        0.5360, 0.6110, 0.6760, 0.7350, 0.7910, 0.8540, 0.9040, 0.9410, 1.008, 1.045,  &
        1.076,  1.115,  1.146,  1.162,  1.186,  1.193,  1.186,  1.162,  1.107, 1.000/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTEgg = 26
    real(8), dimension(NTEgg) :: TEgg = (/0.0, 0.2980, 0.4330, 0.5080, 0.5820, 0.6420, 0.6960, &
        0.7460, 0.7910, 0.8360, 0.8660, 0.8960, 0.9260, 0.9560, 0.9700, 0.9850, 1.000, &
        0.9850, 0.9700, 0.9400, 0.8960, 0.8360, 0.7640, 0.6420, 0.3100, 0.0/)
    
    !==========================================================================
    ! Horseshoe Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull
    integer, parameter :: NYHorseShoe = 51
    real(8), dimension(NYHorseShoe) :: YHorseShoe = (/0.0, 0.04146, 0.07033, 0.09098, 0.10962, &
        0.12921, 0.14813, 0.16701, 0.18565, 0.20401, 0.22211, 0.23998, 0.25769, 0.27524, &
        0.29265, 0.3099,  0.32704, 0.34406, 0.36101, 0.3779,  0.39471, 0.41147, 0.42818, &
        0.44484, 0.46147, 0.47807, 0.49468, 0.51134, 0.52803, 0.54474, 0.56138, 0.57804, &
        0.59478, 0.61171, 0.62881, 0.64609, 0.6635,  0.68111, 0.69901, 0.71722, 0.73583, &
        0.7549,  0.77447, 0.79471, 0.81564, 0.83759, 0.86067, 0.88557, 0.91159, 0.9452,  &
        1.0/)
    !% A/Afull v. Y/Yfull
    integer, parameter :: NAHorseShoe = 26
    real(8), dimension(NAHorseShoe) :: AHorseShoe = (/0.0000, 0.0181, 0.0508, 0.0908, 0.1326, &
        0.1757, 0.2201, 0.2655, 0.3118, 0.3587, 0.4064, 0.4542, 0.5023, 0.5506, 0.5987, &
        0.6462, 0.6931, 0.7387, 0.7829, 0.8253, 0.8652, 0.9022, 0.9356, 0.9645, 0.9873, &
        1.000/)
    !% R/Rfull v. Y/Yfull
    integer, parameter :: NRHorseShoe = 26
    real(8), dimension(NRHorseShoe) :: RHorseShoe = (/0.0100, 0.1040, 0.2065, 0.3243, 0.4322, &
        0.5284, 0.6147, 0.6927, 0.7636, 0.8268, 0.8873, 0.9417, 0.9905, 1.036,  1.077, &
        1.113,  1.143,  1.169,  1.189,  1.202,  1.208,  1.206,  1.195,  1.170,  1.126, &
        1.000/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTHorseShoe = 26
    real(8), dimension(NTHorseShoe) :: THorseShoe = (/0.0000, 0.5878, 0.8772, 0.8900, 0.9028, &
        0.9156, 0.9284, 0.9412, 0.9540, 0.9668, 0.9798, 0.9928, 0.9992, 0.9992, 0.9928, &
        0.9798, 0.9600, 0.9330, 0.8980, 0.8542, 0.8000, 0.7332, 0.6499, 0.5426, 0.3919, &
        0.000/)
    !==========================================================================
    ! Catenary Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull
    integer, parameter :: NYCatenary = 51
    real(8), dimension(NYCatenary) :: YCatenary = (/0.0, 0.02974, 0.06439, 0.08433, 0.10549, &
        0.12064, 0.13952, 0.1556,  0.17032, 0.18512, 0.20057, 0.21995, 0.24011, 0.25892, &
        0.27595, 0.29214, 0.30802, 0.32372, 0.33894, 0.35315, 0.36557, 0.37833, 0.3923,  &
        0.4097,  0.42982, 0.45,    0.46769, 0.48431, 0.5,     0.51466, 0.52886, 0.54292, &
        0.55729, 0.57223, 0.5878,  0.60428, 0.62197, 0.64047, 0.6598,  0.67976, 0.7,     &
        0.71731, 0.73769, 0.76651, 0.8,     0.8209,  0.84311, 0.87978, 0.91576, 0.95,    &
        1.0 /)
    !% A/Afull v. Y/Yfull (generated from the table above)
    integer, parameter :: NACatenary = 51
    real(8), dimension(NACatenary) :: ACatenary = (/0.0, 0.01345, 0.02592, 0.03747, 0.05566, &
        0.07481, 0.09916, 0.12059, 0.14598, 0.17308, 0.19926, 0.22005, 0.23989, 0.26127, &
        0.28500, 0.30989, 0.33526, 0.36149, 0.39103, 0.42239, 0.44885, 0.47024, 0.49008, &
        0.51130, 0.53481, 0.56,    0.58752, 0.61585, 0.64363, 0.66998, 0.69481, 0.71777, &
        0.73949, 0.76020, 0.78024, 0.8,     0.82264, 0.84160, 0.85548, 0.86806, 0.88,    &
        0.89913, 0.91719, 0.92921, 0.94012, 0.95124, 0.96248, 0.97416, 0.984,   0.992,   &
        1.0/)
    !% S/Sfull v. A/Afull (Used for hydraulic radius)
    integer, parameter :: NSCatenary = 51
    real(8), dimension(NSCatenary) :: SCatenary = (/0.0, 0.00605, 0.01455, 0.0254,  0.03863, &
        0.0543,  0.07127, 0.08778, 0.10372, 0.12081, 0.14082, 0.16375, 0.18779, 0.21157, &
        0.23478, 0.25818, 0.28244, 0.30741, 0.33204, 0.35505, 0.37465, 0.39404, 0.41426, &
        0.43804, 0.46531, 0.49357, 0.52187, 0.54925, 0.57647, 0.60321, 0.62964, 0.65639, &
        0.68472, 0.71425, 0.74303, 0.76827, 0.79168, 0.815,   0.84094, 0.86707, 0.89213, &
        0.91607, 0.94,    0.96604, 0.99,    1.00714, 1.02158, 1.03814, 1.05,    1.05,    &
        1.0/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTCatenary = 21
    real(8), dimension(NTCatenary) :: TCatenary = (/0.0,    0.6667,  0.8222,  0.9111,  &
        0.9778,  1.0000,  1.0000,  0.9889,  0.9778, 0.9556,  0.9333,  0.8889,  &
        0.8444,  0.8000,  0.7556,  0.7000,  0.6333, 0.5556,  0.4444,  0.3333,  &
        0.0/)
    !==========================================================================
    ! Gothic Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull
    integer, parameter :: NYGothic = 51
    real(8), dimension(NYGothic) :: YGothic = (/0.0, 0.04522, 0.07825, 0.10646, 0.12645, &
        0.14645, 0.16787, 0.18641, 0.20129, 0.22425, 0.24129, 0.25624, 0.27344, 0.29097, &
        0.30529, 0.32607, 0.33755, 0.35073, 0.36447, 0.37558, 0.4,     0.4181,  0.43648, &
        0.45374, 0.46805, 0.48195, 0.49626, 0.51352, 0.5319,  0.55,    0.56416, 0.57787, &
        0.59224, 0.6095,  0.62941, 0.65,    0.67064, 0.69055, 0.70721, 0.72031, 0.73286, &
        0.74632, 0.76432, 0.78448, 0.80421, 0.82199, 0.84363, 0.87423, 0.90617, 0.93827, &
        1.0/)
    !% A/Afull v. Y/Yfull (generated from the table above)
    integer, parameter :: NAGothic = 51
    real(8), dimension(NAGothic) :: AGothic = (/0.0, 0.00885, 0.01769, 0.02895, 0.04124, &
        0.05542, 0.07355, 0.09355, 0.11265, 0.13309, 0.15827, 0.17629, 0.19849, 0.22437, &
        0.24748, 0.27261, 0.29416, 0.32372, 0.35349, 0.38362, 0.4    , 0.42207, 0.44408, &
        0.46875, 0.49719, 0.52433, 0.54705, 0.56895, 0.59412, 0.62296, 0.64899, 0.67055, &
        0.69029, 0.70968, 0.72940, 0.75134, 0.77953, 0.81061, 0.83519, 0.85556, 0.87573, &
        0.89776, 0.91665, 0.93069, 0.94361, 0.95614, 0.96862, 0.98056, 0.98704, 0.99352, &
        1.0/)
    !% S/Sfull v. A/Afull (Used for hydraulic radius)
    integer, parameter :: NSGothic = 51
    real(8), dimension(NSGothic) :: SGothic = (/0.0, 0.005,   0.0174,  0.03098, 0.04272, &
        0.055,   0.0698,  0.0862,  0.10461, 0.12463, 0.145,   0.16309, 0.18118, 0.2,     &
        0.22181, 0.24487, 0.26888, 0.2938,  0.31901, 0.34389, 0.36564, 0.38612, 0.4072,  &
        0.43,    0.45868, 0.48895, 0.52,    0.55032, 0.5804,  0.61,    0.63762, 0.66505, &
        0.6929,  0.72342, 0.75467, 0.785,   0.81165, 0.83654, 0.86,    0.88253, 0.90414, &
        0.925,   0.94486, 0.96475, 0.98567, 1.00833, 1.03,    1.0536,  1.065,   1.055,   &
        1.0/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTGothic = 21
    real(8), dimension(NTGothic) :: TGothic = (/0.0,   0.286,   0.643,   0.762,   0.833,  &
        0.905,   0.952,   0.976,   0.976,   1.0,     1.0,     0.976,   0.976,   0.952,    &
        0.905,   0.833,   0.762,   0.667,   0.524,   0.357,   0.0/)
    !==========================================================================
    ! Semi-circular Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull
    integer, parameter :: NYSemiCircular = 51
    real(8), dimension(NYSemiCircular) :: YSemiCircular = (/0.0, 0.04102, 0.07407, 0.1,     &
        0.11769, 0.13037, 0.14036, 0.15,    0.16546,      0.18213, 0.2,     0.22018, &
        0.2403,  0.25788, 0.27216, 0.285,   0.29704,      0.30892, 0.32128, 0.33476, &
        0.35,    0.36927, 0.38963, 0.41023, 0.43045,      0.45,    0.46769, 0.48431, &
        0.5,     0.51443, 0.52851, 0.54271, 0.55774,      0.57388, 0.59101, 0.60989, &
        0.63005, 0.65,    0.66682, 0.68318, 0.7,          0.71675, 0.73744, 0.76651, &
        0.8,     0.8209,  0.84311, 0.87978, 0.91576,      0.95, 1.0/)
    !% A/Afull v. Y/Yfull (generated from the table above)
    integer, parameter :: NASemiCircular = 51
    real(8), dimension(NASemiCircular) :: ASemiCircular = (/0.0, 0.00975, 0.01950, 0.03149, &
    0.04457, 0.06,    0.08364, 0.11928, 0.15294, 0.17744, 0.2,     0.21982, 0.23970, &
    0.26297, 0.29221, 0.32498, 0.3579,  0.38688, 0.41038, 0.43054, 0.45007, 0.46966, &
    0.48976, 0.51131, 0.53481, 0.56,    0.58791, 0.61618, 0.64280, 0.66715, 0.68952, &
    0.71003, 0.72997, 0.75189, 0.77611, 0.8,     0.82314, 0.84176, 0.85552, 0.86806, &
    0.88,    0.89913, 0.91719, 0.92921, 0.94012, 0.95124, 0.96248, 0.97416, 0.984,   &
    0.992,   1.0/)
    !% S/Sfull v. A/Afull (Used for hydraulic radius)
    integer, parameter :: NSSemiCircular = 51
    real(8), dimension(NSSemiCircular) :: SSemiCircular = (/0.0, 0.00757, 0.01815, 0.03,    &
    0.0358,  0.04037, 0.04601, 0.055,   0.07475, 0.09834, 0.125,   0.1557,  0.18588, &
    0.20883, 0.223,   0.23472, 0.24667, 0.26758, 0.29346, 0.32124, 0.35,    0.3772,  &
    0.4054,  0.43541, 0.46722, 0.5,     0.53532, 0.56935, 0.6,     0.61544, 0.62811, &
    0.6417,  0.66598, 0.7001,  0.73413, 0.76068, 0.78027, 0.8,     0.82891, 0.85964, &
    0.89,    0.9127,  0.93664, 0.96677, 1.0,     1.02661, 1.04631, 1.05726, 1.06637, &
    1.06,    1.0/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTSemiCircular = 21
    real(8), dimension(NTSemiCircular) :: TSemiCircular = (/0.0, 0.5488,  0.8537,  1.0000,  &
        1.0000,  0.9939,  0.9878,  0.9756,  0.9634, 0.9451,  0.9207,  0.8902,  0.8537, &
        0.8171,  0.7683,  0.7073,  0.6463,  0.5732,  0.4756,  0.3354,  0.0/)
    !==========================================================================
    ! Semi-elliptical Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull
    integer, parameter :: NYSemiEllip = 51
    real(8), dimension(NYSemiEllip) :: YSemiEllip = (/0.0, 0.03075, 0.05137, 0.07032, 0.09,   &
        0.11323, 0.13037, 0.14519, 0.15968, 0.18459, 0.19531, 0.21354, 0.22694, 0.23947, &
        0.25296, 0.265,   0.27784, 0.29212, 0.3097,  0.32982, 0.35,    0.36738, 0.3839,  &
        0.4,     0.41667, 0.43333, 0.45,    0.46697, 0.48372, 0.5,     0.51374, 0.52747, &
        0.54209, 0.5595,  0.57941, 0.6,     0.62,    0.64,    0.66,    0.68,    0.7,     &
        0.71843, 0.73865, 0.76365, 0.7926,  0.82088, 0.85,    0.88341, 0.90998, 0.93871, &
        1.0/)
    !% A/Afull v. Y/Yfull (generated from the table above)
    integer, parameter :: NASemiEllip = 51
    real(8), dimension(NASemiEllip) :: ASemiEllip = (/0.0, 0.01301, 0.02897, 0.04911, 0.06984, &
        0.08861, 0.1079,  0.133,   0.16026, 0.17631, 0.20515, 0.22964, 0.26079, 0.29169, &
        0.32303, 0.34896, 0.37024, 0.39009, 0.41151, 0.43528, 0.46,    0.484,   0.508,   &
        0.53179, 0.55556, 0.58,    0.60912, 0.63714, 0.6605,  0.68057, 0.7,     0.72,    &
        0.74,    0.76,    0.78,    0.8,     0.82155, 0.84108, 0.85708, 0.8713,  0.88523, &
        0.89938, 0.91313, 0.92599, 0.93796, 0.95249, 0.96698, 0.98042, 0.98695, 0.99347, &
        1.0/)
    !% S/Sfull v. A/Afull (Used for hydraulic radius)
    integer, parameter :: NSSemiEllip = 51
    real(8), dimension(NSSemiEllip) :: SSemiEllip = (/0.0, 0.00438, 0.01227, 0.02312, 0.03638, &
        0.05145, 0.06783, 0.085,   0.10093, 0.11752, 0.1353,  0.15626, 0.17917, 0.20296, &
        0.22654, 0.24962, 0.27269, 0.29568, 0.31848, 0.34152, 0.365,   0.38941, 0.41442, &
        0.44,    0.46636, 0.49309, 0.52,    0.54628, 0.57285, 0.6,     0.62949, 0.65877, &
        0.68624, 0.71017, 0.73304, 0.75578, 0.77925, 0.80368, 0.83114, 0.8595,  0.88592, &
        0.90848, 0.93,    0.95292, 0.97481, 0.99374, 1.01084, 1.02858, 1.04543, 1.05,    &
        1.0/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTSemiEllip = 21
    real(8), dimension(NTSemiEllip) :: TSemiEllip = (/0.0, 0.7000,  0.9800,  1.0000,  1.0000,  &
        1.0000,  0.9900,  0.9800, 0.9600, 0.9400,  0.9100,  0.8800,  0.8400,  0.8000,  &
        0.7500,  0.7000,  0.6400, 0.5600, 0.4600,  0.3400,  0.0/)
    !==========================================================================
    ! Arch Shape
    !==========================================================================
    !% Y/Yfull v. A/Afull (generated from the table below)
    integer, parameter :: NYArch = 26
    real(8), dimension(NYArch) :: YArch = (/0.0, 0.06, 0.1, 0.14, 0.176, 0.208, 0.24, &
        0.272,  0.304, 0.336, 0.368, 0.4, 0.432, 0.464, 0.496, 0.528, 0.56, 0.592, &
        0.62667, 0.66222, 0.7, 0.74, 0.78286, 0.82857, 0.88, 1.0/)
    !% A/Afull v. Y/Yfull 
    integer, parameter :: NAArch = 26
    real(8), dimension(NAArch) :: AArch = (/0.0, 0.0200, 0.0600, 0.1000, 0.1400, 0.1900, &
        0.2400, 0.2900, 0.3400, 0.3900, 0.4400, 0.4900, 0.5400, 0.5900, 0.6400, 0.6900, &
        0.7350, 0.7800, 0.8200, 0.8600, 0.8950, 0.9300, 0.9600, 0.9850, 0.9950, 1.000/)
    !% S/Sfull v. A/Afull (Used for hydraulic radius)
    integer, parameter :: NRArch = 26
    real(8), dimension(NRArch) :: RArch = (/0.0100, 0.0983, 0.1965, 0.2948, 0.3940, 0.4962, &
        0.5911, 0.6796, 0.7615, 0.8364, 0.9044, 0.9640, 1.018, 1.065, 1.106, 1.142, 1.170, &
        1.192, 1.208, 1.217, 1.220, 1.213, 1.196, 1.168, 1.112, 1.000/)
    !%T/Tmax v. Y/Yfull
    integer, parameter :: NTArch = 26
    real(8), dimension(NTArch) :: TArch = (/0.0, 0.6272, 0.8521, 0.9243, 0.9645, 0.9846, &
        0.9964, 0.9988, 0.9917, 0.9811, 0.9680, 0.9515, 0.9314, 0.9101, 0.8864, 0.8592, &
        0.8284, 0.7917, 0.7527, 0.7065, 0.6544, 0.5953, 0.5231, 0.4355, 0.3195, 0.0/)
    !==========================================================================
    ! End of module
    !==========================================================================
end module define_xsect_tables
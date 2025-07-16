section .data

_endscrol_txt:
incbin "data/ENDSCROL.TXT"
_endscrol_txt__end:

_troll_up:
incbin "data/TROLL.UP"
_troll_up__end:

_u2a_001:
incbin "data/U2A.001"
_u2a_001__end:

_u2a_002:
incbin "data/U2A.002"
_u2a_002__end:

_u2a_003:
incbin "data/U2A.003"
_u2a_003__end:

_u2a_00m:
incbin "data/U2A.00M"
_u2a_00m__end:

_u2a_0aa:
incbin "data/U2A.0AA"
_u2a_0aa__end:

_u2a_0ab:
incbin "data/U2A.0AB"
_u2a_0ab__end:

_u2e_001:
incbin "data/U2E.001"
_u2e_001__end:

_u2e_002:
incbin "data/U2E.002"
_u2e_002__end:

_u2e_003:
incbin "data/U2E.003"
_u2e_003__end:

_u2e_004:
incbin "data/U2E.004"
_u2e_004__end:

_u2e_005:
incbin "data/U2E.005"
_u2e_005__end:

_u2e_006:
incbin "data/U2E.006"
_u2e_006__end:

_u2e_007:
incbin "data/U2E.007"
_u2e_007__end:

_u2e_008:
incbin "data/U2E.008"
_u2e_008__end:

_u2e_009:
incbin "data/U2E.009"
_u2e_009__end:

_u2e_00m:
incbin "data/U2E.00M"
_u2e_00m__end:

_u2e_010:
incbin "data/U2E.010"
_u2e_010__end:

_u2e_011:
incbin "data/U2E.011"
_u2e_011__end:

_u2e_012:
incbin "data/U2E.012"
_u2e_012__end:

_u2e_013:
incbin "data/U2E.013"
_u2e_013__end:

_u2e_014:
incbin "data/U2E.014"
_u2e_014__end:

_u2e_015:
incbin "data/U2E.015"
_u2e_015__end:

_u2e_016:
incbin "data/U2E.016"
_u2e_016__end:

_u2e_017:
incbin "data/U2E.017"
_u2e_017__end:

_u2e_018:
incbin "data/U2E.018"
_u2e_018__end:

_u2e_019:
incbin "data/U2E.019"
_u2e_019__end:

_u2e_020:
incbin "data/U2E.020"
_u2e_020__end:

_u2e_021:
incbin "data/U2E.021"
_u2e_021__end:

_u2e_022:
incbin "data/U2E.022"
_u2e_022__end:

_u2e_023:
incbin "data/U2E.023"
_u2e_023__end:

_u2e_024:
incbin "data/U2E.024"
_u2e_024__end:

_u2e_025:
incbin "data/U2E.025"
_u2e_025__end:

_u2e_026:
incbin "data/U2E.026"
_u2e_026__end:

_u2e_027:
incbin "data/U2E.027"
_u2e_027__end:

_u2e_028:
incbin "data/U2E.028"
_u2e_028__end:

_u2e_029:
incbin "data/U2E.029"
_u2e_029__end:

_u2e_030:
incbin "data/U2E.030"
_u2e_030__end:

_u2e_031:
incbin "data/U2E.031"
_u2e_031__end:

_u2e_032:
incbin "data/U2E.032"
_u2e_032__end:

_u2e_033:
incbin "data/U2E.033"
_u2e_033__end:

_u2e_034:
incbin "data/U2E.034"
_u2e_034__end:

_u2e_035:
incbin "data/U2E.035"
_u2e_035__end:

_u2e_036:
incbin "data/U2E.036"
_u2e_036__end:

_u2e_037:
incbin "data/U2E.037"
_u2e_037__end:

_u2e_038:
incbin "data/U2E.038"
_u2e_038__end:

_u2e_039:
incbin "data/U2E.039"
_u2e_039__end:

_u2e_040:
incbin "data/U2E.040"
_u2e_040__end:

_u2e_041:
incbin "data/U2E.041"
_u2e_041__end:

_u2e_042:
incbin "data/U2E.042"
_u2e_042__end:

_u2e_0aa:
incbin "data/U2E.0AA"
_u2e_0aa__end:

_u2e_0ab:
incbin "data/U2E.0AB"
_u2e_0ab__end:



; -----------

global _blob_file_count
_blob_file_count dd 53

global _blob_index
_blob_index:

dd 0x1479F4DE, _endscrol_txt, _endscrol_txt__end - _endscrol_txt, 0
dd 0x13517315, _troll_up, _troll_up__end - _troll_up, 0
dd 0x11F8AEAA, _u2a_001, _u2a_001__end - _u2a_001, 0
dd 0x11F9AEAC, _u2a_002, _u2a_002__end - _u2a_002, 0
dd 0x11FAAEAE, _u2a_003, _u2a_003__end - _u2a_003, 0
dd 0x1234AE12, _u2a_00m, _u2a_00m__end - _u2a_00m, 0
dd 0x1259AF4E, _u2a_0aa, _u2a_0aa__end - _u2a_0aa, 0
dd 0x125AAF48, _u2a_0ab, _u2a_0ab__end - _u2a_0ab, 0
dd 0x11FCAE2A, _u2e_001, _u2e_001__end - _u2e_001, 0
dd 0x11FDAE2C, _u2e_002, _u2e_002__end - _u2e_002, 0
dd 0x11FEAE2E, _u2e_003, _u2e_003__end - _u2e_003, 0
dd 0x11FFAE20, _u2e_004, _u2e_004__end - _u2e_004, 0
dd 0x1200AE22, _u2e_005, _u2e_005__end - _u2e_005, 0
dd 0x1201AE24, _u2e_006, _u2e_006__end - _u2e_006, 0
dd 0x1202AE26, _u2e_007, _u2e_007__end - _u2e_007, 0
dd 0x1203AE38, _u2e_008, _u2e_008__end - _u2e_008, 0
dd 0x1204AE3A, _u2e_009, _u2e_009__end - _u2e_009, 0
dd 0x1238AE92, _u2e_00m, _u2e_00m__end - _u2e_00m, 0
dd 0x11FCAE2C, _u2e_010, _u2e_010__end - _u2e_010, 0
dd 0x11FDAE2E, _u2e_011, _u2e_011__end - _u2e_011, 0
dd 0x11FEAE28, _u2e_012, _u2e_012__end - _u2e_012, 0
dd 0x11FFAE2A, _u2e_013, _u2e_013__end - _u2e_013, 0
dd 0x1200AE24, _u2e_014, _u2e_014__end - _u2e_014, 0
dd 0x1201AE26, _u2e_015, _u2e_015__end - _u2e_015, 0
dd 0x1202AE20, _u2e_016, _u2e_016__end - _u2e_016, 0
dd 0x1203AE22, _u2e_017, _u2e_017__end - _u2e_017, 0
dd 0x1204AE3C, _u2e_018, _u2e_018__end - _u2e_018, 0
dd 0x1205AE3E, _u2e_019, _u2e_019__end - _u2e_019, 0
dd 0x11FDAE20, _u2e_020, _u2e_020__end - _u2e_020, 0
dd 0x11FEAE22, _u2e_021, _u2e_021__end - _u2e_021, 0
dd 0x11FFAE24, _u2e_022, _u2e_022__end - _u2e_022, 0
dd 0x1200AE26, _u2e_023, _u2e_023__end - _u2e_023, 0
dd 0x1201AE28, _u2e_024, _u2e_024__end - _u2e_024, 0
dd 0x1202AE2A, _u2e_025, _u2e_025__end - _u2e_025, 0
dd 0x1203AE2C, _u2e_026, _u2e_026__end - _u2e_026, 0
dd 0x1204AE2E, _u2e_027, _u2e_027__end - _u2e_027, 0
dd 0x1205AE30, _u2e_028, _u2e_028__end - _u2e_028, 0
dd 0x1206AE32, _u2e_029, _u2e_029__end - _u2e_029, 0
dd 0x11FEAE24, _u2e_030, _u2e_030__end - _u2e_030, 0
dd 0x11FFAE26, _u2e_031, _u2e_031__end - _u2e_031, 0
dd 0x1200AE20, _u2e_032, _u2e_032__end - _u2e_032, 0
dd 0x1201AE22, _u2e_033, _u2e_033__end - _u2e_033, 0
dd 0x1202AE2C, _u2e_034, _u2e_034__end - _u2e_034, 0
dd 0x1203AE2E, _u2e_035, _u2e_035__end - _u2e_035, 0
dd 0x1204AE28, _u2e_036, _u2e_036__end - _u2e_036, 0
dd 0x1205AE2A, _u2e_037, _u2e_037__end - _u2e_037, 0
dd 0x1206AE34, _u2e_038, _u2e_038__end - _u2e_038, 0
dd 0x1207AE36, _u2e_039, _u2e_039__end - _u2e_039, 0
dd 0x11FFAE38, _u2e_040, _u2e_040__end - _u2e_040, 0
dd 0x1200AE3A, _u2e_041, _u2e_041__end - _u2e_041, 0
dd 0x1201AE3C, _u2e_042, _u2e_042__end - _u2e_042, 0
dd 0x125DAFCE, _u2e_0aa, _u2e_0aa__end - _u2e_0aa, 0
dd 0x125EAFC8, _u2e_0ab, _u2e_0ab__end - _u2e_0ab, 0

{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program ICONV;

Uses Strings;

Type
 FormatType=(_None_,_437,_8859_1,_8859_2,_8859_5,_8859_16,
             ANSI,ASCII,AtariST,UTF8);

Const
 EncodeFormatName:Array[FormatType]of PChar=(
  '','437','8859_1','8859_2','8859_5','8859_16','ANSI',
  'ASCII','ATARIST','UTF-8'
 );

Var
 SourceFile,TargetFile:Text;
 SourceFormat,TargetFormat,FormatCount:FormatType;
 ParamMode:(_None,_Format,_Output,_Target);
 I,Len:Integer;
 CurrLine,SourceFileName,TargetFileName:String;

Const
 i8859_1toUTF32:Array[#0..#255]of Word=(
  {00} $0000,{01} $0001,{02} $0002,{03} $0003,
  {04} $0004,{05} $0005,{06} $0006,{07} $0007,
  {08} $0008,{09} $0009,{0A} $000A,{0B} $000B,
  {0C} $000C,{0D} $000D,{0E} $000E,{0F} $000F,
  {10} $0010,{11} $0011,{12} $0012,{13} $0013,
  {14} $0014,{15} $0015,{16} $0016,{17} $0017,
  {18} $0018,{19} $0019,{1A} $001A,{1B} $001B,
  {1C} $001C,{1D} $001D,{1E} $001E,{1F} $001F,
  {20} $0020,{21} $0021,{22} $0022,{23} $0023,
  {24} $0024,{25} $0025,{26} $0026,{27} $0027,
  {28} $0028,{29} $0029,{2A} $002A,{2B} $002B,
  {2C} $002C,{2D} $002D,{2E} $002E,{2F} $002F,
  {30} $0030,{31} $0031,{32} $0032,{33} $0033,
  {34} $0034,{35} $0035,{36} $0036,{37} $0037,
  {38} $0038,{39} $0039,{3A} $003A,{3B} $003B,
  {3C} $003C,{3D} $003D,{3E} $003E,{3F} $003F,
  {40} $0040,{41} $0041,{42} $0042,{43} $0043,
  {44} $0044,{45} $0045,{46} $0046,{47} $0047,
  {48} $0048,{49} $0049,{4A} $004A,{4B} $004B,
  {4C} $004C,{4D} $004D,{4E} $004E,{4F} $004F,
  {50} $0050,{51} $0051,{52} $0052,{53} $0053,
  {54} $0054,{55} $0055,{56} $0056,{57} $0057,
  {58} $0058,{59} $0059,{5A} $005A,{5B} $005B,
  {5C} $005C,{5D} $005D,{5E} $005E,{5F} $005F,
  {60} $0060,{61} $0061,{62} $0062,{63} $0063,
  {64} $0064,{65} $0065,{66} $0066,{67} $0067,
  {68} $0068,{69} $0069,{6A} $006A,{6B} $006B,
  {6C} $006C,{6D} $006D,{6E} $006E,{6F} $006F,
  {70} $0070,{71} $0071,{72} $0072,{73} $0073,
  {74} $0074,{75} $0075,{76} $0076,{77} $0077,
  {78} $0078,{79} $0079,{7A} $007A,{7B} $007B,
  {7C} $007C,{7D} $007D,{7E} $007E,{7F} $007F,
  {80} $0080,{81} $0081,{82} $0082,{83} $0083,
  {84} $0084,{85} $0085,{86} $0086,{87} $0087,
  {88} $0088,{89} $0089,{8A} $008A,{8B} $008B,
  {8C} $008C,{8D} $008D,{8E} $008E,{8F} $008F,
  {90} $0090,{91} $0091,{92} $0092,{93} $0093,
  {94} $0094,{95} $0095,{96} $0096,{97} $0097,
  {98} $0098,{99} $0099,{9A} $009A,{9B} $009B,
  {9C} $009C,{9D} $009D,{9E} $009E,{9F} $009F,
  {A0} $00A0,{A1} $00A1,{A2} $00A2,{A3} $00A3,
  {A4} $00A4,{A5} $00A5,{A6} $00A6,{A7} $00A7,
  {A8} $00A8,{A9} $00A9,{AA} $00AA,{AB} $00AB,
  {AC} $00AC,{AD} $00AD,{AE} $00AE,{AF} $00AF,
  {B0} $00B0,{B1} $00B1,{B2} $00B2,{B3} $00B3,
  {B4} $00B4,{B5} $00B5,{B6} $00B6,{B7} $00B7,
  {B8} $00B8,{B9} $00B9,{BA} $00BA,{BB} $00BB,
  {BC} $00BC,{BD} $00BD,{BE} $00BE,{BF} $00BF,
  {C0} $00C0,{C1} $00C1,{C2} $00C2,{C3} $00C3,
  {C4} $00C4,{C5} $00C5,{C6} $00C6,{C7} $00C7,
  {C8} $00C8,{C9} $00C9,{CA} $00CA,{CB} $00CB,
  {CC} $00CC,{CD} $00CD,{CE} $00CE,{CF} $00CF,
  {D0} $00D0,{D1} $00D1,{D2} $00D2,{D3} $00D3,
  {D4} $00D4,{D5} $00D5,{D6} $00D6,{D7} $00D7,
  {D8} $00D8,{D9} $00D9,{DA} $00DA,{DB} $00DB,
  {DC} $00DC,{DD} $00DD,{DE} $00DE,{DF} $00DF,
  {E0} $00E0,{E1} $00E1,{E2} $00E2,{E3} $00E3,
  {E4} $00E4,{E5} $00E5,{E6} $00E6,{E7} $00E7,
  {E8} $00E8,{E9} $00E9,{EA} $00EA,{EB} $00EB,
  {EC} $00EC,{ED} $00ED,{EE} $00EE,{EF} $00EF,
  {F0} $00F0,{F1} $00F1,{F2} $00F2,{F3} $00F3,
  {F4} $00F4,{F5} $00F5,{F6} $00F6,{F7} $00F7,
  {F8} $00F8,{F9} $00F9,{FA} $00FA,{FB} $00FB,
  {FC} $00FC,{FD} $00FD,{FE} $00FE,{FF} $00FF
 );

 i8859_2toUTF32:Array[#0..#255]of Word=(
  {00} $0000,{01} $0001,{02} $0002,{03} $0003,
  {04} $0004,{05} $0005,{06} $0006,{07} $0007,
  {08} $0008,{09} $0009,{0A} $000A,{0B} $000B,
  {0C} $000C,{0D} $000D,{0E} $000E,{0F} $000F,
  {10} $0010,{11} $0011,{12} $0012,{13} $0013,
  {14} $0014,{15} $0015,{16} $0016,{17} $0017,
  {18} $0018,{19} $0019,{1A} $001A,{1B} $001B,
  {1C} $001C,{1D} $001D,{1E} $001E,{1F} $001F,
  {20} $0020,{21} $0021,{22} $0022,{23} $0023,
  {24} $0024,{25} $0025,{26} $0026,{27} $0027,
  {28} $0028,{29} $0029,{2A} $002A,{2B} $002B,
  {2C} $002C,{2D} $002D,{2E} $002E,{2F} $002F,
  {30} $0030,{31} $0031,{32} $0032,{33} $0033,
  {34} $0034,{35} $0035,{36} $0036,{37} $0037,
  {38} $0038,{39} $0039,{3A} $003A,{3B} $003B,
  {3C} $003C,{3D} $003D,{3E} $003E,{3F} $003F,
  {40} $0040,{41} $0041,{42} $0042,{43} $0043,
  {44} $0044,{45} $0045,{46} $0046,{47} $0047,
  {48} $0048,{49} $0049,{4A} $004A,{4B} $004B,
  {4C} $004C,{4D} $004D,{4E} $004E,{4F} $004F,
  {50} $0050,{51} $0051,{52} $0052,{53} $0053,
  {54} $0054,{55} $0055,{56} $0056,{57} $0057,
  {58} $0058,{59} $0059,{5A} $005A,{5B} $005B,
  {5C} $005C,{5D} $005D,{5E} $005E,{5F} $005F,
  {60} $0060,{61} $0061,{62} $0062,{63} $0063,
  {64} $0064,{65} $0065,{66} $0066,{67} $0067,
  {68} $0068,{69} $0069,{6A} $006A,{6B} $006B,
  {6C} $006C,{6D} $006D,{6E} $006E,{6F} $006F,
  {70} $0070,{71} $0071,{72} $0072,{73} $0073,
  {74} $0074,{75} $0075,{76} $0076,{77} $0077,
  {78} $0078,{79} $0079,{7A} $007A,{7B} $007B,
  {7C} $007C,{7D} $007D,{7E} $007E,{7F} $007F,
  {80} $0080,{81} $0081,{82} $0082,{83} $0083,
  {84} $0084,{85} $0085,{86} $0086,{87} $0087,
  {88} $0088,{89} $0089,{8A} $008A,{8B} $008B,
  {8C} $008C,{8D} $008D,{8E} $008E,{8F} $008F,
  {90} $0090,{91} $0091,{92} $0092,{93} $0093,
  {94} $0094,{95} $0095,{96} $0096,{97} $0097,
  {98} $0098,{99} $0099,{9A} $009A,{9B} $009B,
  {9C} $009C,{9D} $009D,{9E} $009E,{9F} $009F,
  {A0} $00A0,{A1} $0104,{A2} $02D8,{A3} $0141,
  {A4} $00A4,{A5} $013D,{A6} $015A,{A7} $00A7,
  {A8} $00A8,{A9} $0160,{AA} $015E,{AB} $0164,
  {AC} $0179,{AD} $00AD,{AE} $017D,{AF} $017B,
  {B0} $00B0,{B1} $0105,{B2} $02DB,{B3} $0142,
  {B4} $00B4,{B5} $013E,{B6} $015B,{B7} $02C7,
  {B8} $00B8,{B9} $0161,{BA} $015F,{BB} $0165,
  {BC} $017A,{BD} $02DD,{BE} $017E,{BF} $017C,
  {C0} $0154,{C1} $00C1,{C2} $00C2,{C3} $0102,
  {C4} $00C4,{C5} $0139,{C6} $0106,{C7} $00C7,
  {C8} $010C,{C9} $00C9,{CA} $0118,{CB} $00CB,
  {CC} $011A,{CD} $00CD,{CE} $00CE,{CF} $010E,
  {D0} $0110,{D1} $0143,{D2} $0147,{D3} $00D3,
  {D4} $00D4,{D5} $0150,{D6} $00D6,{D7} $00D7,
  {D8} $0158,{D9} $016E,{DA} $00DA,{DB} $0170,
  {DC} $00DC,{DD} $00DD,{DE} $0162,{DF} $00DF,
  {E0} $0155,{E1} $00E1,{E2} $00E2,{E3} $0103,
  {E4} $00E4,{E5} $013A,{E6} $0107,{E7} $00E7,
  {E8} $010D,{E9} $00E9,{EA} $0119,{EB} $00EB,
  {EC} $011B,{ED} $00ED,{EE} $00EE,{EF} $010F,
  {F0} $0111,{F1} $0144,{F2} $0148,{F3} $00F3,
  {F4} $00F4,{F5} $0151,{F6} $00F6,{F7} $00F7,
  {F8} $0159,{F9} $016F,{FA} $00FA,{FB} $0171,
  {FC} $00FC,{FD} $00FD,{FE} $0163,{FF} $02D9
 );

 i8859_5toUTF32:Array[#0..#255]of Word=(
  {00} $0000,{01} $0001,{02} $0002,{03} $0003,
  {04} $0004,{05} $0005,{06} $0006,{07} $0007,
  {08} $0008,{09} $0009,{0A} $000A,{0B} $000B,
  {0C} $000C,{0D} $000D,{0E} $000E,{0F} $000F,
  {10} $0010,{11} $0011,{12} $0012,{13} $0013,
  {14} $0014,{15} $0015,{16} $0016,{17} $0017,
  {18} $0018,{19} $0019,{1A} $001A,{1B} $001B,
  {1C} $001C,{1D} $001D,{1E} $001E,{1F} $001F,
  {20} $0020,{21} $0021,{22} $0022,{23} $0023,
  {24} $0024,{25} $0025,{26} $0026,{27} $0027,
  {28} $0028,{29} $0029,{2A} $002A,{2B} $002B,
  {2C} $002C,{2D} $002D,{2E} $002E,{2F} $002F,
  {30} $0030,{31} $0031,{32} $0032,{33} $0033,
  {34} $0034,{35} $0035,{36} $0036,{37} $0037,
  {38} $0038,{39} $0039,{3A} $003A,{3B} $003B,
  {3C} $003C,{3D} $003D,{3E} $003E,{3F} $003F,
  {40} $0040,{41} $0041,{42} $0042,{43} $0043,
  {44} $0044,{45} $0045,{46} $0046,{47} $0047,
  {48} $0048,{49} $0049,{4A} $004A,{4B} $004B,
  {4C} $004C,{4D} $004D,{4E} $004E,{4F} $004F,
  {50} $0050,{51} $0051,{52} $0052,{53} $0053,
  {54} $0054,{55} $0055,{56} $0056,{57} $0057,
  {58} $0058,{59} $0059,{5A} $005A,{5B} $005B,
  {5C} $005C,{5D} $005D,{5E} $005E,{5F} $005F,
  {60} $0060,{61} $0061,{62} $0062,{63} $0063,
  {64} $0064,{65} $0065,{66} $0066,{67} $0067,
  {68} $0068,{69} $0069,{6A} $006A,{6B} $006B,
  {6C} $006C,{6D} $006D,{6E} $006E,{6F} $006F,
  {70} $0070,{71} $0071,{72} $0072,{73} $0073,
  {74} $0074,{75} $0075,{76} $0076,{77} $0077,
  {78} $0078,{79} $0079,{7A} $007A,{7B} $007B,
  {7C} $007C,{7D} $007D,{7E} $007E,{7F} $007F,
  {80} $0080,{81} $0081,{82} $0082,{83} $0083,
  {84} $0084,{85} $0085,{86} $0086,{87} $0087,
  {88} $0088,{89} $0089,{8A} $008A,{8B} $008B,
  {8C} $008C,{8D} $008D,{8E} $008E,{8F} $008F,
  {90} $0090,{91} $0091,{92} $0092,{93} $0093,
  {94} $0094,{95} $0095,{96} $0096,{97} $0097,
  {98} $0098,{99} $0099,{9A} $009A,{9B} $009B,
  {9C} $009C,{9D} $009D,{9E} $009E,{9F} $009F,
  {A0} $00A0,{A1} $0401,{A2} $0402,{A3} $0403,
  {A4} $0404,{A5} $0405,{A6} $0406,{A7} $0407,
  {A8} $0408,{A9} $0409,{AA} $040A,{AB} $040B,
  {AC} $040C,{AD} $00AD,{AE} $040E,{AF} $040F,
  {B0} $0410,{B1} $0411,{B2} $0412,{B3} $0413,
  {B4} $0414,{B5} $0415,{B6} $0416,{B7} $0417,
  {B8} $0418,{B9} $0419,{BA} $041A,{BB} $041B,
  {BC} $041C,{BD} $041D,{BE} $041E,{BF} $041F,
  {C0} $0420,{C1} $0421,{C2} $0422,{C3} $0423,
  {C4} $0424,{C5} $0425,{C6} $0426,{C7} $0427,
  {C8} $0428,{C9} $0429,{CA} $042A,{CB} $042B,
  {CC} $042C,{CD} $042D,{CE} $042E,{CF} $042F,
  {D0} $0430,{D1} $0431,{D2} $0432,{D3} $0433,
  {D4} $0434,{D5} $0435,{D6} $0436,{D7} $0437,
  {D8} $0438,{D9} $0439,{DA} $043A,{DB} $043B,
  {DC} $043C,{DD} $043D,{DE} $043E,{DF} $043F,
  {E0} $0440,{E1} $0441,{E2} $0442,{E3} $0443,
  {E4} $0444,{E5} $0445,{E6} $0446,{E7} $0447,
  {E8} $0448,{E9} $0449,{EA} $044A,{EB} $044B,
  {EC} $044C,{ED} $044D,{EE} $044E,{EF} $044F,
  {F0} $2116,{F1} $0451,{F2} $0452,{F3} $0453,
  {F4} $0454,{F5} $0455,{F6} $0456,{F7} $0457,
  {F8} $0458,{F9} $0459,{FA} $045A,{FB} $045B,
  {FC} $045C,{FD} $00A7,{FE} $045E,{FF} $045F
 );

 i8859_16toUTF32:Array[#0..#255]of Word=(
  {00} $0000,{01} $0001,{02} $0002,{03} $0003,
  {04} $0004,{05} $0005,{06} $0006,{07} $0007,
  {08} $0008,{09} $0009,{0A} $000A,{0B} $000B,
  {0C} $000C,{0D} $000D,{0E} $000E,{0F} $000F,
  {10} $0010,{11} $0011,{12} $0012,{13} $0013,
  {14} $0014,{15} $0015,{16} $0016,{17} $0017,
  {18} $0018,{19} $0019,{1A} $001A,{1B} $001B,
  {1C} $001C,{1D} $001D,{1E} $001E,{1F} $001F,
  {20} $0020,{21} $0021,{22} $0022,{23} $0023,
  {24} $0024,{25} $0025,{26} $0026,{27} $0027,
  {28} $0028,{29} $0029,{2A} $002A,{2B} $002B,
  {2C} $002C,{2D} $002D,{2E} $002E,{2F} $002F,
  {30} $0030,{31} $0031,{32} $0032,{33} $0033,
  {34} $0034,{35} $0035,{36} $0036,{37} $0037,
  {38} $0038,{39} $0039,{3A} $003A,{3B} $003B,
  {3C} $003C,{3D} $003D,{3E} $003E,{3F} $003F,
  {40} $0040,{41} $0041,{42} $0042,{43} $0043,
  {44} $0044,{45} $0045,{46} $0046,{47} $0047,
  {48} $0048,{49} $0049,{4A} $004A,{4B} $004B,
  {4C} $004C,{4D} $004D,{4E} $004E,{4F} $004F,
  {50} $0050,{51} $0051,{52} $0052,{53} $0053,
  {54} $0054,{55} $0055,{56} $0056,{57} $0057,
  {58} $0058,{59} $0059,{5A} $005A,{5B} $005B,
  {5C} $005C,{5D} $005D,{5E} $005E,{5F} $005F,
  {60} $0060,{61} $0061,{62} $0062,{63} $0063,
  {64} $0064,{65} $0065,{66} $0066,{67} $0067,
  {68} $0068,{69} $0069,{6A} $006A,{6B} $006B,
  {6C} $006C,{6D} $006D,{6E} $006E,{6F} $006F,
  {70} $0070,{71} $0071,{72} $0072,{73} $0073,
  {74} $0074,{75} $0075,{76} $0076,{77} $0077,
  {78} $0078,{79} $0079,{7A} $007A,{7B} $007B,
  {7C} $007C,{7D} $007D,{7E} $007E,{7F} $007F,
  {80} $0080,{81} $0081,{82} $0082,{83} $0083,
  {84} $0084,{85} $0085,{86} $0086,{87} $0087,
  {88} $0088,{89} $0089,{8A} $008A,{8B} $008B,
  {8C} $008C,{8D} $008D,{8E} $008E,{8F} $008F,
  {90} $0090,{91} $0091,{92} $0092,{93} $0093,
  {94} $0094,{95} $0095,{96} $0096,{97} $0097,
  {98} $0098,{99} $0099,{9A} $009A,{9B} $009B,
  {9C} $009C,{9D} $009D,{9E} $009E,{9F} $009F,
  {A0} $00A0,{A1} $0104,{A2} $0105,{A3} $0141,
  {A4} $20AC,{A5} $201E,{A6} $0160,{A7} $00A7,
  {A8} $0161,{A9} $00A9,{AA} $0218,{AB} $00AB,
  {AC} $0179,{AD} $00AD,{AE} $017A,{AF} $017B,
  {B0} $00B0,{B1} $00B1,{B2} $010C,{B3} $0142,
  {B4} $017D,{B5} $201D,{B6} $00B6,{B7} $00B7,
  {B8} $017E,{B9} $010D,{BA} $0219,{BB} $00BB,
  {BC} $0152,{BD} $0153,{BE} $0178,{BF} $017C,
  {C0} $00C0,{C1} $00C1,{C2} $00C2,{C3} $0102,
  {C4} $00C4,{C5} $0106,{C6} $00C6,{C7} $00C7,
  {C8} $00C8,{C9} $00C9,{CA} $00CA,{CB} $00CB,
  {CC} $00CC,{CD} $00CD,{CE} $00CE,{CF} $00CF,
  {D0} $0110,{D1} $0143,{D2} $00D2,{D3} $00D3,
  {D4} $00D4,{D5} $0150,{D6} $00D6,{D7} $015A,
  {D8} $0170,{D9} $00D9,{DA} $00DA,{DB} $00DB,
  {DC} $00DC,{DD} $0118,{DE} $021A,{DF} $00DF,
  {E0} $00E0,{E1} $00E1,{E2} $00E2,{E3} $0103,
  {E4} $00E4,{E5} $0107,{E6} $00E6,{E7} $00E7,
  {E8} $00E8,{E9} $00E9,{EA} $00EA,{EB} $00EB,
  {EC} $00EC,{ED} $00ED,{EE} $00EE,{EF} $00EF,
  {F0} $0111,{F1} $0144,{F2} $00F2,{F3} $00F3,
  {F4} $00F4,{F5} $0151,{F6} $00F6,{F7} $015B,
  {F8} $0171,{F9} $00F9,{FA} $00FA,{FB} $00FB,
  {FC} $00FC,{FD} $0119,{FE} $021B,{FF} $00FF
 );

 AtariSTtoUTF32:Array[#0..#255]of Word=(
  {00} $0000,{01} $0001,{02} $0002,{03} $0003,
  {04} $0004,{05} $0005,{06} $0006,{07} $0007,
  {08} $0008,{09} $0009,{0A} $000A,{0B} $000B,
  {0C} $000C,{0D} $000D,{0E} $000E,{0F} $000F,
  {10} $0010,{11} $0011,{12} $0012,{13} $0013,
  {14} $0014,{15} $0015,{16} $0016,{17} $0017,
  {18} $0018,{19} $0019,{1A} $001A,{1B} $001B,
  {1C} $001C,{1D} $001D,{1E} $001E,{1F} $001F,
  {20} $0020,{21} $0021,{22} $0022,{23} $0023,
  {24} $0024,{25} $0025,{26} $0026,{27} $0027,
  {28} $0028,{29} $0029,{2A} $002A,{2B} $002B,
  {2C} $002C,{2D} $002D,{2E} $002E,{2F} $002F,
  {30} $0030,{31} $0031,{32} $0032,{33} $0033,
  {34} $0034,{35} $0035,{36} $0036,{37} $0037,
  {38} $0038,{39} $0039,{3A} $003A,{3B} $003B,
  {3C} $003C,{3D} $003D,{3E} $003E,{3F} $003F,
  {40} $0040,{41} $0041,{42} $0042,{43} $0043,
  {44} $0044,{45} $0045,{46} $0046,{47} $0047,
  {48} $0048,{49} $0049,{4A} $004A,{4B} $004B,
  {4C} $004C,{4D} $004D,{4E} $004E,{4F} $004F,
  {50} $0050,{51} $0051,{52} $0052,{53} $0053,
  {54} $0054,{55} $0055,{56} $0056,{57} $0057,
  {58} $0058,{59} $0059,{5A} $005A,{5B} $005B,
  {5C} $005C,{5D} $005D,{5E} $005E,{5F} $005F,
  {60} $0060,{61} $0061,{62} $0062,{63} $0063,
  {64} $0064,{65} $0065,{66} $0066,{67} $0067,
  {68} $0068,{69} $0069,{6A} $006A,{6B} $006B,
  {6C} $006C,{6D} $006D,{6E} $006E,{6F} $006F,
  {70} $0070,{71} $0071,{72} $0072,{73} $0073,
  {74} $0074,{75} $0075,{76} $0076,{77} $0077,
  {78} $0078,{79} $0079,{7A} $007A,{7B} $007B,
  {7C} $007C,{7D} $007D,{7E} $007E,{7F} $007F,
  {80} $00C7,{81} $00FC,{82} $00E9,{83} $00E2,
  {84} $00E4,{85} $00E0,{86} $00E5,{87} $00E7,
  {88} $00EA,{89} $00EB,{8A} $00E8,{8B} $00EF,
  {8C} $00EE,{8D} $00EC,{8E} $00C4,{8F} $00C5,
  {90} $00C9,{91} $00E6,{92} $00C6,{93} $00F4,
  {94} $00F6,{95} $00F2,{96} $00FB,{97} $00F9,
  {98} $00FF,{99} $00D6,{9A} $00DC,{9B} $00A2,
  {9C} $00A3,{9D} $00A5,{9E} $03B2,{9F} $0192,
  {A0} $00E1,{A1} $00ED,{A2} $00F3,{A3} $00FA,
  {A4} $00F1,{A5} $00D1,{A6} $00AA,{A7} $00BA,
  {A8} $00BF,{A9} $2310,{AA} $00AC,{AB} $00BD,
  {AC} $00BC,{AD} $00A1,{AE} $00AB,{AF} $00BB,
  {B0} $00E3,{B1} $00F5,{B2} $00D8,{B3} $00F8,
  {B4} $0153,{B5} $0152,{B6} $00C0,{B7} $00C3,
  {B8} $00D5,{B9} $00A8,{BA} $00B4,{BB} $2020,
  {BC} $00B6,{BD} $00A9,{BE} $00AE,{BF} $2122,
  {C0} $0133,{C1} $0132,{C2} $05D0,{C3} $05D1,
  {C4} $05D2,{C5} $05D3,{C6} $05D4,{C7} $05D5,
  {C8} $05D6,{C9} $05D7,{CA} $05D8,{CB} $05D9,
  {CC} $05DB,{CD} $05DC,{CE} $05DE,{CF} $05E0,
  {D0} $05E1,{D1} $05E2,{D2} $05E4,{D3} $05E6,
  {D4} $05E7,{D5} $05E8,{D6} $05E9,{D7} $05EA,
  {D8} $05DF,{D9} $05DA,{DA} $05DD,{DB} $05E3,
  {DC} $05E5,{DD} $00A7,{DE} $2227,{DF} $221E,
  {E0} $03B1,{E1} $00DF,{E2} $0393,{E3} $03C0,
  {E4} $03A3,{E5} $03C3,{E6} $00B5,{E7} $03C4,
  {E8} $03A6,{E9} $0398,{EA} $03A9,{EB} $03B4,
  {EC} $222E,{ED} $03C6,{EE} $03B5,{EF} $2229,
  {F0} $2261,{F1} $00B1,{F2} $2265,{F3} $2264,
  {F4} $2320,{F5} $2321,{F6} $00F7,{F7} $2248,
  {F8} $00B0,{F9} $2219,{FA} $00B7,{FB} $221A,
  {FC} $207F,{FD} $00B2,{FE} $22B3,{FF} $00AF
);


Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function AnsiTo437(Ch:Char):Char;Begin
 Case Ch of
  #171:Ch:=#174;
  #176:Ch:=#248;
  #177:Ch:=#241;
  #187:Ch:=#175;
  #188:Ch:=#172;
  #189:Ch:=#171;
  #192..#195:Ch:='A';
  #196:Ch:=#142;
  #197:Ch:=#143;
  #198:Ch:=#146;
  #199:Ch:=#128;
  #200:Ch:='E';
  #201:Ch:=#144;
  #202:Ch:='E';
  #203:Ch:='E';
  #204..#207:Ch:='I';
  #208:Ch:='D';
  #209:Ch:=#165;
  #210..#214:Ch:='O';
  #217..#219:Ch:='U';
  #220:Ch:=#154;
  #224:Ch:=#133;
  #225:Ch:=#160;
  #226:Ch:=#131;
  #227:Ch:='a';
  #228:Ch:=#132;
  #229:Ch:=#134;
  #230:Ch:=#145;
  #231:Ch:=#135;
  #232:Ch:=#138;
  #233:Ch:=#130;
  #234:Ch:=#136;
  #235:Ch:=#137;
  #236:Ch:=#141;
  #237:Ch:=#161;
  #238:Ch:=#140;
  #239:Ch:=#139;
  #241:Ch:=#164;
  #242:Ch:=#149;
  #243:Ch:=#162;
  #244:Ch:=#147;
  #246:Ch:=#148;
  #247:Ch:=#246;
  #249:Ch:=#151;
  #250:Ch:=#163;
  #251:Ch:=#150;
  #252:Ch:=#129;
 End;
 AnsiTo437:=Ch;
End;

Function _437ToAnsi(Ch:Char):Char;Begin
 Case Ch of
  #174:Ch:=#171;
  #248:Ch:=#176;
  #241:Ch:=#177;
  #175:Ch:=#187;
  #172:Ch:=#188;
  #171:Ch:=#189;
  #142:Ch:=#196;
  #143:Ch:=#197;
  #146:Ch:=#198;
  #128:Ch:=#199;
  #144:Ch:=#201;
  #165:Ch:=#209;
  #154:Ch:=#220;
  #133:Ch:=#224;
  #160:Ch:=#225;
  #131:Ch:=#226;
  #132:Ch:=#228;
  #134:Ch:=#229;
  #145:Ch:=#230;
  #135:Ch:=#231;
  #138:Ch:=#232;
  #130:Ch:=#233;
  #136:Ch:=#234;
  #137:Ch:=#235;
  #141:Ch:=#236;
  #161:Ch:=#237;
  #140:Ch:=#238;
  #139:Ch:=#239;
  #164:Ch:=#241;
  #149:Ch:=#242;
  #162:Ch:=#243;
  #147:Ch:=#244;
  #148:Ch:=#246;
  #246:Ch:=#247;
  #151:Ch:=#249;
  #163:Ch:=#250;
  #150:Ch:=#251;
  #129:Ch:=#252;
 End;
 _437ToAnsi:=Ch;
End;

Function ProcessLine:String;
Var
 I:Integer;
 R:String;
Begin
 R:='';
 Case SourceFormat of
  _437:Case TargetFormat of
   ANSI:Begin
    For I:=1 to Length(CurrLine)do Begin
     R:=R+_437ToAnsi(CurrLine[I]);
    End;
   End;
   Else R:=CurrLine;
  End;
  _8859_1:Case TargetFormat of
   UTF8:Begin
    For I:=1 to Length(CurrLine)do Begin
     R:=R+Chr(Lo(i8859_1toUTF32[CurrLine[I]]))+Chr(Hi(i8859_1toUTF32[CurrLine[I]]));
    End;
   End;
   Else R:=CurrLine;
  End;
  _8859_2:Case TargetFormat of
   UTF8:Begin
    For I:=1 to Length(CurrLine)do Begin
     R:=R+Chr(Lo(i8859_2toUTF32[CurrLine[I]]))+Chr(Hi(i8859_2toUTF32[CurrLine[I]]));
    End;
   End;
   Else R:=CurrLine;
  End;
  _8859_5:Case TargetFormat of
   UTF8:Begin
    For I:=1 to Length(CurrLine)do Begin
     R:=R+Chr(Lo(i8859_5toUTF32[CurrLine[I]]))+Chr(Hi(i8859_5toUTF32[CurrLine[I]]));
    End;
   End;
   Else R:=CurrLine;
  End;
  _8859_16:Case TargetFormat of
   UTF8:Begin
    For I:=1 to Length(CurrLine)do Begin
     R:=R+Chr(Lo(i8859_16toUTF32[CurrLine[I]]))+Chr(Hi(i8859_16toUTF32[CurrLine[I]]));
    End;
   End;
   Else R:=CurrLine;
  End;
  ANSI:Case TargetFormat of
   _437:Begin
    For I:=1 to Length(CurrLine)do Begin
     R:=R+AnsiTo437(CurrLine[I]);
    End;
   End;
   Else R:=CurrLine;
  End;
  ATARIST:Case TargetFormat of
   UTF8:Begin
    For I:=1 to Length(CurrLine)do Begin
     R:=R+Chr(Lo(AtariSTtoUTF32[CurrLine[I]]))+Chr(Hi(AtariSTtoUTF32[CurrLine[I]]));
    End;
   End;
   Else R:=CurrLine;
  End;
  Else R:=CurrLine;
 End;
 ProcessLine:=R;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('ICONV : Cette commande permet de convertir un fichier d''un ',
                'format … un autre.');
  WriteLn;
  WriteLn('Syntaxe : ICONV [-f format] source [-o target] [-t format]');
  WriteLn;
  WriteLn(' source          Nom du fichier source');
  WriteLn(' -f format       Format source');
  WriteLn(' -l              Affiche la liste des formats');
  WriteLn(' -o target       Nom du fichier destinatire');
  WriteLn(' -t format       Format destinaire');
  WriteLn(' --list          Affiche la liste des formats');
 End
  Else
 Begin
  SourceFileName:='';
  TargetFileName:='';
  SourceFormat:=_None_;
  TargetFormat:=_None_;
  ParamMode:=_None;
  For I:=1 to ParamCount do Begin
   Case ParamMode of
    _Format:Begin
     For FormatCount:=Succ(_None_)To High(FormatCount) do Begin
      If StrToUpper(ParamStr(I))=StrPas(EncodeFormatName[FormatCount])Then Begin
       SourceFormat:=FormatCount;
      End;
     End;
     If SourceFormat=_None_ Then Begin
      WriteLn('Format non reconnu : ',ParamStr(I));
      Halt(1);
     End;
     ParamMode:=_None;
    End;
    _Output:Begin
     TargetFileName:=ParamStr(I);
     ParamMode:=_None;
    End;
    _Target:Begin
     For FormatCount:=Succ(_None_)To High(FormatCount) do Begin
      If StrToUpper(ParamStr(I))=StrPas(EncodeFormatName[FormatCount])Then Begin
       TargetFormat:=FormatCount;
      End;
     End;
     If SourceFormat=_None_ Then Begin
      WriteLn('Format non reconnu : ',ParamStr(I));
      Halt(1);
     End;
     ParamMode:=_None;
    End;
    Else Begin
     If ParamStr(I)='-f'Then ParamMode:=_Format Else
     If(ParamStr(I)='-l')or(ParamStr(I)='--list')Then Begin
      Write('  ');
      Len:=0;
      For FormatCount:=Succ(_None_)To High(FormatCount) do Begin
       Write(StrPas(EncodeFormatName[FormatCount]));
       Inc(Len,StrLen(EncodeFormatName[FormatCount])+2);
       If FormatCount<>High(FormatCount)Then Write(', ');
       If Len>70 Then Begin
        Len:=0;
        WriteLn;
       End;
      End;
      Halt;
     End
      Else
     If ParamStr(I)='-o'Then ParamMode:=_Output Else
     If ParamStr(I)='-t'Then ParamMode:=_Target
      Else
     Begin
      SourceFileName:=ParamStr(I);
     End;
    End;
   End;
  End;
  If(SourceFileName='')Then Begin
   If TargetFileName<>''Then Begin
    {$I-}Assign(TargetFile,TargetFileName);
    Rewrite(TargetFile);{$I+}
    If IOResult<>0 Then Begin
     WriteLn('Impossible d''‚crire le fichier ',TargetFileName);
     Halt(2);
    End;
    While Not EOF do Begin
     ReadLn(CurrLine);
     WriteLn(TargetFile,ProcessLine);
    End;
    Close(TargetFile);
   End
    Else
   Begin
    While Not EOF do Begin
     ReadLn(CurrLine);
     WriteLn(ProcessLine);
    End;
   End;
  End
   Else
  Begin
   {$I-}Assign(SourceFile,SourceFileName);
   Reset(SourceFile);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible de lire le fichier ',SourceFileName);
    Halt(1);
   End;
   If TargetFileName<>''Then Begin
    {$I-}Assign(TargetFile,TargetFileName);
    Rewrite(TargetFile);{$I+}
    If IOResult<>0 Then Begin
     WriteLn('Impossible d''‚crire le fichier ',TargetFileName);
     Halt(2);
    End;
    While Not EOF(SourceFile)do Begin
     ReadLn(SourceFile,CurrLine);
     WriteLn(TargetFile,ProcessLine);
    End;
    Close(TargetFile);
   End
    Else
   Begin
    While Not EOF(SourceFile)do Begin
     ReadLn(SourceFile,CurrLine);
     WriteLn(ProcessLine);
    End;
   End;
   Close(SourceFile);
  End;
 End;
END.
{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7)
}

Program PCIINFO;

Uses Strings;

Type
 PCIVendorRec=Record
  VID:Word;
  Name:PChar;
 End;

 PCIDeviceRec=Record
  VID,DID:Word;
  Name:PChar;
 End;

Const
 PCIVendor:Array[0..1447]of PCIVendorRec=(
  (VID:$001A;Name:'Ascend Communications, Inc.'),
  (VID:$0033;Name:'Paradyne Corp'),
  (VID:$003D;Name:'Martin-Marietta Corporation'),
  (VID:$0070;Name:'Hauppauge Computer Works Inc'),
  (VID:$0675;Name:'Dynalink'),
  (VID:$0A89;Name:'BREA Technologies Inc'),
  (VID:$0E11;Name:'Compaq'),
  (VID:$1000;Name:'Symbios Logic Inc (NCR)'),
  (VID:$1001;Name:'Initio'),
  (VID:$1002;Name:'ATI'),
  (VID:$1003;Name:'ULSI Systems'),
  (VID:$1004;Name:'VLSI Technologies'),
  (VID:$1005;Name:'Avance Logic'),
  (VID:$1006;Name:'Reply Group'),
  (VID:$1007;Name:'Netframe Systems Inc.'),
  (VID:$1008;Name:'Epson'),
  (VID:$100A;Name:'Phoenix Technologies'),
  (VID:$100B;Name:'National Semiconductor'),
  (VID:$100C;Name:'Tseng Labs'),
  (VID:$100D;Name:'AST Research'),
  (VID:$100E;Name:'Weitek'),
  (VID:$1010;Name:'Video Logic Ltd'),
  (VID:$1011;Name:'Digital (DEC)'),
  (VID:$1012;Name:'Micronics Computers'),
  (VID:$1013;Name:'Cirrus Logic'),
  (VID:$1014;Name:'IBM'),
  (VID:$1015;Name:'LSI Logic Corp. du Canada'),
  (VID:$1016;Name:'ICL Personal Systems'),
  (VID:$1017;Name:'SPEA Software AG'),
  (VID:$1018;Name:'Unisys'),
  (VID:$1019;Name:'EliteGroup Computer Sys'),
  (VID:$101A;Name:'NCR/AT&T GIS'),
  (VID:$101B;Name:'Vitesse Semiconductor'),
  (VID:$101C;Name:'Western Digital'),
  (VID:$101E;Name:'AMI'),
  (VID:$101F;Name:'Picturetel'),
  (VID:$1020;Name:'Hitachi Computer Electronics'),
  (VID:$1021;Name:'Oki Electric Industry'),
  (VID:$1022;Name:'Advanced Micro Devices (AMD)'),
  (VID:$1023;Name:'Trident'),
  (VID:$1024;Name:'Zenith Data Systems'),
  (VID:$1025;Name:'Acer'),
  (VID:$1028;Name:'Dell Computer Corporation'),
  (VID:$1029;Name:'Siemens Nixdorf'),
  (VID:$102A;Name:'LSI Logic, Headland Division'),
  (VID:$102B;Name:'Matrox'),
  (VID:$102C;Name:'Chips & Technologies'),
  (VID:$102D;Name:'Wyse Technologies'),
  (VID:$102E;Name:'Olivetti Advanced Technology'),
  (VID:$102F;Name:'Toshiba America'),
  (VID:$1030;Name:'TMC Research'),
  (VID:$1031;Name:'Miro Computer Products AG'),
  (VID:$1032;Name:'Compaq'),
  (VID:$1033;Name:'NEC Corporation'),
  (VID:$1034;Name:'Burndy Corporation'),
  (VID:$1035;Name:'Computers and Communications Research Lab'),
  (VID:$1036;Name:'Future Domain'),
  (VID:$1037;Name:'Hitachi Micro Systems'),
  (VID:$1038;Name:'AMP Incorporated'),
  (VID:$1039;Name:'Silicon Integrated System (SIS)'),
  (VID:$103A;Name:'Seiko Epson Corporation'),
  (VID:$103B;Name:'Tatung Corp. des Am,riques'),
  (VID:$103C;Name:'Hewlett-Packard'),
  (VID:$103E;Name:'Solliday'),
  (VID:$103F;Name:'Logic Modeling'),
  (VID:$1040;Name:'Kubota Pacific'),
  (VID:$1041;Name:'Computrend'),
  (VID:$1042;Name:'PC Technology'),
  (VID:$1043;Name:'Asustek'),
  (VID:$1044;Name:'Distributed Processing Technology (DPT)'),
  (VID:$1045;Name:'OPTi'),
  (VID:$1046;Name:'IPC Corporation, Ltd.'),
  (VID:$1047;Name:'Genoa Systems Corp.'),
  (VID:$1048;Name:'Elsa GmbH'),
  (VID:$1049;Name:'Fountain Technology'),
  (VID:$104A;Name:'SGS Thomson Microelectric'),
  (VID:$104B;Name:'BusLogic'),
  (VID:$104C;Name:'Texas Instruments'),
  (VID:$104D;Name:'Sony Corporation'),
  (VID:$104E;Name:'Oak Technology'),
  (VID:$104F;Name:'Co-Time Computer Ltd.'),
  (VID:$1050;Name:'Winbond'),
  (VID:$1051;Name:'Anigma Corp.'),
  (VID:$1052;Name:'Young Micro Systems'),
  (VID:$1053;Name:'Young Micro Systems'),
  (VID:$1054;Name:'Hitachi, Ltd.'),
  (VID:$1055;Name:'EFAR Microsystems'),
  (VID:$1056;Name:'ICL'),
  (VID:$1057;Name:'Motorola'),
  (VID:$1058;Name:'Electronics and Telecommunications Research'),
  (VID:$1059;Name:'Teknor Microsystems'),
  (VID:$105A;Name:'Promise Technology'),
  (VID:$105B;Name:'Foxconn International'),
  (VID:$105C;Name:'Wipro Infotech Ltd.'),
  (VID:$105D;Name:'Number Nine (#9)'),
  (VID:$105E;Name:'VTech Engineering Canada, Ltd.'),
  (VID:$105F;Name:'Infotronic America, Inc.'),
  (VID:$1060;Name:'UMC'),
  (VID:$1061;Name:'8x8 (X Tech)'),
  (VID:$1062;Name:'Maspar Computer Copr.'),
  (VID:$1063;Name:'Ocean Office Automation'),
  (VID:$1064;Name:'Alcatel Cit'),
  (VID:$1065;Name:'Texas Microsystems'),
  (VID:$1066;Name:'PicoPower Technology'),
  (VID:$1067;Name:'Mitsubishi Electronics'),
  (VID:$1068;Name:'Diversified Technology'),
  (VID:$1069;Name:'Mylex Corporation'),
  (VID:$106A;Name:'Aten Research'),
  (VID:$106B;Name:'Apple Computer'),
  (VID:$106C;Name:'Hyundai Electronics America'),
  (VID:$106D;Name:'Sequent'),
  (VID:$106E;Name:'DFI Inc.'),
  (VID:$106F;Name:'City Gate Development, Ltd.'),
  (VID:$1070;Name:'Daewoo Telecom Ltd.'),
  (VID:$1071;Name:'Mitac'),
  (VID:$1072;Name:'GIT Co., Ltd.'),
  (VID:$1073;Name:'Yamaha Corporation'),
  (VID:$1074;Name:'NexGen Microsystems'),
  (VID:$1075;Name:'Advanced Integration Research'),
  (VID:$1076;Name:'Chaintech Computer Co. Ltd.'),
  (VID:$1077;Name:'Q Logic'),
  (VID:$1078;Name:'Cyrix Corporation'),
  (VID:$1079;Name:'I-Bus'),
  (VID:$107A;Name:'Networth'),
  (VID:$107B;Name:'Gateway 2000'),
  (VID:$107C;Name:'Goldstar Co. Ltd.'),
  (VID:$107D;Name:'Leadtek Research'),
  (VID:$107E;Name:'Interphase Corporation'),
  (VID:$107F;Name:'Data Technology Corporation (DTC)'),
  (VID:$1080;Name:'Contaq Microsystems'),
  (VID:$1081;Name:'Supermac Technology'),
  (VID:$1082;Name:'EFA Corporation d''Am,riques'),
  (VID:$1083;Name:'Forex Computer Corporation'),
  (VID:$1084;Name:'Parador'),
  (VID:$1085;Name:'Tulip Computers Int''l BV'),
  (VID:$1086;Name:'J. Bond Computer Systems'),
  (VID:$1087;Name:'Cache Computer'),
  (VID:$1088;Name:'Microcomputer Systems (M) Son'),
  (VID:$1089;Name:'Data General Corporation'),
  (VID:$108A;Name:'Bit3 Computer'),
  (VID:$108C;Name:'Elonex PLC (Oakleigh Systems, Inc)'),
  (VID:$108D;Name:'Olicom'),
  (VID:$108E;Name:'Sun Microsystems'),
  (VID:$108F;Name:'Systemsoft Corporation'),
  (VID:$1090;Name:'Encore Computer Corporation'),
  (VID:$1091;Name:'Intergraph Corporation'),
  (VID:$1092;Name:'Diamond Computer Systems'),
  (VID:$1093;Name:'National Instruments'),
  (VID:$1094;Name:'First International Computers (FIC)'),
  (VID:$1095;Name:'CMD Technology, Inc.'),
  (VID:$1096;Name:'Alacron'),
  (VID:$1097;Name:'Appian Technology'),
  (VID:$1098;Name:'Vision / Quantum Designs Ltd'),
  (VID:$1099;Name:'Samsung Electronics Co. Ltd.'),
  (VID:$109A;Name:'Packard Bell'),
  (VID:$109B;Name:'Gemlight Computer Ltd.'),
  (VID:$109C;Name:'Megachips Corporation'),
  (VID:$109D;Name:'Zida Technologies'),
  (VID:$109E;Name:'Brooktree Corporation'),
  (VID:$109F;Name:'Trigem Computer Inc.'),
  (VID:$10A0;Name:'Meidensha Corporation'),
  (VID:$10A1;Name:'Juko Electronics Inc. Ltd.'),
  (VID:$10A2;Name:'Quantum Corporation'),
  (VID:$10A3;Name:'Everex Systems Inc.'),
  (VID:$10A4;Name:'Globe Manufacturing Sales'),
  (VID:$10A5;Name:'Racal Interlan'),
  (VID:$10A6;Name:'Informtech Industrial Ltd.'),
  (VID:$10A7;Name:'Benchmarq Microelectronics'),
  (VID:$10A8;Name:'Sierra Semiconductor'),
  (VID:$10A9;Name:'Silicon Graphics'),
  (VID:$10AA;Name:'ACC Microelectronics'),
  (VID:$10AB;Name:'Digicom'),
  (VID:$10AC;Name:'Honeywell IASD'),
  (VID:$10AD;Name:'Symphony Labs'),
  (VID:$10AE;Name:'Cornerstone Technology'),
  (VID:$10AF;Name:'Microcomputer Systems'),
  (VID:$10B0;Name:'CardExpert Technology'),
  (VID:$10B1;Name:'Cabletron Systems, Inc.'),
  (VID:$10B2;Name:'Raytheon Company'),
  (VID:$10B3;Name:'Databook Inc'),
  (VID:$10B4;Name:'STB Systems'),
  (VID:$10B5;Name:'PLX Technology'),
  (VID:$10B6;Name:'Madge Networks'),
  (VID:$10B7;Name:'3com Corporation'),
  (VID:$10B8;Name:'Standard Microsystems Corporation (SMC)'),
  (VID:$10B9;Name:'Acer Labs Inc.'),
  (VID:$10BA;Name:'Mitsubishi Electronics Corp.'),
  (VID:$10BB;Name:'Dapha Electronics Corporation'),
  (VID:$10BC;Name:'Advanced Logic Research Inc. (ALR)'),
  (VID:$10BD;Name:'Surecom Technology'),
  (VID:$10BE;Name:'Tseng Labs International Corp.'),
  (VID:$10BF;Name:'Most Inc.'),
  (VID:$10C0;Name:'Boca Research Inc.'),
  (VID:$10C1;Name:'ICM Corp. Ltd.'),
  (VID:$10C2;Name:'Auspex Systems Inc.'),
  (VID:$10C3;Name:'Samsung Semiconductors'),
  (VID:$10C4;Name:'Award Software International Inc.'),
  (VID:$10C5;Name:'Xerox Corporation'),
  (VID:$10C6;Name:'Rambus Inc.'),
  (VID:$10C7;Name:'Media Vision'),
  (VID:$10C8;Name:'Neomagic Corporation'),
  (VID:$10C9;Name:'DataExpert Corporation'),
  (VID:$10CA;Name:'Fujitsu'),
  (VID:$10CB;Name:'Omron Corporation'),
  (VID:$10CC;Name:'Mentor Arc Inc.'),
  (VID:$10CD;Name:'Advanced System Products'),
  (VID:$10CE;Name:'Radius Inc.'),
  (VID:$10CF;Name:'Citicorp TTI'),
  (VID:$10D0;Name:'Fujitsu Limited'),
  (VID:$10D1;Name:'Future+ Systems'),
  (VID:$10D2;Name:'Molex Incorporated'),
  (VID:$10D3;Name:'Jabil Circuit Inc.'),
  (VID:$10D4;Name:'Hualon Microelectronics'),
  (VID:$10D5;Name:'Autologic Inc.'),
  (VID:$10D6;Name:'Cetia'),
  (VID:$10D7;Name:'BCM Advanced Research'),
  (VID:$10D8;Name:'Advanced Peripherals Labs'),
  (VID:$10D9;Name:'Macronix International Co. Ltd'),
  (VID:$10DA;Name:'Thomas-Conrad Corporation'),
  (VID:$10DB;Name:'Rohm Research'),
  (VID:$10DC;Name:'CERN/ECP/EDU'),
  (VID:$10DD;Name:'Evans & Sutherland'),
  (VID:$10DE;Name:'NVIDIA Corporation'),
  (VID:$10DF;Name:'Emulex Corporation'),
  (VID:$10E0;Name:'Integrated Micro Solutions (IMS)'),
  (VID:$10E1;Name:'TekRAM Technology Corporation Ltd.'),
  (VID:$10E2;Name:'Aptix Corporation'),
  (VID:$10E3;Name:'Newbridge Microsystems'),
  (VID:$10E4;Name:'Tandem Computers'),
  (VID:$10E5;Name:'Micro Industries'),
  (VID:$10E6;Name:'Gainbery Computer Products Inc.'),
  (VID:$10E7;Name:'Vadem'),
  (VID:$10E8;Name:'Applied Micro Circuits Corp.'),
  (VID:$10E9;Name:'Alps Electronic Corp. Ltd.'),
  (VID:$10EA;Name:'Integraphics Systems'),
  (VID:$10EB;Name:'Artist Graphics'),
  (VID:$10EC;Name:'Realtek Semiconductor'),
  (VID:$10ED;Name:'ASCII Corporation'),
  (VID:$10EE;Name:'Xilinx Corporation'),
  (VID:$10EF;Name:'Racore Computer Products'),
  (VID:$10F0;Name:'Peritek Corporation'),
  (VID:$10F1;Name:'Tyan Computer'),
  (VID:$10F2;Name:'Achme Computer Inc.'),
  (VID:$10F3;Name:'Alaris Inc.'),
  (VID:$10F4;Name:'S-MOS Systems'),
  (VID:$10F5;Name:'NKK Corporation'),
  (VID:$10F6;Name:'Creative Electronic Systems SA'),
  (VID:$10F7;Name:'Matsushita Electric Industrial Corp. Ltd.'),
  (VID:$10F8;Name:'Altos India Ltd.'),
  (VID:$10F9;Name:'PC Direct'),
  (VID:$10FA;Name:'Truevision'),
  (VID:$10FB;Name:'Thesys Ges. f?r Microelektronik mbH'),
  (VID:$10FC;Name:'I/O Data Device Inc.'),
  (VID:$10FD;Name:'Soyo Technology Corp. Ltd.'),
  (VID:$10FE;Name:'Fast Electronic GmbH'),
  (VID:$10FF;Name:'N-Cube'),
  (VID:$1100;Name:'Jazz Multimedia'),
  (VID:$1101;Name:'Initio Corporation'),
  (VID:$1102;Name:'Creative Labs'),
  (VID:$1103;Name:'Triones Technologies Inc.'),
  (VID:$1104;Name:'Rasterops'),
  (VID:$1105;Name:'Sigma Designs, Inc.'),
  (VID:$1106;Name:'VIA Technologies'),
  (VID:$1107;Name:'Stratus Computer'),
  (VID:$1108;Name:'Proteon Inc.'),
  (VID:$1109;Name:'Cogent Data Technologies'),
  (VID:$110A;Name:'Siemens AG / Siemens Nixdorf AG'),
  (VID:$110B;Name:'Xenon Microsystems / Chromatic Research, Inc.'),
  (VID:$110C;Name:'Mini-Max Technology Inc.'),
  (VID:$110D;Name:'ZNyX Corporation'),
  (VID:$110E;Name:'CPU Technology'),
  (VID:$110F;Name:'Ross Technology'),
  (VID:$1110;Name:'Powerhouse Systems'),
  (VID:$1111;Name:'Santa Cruz Operation (SCO)'),
  (VID:$1112;Name:'Rockwell / RNS division of Meret Communications Inc.'),
  (VID:$1113;Name:'Accton Technology Corporation'),
  (VID:$1114;Name:'Atmel Corporation'),
  (VID:$1115;Name:'DuPont Pixel Systems'),
  (VID:$1116;Name:'Data Translation / Media 100, Inc.'),
  (VID:$1117;Name:'Datacube Inc.'),
  (VID:$1118;Name:'Berg Electronics'),
  (VID:$1119;Name:'Vortex Computersysteme GmbH'),
  (VID:$111A;Name:'Efficient Networks, Inc.'),
  (VID:$111B;Name:'Teledyne Electronic Systems'),
  (VID:$111C;Name:'Tricord Systems, Inc.'),
  (VID:$111D;Name:'Integrated Device Technology'),
  (VID:$111E;Name:'Eldec Corporation'),
  (VID:$111F;Name:'Precision Digital Images'),
  (VID:$1120;Name:'EMC Corporation'),
  (VID:$1121;Name:'Zilog'),
  (VID:$1122;Name:'Multi-tech Systems, Inc.'),
  (VID:$1123;Name:'Excellent Design, Inc.'),
  (VID:$1124;Name:'Leutron Vision AG'),
  (VID:$1125;Name:'Eurocore'),
  (VID:$1126;Name:'Vigra'),
  (VID:$1127;Name:'FORE Systems'),
  (VID:$1129;Name:'Firmworks'),
  (VID:$112A;Name:'Hermes Electronics Co.'),
  (VID:$112B;Name:'Linotype - Hell AG'),
  (VID:$112C;Name:'ZENITH DATA Systems'),
  (VID:$112D;Name:'Ravicad'),
  (VID:$112E;Name:'Infomedia MicroElectronics Inc'),
  (VID:$112F;Name:'Imaging Technology'),
  (VID:$1130;Name:'Computervision'),
  (VID:$1131;Name:'Philips Semiconductors'),
  (VID:$1132;Name:'Mitel Corp'),
  (VID:$1133;Name:'Eicon Technology Corporation'),
  (VID:$1134;Name:'Mercury Computer Systems Inc'),
  (VID:$1135;Name:'Fuji Xerox Co Ltd'),
  (VID:$1136;Name:'Momentum Data Systems'),
  (VID:$1137;Name:'Cisco Systems Inc'),
  (VID:$1138;Name:'Ziatech Corporation'),
  (VID:$1139;Name:'Dynamic Pictures Inc'),
  (VID:$113A;Name:'FWB Inc'),
  (VID:$113B;Name:'Network computing devices'),
  (VID:$113C;Name:'Cyclone Microsystems (PLX)'),
  (VID:$113D;Name:'Leading Edge Products Inc'),
  (VID:$113E;Name:'Sanyo Electric Co. - Computer Engineering Dept.'),
  (VID:$113F;Name:'Equinox Systems'),
  (VID:$1140;Name:'Intervoice Inc'),
  (VID:$1141;Name:'Crest Microsystem Inc'),
  (VID:$1142;Name:'Alliance Semiconductor Corp'),
  (VID:$1143;Name:'Netpower, Inc.'),
  (VID:$1144;Name:'Cincinnati Milacron / Vickers Inc. Electronic Systems'),
  (VID:$1145;Name:'Workbit Corp'),
  (VID:$1146;Name:'Force Computers'),
  (VID:$1147;Name:'Interface Corp.'),
  (VID:$1148;Name:'Schneider & Koch Co. / Syskonnect'),
  (VID:$1149;Name:'Win System Corporation'),
  (VID:$114A;Name:'VMIC'),
  (VID:$114B;Name:'Canopus Co.'),
  (VID:$114C;Name:'Annabooks'),
  (VID:$114D;Name:'IC Corporation'),
  (VID:$114E;Name:'Nikon Systems Inc'),
  (VID:$114F;Name:'Digi International / Stargate'),
  (VID:$1150;Name:'Thinking Machines Corp.'),
  (VID:$1151;Name:'JAE Electronics Inc.'),
  (VID:$1152;Name:'Megatek'),
  (VID:$1153;Name:'Land Win Electronic Corp.'),
  (VID:$1154;Name:'Melco Inc.'),
  (VID:$1155;Name:'Pine Technology Ltd.'),
  (VID:$1156;Name:'Periscope Engineering'),
  (VID:$1157;Name:'Avsys Corporation'),
  (VID:$1158;Name:'Voarx R&D Inc.'),
  (VID:$1159;Name:'MuTech'),
  (VID:$115A;Name:'Harleguin Ltd.'),
  (VID:$115B;Name:'Parallax Graphics'),
  (VID:$115C;Name:'Photron, Ltd.'),
  (VID:$115D;Name:'Xircom'),
  (VID:$115E;Name:'Peer Protocols Inc.'),
  (VID:$115F;Name:'MAXTOR Corp'),
  (VID:$1160;Name:'Megasoft Inc.'),
  (VID:$1161;Name:'PFU Ltd.'),
  (VID:$1162;Name:'OA Laboratory Co Ltd.'),
  (VID:$1163;Name:'Creative Labs / Rendition'),
  (VID:$1164;Name:'Advanced Peripherals Tech'),
  (VID:$1165;Name:'Imagraph Corporation'),
  (VID:$1166;Name:'Pequr Technology Inc. / Relience Computer'),
  (VID:$1167;Name:'Mutoh Industries, Inc.'),
  (VID:$1168;Name:'Thine Electronics Inc'),
  (VID:$1169;Name:'Centre for Development of Advanced Computing'),
  (VID:$116A;Name:'Polaris Communications'),
  (VID:$116B;Name:'Connectware Inc'),
  (VID:$116C;Name:'Intelligent resources'),
  (VID:$116E;Name:'Electronics for imaging'),
  (VID:$116F;Name:'Workstation Technology'),
  (VID:$1170;Name:'Inventec Corporation'),
  (VID:$1171;Name:'Loughborough Sound Images'),
  (VID:$1172;Name:'Altera Corporation'),
  (VID:$1173;Name:'Adobe Systems'),
  (VID:$1174;Name:'Bridgeport Machines'),
  (VID:$1175;Name:'Mitron Computer Inc.'),
  (VID:$1176;Name:'SBE'),
  (VID:$1177;Name:'Silicon Engineering'),
  (VID:$1178;Name:'Alfa Inc'),
  (VID:$1179;Name:'Toshiba America Info Systems'),
  (VID:$117A;Name:'A-Trend Technology'),
  (VID:$117B;Name:'LG Electronics Inc.'),
  (VID:$117C;Name:'Atto Technology'),
  (VID:$117D;Name:'Becton Dickinson'),
  (VID:$117E;Name:'T/R Systems'),
  (VID:$117F;Name:'INTEGRATED CIRCUIT Systems'),
  (VID:$1180;Name:'Ricoh Co Ltd'),
  (VID:$1181;Name:'Telmatics International'),
  (VID:$1183;Name:'Fujikura Ltd'),
  (VID:$1184;Name:'Forks Inc'),
  (VID:$1185;Name:'Dataworld'),
  (VID:$1186;Name:'D-Link System Inc'),
  (VID:$1187;Name:'Advanced Technology Laboratories'),
  (VID:$1188;Name:'Shima Seiki Manufacturing Ltd.'),
  (VID:$1189;Name:'Matsushita Electronics'),
  (VID:$118A;Name:'Hilevel Technology'),
  (VID:$118B;Name:'HYPERTEC PTY Ltd'),
  (VID:$118C;Name:'Corollary Inc'),
  (VID:$118D;Name:'BitFlow Inc'),
  (VID:$118E;Name:'Hermstedt GmbH'),
  (VID:$118F;Name:'GREEN LOGIC'),
  (VID:$1190;Name:'Tripace'),
  (VID:$1191;Name:'Artop Electric / Acard Technology Corp.'),
  (VID:$1192;Name:'Densan Co. Ltd'),
  (VID:$1193;Name:'Zeitnet Inc.'),
  (VID:$1194;Name:'Toucan Technology'),
  (VID:$1195;Name:'Ratoc System Inc'),
  (VID:$1196;Name:'Hytec Electronics Ltd'),
  (VID:$1197;Name:'Gage Applied Sciences Inc.'),
  (VID:$1198;Name:'Lambda Systems Inc'),
  (VID:$1199;Name:'Digital Communications Associates Inc'),
  (VID:$119A;Name:'Mind Share Inc.'),
  (VID:$119B;Name:'Omega Micro Inc.'),
  (VID:$119C;Name:'Information Technology Inst.'),
  (VID:$119D;Name:'Bug Sapporo Japan'),
  (VID:$119E;Name:'Fujitsu'),
  (VID:$119F;Name:'Bull Hn Information Systems'),
  (VID:$11A0;Name:'Convex Computer Corporation'),
  (VID:$11A1;Name:'Hamamatsu Photonics K.K.'),
  (VID:$11A2;Name:'Sierra Research and Technology'),
  (VID:$11A3;Name:'Deuretzbacher GmbH & Co. Eng. KG'),
  (VID:$11A4;Name:'Barco'),
  (VID:$11A5;Name:'MicroUnity Systems Engineering, Inc.'),
  (VID:$11A6;Name:'Pure Data'),
  (VID:$11A7;Name:'Power Computing Corp.'),
  (VID:$11A9;Name:'InnoSys Inc.'),
  (VID:$11AA;Name:'Actel'),
  (VID:$11AB;Name:'Galileo Technology Ltd.'),
  (VID:$11AC;Name:'Canon Information Systems'),
  (VID:$11AD;Name:'Lite-On Communications Inc'),
  (VID:$11AE;Name:'Scitex Corporation Ltd'),
  (VID:$11AF;Name:'Pro-Log Corporation / Avid Technology Corp.'),
  (VID:$11B0;Name:'V3 Semiconductor Inc.'),
  (VID:$11B1;Name:'Apricot Computers'),
  (VID:$11B2;Name:'Eastman Kodak'),
  (VID:$11B3;Name:'Barr Systems Inc.'),
  (VID:$11B4;Name:'Leitch Technology International'),
  (VID:$11B5;Name:'Radstone Technology Plc'),
  (VID:$11B6;Name:'United Video Corp'),
  (VID:$11B7;Name:'Motorola'),
  (VID:$11B8;Name:'Xpoint Technologies Inc'),
  (VID:$11B9;Name:'Pathlight Technology Inc.'),
  (VID:$11BA;Name:'Videotron Corp'),
  (VID:$11BB;Name:'Pyramid Technology'),
  (VID:$11BC;Name:'Network Peripherals Inc'),
  (VID:$11BD;Name:'Pinnacle Systems Inc.'),
  (VID:$11BE;Name:'International Microcircuits Inc'),
  (VID:$11BF;Name:'Astrodesign, Inc.'),
  (VID:$11C0;Name:'HEWLETT PACKARD'),
  (VID:$11C1;Name:'AT&T Microelectronics (Lucent)'),
  (VID:$11C2;Name:'SAND microelectronics'),
  (VID:$11C3;Name:'NEC Corporation'),
  (VID:$11C4;Name:'Document Technologies Ind.'),
  (VID:$11C5;Name:'Shiva Corporatin'),
  (VID:$11C6;Name:'Dainippon Screen Mfg. Co., Ltd.'),
  (VID:$11C7;Name:'D.C.M. Data Systems'),
  (VID:$11C8;Name:'Dolphin Interconnect Solutions'),
  (VID:$11C9;Name:'MAGMA'),
  (VID:$11CA;Name:'LSI Systems Inc'),
  (VID:$11CB;Name:'Specialix International, Ltd.'),
  (VID:$11CC;Name:'Michels & Kleberhoff Computer GmbH'),
  (VID:$11CD;Name:'HAL Computer Systems Inc.'),
  (VID:$11CE;Name:'Netaccess'),
  (VID:$11CF;Name:'pioneer electronic Corp'),
  (VID:$11D0;Name:'Lockheed Martin Federal Systems-Manassas'),
  (VID:$11D1;Name:'Auravision'),
  (VID:$11D2;Name:'Intercom, Inc.'),
  (VID:$11D3;Name:'Trancell Systems Inc'),
  (VID:$11D4;Name:'Analog Devices'),
  (VID:$11D5;Name:'Ikon Corp.'),
  (VID:$11D6;Name:'TEKELEC Technologies'),
  (VID:$11D7;Name:'TRENTON TERMINALS Inc'),
  (VID:$11D8;Name:'IMAGE Technologies DEVELOPMENT'),
  (VID:$11D9;Name:'TEC Corp.'),
  (VID:$11DA;Name:'Novell'),
  (VID:$11DB;Name:'Sega Enterprises, Ltd.'),
  (VID:$11DC;Name:'QUESTRA Corp'),
  (VID:$11DD;Name:'CROSFIELD Electronics Ltd'),
  (VID:$11DE;Name:'Zoran Corporation'),
  (VID:$11DF;Name:'New Wave PDG'),
  (VID:$11E0;Name:'CRAY COMMUNICATIONS A/S'),
  (VID:$11E1;Name:'GEC Plessey Semi Inc.'),
  (VID:$11E2;Name:'Samsung Information Systems Americ'),
  (VID:$11E3;Name:'Quicklogic Corporation'),
  (VID:$11E4;Name:'Second Wave Inc.'),
  (VID:$11E5;Name:'IIX Consulting'),
  (VID:$11E6;Name:'Mitsui-Zosen System Research'),
  (VID:$11E7;Name:'TOSHIBA AMERICA, ELEC. Company'),
  (VID:$11E8;Name:'Digital Processing Systems Inc.'),
  (VID:$11E9;Name:'Highwater Designs Ltd'),
  (VID:$11EA;Name:'Elsag Bailey'),
  (VID:$11EB;Name:'Formation Inc.'),
  (VID:$11EC;Name:'Coreco Inc.'),
  (VID:$11ED;Name:'Mediamatics'),
  (VID:$11EE;Name:'Dome Imaging Systems Inc.'),
  (VID:$11EF;Name:'Nicolet Technologies B.V.'),
  (VID:$11F0;Name:'Compu-Shack GmbH'),
  (VID:$11F1;Name:'Symbios Logic Inc.'),
  (VID:$11F2;Name:'Picture Tel Japan K.K.'),
  (VID:$11F3;Name:'Keithley Metrabyte'),
  (VID:$11F4;Name:'Kinetic Systems Corporation'),
  (VID:$11F5;Name:'Computing Devices International'),
  (VID:$11F6;Name:'Powermatic Data Systems Ltd.'),
  (VID:$11F6;Name:'Compex USA, Inc.'),
  (VID:$11F7;Name:'Scientific Atlanta'),
  (VID:$11F8;Name:'PMC-Sierra Inc.'),
  (VID:$11F9;Name:'I-Cube, Inc.'),
  (VID:$11FA;Name:'KASAN Electronics Company Ltd'),
  (VID:$11FB;Name:'DATEL Inc'),
  (VID:$11FC;Name:'SILICON MAGIC'),
  (VID:$11FD;Name:'HIGH STREET CONSULTANTS'),
  (VID:$11FE;Name:'RP'),
  (VID:$11FF;Name:'SCION Corp'),
  (VID:$1200;Name:'CSS Corp'),
  (VID:$1201;Name:'Vista Controls Corp.'),
  (VID:$1202;Name:'NETWORK GENERAL Corp'),
  (VID:$1203;Name:'Bayer Corp., AGFA division'),
  (VID:$1204;Name:'Lattice Semiconductor Corp.'),
  (VID:$1205;Name:'Array Corp.'),
  (VID:$1206;Name:'Amdahl Corp.'),
  (VID:$1208;Name:'PARSYTEC GmbH'),
  (VID:$1209;Name:'SCI Systems Inc'),
  (VID:$120A;Name:'SYNAPTEL'),
  (VID:$120B;Name:'ADAPTIVE SOLUTIONS'),
  (VID:$120C;Name:'TECHNICAL Corp'),
  (VID:$120D;Name:'COMPRESSION LABS Inc'),
  (VID:$120E;Name:'Cyclades'),
  (VID:$120F;Name:'Essential Communications'),
  (VID:$1210;Name:'HYPERPARALLEL Technologies'),
  (VID:$1211;Name:'BRAINTECH Inc'),
  (VID:$1212;Name:'KINGSTON Technology Corp'),
  (VID:$1213;Name:'APPLIED INTELLIGENT Systems Inc'),
  (VID:$1214;Name:'PERFORMANCE Technologies Inc'),
  (VID:$1215;Name:'INTERWARE Co Ltd'),
  (VID:$1216;Name:'PURUP Eskofot A/S'),
  (VID:$1217;Name:'O2Micro, Inc.'),
  (VID:$1218;Name:'HYBRICON Corp'),
  (VID:$1219;Name:'FIRST VIRTUAL Corp'),
  (VID:$121A;Name:'3DFX Interactive, Inc.'),
  (VID:$121B;Name:'Advanced Telecomm Modules'),
  (VID:$121C;Name:'NIPPON TEXA Co Ltd'),
  (VID:$121D;Name:'LIPPERT AUTOMATIONSTECHNIK GmbH'),
  (VID:$121E;Name:'CSPI'),
  (VID:$121F;Name:'ARCUS Technology Inc'),
  (VID:$1220;Name:'Ariel Corporation'),
  (VID:$1220;Name:'AMCC 5933  TMS320C80 DSP/Imaging Board'),
  (VID:$1221;Name:'Contec Co., Ltd.'),
  (VID:$1222;Name:'Ancor Communications, Inc.'),
  (VID:$1223;Name:'Heurikon/Computer Products'),
  (VID:$1224;Name:'Interactive Images'),
  (VID:$1225;Name:'Power I/O, Inc.'),
  (VID:$1227;Name:'Tech-Source'),
  (VID:$1228;Name:'Norsk Elektro Optikk A/S'),
  (VID:$1229;Name:'Data Kinesis Inc.'),
  (VID:$122A;Name:'Integrated Telecom'),
  (VID:$122B;Name:'LG Industrial Systems Co. Ltd.'),
  (VID:$122C;Name:'Sican GmbH'),
  (VID:$122D;Name:'Aztech Systems Ltd'),
  (VID:$122E;Name:'Xyratex'),
  (VID:$122F;Name:'Andrew Corporation'),
  (VID:$1230;Name:'Fishcamp Engineering'),
  (VID:$1231;Name:'Woodward McCoach, Inc.'),
  (VID:$1232;Name:'GPT Limited'),
  (VID:$1233;Name:'Bus-Tech, Inc.'),
  (VID:$1234;Name:'Technical Corp.'),
  (VID:$1235;Name:'Risq Modular Systems, Inc. / Smart Modular Technologies, Inc.'),
  (VID:$1236;Name:'Sigma Designs Corporation'),
  (VID:$1237;Name:'Alta Technology Corporation'),
  (VID:$1238;Name:'Adtran'),
  (VID:$1239;Name:'The 3DO Company'),
  (VID:$123A;Name:'Visicom Laboratories, Inc.'),
  (VID:$123B;Name:'Seeq Technology, Inc.'),
  (VID:$123C;Name:'Century Systems, Inc.'),
  (VID:$123D;Name:'Engineering Design Team, Inc.'),
  (VID:$123E;Name:'Sumutech, Inc.'),
  (VID:$123F;Name:'C-Cube Microsystems'),
  (VID:$1240;Name:'Marathon Technologies Corp.'),
  (VID:$1241;Name:'DSC Communications'),
  (VID:$1242;Name:'(vendeur inconnu)'),
  (VID:$1243;Name:'Delphax'),
  (VID:$1244;Name:'AVM Audiovisuelles Mktg & Computer GmbH'),
  (VID:$1245;Name:'A.P.D., S.A.'),
  (VID:$1246;Name:'Dipix Technologies, Inc.'),
  (VID:$1247;Name:'Xylon Research, Inc.'),
  (VID:$1248;Name:'Central Data Corporation'),
  (VID:$1249;Name:'Samsung Electronics Co., Ltd.'),
  (VID:$124A;Name:'AEG Electrocom GmbH'),
  (VID:$124B;Name:'SBS/Greenspring Modular I/O'),
  (VID:$124C;Name:'Solitron Technologies, Inc.'),
  (VID:$124D;Name:'Stallion Technologies'),
  (VID:$124E;Name:'Cylink'),
  (VID:$124F;Name:'Infortrend Technology, Inc.'),
  (VID:$1250;Name:'Hitachi Microcomputer System, Ltd.'),
  (VID:$1251;Name:'VLSI Solution Oy'),
  (VID:$1253;Name:'Guzik Technical Enterprises'),
  (VID:$1254;Name:'Linear Systems Ltd.'),
  (VID:$1255;Name:'Optibase Ltd.'),
  (VID:$1256;Name:'Perceptive Solutions, Inc.'),
  (VID:$1257;Name:'Vertex Networks, Inc.'),
  (VID:$1258;Name:'Gilbarco, Inc.'),
  (VID:$1259;Name:'Allied telesyn International'),
  (VID:$125A;Name:'ABB Power Systems'),
  (VID:$125B;Name:'Asix Electronics Corporation'),
  (VID:$125C;Name:'Aurora Technologies, Inc.'),
  (VID:$125D;Name:'ESS Technology'),
  (VID:$125E;Name:'SpecialVideo Engineering SRL'),
  (VID:$125F;Name:'Concurrent Technologies, Inc.'),
  (VID:$1260;Name:'Harris Semiconductor'),
  (VID:$1261;Name:'Matsushita-Kotobuki Electronics Industries'),
  (VID:$1262;Name:'ES Computer Company, Ltd.'),
  (VID:$1263;Name:'Sonic Solutions'),
  (VID:$1264;Name:'Aval Nagasaki Corporation'),
  (VID:$1265;Name:'Casio Computer Co., Ltd.'),
  (VID:$1266;Name:'Microdyne Corporation'),
  (VID:$1267;Name:'S.A. Telecommunications'),
  (VID:$1268;Name:'Tektronix'),
  (VID:$1269;Name:'Thomson-CSF/TTM'),
  (VID:$126A;Name:'Lexmark International, Inc.'),
  (VID:$126B;Name:'Adax, Inc.'),
  (VID:$126C;Name:'Northern Telecom'),
  (VID:$126D;Name:'Splash Technology, Inc.'),
  (VID:$126E;Name:'Sumitomo Metal Industries, Ltd.'),
  (VID:$126F;Name:'Silicon Motion, Inc.'),
  (VID:$1270;Name:'Olympus Optical Co., Ltd.'),
  (VID:$1271;Name:'GW Instruments'),
  (VID:$1272;Name:'Telematics International'),
  (VID:$1273;Name:'Hughes Network Systems'),
  (VID:$1274;Name:'Ensoniq'),
  (VID:$1275;Name:'Network Appliance Corporation'),
  (VID:$1276;Name:'Switched Network Tecnologies, Inc.'),
  (VID:$1277;Name:'Comstream'),
  (VID:$1278;Name:'Transtech Parallel Systems Ltd.'),
  (VID:$1279;Name:'Transmeta Corporation'),
  (VID:$127A;Name:'Rockwell Semiconductor Systems'),
  (VID:$127B;Name:'Pixera Corporation'),
  (VID:$127C;Name:'Crosspoint Solutions, Inc.'),
  (VID:$127D;Name:'Vela Research'),
  (VID:$127E;Name:'Winnov, L.P.'),
  (VID:$127F;Name:'Fujifilm'),
  (VID:$1280;Name:'Photoscript Group Ltd.'),
  (VID:$1281;Name:'Yokogawa Electric Corporation'),
  (VID:$1282;Name:'Davicom Semiconductor, Inc.'),
  (VID:$1283;Name:'Integrated Technology Express, Inc.'),
  (VID:$1284;Name:'Sahara Networks, Inc.'),
  (VID:$1285;Name:'Platform Technologies, Inc.'),
  (VID:$1286;Name:'Mazet GmbH'),
  (VID:$1287;Name:'M-Pact, Inc. / Luxsonor, Inc.'),
  (VID:$1288;Name:'Timestep Corporation'),
  (VID:$1289;Name:'AVC Technology, Inc.'),
  (VID:$128A;Name:'Asante Technologies, Inc.'),
  (VID:$128B;Name:'Transwitch Corporation'),
  (VID:$128C;Name:'Retix Corporation / Sonoma Systems, Inc.'),
  (VID:$128D;Name:'G2 Networks, Inc.'),
  (VID:$128C;Name:'Retix Corp'),
  (VID:$128D;Name:'G2 Networks Inc'),
  (VID:$128E;Name:'Samho Multi Tech Ltd. / Hoon Tech Co., Ltd.'),
  (VID:$128F;Name:'Tateno Dennou, Inc.'),
  (VID:$1290;Name:'Sord Computer Corporation'),
  (VID:$1291;Name:'NCS Computer Italia'),
  (VID:$1292;Name:'Tritech Microelectronics, Inc.'),
  (VID:$1293;Name:'Media Reality Technology'),
  (VID:$1294;Name:'Rhetorex, Inc.'),
  (VID:$1295;Name:'Imagenation Corporation'),
  (VID:$1296;Name:'Kofax Image Products'),
  (VID:$1297;Name:'Holco Ent Co, Ltd / Shuttle Computer'),
  (VID:$1298;Name:'Spellcaster Telecommunications Inc.'),
  (VID:$1299;Name:'Knowledge Technology Lab.'),
  (VID:$129A;Name:'VMetro, Inc.'),
  (VID:$129B;Name:'Image Access'),
  (VID:$129C;Name:'Jaycor / Xantel Corporation'),
  (VID:$129D;Name:'Compcore Multimedia, Inc.'),
  (VID:$129E;Name:'Victor Company of Japan, Ltd.'),
  (VID:$129F;Name:'OEC Medical Systems, Inc.'),
  (VID:$12A0;Name:'Allen-Bradley Company'),
  (VID:$12A1;Name:'Simpact Associates, Inc.'),
  (VID:$12A2;Name:'Newgen Systems Corporation'),
  (VID:$12A3;Name:'Lucent Technologies'),
  (VID:$12A4;Name:'NTT Electronics Technology Company'),
  (VID:$12A5;Name:'Vision Dynamics Ltd.'),
  (VID:$12A6;Name:'Scalable Networks, Inc.'),
  (VID:$12A7;Name:'AMO GmbH'),
  (VID:$12A8;Name:'News Datacom'),
  (VID:$12A9;Name:'Xiotech Corporation'),
  (VID:$12AA;Name:'SDL Communications, Inc.'),
  (VID:$12AB;Name:'Yuan Yuan Enterprise Co., Ltd.'),
  (VID:$12AC;Name:'MeasureX Corporation'),
  (VID:$12AD;Name:'Multidata GmbH'),
  (VID:$12AE;Name:'Alteon Networks, inc.'),
  (VID:$12AF;Name:'TDK USA Corporation'),
  (VID:$12B0;Name:'Jorge Scientific Corporation'),
  (VID:$12B1;Name:'GammaLink'),
  (VID:$12B2;Name:'General Signal Networks'),
  (VID:$12B3;Name:'Inter-Face Co. Ltd.'),
  (VID:$12B4;Name:'FutureTel Inc.'),
  (VID:$12B5;Name:'Granite Systems Inc.'),
  (VID:$12B6;Name:'Natural Microsystems'),
  (VID:$12B7;Name:'Acumen'),
  (VID:$12B8;Name:'Korg'),
  (VID:$12B9;Name:'US Robotics / 3com Corporation'),
  (VID:$12BA;Name:'PMC Sierra'),
  (VID:$12BB;Name:'Nippon Unisoft Corporation'),
  (VID:$12BC;Name:'Array Microsystems'),
  (VID:$12BD;Name:'Computerm Corp.'),
  (VID:$12BE;Name:'Anchor Chips'),
  (VID:$12BF;Name:'Fujifilm Microdevices'),
  (VID:$12C0;Name:'InfiMed'),
  (VID:$12C1;Name:'GMM Research Corp.'),
  (VID:$12C2;Name:'Mentec Limited'),
  (VID:$12C3;Name:'Holtek Microelectronics Inc.'),
  (VID:$12C4;Name:'Connect Tech Inc.'),
  (VID:$12C5;Name:'Picture Elements, Inc.'),
  (VID:$12C6;Name:'Mitani Corporation'),
  (VID:$12C7;Name:'Dialogic Corporation'),
  (VID:$12C8;Name:'G Force Co, Ltd.'),
  (VID:$12C9;Name:'Gigi Operations'),
  (VID:$12CA;Name:'Integrated Computing Engines'),
  (VID:$12CB;Name:'Antex Electronics Corporation'),
  (VID:$12CC;Name:'Pluto Technologies International'),
  (VID:$12CD;Name:'Aims Lab'),
  (VID:$12CE;Name:'Netspeed, Inc.'),
  (VID:$12CF;Name:'Prophet Systems, Inc.'),
  (VID:$12D0;Name:'GDE Systems, Inc.'),
  (VID:$12D1;Name:'Psitech'),
  (VID:$12D2;Name:'NVIDIA / SGS Thomson'),
  (VID:$12D3;Name:'Vingmed Sound A/S'),
  (VID:$12D4;Name:'DGM&S'),
  (VID:$12D5;Name:'Equator Technologies'),
  (VID:$12D6;Name:'Analogic Corporation'),
  (VID:$12D7;Name:'Biotronic SRL'),
  (VID:$12D8;Name:'Pericom Semiconductor'),
  (VID:$12D9;Name:'Aculab PLC'),
  (VID:$12DA;Name:'True Time'),
  (VID:$12DB;Name:'Annapolis Micro Systems, Inc.'),
  (VID:$12DC;Name:'Symicron Computer Communication Ltd.'),
  (VID:$12DD;Name:'Management Graphics'),
  (VID:$12DE;Name:'Rainbow Technologies'),
  (VID:$12DF;Name:'SBS Technologies Inc.'),
  (VID:$12E0;Name:'Chase Research'),
  (VID:$12E1;Name:'Nintendo Co, Ltd.'),
  (VID:$12E2;Name:'Datum Inc, Bancomm-Timing Division'),
  (VID:$12E3;Name:'Imation Corp - Medical Imaging Systems'),
  (VID:$12E4;Name:'Brooktrout Technology Inc.'),
  (VID:$12E5;Name:'Apex Inc / XCD Inc.'),
  (VID:$12E6;Name:'Cirel Systems'),
  (VID:$12E7;Name:'Sunsgroup Corporation / Sebring Systems'),
  (VID:$12E8;Name:'CRISC Corporation'),
  (VID:$12E9;Name:'GE Spacenet'),
  (VID:$12EA;Name:'Zuken / Real Vision, Inc.'),
  (VID:$12EB;Name:'Aureal Semiconductor'),
  (VID:$12EC;Name:'3A International, Inc.'),
  (VID:$12ED;Name:'Optivision Inc.'),
  (VID:$12EE;Name:'Orange Micro'),
  (VID:$12EF;Name:'Vienna Systems'),
  (VID:$12F0;Name:'Pentek'),
  (VID:$12F1;Name:'Sorenson Vision Inc.'),
  (VID:$12F2;Name:'GammaGraphx, Inc.'),
  (VID:$12F3;Name:'XING, Inc.'),
  (VID:$12F4;Name:'Megatel'),
  (VID:$12F5;Name:'Forks'),
  (VID:$12F6;Name:'Dawson France'),
  (VID:$12F7;Name:'Cognex'),
  (VID:$12F8;Name:'Electronic-Design GmbH'),
  (VID:$12F9;Name:'FourFold Technologies'),
  (VID:$12FB;Name:'Spectrum Signal Processing'),
  (VID:$12FC;Name:'Capital Equipment Corp.'),
  (VID:$12FD;Name:'i2S'),
  (VID:$12FE;Name:'ESD Electronic System Design GmbH'),
  (VID:$12FF;Name:'Lexicon'),
  (VID:$1300;Name:'Harman International Industries, Inc.'),
  (VID:$1302;Name:'Computer Sciences Corp.'),
  (VID:$1303;Name:'Innovative Integration'),
  (VID:$1304;Name:'Juniper Networks'),
  (VID:$1305;Name:'NetPhone, Inc.'),
  (VID:$1306;Name:'Duet Technologies'),
  (VID:$1307;Name:'Computer Boards'),
  (VID:$1308;Name:'Jato Technologies, Inc.'),
  (VID:$1309;Name:'AB Semicon, Ltd.'),
  (VID:$130A;Name:'Mitsubishi Electric MicroComputer'),
  (VID:$130B;Name:'Colorgraphic Communications Corp.'),
  (VID:$130C;Name:'AMBEX Technologies, Inc.'),
  (VID:$130D;Name:'Accelerix, Inc.'),
  (VID:$130E;Name:'Yamatake-Honeywell Co., Ltd.'),
  (VID:$130F;Name:'Advanet, Inc.'),
  (VID:$1310;Name:'GESPAC'),
  (VID:$1311;Name:'VideoServer, Inc.'),
  (VID:$1312;Name:'Acuity Imaging, Inc.'),
  (VID:$1313;Name:'Yaskawa Electric Co.'),
  (VID:$1316;Name:'Teradyne, Inc.'),
  (VID:$1317;Name:'Bridgecom, Inc.'),
  (VID:$1318;Name:'Packet Engines, Inc.'),
  (VID:$1319;Name:'ForteMedia, Inc.'),
  (VID:$131A;Name:'Finisar Corp.'),
  (VID:$131C;Name:'Nippon Electro-Sensory Devices Corp.'),
  (VID:$131D;Name:'Sysmic, Inc.'),
  (VID:$131E;Name:'Xinex Networks, Inc.'),
  (VID:$131F;Name:'SIIG, Inc.'),
  (VID:$1320;Name:'Crypto AG'),
  (VID:$1321;Name:'Arcobel Graphics BV'),
  (VID:$1322;Name:'MTT Co., Ltd.'),
  (VID:$1323;Name:'DOME, Inc.'),
  (VID:$1324;Name:'Sphere Communications'),
  (VID:$1325;Name:'Salix Technologies, Inc.'),
  (VID:$1326;Name:'SeaChange International'),
  (VID:$1327;Name:'Voss Scientific'),
  (VID:$1328;Name:'Quadrant International'),
  (VID:$1329;Name:'Productivity Enhancement'),
  (VID:$132A;Name:'Microcom, Inc.'),
  (VID:$132B;Name:'BroadBand Technologies'),
  (VID:$132C;Name:'Micrel, Inc.'),
  (VID:$132D;Name:'Integrated Silicon Solution, Inc.'),
  (VID:$131E;Name:'Xinex Networks Inc'),
  (VID:$131F;Name:'SIIG Inc'),
  (VID:$1320;Name:'Crypto AG'),
  (VID:$1321;Name:'Arcobel Graphics BV'),
  (VID:$1322;Name:'MTT Co Ltd'),
  (VID:$1323;Name:'DOME Inc'),
  (VID:$1324;Name:'Sphere Communications'),
  (VID:$1325;Name:'Salix Technologies Inc'),
  (VID:$1326;Name:'SeaChange International'),
  (VID:$1327;Name:'Voss Scientific'),
  (VID:$1328;Name:'Quadrant International'),
  (VID:$1329;Name:'Productivity Enhancement'),
  (VID:$132A;Name:'Microcom Inc'),
  (VID:$132B;Name:'BroadBand Technologies'),
  (VID:$132C;Name:'Micrel Inc'),
  (VID:$132D;Name:'Integrated Silicon Solution Inc'),
  (VID:$1330;Name:'MMC Networks'),
  (VID:$1331;Name:'RadiSys Corporation'),
  (VID:$1332;Name:'Micro Memory'),
  (VID:$1334;Name:'Redcreek Communications, Inc.'),
  (VID:$1335;Name:'Videomail, Inc.'),
  (VID:$1337;Name:'Third Planet Publishing'),
  (VID:$1338;Name:'BT Electronics'),
  (VID:$133A;Name:'VTEL Corp.'),
  (VID:$133B;Name:'Softcom Microsystems'),
  (VID:$133C;Name:'Holontech Corp.'),
  (VID:$133D;Name:'S S Technologies'),
  (VID:$133E;Name:'Virtual Computer Corp.'),
  (VID:$133F;Name:'SCM Microsystems'),
  (VID:$1340;Name:'Atalla Corp.'),
  (VID:$1341;Name:'Kyoto Microcomputer Co.'),
  (VID:$1342;Name:'Promax Systems Inc.'),
  (VID:$1343;Name:'Phylon Communications, Inc.'),
  (VID:$1344;Name:'Crucial Technology'),
  (VID:$1345;Name:'Arescom, Inc.'),
  (VID:$1347;Name:'Odetics'),
  (VID:$1349;Name:'Sumitomo Electric Industries, Ltd.'),
  (VID:$134A;Name:'DTC Technology Corp.'),
  (VID:$134B;Name:'Ark Research Corp.'),
  (VID:$134C;Name:'Chori Joho System Co., Ltd.'),
  (VID:$134D;Name:'Pctel, Inc.'),
  (VID:$134E;Name:'CSTI'),
  (VID:$134F;Name:'Algo System Co., Ltd.'),
  (VID:$1350;Name:'Systec Co., Ltd.'),
  (VID:$1351;Name:'Sonix, Inc.'),
  (VID:$1353;Name:'Dassault A.T.'),
  (VID:$1354;Name:'dWave System, Inc.'),
  (VID:$1355;Name:'Kratos Analytical, Ltd.'),
  (VID:$1356;Name:'The Logical Co.'),
  (VID:$1359;Name:'Prisa Networks'),
  (VID:$135A;Name:'Brain Boxes'),
  (VID:$135B;Name:'Giganet, Inc.'),
  (VID:$135C;Name:'Quatech, Inc.'),
  (VID:$135D;Name:'ABB Network Partner AB'),
  (VID:$135E;Name:'Sealevel Systems, Inc.'),
  (VID:$135F;Name:'I-Data International A-S'),
  (VID:$1360;Name:'Meinberg Funkuhren'),
  (VID:$1361;Name:'Soliton Systems K.K.'),
  (VID:$1362;Name:'Fujifacom Corp.'),
  (VID:$1363;Name:'Phoenix Technology, Ltd.'),
  (VID:$1364;Name:'ATM Communications, Inc.'),
  (VID:$1365;Name:'Hypercope Corp.'),
  (VID:$1366;Name:'Teijin Seiki Co., Ltd.'),
  (VID:$1367;Name:'Hitachi Zosen Corp.'),
  (VID:$1368;Name:'Skyware Corp.'),
  (VID:$1369;Name:'Digigram'),
  (VID:$136A;Name:'High Soft Tech'),
  (VID:$136B;Name:'Kawasaki Steel Corp.'),
  (VID:$136C;Name:'Adtek System Science Co., Ltd.'),
  (VID:$136D;Name:'Gigalabs, Ltd.'),
  (VID:$136F;Name:'Applied Magic, Inc.'),
  (VID:$1370;Name:'ATL Products'),
  (VID:$1371;Name:'CNET Technology, Inc.'),
  (VID:$1373;Name:'Silicon Vision, Inc.'),
  (VID:$1374;Name:'Silicom, Ltd.'),
  (VID:$1375;Name:'Argosystems, Inc.'),
  (VID:$1376;Name:'LMC'),
  (VID:$1377;Name:'Electronic Equipment Production'),
  (VID:$1378;Name:'Telemann Co., Ltd.'),
  (VID:$1379;Name:'Asahi Kasei Microsystems Co., Ltd.'),
  (VID:$137A;Name:'Mark Of The Unicorn, Inc.'),
  (VID:$137B;Name:'PPT Vision'),
  (VID:$137C;Name:'Iwatsu Electric Co., Ltd.'),
  (VID:$137D;Name:'Dynachip Corp.'),
  (VID:$137E;Name:'Patriot Scientific Corp.'),
  (VID:$137F;Name:'Japan Satellite Systems, Inc.'),
  (VID:$1380;Name:'Sanritz Automation Co., Ltd.'),
  (VID:$1381;Name:'Brains Co., Ltd.'),
  (VID:$1382;Name:'Marian - Electronic & Software'),
  (VID:$1383;Name:'Controlnet, Inc.'),
  (VID:$1384;Name:'Reality Simulation Systems, Inc.'),
  (VID:$1385;Name:'Netgear'),
  (VID:$1386;Name:'Video Domain Technologies'),
  (VID:$1387;Name:'Systran Corp.'),
  (VID:$1388;Name:'Hitachi Information Technology Co., Ltd.'),
  (VID:$1389;Name:'Applicom International'),
  (VID:$138A;Name:'Fusion Micromedia Corp.'),
  (VID:$138B;Name:'Tokimec, Inc.'),
  (VID:$138C;Name:'Silicon Reality'),
  (VID:$138D;Name:'Future Techno Designs Pte., Ltd.'),
  (VID:$138E;Name:'Basler GmbH'),
  (VID:$138F;Name:'Patapsco Designs, Inc.'),
  (VID:$1390;Name:'Concept Development, Inc.'),
  (VID:$1391;Name:'Development Concepts, Inc.'),
  (VID:$1392;Name:'Medialight, Inc.'),
  (VID:$1394;Name:'Level One Communications'),
  (VID:$1395;Name:'Ambicom, Inc.'),
  (VID:$1396;Name:'Cipher Systems, Inc.'),
  (VID:$1397;Name:'Cologne Chip Designs GmbH'),
  (VID:$1398;Name:'Clarion Co., Ltd.'),
  (VID:$1399;Name:'Rios Systems Co., Ltd.'),
  (VID:$139A;Name:'Alacritech, Inc.'),
  (VID:$139B;Name:'Mediasonic Multimedia Systems, Ltd.'),
  (VID:$139C;Name:'Quantum 3D, Inc.'),
  (VID:$139D;Name:'EPL, Ltd.'),
  (VID:$139E;Name:'Media4'),
  (VID:$139F;Name:'Aethra S.R.L.'),
  (VID:$13A0;Name:'Crystal Group, Inc.'),
  (VID:$13A1;Name:'Kawasaki Heavy Industries, Ltd.'),
  (VID:$13A2;Name:'Ositech Communications, Inc.'),
  (VID:$13A3;Name:'HI-FN'),
  (VID:$13A4;Name:'Rascom, Inc.'),
  (VID:$13A5;Name:'Audio Digital Imaging, Inc.'),
  (VID:$13A6;Name:'Videonics, Inc.'),
  (VID:$13A7;Name:'Teles AG'),
  (VID:$13A8;Name:'Exar Corp.'),
  (VID:$13A9;Name:'Ultrasound Group'),
  (VID:$13AA;Name:'Broadband Networks, Inc.'),
  (VID:$13AB;Name:'Arcom Control Systems, Ltd.'),
  (VID:$13AC;Name:'Motion Media Technology, Ltd.'),
  (VID:$13AD;Name:'Nexus, Inc.'),
  (VID:$13AE;Name:'ALD Technology, Ltd.'),
  (VID:$13AF;Name:'T.Sqware'),
  (VID:$13B0;Name:'Maxspeed Corp.'),
  (VID:$13B1;Name:'Tamura Corp.'),
  (VID:$13B2;Name:'Techno Chips Co., Ltd.'),
  (VID:$13B3;Name:'Lanart Corp.'),
  (VID:$13B4;Name:'Wellbean Co, Inc.'),
  (VID:$13B5;Name:'ARM'),
  (VID:$13B6;Name:'DLoG GmbH'),
  (VID:$13B7;Name:'LOGIC Devices, Inc.'),
  (VID:$13B8;Name:'Nokia Telecommunications Oy'),
  (VID:$13B9;Name:'Elecom Co., Ltd.'),
  (VID:$13BA;Name:'Oxford Instruments'),
  (VID:$13BB;Name:'Sanyo Technosound Co., Ltd.'),
  (VID:$13BC;Name:'Bitran Corp.'),
  (VID:$13BD;Name:'Sharp Corp.'),
  (VID:$13BE;Name:'Miroku Jyoho Service Co., Ltd.'),
  (VID:$13BF;Name:'Sharewave., Inc.'),
  (VID:$13C0;Name:'Microgate Corp.'),
  (VID:$13C1;Name:'3ware Inc.'),
  (VID:$13C2;Name:'Technotrend Systemtechnik GmbH'),
  (VID:$13C3;Name:'Janz Computer AG'),
  (VID:$13C4;Name:'Phase Metrics'),
  (VID:$13C5;Name:'Alphi Technology Corp.'),
  (VID:$13C6;Name:'Condor Engineering, Inc.'),
  (VID:$13C7;Name:'Blue Chip Technology, Ltd.'),
  (VID:$13C8;Name:'Apptech, Inc.'),
  (VID:$13C9;Name:'Eaton Corp.'),
  (VID:$13CA;Name:'IOMEGA Corp.'),
  (VID:$13CB;Name:'Yano Electric Co., Ltd.'),
  (VID:$13CC;Name:'Metheus Corp.'),
  (VID:$13CD;Name:'Compatible Systems Corp.'),
  (VID:$13CE;Name:'Cocom A/S'),
  (VID:$13CF;Name:'Studio Audio & Video, Ltd.'),
  (VID:$13D0;Name:'Techsan Electronics Co., Ltd.'),
  (VID:$13D1;Name:'Abocom Systems, Inc.'),
  (VID:$13D2;Name:'Shark Multimedia, Inc.'),
  (VID:$13D3;Name:'IMC Networks'),
  (VID:$13D4;Name:'Graphics Microsystems, Inc.'),
  (VID:$13D5;Name:'Media 100, Inc.'),
  (VID:$13D6;Name:'K.I. Technology Co., Inc.'),
  (VID:$13D7;Name:'Toshiba Engineering Corp.'),
  (VID:$13D8;Name:'Phobos Corp.'),
  (VID:$13D9;Name:'Apex PC Solutions, Inc.'),
  (VID:$13DA;Name:'Intresource Systems Pte., Ltd.'),
  (VID:$13DB;Name:'Janich & Klass Computertechnik GmbH'),
  (VID:$13DC;Name:'Netboost Corp.'),
  (VID:$13DD;Name:'Multimedia Bundle, Inc.'),
  (VID:$13DE;Name:'ABB Robotics Products AB'),
  (VID:$13DF;Name:'E-Tech, Inc.'),
  (VID:$13E0;Name:'GVC Corp.'),
  (VID:$13E1;Name:'Silicom Multimedia Systems, Inc.'),
  (VID:$13E2;Name:'Dynamics Research Corp.'),
  (VID:$13E3;Name:'Nest, Inc.'),
  (VID:$13E4;Name:'Calculex, Inc.'),
  (VID:$13E5;Name:'Telesoft Design, Ltd.'),
  (VID:$13E6;Name:'Argosy Research, Inc.'),
  (VID:$13E7;Name:'NAC, Inc.'),
  (VID:$13E8;Name:'Chip Express Corp.'),
  (VID:$13E9;Name:'Intraserver Technology, Inc.'),
  (VID:$13EA;Name:'Dallas Semiconductor'),
  (VID:$13EB;Name:'Hauppauge Computer Works, Inc.'),
  (VID:$13EC;Name:'Zydacron, Inc.'),
  (VID:$13ED;Name:'Raytheion E-Systems'),
  (VID:$13EE;Name:'Hayes Microcomputer Products, Inc.'),
  (VID:$13EF;Name:'Coppercom Inc'),
  (VID:$13F0;Name:'Sundance Technology, Inc.'),
  (VID:$13F1;Name:'Oce'' - Technologies B.V.'),
  (VID:$13F2;Name:'Ford Microelectronics, Inc.'),
  (VID:$13F3;Name:'McData Corp.'),
  (VID:$13F4;Name:'Troika Design, Inc.'),
  (VID:$13F5;Name:'Kansai Electric Co., Ltd.'),
  (VID:$13F6;Name:'C-Media Electronics, Inc.'),
  (VID:$13F7;Name:'Wildfire Communications'),
  (VID:$13F8;Name:'Ad Lib Multimedia, Inc.'),
  (VID:$13F9;Name:'NTT Advanced Technology Corp.'),
  (VID:$13FA;Name:'Pentland Systems, Ltd.'),
  (VID:$13FB;Name:'Aydin Corp.'),
  (VID:$13FC;Name:'Computer Peripherals International'),
  (VID:$13FD;Name:'Micro Science, Inc.'),
  (VID:$13FE;Name:'Advantech Co., Ltd.'),
  (VID:$13FF;Name:'Silicon Spice, Inc.'),
  (VID:$1400;Name:'ARTX, Inc.'),
  (VID:$1401;Name:'CR-Systems A/S'),
  (VID:$1402;Name:'Meilhaus Electronic GmbH'),
  (VID:$1403;Name:'Ascor, Inc.'),
  (VID:$1404;Name:'Fundamental Software, Inc.'),
  (VID:$1405;Name:'Excalibur Systems, Inc.'),
  (VID:$1406;Name:'Oce'' Printing Systems GmbH'),
  (VID:$1407;Name:'Lava Computer Mfg., Inc.'),
  (VID:$1408;Name:'Aloka Co., Ltd.'),
  (VID:$1409;Name:'Timedia Technology Co., Ltd.'),
  (VID:$140A;Name:'DSP Research, Inc.'),
  (VID:$140B;Name:'Ramix, Inc.'),
  (VID:$140C;Name:'Elmic Systems, Inc.'),
  (VID:$140D;Name:'Matsushita Electrics Works, Ltd.'),
  (VID:$140E;Name:'Goepel Electronic GmbH'),
  (VID:$140F;Name:'Salient Systems Corp.'),
  (VID:$1410;Name:'Midas Lab, Inc.'),
  (VID:$1411;Name:'Ikos Systems, Inc.'),
  (VID:$1412;Name:'IC Ensemble, Inc.'),
  (VID:$1413;Name:'Addonics'),
  (VID:$1414;Name:'Microsoft'),
  (VID:$1415;Name:'Oxford Semiconductor, Ltd.'),
  (VID:$1416;Name:'Multiwave Innovation Pte, Ltd.'),
  (VID:$1417;Name:'Convergenet Technologies, Inc.'),
  (VID:$1418;Name:'Kyushu Electronics Systems, Inc.'),
  (VID:$1419;Name:'Excel Switching Corp.'),
  (VID:$141A;Name:'Apache Micro Peripherals, Inc.'),
  (VID:$141B;Name:'Zoom Telephonics, Inc.'),
  (VID:$141D;Name:'Digitan Systems, Inc.'),
  (VID:$141E;Name:'Fanuc, Ltd.'),
  (VID:$141F;Name:'Visiontech, Ltd.'),
  (VID:$1420;Name:'Psion Dacom PLC'),
  (VID:$1421;Name:'ADS Technologies, Inc.'),
  (VID:$1422;Name:'Ygrec Systems Co., Ltd.'),
  (VID:$1423;Name:'Custom Technology Corp.'),
  (VID:$1424;Name:'Vidoeserver Connections'),
  (VID:$1425;Name:'ASIC Designers, Inc.'),
  (VID:$1426;Name:'Storage Technology Corp.'),
  (VID:$1427;Name:'Better On-line Solutions'),
  (VID:$1428;Name:'EDEC Co., Ltd.'),
  (VID:$1429;Name:'UNEX Technology Corp.'),
  (VID:$142A;Name:'Kingmax Technology, Inc.'),
  (VID:$142B;Name:'RadioLAN'),
  (VID:$142C;Name:'Minton Optic Industry Co., Ltd.'),
  (VID:$142D;Name:'Pix Stream, Inc.'),
  (VID:$142E;Name:'Vitec Multimedia'),
  (VID:$142F;Name:'Radicom Research, Inc.'),
  (VID:$1430;Name:'ITT Aerospace/Communications Division'),
  (VID:$1431;Name:'Gilat Satellite Networks'),
  (VID:$1432;Name:'Edimax Computer Co.'),
  (VID:$1433;Name:'Eltec Elektronik GmbH'),
  (VID:$1435;Name:'Real Time Devices US, Inc.'),
  (VID:$1436;Name:'CIS Technology, Inc.'),
  (VID:$1437;Name:'Nissin Co Inc'),
  (VID:$1438;Name:'Atmel-Dream'),
  (VID:$1439;Name:'Outsource Engineering & Mfg. Inc'),
  (VID:$143A;Name:'Stargate Solutions Inc'),
  (VID:$143B;Name:'Canon Research Center, America'),
  (VID:$143C;Name:'Amlogic Inc'),
  (VID:$143D;Name:'Tamarack Microelectronics Inc'),
  (VID:$143E;Name:'JONES FUTUREX Inc'),
  (VID:$143F;Name:'Lightwell Co Ltd - Zax Division'),
  (VID:$1440;Name:'Algol Corp'),
  (VID:$1441;Name:'AGIE LTD'),
  (VID:$1442;Name:'Phoenix Contact Co GmbH'),
  (VID:$1443;Name:'Unibrain S.A.'),
  (VID:$1444;Name:'TRW'),
  (VID:$1445;Name:'Logical do Ltd'),
  (VID:$1446;Name:'Graphin Co Ltd'),
  (VID:$1447;Name:'AIM GmbH'),
  (VID:$1448;Name:'Alesis Studio'),
  (VID:$1449;Name:'TUT Systems Inc'),
  (VID:$144A;Name:'Adlink Technology'),
  (VID:$144B;Name:'Loronix Information Systems Inc'),
  (VID:$144C;Name:'Catalina Research Inc'),
  (VID:$144D;Name:'SAMSUNG Electronics Co Ltd'),
  (VID:$144E;Name:'Olitec'),
  (VID:$144F;Name:'Askey Computer Corp'),
  (VID:$1450;Name:'Nexus Systems Inc'),
  (VID:$1451;Name:'SP3D Chip Design GmbH'),
  (VID:$1453;Name:'Mycom Inc'),
  (VID:$1454;Name:'Altiga Networks'),
  (VID:$1455;Name:'Logic Plus Plus Inc'),
  (VID:$1456;Name:'Advanced Hardware'),
  (VID:$1457;Name:'Nuera Communications Inc'),
  (VID:$1458;Name:'Giga-Byte Technology'),
  (VID:$1459;Name:'Dooin Electronics'),
  (VID:$145A;Name:'Escalate Networks Inc'),
  (VID:$145B;Name:'Praim SRL'),
  (VID:$145C;Name:'Cryptek'),
  (VID:$145D;Name:'Gallant Computer Inc'),
  (VID:$145E;Name:'Aashima Technology B.V.'),
  (VID:$145F;Name:'Baldor Electric Company'),
  (VID:$1460;Name:'Dynarc Inc'),
  (VID:$1461;Name:'Avermedia Technologies Inc'),
  (VID:$1462;Name:'Micro-Star International Co Ltd'),
  (VID:$1463;Name:'Fast Corp'),
  (VID:$1464;Name:'Interactive Circuits & Systems Ltd'),
  (VID:$1465;Name:'GN Nettest Telecom Div.'),
  (VID:$1466;Name:'Designpro Inc'),
  (VID:$1467;Name:'Digicom SPA'),
  (VID:$1468;Name:'Ambit microsystem Corp'),
  (VID:$1469;Name:'Cleveland Motion Controls'),
  (VID:$146A;Name:'IFR Ltd'),
  (VID:$146B;Name:'Parascan Technologies Ltd'),
  (VID:$146C;Name:'Ruby Tech Corp'),
  (VID:$146D;Name:'Tachyon Inc'),
  (VID:$146E;Name:'Williams Electronic Games Inc'),
  (VID:$146F;Name:'Multi Dimensional Consulting Inc'),
  (VID:$1470;Name:'Bay Networks'),
  (VID:$1471;Name:'Integrated Telecom Express Inc'),
  (VID:$1472;Name:'Daikin Indistries Ltd'),
  (VID:$1473;Name:'Zapex Technologies Inc'),
  (VID:$1474;Name:'Doug Carson & Associates'),
  (VID:$1475;Name:'Picazo Communications'),
  (VID:$1476;Name:'Mortara Instrument Inc'),
  (VID:$1477;Name:'Net Insight'),
  (VID:$1478;Name:'Diatrend Corp'),
  (VID:$1479;Name:'Toray Industries Inc'),
  (VID:$147A;Name:'Formosa Industrial Computing'),
  (VID:$147B;Name:'Abit Computer Corp'),
  (VID:$147C;Name:'Aware Inc'),
  (VID:$147D;Name:'Interworks Computer Products'),
  (VID:$147E;Name:'Matsushita Graphic Communication Systems Inc'),
  (VID:$147F;Name:'Nihon Unisys Ltd'),
  (VID:$1480;Name:'SCII Telecom'),
  (VID:$1481;Name:'Biopac Systems Inc'),
  (VID:$1482;Name:'ISYTEC'),
  (VID:$1483;Name:'Labway Corp'),
  (VID:$1484;Name:'LOGIC COPORATION'),
  (VID:$1485;Name:'ERMA - Electronic GmbH'),
  (VID:$1486;Name:'L3 COMMUNICATIONS TELEMETRY & INSTRUMENTATION'),
  (VID:$1487;Name:'MARQUETTE MEDICAL Systems'),
  (VID:$1488;Name:'KONTRON ELECTRONIK GmbH'),
  (VID:$1489;Name:'KYE Systems Corp'),
  (VID:$148A;Name:'OPTO 22'),
  (VID:$148B;Name:'INNOMEDIALOGIC Inc'),
  (VID:$148C;Name:'C.P. Technology Co Ltd'),
  (VID:$148D;Name:'DIGICOM Systems, Inc'),
  (VID:$148E;Name:'OSI PLUS Corp'),
  (VID:$148F;Name:'PLANT EQUIPMENT, Inc'),
  (VID:$1490;Name:'STONE MICROSystems PTY Ltd.'),
  (VID:$1491;Name:'ZEAL Corp'),
  (VID:$1492;Name:'TIME LOGIC Corp'),
  (VID:$1493;Name:'MAKER COMMUNICATIONS'),
  (VID:$1494;Name:'WINTOP Technology, Inc'),
  (VID:$1495;Name:'TOKAI COMMUNICATIONS Industry Co Ltd'),
  (VID:$1496;Name:'JOYTECH Computer Co, Ltd.'),
  (VID:$1497;Name:'SMA REGELSystemE GmbH'),
  (VID:$1498;Name:'TEWS DATENTECHNIK GmbH'),
  (VID:$1499;Name:'EMTEC Co, Ltd'),
  (VID:$149A;Name:'ANDOR Technology Ltd'),
  (VID:$149B;Name:'SEIKO INSTRUMENTS Inc'),
  (VID:$149C;Name:'OVISLINK Corp'),
  (VID:$149D;Name:'NEWTEK Inc'),
  (VID:$149E;Name:'MAPLETREE NETWORKS Inc'),
  (VID:$149F;Name:'LECTRON CO Ltd'),
  (VID:$14A0;Name:'SOFTING GmbH'),
  (VID:$14A1;Name:'SystemBASE CO Ltd'),
  (VID:$14A2;Name:'MILLENNIUM ENGINEERING Inc'),
  (VID:$14A3;Name:'MAVERICK NETWORKS'),
  (VID:$14A4;Name:'GVC/BCM ADVANCED RESEARCH'),
  (VID:$14A5;Name:'XIONICS DOCUMENT Technologies Inc)'),
  (VID:$14A6;Name:'INOVA Computers GmbH & CO KG'),
  (VID:$14A7;Name:'MYTHOS Systems Inc'),
  (VID:$14A8;Name:'FEATRON Technologies Corp'),
  (VID:$14A9;Name:'HIVERTEC Inc'),
  (VID:$14AA;Name:'ADVANCED MOS Technology Inc'),
  (VID:$14AB;Name:'MENTOR GRAPHICS Corp'),
  (VID:$14AC;Name:'NOVAWEB Technologies Inc'),
  (VID:$14AD;Name:'TIME SPACE RADIO AB'),
  (VID:$14AE;Name:'CTI, Inc'),
  (VID:$14AF;Name:'GUILLEMOT Corp'),
  (VID:$14B0;Name:'BST COMMUNICATION Technology Ltd'),
  (VID:$14B1;Name:'NEXTCOM K.K.'),
  (VID:$14B2;Name:'ENNOVATE NETWORKS Inc'),
  (VID:$14B3;Name:'XPEED Inc'),
  (VID:$14B4;Name:'PHILIPS BUSINESS Electronics B.V.'),
  (VID:$14B5;Name:'CREAMWARE GmbH'),
  (VID:$14B6;Name:'QUANTUM DATA Corp'),
  (VID:$14B7;Name:'PROXIM Inc'),
  (VID:$14B8;Name:'TECHSOFT Technology CO Ltd'),
  (VID:$14B9;Name:'AIRONET WIRELESS COMMUNICATIONS'),
  (VID:$14BA;Name:'INTERNIX Inc'),
  (VID:$14BB;Name:'SEMTECH Corp'),
  (VID:$14BC;Name:'GLOBESPAN SEMICONDUCTOR Inc'),
  (VID:$14BD;Name:'CARDIO CONTROL N.V.'),
  (VID:$14BE;Name:'L3 COMMUNICATIONS'),
  (VID:$14BF;Name:'SPIDER COMMUNICATIONS Inc'),
  (VID:$14C0;Name:'COMPAL Electronics Inc'),
  (VID:$14C1;Name:'MYRICOM Inc'),
  (VID:$14C2;Name:'DTK Computer'),
  (VID:$14C3;Name:'MEDIATEK Corp'),
  (VID:$14C4;Name:'IWASAKI INFORMATION Systems CO Ltd'),
  (VID:$14C5;Name:'ABB AUTOMATION PRODUCTS AB'),
  (VID:$14C6;Name:'DATA RACE Inc'),
  (VID:$14C7;Name:'MODULAR TECHNOLOY HOLDINGS Ltd'),
  (VID:$14C8;Name:'TURBOCOMM TECH. Inc'),
  (VID:$14C9;Name:'ODIN TELESystems Inc'),
  (VID:$14CA;Name:'PE LOGIC Corp'),
  (VID:$14CB;Name:'Billionton Systems Inc./Cadmus Micro Inc.'),
  (VID:$14CC;Name:'NAKAYO TELECOMMUNICATIONS Inc'),
  (VID:$14CD;Name:'UNIVERSAL SCIENTIFIC Ind'),
  (VID:$14CE;Name:'WHISTLE COMMUNICATIONS'),
  (VID:$14CF;Name:'TEK MICROSystems Inc'),
  (VID:$14D0;Name:'ERICSSON AXE R & D'),
  (VID:$14D1;Name:'Computer HI-TECH CO Ltd'),
  (VID:$14D2;Name:'TITAN Electronics Inc'),
  (VID:$14D3;Name:'CIRTECH (UK) Ltd'),
  (VID:$14D4;Name:'PANACOM Technology Corp'),
  (VID:$14D5;Name:'NITSUKO Corp'),
  (VID:$14D6;Name:'ACCUSYS Inc'),
  (VID:$14D7;Name:'HIRAKAWA HEWTECH Corp'),
  (VID:$14D8;Name:'HOPF ELEKTRONIK GmbH'),
  (VID:$14D9;Name:'ALPHA PROCESSOR Inc'),
  (VID:$14DA;Name:'NATIONAL AEROSPACE LABORATORIES'),
  (VID:$14DB;Name:'AVLAB Technology Inc'),
  (VID:$14DC;Name:'AMPLICON LIVELINE Ltd'),
  (VID:$14DD;Name:'BOLDER DESIGN LABS Inc'),
  (VID:$14DE;Name:'APPLIED INTEGRATION Corp'),
  (VID:$14DF;Name:'BASIS COMMUNICATIONS Corp'),
  (VID:$14E1;Name:'INVERTEX'),
  (VID:$14E2;Name:'INFOLIBRIA'),
  (VID:$14E3;Name:'AMTELCO'),
  (VID:$14E4;Name:'BROADCOM Corp'),
  (VID:$14E5;Name:'PIXELFUSION Ltd'),
  (VID:$14E6;Name:'SHINING Technology Inc'),
  (VID:$14E7;Name:'3CX'),
  (VID:$14E8;Name:'RAYCER Inc'),
  (VID:$14E9;Name:'GARNETS System CO Ltd'),
  (VID:$14EA;Name:'PLANEX COMMUNICATIONS Inc'),
  (VID:$14EB;Name:'SEIKO EPSON Corp'),
  (VID:$14EC;Name:'ACQIRIS'),
  (VID:$14ED;Name:'DATAKINETICS Ltd'),
  (VID:$14EE;Name:'MASPRO KENKOH Corp'),
  (VID:$14EF;Name:'CARRY Computer ENG. CO Ltd'),
  (VID:$14F0;Name:'CANON RESEACH CENTRE FRANCE'),
  (VID:$14F1;Name:'CONEXANT'),
  (VID:$14F2;Name:'MOBILITY Electronics'),
  (VID:$14F3;Name:'BROADLOGIC'),
  (VID:$14F4;Name:'TOKYO Electronic Industry CO Ltd'),
  (VID:$14F5;Name:'SOPAC Ltd'),
  (VID:$14F6;Name:'COYOTE Technologies LLC'),
  (VID:$14F7;Name:'WOLF Technology Inc'),
  (VID:$14F8;Name:'AUDIOCODES Inc'),
  (VID:$14F9;Name:'AG COMMUNICATIONS'),
  (VID:$14FA;Name:'WANDEL & GOCHERMANN'),
  (VID:$14FB;Name:'TRANSAS MARINE (UK) Ltd'),
  (VID:$14FC;Name:'QUADRICS Supercomputers World'),
  (VID:$14FD;Name:'JAPAN Computer Industry Inc'),
  (VID:$14FE;Name:'ARCHTEK TELECOM Corp'),
  (VID:$14FF;Name:'TWINHEAD INTERNATIONAL Corp'),
  (VID:$1500;Name:'LANTECH Computer Company'),
  (VID:$1501;Name:'BANKSOFT CANADA Ltd'),
  (VID:$1502;Name:'MITSUBISHI ELECTRIC LOGISTICS SUPPORT Co Ltd'),
  (VID:$1503;Name:'KAWASAKI LSI USA Inc'),
  (VID:$1504;Name:'KAISER Electronics'),
  (VID:$1505;Name:'ITA INGENIEURBURO FUR TESTAUFGABEN GmbH'),
  (VID:$1506;Name:'CHAMELEON Systems Inc'),
  (VID:$1507;Name:'HTEC Ltd'),
  (VID:$1508;Name:'HONDA CONNECTORS/MHOTRONICS Inc'),
  (VID:$1509;Name:'FIRST INTERNATIONAL Computer Inc'),
  (VID:$150A;Name:'FORVUS RESEARCH Inc'),
  (VID:$150B;Name:'YAMASHITA Systems Corp'),
  (VID:$150C;Name:'KYOPAL CO Ltd'),
  (VID:$150D;Name:'WARPSPPED Inc'),
  (VID:$150E;Name:'C-PORT Corp'),
  (VID:$150F;Name:'INTEC GmbH'),
  (VID:$1510;Name:'BEHAVIOR TECH Computer Corp'),
  (VID:$1511;Name:'CENTILLIUM Technology Corp'),
  (VID:$1512;Name:'ROSUN Technologies Inc'),
  (VID:$1513;Name:'Raychem'),
  (VID:$1514;Name:'TFL LAN Inc'),
  (VID:$1515;Name:'Advent design'),
  (VID:$1516;Name:'MYSON Technology Inc'),
  (VID:$1517;Name:'ECHOTEK Corp'),
  (VID:$1518;Name:'PEP MODULAR Computers GmbH'),
  (VID:$1519;Name:'TELEFON AKTIEBOLAGET LM Ericsson'),
  (VID:$151A;Name:'GLOBETEK Inc'),
  (VID:$151B;Name:'COMBOX Ltd'),
  (VID:$151C;Name:'DIGITAL AUDIO LABS Inc'),
  (VID:$151D;Name:'Fujitsu Computer Products d''Amerique'),
  (VID:$151E;Name:'MATRIX Corp'),
  (VID:$151F;Name:'TOPIC SEMICONDUCTOR Corp'),
  (VID:$1520;Name:'CHAPLET System Inc'),
  (VID:$1521;Name:'BELL Corp'),
  (VID:$1522;Name:'MAINPINE Ltd'),
  (VID:$1523;Name:'MUSIC Semiconductors'),
  (VID:$1524;Name:'ENE Technology Inc'),
  (VID:$1525;Name:'IMPACT Technologies'),
  (VID:$1526;Name:'ISS, Inc'),
  (VID:$1527;Name:'SOLECTRON'),
  (VID:$1528;Name:'ACKSYS'),
  (VID:$1529;Name:'AMERICAN MICROSystems Inc'),
  (VID:$152A;Name:'QUICKTURN DESIGN Systems'),
  (VID:$152B;Name:'FLYTECH Technology CO Ltd'),
  (VID:$152C;Name:'MACRAIGOR Systems LLC'),
  (VID:$152D;Name:'QUANTA Computer Inc'),
  (VID:$152E;Name:'MELEC Inc'),
  (VID:$152F;Name:'PHILIPS - CRYPTO'),
  (VID:$1530;Name:'ACQIS Technology Inc'),
  (VID:$1531;Name:'CHRYON Corp'),
  (VID:$1532;Name:'ECHELON Corp'),
  (VID:$1533;Name:'BALTIMORE'),
  (VID:$1534;Name:'ROAD Corp'),
  (VID:$1535;Name:'EVERGREEN Technologies Inc'),
  (VID:$1537;Name:'DATALEX COMMUNCATIONS'),
  (VID:$1538;Name:'ARALION Inc'),
  (VID:$1539;Name:'ATELIER INFORMATIQUES et ELECTRONIQUE ETUDES S.A.'),
  (VID:$153A;Name:'ONO SOKKI'),
  (VID:$153B;Name:'TERRATEC Electronic GmbH'),
  (VID:$153C;Name:'ANTAL Electronic'),
  (VID:$153D;Name:'FILANET Corp'),
  (VID:$153E;Name:'TECHWELL Inc'),
  (VID:$153F;Name:'MIPS DENMARK'),
  (VID:$1540;Name:'PROVIDEO MULTIMEDIA CO Ltd'),
  (VID:$1541;Name:'MACHONE Communications'),
  (VID:$1542;Name:'VIVID Technology Inc'),
  (VID:$1543;Name:'SILICON Laboratories'),
  (VID:$1544;Name:'DCM DATA Systems'),
  (VID:$1545;Name:'VISIONTEK'),
  (VID:$1546;Name:'IOI Technology Corp'),
  (VID:$1547;Name:'MITUTOYO Corp'),
  (VID:$1548;Name:'JET PROPULSION Laboratory'),
  (VID:$1549;Name:'INTERCONNECT Systems Solutions'),
  (VID:$154A;Name:'MAX Technologies Inc'),
  (VID:$154B;Name:'COMPUTEX CO Ltd'),
  (VID:$154C;Name:'VISUAL Technology Inc'),
  (VID:$154D;Name:'PAN INTERNATIONAL Industrial Corp'),
  (VID:$154E;Name:'SERVOTEST Ltd'),
  (VID:$154F;Name:'STRATABEAM Technology'),
  (VID:$1550;Name:'OPEN NETWORK Co Ltd'),
  (VID:$1551;Name:'SMART Electronic DEVELOPMENT GmbH'),
  (VID:$1552;Name:'RACAL AIRTECH Ltd'),
  (VID:$1553;Name:'CHICONY Electronics Co Ltd'),
  (VID:$1554;Name:'PROLINK Microsystems Corp'),
  (VID:$1555;Name:'GESYTEC GmbH'),
  (VID:$1556;Name:'PLD APPLICATIONS'),
  (VID:$1557;Name:'MEDIASTAR Co Ltd'),
  (VID:$1558;Name:'CLEVO/KAPOK Computer'),
  (VID:$1559;Name:'SI LOGIC Ltd'),
  (VID:$155A;Name:'INNOMEDIA Inc'),
  (VID:$155B;Name:'PROTAC INTERNATIONAL Corp'),
  (VID:$15A1;Name:'Geocast Network Systems'),
  (VID:$157C;Name:'Eurosoft (UK)'),
  (VID:$1668;Name:'Action Tec Electronics, Inc.'),
  (VID:$1A08;Name:'Sierra'),
  (VID:$1B13;Name:'Jaton Corp.'),
  (VID:$1C1C;Name:'Symphony'),
  (VID:$1D44;Name:'DPT'),
  (VID:$1DE1;Name:'TekRAM'),
  (VID:$2001;Name:'Temporal Research Ltd'),
  (VID:$21C3;Name:'21st Century Computer Corp.'),
  (VID:$2348;Name:'Racore'),
  (VID:$2646;Name:'Kingston Technologies'),
  (VID:$270B;Name:'Xantel Corp.'),
  (VID:$270F;Name:'Chaintech Computer Co., Ltd.'),
  (VID:$3000;Name:'Hansol Electronics Inc.'),
  (VID:$3142;Name:'Post Impression Systems'),
  (VID:$3388;Name:'Hint Corp.'),
  (VID:$3D3D;Name:'3DLabs'),
  (VID:$4005;Name:'Avance Logic, Inc.'),
  (VID:$4033;Name:'Addtron Technology Co Inc'),
  (VID:$4143;Name:'Digital Equipment Corp'),
  (VID:$416C;Name:'Aladdin Knowledge Systems'),
  (VID:$4444;Name:'Internext Compression, Inc.'),
  (VID:$4468;Name:'BRIDGEPORT MACHINES'),
  (VID:$4594;Name:'Cogetec Informatique Inc.'),
  (VID:$4680;Name:'UMAX Computer Corp.'),
  (VID:$4843;Name:'Hercules Computer Technology, Inc.'),
  (VID:$4942;Name:'Ensoniq'),
  (VID:$4943;Name:'Growth Networks'),
  (VID:$4978;Name:'Axil Computer, Inc.'),
  (VID:$4A14;Name:'NetVin'),
  (VID:$4B10;Name:'Buslogic Inc.'),
  (VID:$4C48;Name:'Lung Hwa Electronics'),
  (VID:$4D51;Name:'Mediaq Inc'),
  (VID:$4DDC;Name:'ILC data Device Corp.'),
  (VID:$5053;Name:'Voyetra Technologies'),
  (VID:$5136;Name:'S S Technologies'),
  (VID:$5143;Name:'Qualcomm, Inc.'),
  (VID:$5333;Name:'S3'),
  (VID:$544C;Name:'Teralogic Inc'),
  (VID:$5455;Name:'Technische University Berlin'),
  (VID:$5519;Name:'Cnet Technologies, Inc.'),
  (VID:$5555;Name:'Genroco Inc'),
  (VID:$5700;Name:'Netpower'),
  (VID:$6356;Name:'UltraStor'),
  (VID:$6374;Name:'c''t Magazin fuer Computertechnik'),
  (VID:$6409;Name:'Logitec Corp'),
  (VID:$6666;Name:'Decision Computer International Co.'),
  (VID:$7604;Name:'O.N. Electric Co Ltd'),
  (VID:$7BDE;Name:'MITAC Corporation'),
  (VID:$8008;Name:'Quancom Electronic GmbH'),
  (VID:$8086;Name:'Intel'),
  (VID:$80FF;Name:'Intel'),
  (VID:$8800;Name:'Trigem Computer'),
  (VID:$8866;Name:'T-Square Design Inc'),
  (VID:$8888;Name:'Silicon Magic'),
  (VID:$8E0E;Name:'Computone Corporation'),
  (VID:$8E2E;Name:'KTI'),
  (VID:$9004;Name:'Adaptec'),
  (VID:$9005;Name:'Adaptec'),
  (VID:$907F;Name:'Atronics'),
  (VID:$9412;Name:'Holtek'),
  (VID:$A0A0;Name:'Aopen Inc'),
  (VID:$A0F1;Name:'Unisys Corp'),
  (VID:$A200;Name:'NEC Corp.'),
  (VID:$A259;Name:'Hewlett Packard'),
  (VID:$A25B;Name:'Hewlett Packard GmbH PL24-MKT'),
  (VID:$A304;Name:'Sony'),
  (VID:$A727;Name:'3com Corp.'),
  (VID:$AA42;Name:'Scitex Digital Video'),
  (VID:$B1B3;Name:'Shiva Europe, Ltd.'),
  (VID:$C001;Name:'TSI Telsys'),
  (VID:$C0A9;Name:'Micron/Crucial Technology'),
  (VID:$C0DE;Name:'Motorola'),
  (VID:$C0FE;Name:'Motion Engineering, Inc.'),
  (VID:$CA50;Name:'Varian Australia Pty Ltd'),
  (VID:$CAFE;Name:'Chrysalis-ITS'),
  (VID:$CCCC;Name:'Catapult Communications'),
  (VID:$D4D4;Name:'DY4 Systems Inc.'),
  (VID:$E000;Name:'Winbond'),
  (VID:$E159;Name:'Tiger Jet Network Inc.'),
  (VID:$ECC0;Name:'Echo Corporation'),
  (VID:$EDD8;Name:'Ark Logic Inc.'),
  (VID:$FA57;Name:'Fast Search & Transfer ASA'),
  (VID:$FEDA;Name:'Epigram Inc'),
  (VID:$FFFE;Name:'VMWare Inc')
 );

 PCIDevice:Array[0..129]of PCIDeviceRec=(
  (VID:$100C;DID:$3202;Name:'ET4000/W32p-2'),
  (VID:$100C;DID:$3205;Name:'ET4000/W32p-B'),
  (VID:$100C;DID:$3206;Name:'ET4000/W32p-C'),
  (VID:$100C;DID:$3207;Name:'ET4000/W32p-D'),
  (VID:$100C;DID:$3208;Name:'ET6000/ET6100'),
  (VID:$100C;DID:$4702;Name:'ET6300'),

  (VID:$5333;DID:$5631;Name:'86C325 ViRGE 3D GUI Accelerator'),
  (VID:$5333;DID:$8800;Name:'Vision 866'),
  (VID:$5333;DID:$8801;Name:'Vision 964'),
  (VID:$5333;DID:$8810;Name:'S3 Trio32'),
  (VID:$5333;DID:$8811;Name:'S3 Trio64'),
  (VID:$5333;DID:$8812;Name:'S3 Aurora64V+'),
  (VID:$5333;DID:$8813;Name:'S3 Trio64 v3'),
  (VID:$5333;DID:$8814;Name:'S3 Trio64UV+ (767)'),
  (VID:$5333;DID:$8815;Name:'S3 Aurora128'),
  (VID:$5333;DID:$883D;Name:'S3 ViRGE/VX'),
  (VID:$5333;DID:$8880;Name:'S3 86c866'),
  (VID:$5333;DID:$88B0;Name:'S3 928 PCI'),
  (VID:$5333;DID:$88C0;Name:'S3 86c864'),
  (VID:$5333;DID:$88C1;Name:'S3 86c864P'),
  (VID:$5333;DID:$88C2;Name:'S3 86c864-3'),
  (VID:$5333;DID:$88C3;Name:'S3 86c864-4'),
  (VID:$5333;DID:$88D0;Name:'S3 86c964-1'),
  (VID:$5333;DID:$88D1;Name:'S3 86c964-2'),
  (VID:$5333;DID:$88D2;Name:'S3 86c964-3'),
  (VID:$5333;DID:$88D3;Name:'S3 86c964-4'),
  (VID:$5333;DID:$88F0;Name:'S3 86c968'),
  (VID:$5333;DID:$88F1;Name:'S3 86c968-2'),
  (VID:$5333;DID:$88F2;Name:'S3 86c968-3'),
  (VID:$5333;DID:$88F3;Name:'S3 86c968-3'),
  (VID:$5333;DID:$8900;Name:'S3 Trio64 V2/DX GUI Accelerator'),
  (VID:$5333;DID:$8901;Name:'S3 Trio64V2-DX/GX (775/785)'),
  (VID:$5333;DID:$8902;Name:'S3 PLATO/PX'),
  (VID:$5333;DID:$8A01;Name:'S3 ViRGE/DX or ViRGE/GX'),
  (VID:$5333;DID:$8A10;Name:'S3 ViRGE-GX2 PCI (357)'),
  (VID:$5333;DID:$8C01;Name:'S3 ViRGE-M5 PCI'),

  (VID:$6374;DID:$6773;Name:'Interface PCI GPPCI'),

  (VID:$8008;DID:$0010;Name:'PCI-WDOG1 Watchdog'),
  (VID:$8008;DID:$0011;Name:'PWDOG2 Watchdog2/PCI'),

  (VID:$8086;DID:$0008;Name:'Contrìleur de prise en charge systSme Intel Extended Express'),
  (VID:$8086;DID:$0482;Name:'Pont PCI-EISA 82375EB/SB'),
  (VID:$8086;DID:$0483;Name:'Contrìleur de cache 82424'),
  (VID:$8086;DID:$0484;Name:'Intel 82378/82379 Bus Interface (ensembles de puces Mercury/Saturn/Neptune)'),
  (VID:$8086;DID:$0486;Name:'Intel 82425EX/82430'),
  (VID:$8086;DID:$04A3;Name:'Intel 82434 LX (Mercury) / NX (Neptune)'),
  (VID:$8086;DID:$0960;Name:'Intel i960 RP Microprocessor/Bridge'),
  (VID:$8086;DID:$1130;Name:'Contrìleur processeur Intel(r) 82815 vers E/S - 1130'),
  (VID:$8086;DID:$1131;Name:'Contrìleur processeur Intel(r) 82815 vers AGP - 1131'),
  (VID:$8086;DID:$1132;Name:'Contrìleur graphique Intel(r) 82815 4.12.01.2604'),
  (VID:$8086;DID:$1161;Name:'Contrìleur d''interruption programmable avancÇ Intel(r) 82806AA'),
  (VID:$8086;DID:$1221;Name:'Intel 82092AA PCMCIA Bridge'),
  (VID:$8086;DID:$1222;Name:'Intel 82092AA IDE Controller'),
  (VID:$8086;DID:$1223;Name:'Intel SAA7116'),
  (VID:$8086;DID:$1225;Name:'Pont Intel Processeur Pentium(r) Extended Express vers PCI'),
  (VID:$8086;DID:$1226;Name:'Intel 82596'),
  (VID:$8086;DID:$1227;Name:'Intel 82865'),
  (VID:$8086;DID:$1228;Name:'EtherExpress Pro/100 Smart'),
  (VID:$8086;DID:$1229;Name:'Intel 82557 Fast Ethernet'),
  (VID:$8086;DID:$122D;Name:'Intel 82437FX (Triton)'),
  (VID:$8086;DID:$122E;Name:'Intel 82371FB ISA Bridge (Triton)'),
  (VID:$8086;DID:$1230;Name:'Intel 82338 IDE controller / 82371FB IDE function (Triton)'),
  (VID:$8086;DID:$1234;Name:'Intel 82371MX'),
  (VID:$8086;DID:$1235;Name:'Intel 82437MX Processeur Pentium(r) vers PCI'),
  (VID:$8086;DID:$1237;Name:'Intel 82441FX'),
  (VID:$8086;DID:$1239;Name:'Intel 82371FB IDE Interface (Triton)'),
  (VID:$8086;DID:$123B;Name:'Pont Intel 82380PB PCI vers PCI Docking'),
  (VID:$8086;DID:$123C;Name:'Intel 82380AB Mobile Pont PCI Ö ISA'),
  (VID:$8086;DID:$123D;Name:'Intel (683053) Programmable Interrupt Device'),
  (VID:$8086;DID:$124B;Name:'Intel 82380FB Mobile Pont PCI Ö PCI'),
  (VID:$8086;DID:$1250;Name:'Intel 430HX PCISet: Contr"leur systSme 82439HX'),
  (VID:$8086;DID:$1360;Name:'Pont PCI Intel(r) 82806AA'),
  (VID:$8086;DID:$1361;Name:'Contrìleur Intel(r) 82806AA (rÇservÇ)'),
  (VID:$8086;DID:$1960;Name:'Intel 80960RP Microprocesseur i960RP'),
  (VID:$8086;DID:$1A10;Name:'Contrìleur processeur Intel(r) Celeron(TM) vers E/S - 1A10'),
  (VID:$8086;DID:$1A21;Name:'Contrìleur Processeur Intel(r) 82840 vers entrÇe/sortie'),
  (VID:$8086;DID:$1A23;Name:'Contrìleur processeur Intel(r) 82840 vers AGP'),
  (VID:$8086;DID:$1A24;Name:'Pont PCI Intel(r) 82840'),
  (VID:$8086;DID:$2410;Name:'Intel Controller Hub 82801AA - Registres de l''interface LPC pour ce pont'),
  (VID:$8086;DID:$2411;Name:'Intel Controller Hub 82801AA - Registres de contr"leur IDE'),
  (VID:$8086;DID:$2412;Name:'Intel Controller Hub 82801AA - Registres de contr"leur USB'),
  (VID:$8086;DID:$2413;Name:'Intel Controller Hub 82801AA - Registres de contr"leur SMBus'),
  (VID:$8086;DID:$2415;Name:'Intel Controller Hub 82801AA - Registres de contr"leur audio AC''97'),
  (VID:$8086;DID:$2416;Name:'Intel Controller Hub 82801AA - Registres de contr"leur modem AC''97'),
  (VID:$8086;DID:$2418;Name:'Intel Controller Hub 82801AA - Registres de contr"leur PCI'),
  (VID:$8086;DID:$2420;Name:'Intel Controller Hub 82801AB - Registres de l''interface LPC pour ce pont'),
  (VID:$8086;DID:$2421;Name:'Intel Controller Hub 82801AB - Registres de contr"leur IDE'),
  (VID:$8086;DID:$2422;Name:'Intel Controller Hub 82801AB - Registres de contr"leur USB'),
  (VID:$8086;DID:$2423;Name:'Intel Controller Hub 82801AB - Registres de contr"leur SMBus'),
  (VID:$8086;DID:$2425;Name:'Intel Controller Hub 82801AB - Registres de contr"leur audio AC''97'),
  (VID:$8086;DID:$2426;Name:'Intel Controller Hub 82801AB - Registres de contr"leur modem AC''97'),
  (VID:$8086;DID:$2428;Name:'Intel Controller Hub 82801AB - Registres de contr"leur PCI'),
  (VID:$8086;DID:$2440;Name:'Contrìleur d''interface Intel(r) 82801BA LPC - 2440'),
  (VID:$8086;DID:$2443;Name:'Contrìleur Intel(r) 82801BA/BAM SMBus - 2443'),
  (VID:$8086;DID:$244E;Name:'Pont PCI Intel(r) 82801BA - 244E'),
  (VID:$8086;DID:$2500;Name:'Contrìleur processeur Intel 82820 vers E/S'),
  (VID:$8086;DID:$2501;Name:'Contrìleur processeur vers E/S Intel(r) 82820'),
  (VID:$8086;DID:$250B;Name:'Contrìleur processeur vers E/S Intel(r) 82820'),
  (VID:$8086;DID:$7000;Name:'Pont ISA 82371SB'),
  (VID:$8086;DID:$7010;Name:'Contrìleur IDE Intel 82371SB'),
  (VID:$8086;DID:$7020;Name:'Intel 82371SB'),
  (VID:$8086;DID:$7030;Name:'Intel 82437VX (Ensemble de puce 430VX)'),
  (VID:$8086;DID:$7100;Name:'Intel 430TX PCISet: Contrìleur systäme 82439TX'),
  (VID:$8086;DID:$7110;Name:'Intel 82371AB/EB PIIX4 Pont PCI . ISA'),
  (VID:$8086;DID:$7111;Name:'Intel 82371AB/EB Contrìleur primaire IDE'),
  (VID:$8086;DID:$7112;Name:'Intel 82371AB/EB Contrìleur universel USB'),
  (VID:$8086;DID:$7113;Name:'Intel 82371AB/EB Contrìleur de gestionnaire d''alimentation (APM)'),
  (VID:$8086;DID:$7120;Name:'Intel 82810'),
  (VID:$8086;DID:$7121;Name:'Contrìleur graphique Intel(r) 82810 4.12.01.2604'),
  (VID:$8086;DID:$7122;Name:'Intel 82810-DC100 (GMC H)'),
  (VID:$8086;DID:$7123;Name:'Contrìleur graphique Intel(r) 82810-DC100 4.12.01.2604'),
  (VID:$8086;DID:$7124;Name:'Contrìleur systäme et graphique Intel(r) 82810e DC-133'),
  (VID:$8086;DID:$7125;Name:'Contrìleur graphique Intel(r) 82810E 4.12.01.2604'),
  (VID:$8086;DID:$7180;Name:'Intel 82443LX/EX processeur Pentium II au pont PCI'),
  (VID:$8086;DID:$7181;Name:'Intel 82443LX/EX processeur Pentium II au contrìleur AGP'),
  (VID:$8086;DID:$7190;Name:'Intel 82443BX processeur Pentium II au pont PCI'),
  (VID:$8086;DID:$7191;Name:'Intel 82443BX processeur Pentium II au contrìleur AGP'),
  (VID:$8086;DID:$7192;Name:'Intel 82443BX processeur Pentium II au pont PCI'),
  (VID:$8086;DID:$7194;Name:'Contrìleur processeur Intel 82440MX vers E/S'),
  (VID:$8086;DID:$7198;Name:'Pont Intel 82440MX PCI vers ISA'),
  (VID:$8086;DID:$719B;Name:'Contrìleur de gestion d''alimentation Intel 82440MX'),
  (VID:$8086;DID:$71A0;Name:'Intel 82443GX processeur Pentium II au pont PCI'),
  (VID:$8086;DID:$71A1;Name:'Intel 82443GX processeur Pentium II au contrìleur AGP'),
  (VID:$8086;DID:$71A2;Name:'Intel 82443GX processeur Pentium II au pont PCI'),
  (VID:$8086;DID:$7600;Name:'Pont PCI vers ISA Intel 82372FB'),
  (VID:$8086;DID:$7603;Name:'Contrìleur de bus de gestion systäme Intel 82372FB'),
  (VID:$8086;DID:$7605;Name:'Contrìleur d''hìte 1394 OHCI Intel 82372FB'),
  (VID:$8086;DID:$84C4;Name:'Intel 82450KX/GX Pont PCI (Orion)'),
  (VID:$8086;DID:$84C5;Name:'Intel 82450KX/GX Contr"leur m,moire (Orion)'),
  (VID:$8086;DID:$84CA;Name:'Intel 450NX PCISet: MIOC (Memory & I/O Controller)'),
  (VID:$8086;DID:$84CB;Name:'Intel 450NX PCISet: PXB (PCI Expansion Bridge)')
 );

 PCIClass:Array[0..17]of PChar=(
  'IndÇfini',
  'Entreposage',
  'RÇseau',
  'Affichage',
  'MultimÇdia',
  'MÇmoire',
  'Pont',
  'Simple Communication',
  'Systäme',
  'EntrÇe',
  'Docking',
  'Processeur',
  'SÇrial',
  'Wireless',
  'EntrÇe/sortie intelligente',
  'Satellite de Communication',
  'Encryption/Decryption',
  'DonnÇes d''Aquisition et Processeur de Signal'
 );

Type
 PCIInfoRec=Record
  VID:Word;
  DID:Word;
  Command:Record Case Byte Of
   0:(Value:Word);
   1:(Flags:Set of (
    cmdIOAccess,cmdMemoryAccess,cmdBusMaster,cmdSpecialCycles,
    cmdMemWriteInvalidate,cmdVGAPaletteSnoop,cmdParityErrorResponse,cmdWaitCycles,
    cmdSystemErrors,cmdBackToBackTransactions));
  End;
  InfoTbl:Array[6..$FF]of Byte;
  Vendor:String;
  Identificator:String;
 End;

Var
 I:Integer;
 UseBios:Boolean;
 SysErr:Byte;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;


Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function WordToStr(Value:Word):String;
Var
 S:String;
Begin
 Str(Value,S);
 WordToStr:=S;
End;

Function LookUpBios(DeviceId,Func,Bus:Byte;Index:Word):Byte;Assembler;ASM
 MOV AX,0B108h
 MOV BL,DeviceId
 {$IFOPT G+}
  SHL BL,3
 {$ELSE}
  SHL BL,1
  SHL BL,1
  SHL BL,1
 {$ENDIF}
 ADD BL,Func
 MOV BH,Bus
 MOV DI,Index
 INT 01Ah
 JC @Exit
 XCHG AX,CX
@Exit:
 MOV Byte Ptr SysErr[1],AH
END;

Function LookUpHardware(DeviceId,Func,Bus:Byte;Index:Word):Byte;Assembler;ASM
 MOV AX,$8000
 MOV AL,bus
 MOV CL,16
 DB $66;SHL AX,CL
 MOV AX,Index
 AND AX,00FCh
 MOV AH,DeviceID
 {$IFOPT G+}
  SHL AH,3
 {$ELSE}
  SHL AH,1
  SHL AH,1
  SHL AH,1
 {$ENDIF}
 ADD AH,Func
 MOV DX,0CF8h
 DB $66;OUT DX,AX
 MOV AX,Index
 AND AX,3
 MOV BL,8
 MUL BL
 MOV CX,AX
 MOV DX,0CFCh
 DB $66;IN AX,DX
 DB $66;SHR AX,CL
 XCHG AX,BX
 DB $66;XOR AX,AX
 MOV DX,0CF8h
 DB $66;OUT DX,AX
 XCHG AX,BX
END;

Procedure ShowPCI(Const PCI:PCIInfoRec);
Var
 First:Boolean;
 nn:Byte;
 pp:Byte;
 Addr:Word;
 OldShade:Boolean;
 I:Integer;
 S:String;
 Data:Record
  ID:Word;
  ClassName:String;
 End;
 DataClass:Record
  ID:Byte;
  Name:String;
 End Absolute Data;

 Procedure InsertCmd(Const AS:String);Begin
  If Not(First)Then S:=S+',';
  S:=S+AS;
  First:=False;
 End;

Begin
 WriteLn('PÇriphÇrique PCI');
 WriteLn;
 WriteLn('Vendeur : ',PCI.Vendor,' ('+HexWord2Str(PCI.VID),'h)');
 WriteLn('PÇriphÇrique : '+PCI.Identificator+' ('+HexWord2Str(PCI.DID)+'h)');
 S:='Commande : '+HexWord2Str(PCI.Command.Value)+'h';
 If PCI.Command.Value>0Then Begin
  S:=S+' (';
  First:=True;
  If(cmdIOAccess)in(PCI.Command.Flags)Then InsertCmd('Accäs d''entrÇe/sortie');
  If(cmdMemoryAccess)in(PCI.Command.Flags)Then InsertCmd('Accäs mÇmoire');
  If(cmdBusMaster)in(PCI.Command.Flags)Then InsertCmd('BusMaster');
  If(cmdSpecialCycles)in(PCI.Command.Flags)Then InsertCmd('Cycles spÇcial');
  If(cmdMemWriteInvalidate)in(PCI.Command.Flags)Then InsertCmd('MemWrite+Invalidate');
  If(cmdVGAPaletteSnoop)in(PCI.Command.Flags)Then InsertCmd('VGA Palette Snoop');
  If(cmdParityErrorResponse)in(PCI.Command.Flags)Then InsertCmd('RÇponse d''erreur de paritÇ');
  If(cmdWaitCycles)in(PCI.Command.Flags)Then InsertCmd('Cycles d''attente');
  If(cmdSystemErrors)in(PCI.Command.Flags)Then InsertCmd('Erreurs systäme');
  If(cmdBackToBackTransactions)in(PCI.Command.Flags)Then InsertCmd('Transactions Back-To-Back');
  S:=S+')';
 End;
 WriteLn(S);
 S:='êtat: '+HexWord2Str(PCI.InfoTbl[7]shl 8+PCI.InfoTbl[6])+'h';
 If(PCI.InfoTbl[6]<>0)or(PCI.InfoTbl[7]<>0)Then Begin
  First:=True;
  S:=S+' (';
  If PCI.InfoTbl[6]and 16=16Then InsertCmd('A une liste de capacitÇs');
  If PCI.InfoTbl[6]and 32=32Then InsertCmd('66 MHz supportÇs');
  If PCI.InfoTbl[6]and 64=64Then InsertCmd('UDF');
  If PCI.InfoTbl[6]and 128=128Then InsertCmd('Supports Back-To-Back Trans.');
  If PCI.InfoTbl[7]and 1=1Then InsertCmd('Erreur de donnÇe de paritÇ');
  If PCI.InfoTbl[7]and 8=8Then InsertCmd('Signal de destination annuler');
  If PCI.InfoTbl[7]and 16=16Then InsertCmd('RÇception de destination annuler');
  If PCI.InfoTbl[7]and 32=32Then InsertCmd('RÇception principal annuler');
  If PCI.InfoTbl[7]and 64=64Then InsertCmd('Signal d''erreur systäme');
  If PCI.InfoTbl[7]and 128=128Then InsertCmd('DÇtection d''erreur de paritÇ');
  Case((PCI.InfoTbl[7]and 6)shr 1)of
   0:InsertCmd('Minuterie rapide');
   1:InsertCmd('Minuterie moyenne');
   2:InsertCmd('Minuterie lente');
   3:InsertCmd('Minuterie inconnu');
  End;
  S:=S+')';
 End;
 WriteLn(S);
 S:='RÇvision : '+ByteHex2Str(PCI.InfoTbl[8])+'h';
 WriteLn(S,', Type d''entàte ',ByteHex2Str(PCI.InfoTbl[$E]),'h');
 S:=S+', latence du bus '+ByteHex2Str(PCI.InfoTbl[$D])+'h';
 WriteLn(S);
 S:='Test de vÇrification : '+ByteHex2Str(PCI.InfoTbl[$F])+'h (Test de vÇrification ';
 If PCI.InfoTbl[$F]and$80=0Then S:=S+'non ';
 S:=S+'supportÇ';
 If PCI.InfoTbl[$F]and$80=$80Then Begin
  S:=S+': Code "Completion" '+ByteHex2Str(PCI.InfoTbl[$F]and$F)+'h - ';
  If PCI.InfoTbl[$F]and$F=0Then Begin
   S:=S+'Correcte';
  End
   Else
  S:=S+'Çchec!!';
 End;
 S:=S+')';
 WriteLn(S);
 If PCI.InfoTbl[$C]<>0Then WriteLn('Taille de ligne de cache : ',PCI.InfoTbl[$C]*4,
                           ' octets (',PCI.InfoTbl[$C],' Double mots)');
 S:='Classe PCI '+StrPas(PCIClass[PCI.InfoTbl[$B]]);
 S:=S+' Sous-classe ';
 Case PCI.InfoTbl[$B] of
  $00:Case PCI.InfoTbl[$A] of
   $00:S:=S+'IndÇfini';
   $01:S:=S+'VGA';
  End;
  $01:Case PCI.InfoTbl[$A] of
   $00:S:=S+'SCSI';
   $01:S:=S+'IDE';
   $02:S:=S+'Lecteur';
   $03:S:=S+'IPI';
   $04:S:=S+'RAID';
   $80:S:=S+'Autre';
  End;
  $02:Case PCI.InfoTbl[$A] of
   $00:S:=S+'Ethernet';
   $01:S:=S+'Token Ring';
   $02:S:=S+'FDDI';
   $03:S:=S+'ATM';
   $04:S:=S+'ISDN';
   $80:S:=S+'Autre';
  End;
  $03:Case PCI.InfoTbl[$A] of
   $00:S:=S+'VGA';
   $01:S:=S+'XGA';
   $3D:S:=S+'3D';
   $80:S:=S+'Autre';
  End;
  $04:Case PCI.InfoTbl[$A] of
   $00:S:=S+'VidÇo';
   $01:S:=S+'Audio';
   $02:S:=S+'TÇlÇphonie';
   $80:S:=S+'Autre';
  End;
  $05:Case PCI.InfoTbl[$A] of
   $00:S:=S+'RAM';
   $01:S:=S+'Flash';
   $80:S:=S+'Autre';
  End;
  $06:Case PCI.InfoTbl[$A] of
   $00:S:=S+'PCI - Hìte';
   $01:S:=S+'PCI - ISA';
   $02:S:=S+'PCI - EISA';
   $03:S:=S+'PCI - MCA';
   $04:S:=S+'PCI - PCI';
   $05:S:=S+'PCI - PCMCIA';
   $06:S:=S+'PCI - NuBUS';
   $07:S:=S+'PCI - Cardbus';
   $08:S:=S+'PCI - RACEway';
   $09:S:=S+'PCI - PCI';
   $0A:S:=S+'PCI - InfiBand';
   $80:S:=S+'PCI - Autre';
  End;
  $07:Case PCI.InfoTbl[$A] of
   $00:S:=S+'SÇrie';
   $01:S:=S+'Paralläle';
   $02:S:=S+'Multiport SÇrie';
   $03:S:=S+'Hayes Compatible Modem';
   $80:S:=S+'Autre';
  End;
  $08:Case PCI.InfoTbl[$A] of
   $00:S:=S+'PIC';
   $01:S:=S+'DMA';
   $02:S:=S+'Horloge';
   $03:S:=S+'RTC ou Hot-Plug';
   $80:S:=S+'Autre';
  End;
  $09:Case PCI.InfoTbl[$A] of
   $00:S:=S+'Clavier';
   $01:S:=S+'Crayon lumineux';
   $02:S:=S+'Souris';
   $03:S:=S+'Scanner';
   $04:S:=S+'Port de jeux';
   $80:S:=S+'Autre';
  End;
  $0A:Case PCI.InfoTbl[$A] of
   $00:S:=S+'GÇnÇrique';
   $80:S:=S+'Autre';
  End;
  $0B:Case PCI.InfoTbl[$A] of
   $00:S:=S+'386';
   $01:S:=S+'486';
   $02:S:=S+'Pentium';
   $03:S:=S+'PentiumPro';
   $10:S:=S+'DEC Alpha';
   $20:S:=S+'PowerPC';
   $30:S:=S+'MIPS';
   $40:S:=S+'Coprocessor';
   $80:S:=S+'Autre';
  End;
  $0C:Case PCI.InfoTbl[$A] of
   $00:S:=S+'FireWire';
   $01:S:=S+'Accäs au Bus';
   $02:S:=S+'SSA';
   $03:S:=S+'USB';
   $04:S:=S+'Fiber';
   $05:S:=S+'Contrìleur SMBus';
   $06:S:=S+'InfiniBand';
   $80:S:=S+'Autre';
  End;
  $0D:Case PCI.InfoTbl[$A] of
   $00:S:=S+'iRDA';
   $01:S:=S+'Consumer IR';
   $10:S:=S+'RF';
   $80:S:=S+'Autre';
  End;
  $0E:Case PCI.InfoTbl[$A] of
   $00:S:=S+'I2O';
   $80:S:=S+'Autre';
  End;
  $0F:Case PCI.InfoTbl[$A] of
   $01:S:=S+'TV';
   $02:S:=S+'Audio';
   $03:S:=S+'Voix';
   $04:S:=S+'DonnÇe';
   $80:S:=S+'Autre';
  End;
  $10:Case PCI.InfoTbl[$A] of
   $00:S:=S+'RÇseau';
   $10:S:=S+'Divertissement';
   $80:S:=S+'Autre';
  End;
  $11:Case PCI.InfoTbl[$A] of
   $00:S:=S+'Module DPIO';
   $01:S:=S+'Compteurs de Performance';
   $10:S:=S+'Synchronisation des communications, mesure du temps et de la frÇquence';
   $80:S:=S+'Autre';
  End;
 End;
 S:=S+' Interface ';
 S:=S+HexWord2Str(PCI.InfoTbl[9])+'h';
 WriteLn(S);
 If(PCI.InfoTbl[$B]=01)and(PCI.InfoTbl[$A]=01)Then Begin
  S:='Fourniture du contrìleur PCI EIDE : BusMaster EIDE ';
  If PCI.InfoTbl[$9]and$80=0Then S:=S+'n''est '
                            Else S:=S+'est ';
  S:=S+'supportÇ';
  WriteLn(S);
  If PCI.InfoTbl[$9]and 1=0Then Begin
   WriteLn(PadRight('Primaire',12),PadRight('Port d''EntrÇe/Sortie',23),'01F0h');
   WriteLn(PadRight('Primaire',12),PadRight('Requàte d''Interruption',23),'IRQ 14');
  End;
  If PCI.InfoTbl[$9]and 4=0Then Begin
   WriteLn(PadRight('Secondaire',12),PadRight('Port d''EntrÇe/Sortie',23),'0170h');
   WriteLn(PadRight('Secondaire',12),PadRight('Requàte d''Interruption',23),'IRQ 15');
  End;
 End;
{  End;
 Begin}
  Case(PCI.InfoTbl[$E]and$7F)of
   0:PP:=5;
   1:PP:=1;
   Else PP:=0;
  End;
  If PP>0Then For NN:=0to(PP)do Begin
   If PCI.InfoTbl[$10+(NN*4)]+PCI.InfoTbl[$11+(NN*4)]+
      PCI.InfoTbl[$12+(NN*4)]+PCI.InfoTbl[$13+(NN*4)]<>0Then Begin
    S:=PadRight(WordToStr(NN),12);
    If PCI.InfoTbl[$10+(NN*4)]and 1=1Then Begin
     S:=S+PadRight('Port EntrÇe/Sortie',23);
     Addr:=PCI.InfoTbl[$11+(NN*4)]shl 8+(PCI.InfoTbl[$10+(NN*4)]and$FC);
     S:=S+HexWord2Str(Addr)+'h';
    End
     Else
    Begin
     S:=S+PadRight('Plage mÇmoire',23);
     Addr:=PCI.InfoTbl[$13+(NN*4)]shl 8+PCI.InfoTbl[$12+(NN*4)];
     S:=S+HexWord2Str(Addr);
     Addr:=PCI.InfoTbl[$11+(NN*4)]shl 8+(PCI.InfoTbl[$10+(NN*4)]and$F0);
     S:=S+HexWord2Str(Addr)+'h';
     If PCI.InfoTbl[$10+(NN*4)]and 6=0Then S:=S+' (sous 4 Go';
     If PCI.InfoTbl[$10+(NN*4)]and 6=2Then S:=S+' (sous 1 Mo';
     If PCI.InfoTbl[$10+(NN*4)]and 6=4Then S:=S+' (sous 64-bits d''espace';
     If PCI.InfoTbl[$10+(NN*4)]and 6=6Then S:=S+' (rÇservÇ';
     If PCI.InfoTbl[$10+(NN*4)]and 8=8Then S:=S+', Prefetchable)'
                                      Else S:=S+')';
    End;
   End;
  End;
  If PCI.InfoTbl[$3C]in[1..15]Then Begin
   S:=PadRight('',12)+PadRight('Requàte d''interruption',23)+'IRQ '+WordToStr(PCI.InfoTbl[$3C])+', INT ';
   If PCI.InfoTbl[$3D]=0Then S:=S+'-'
    Else
   Begin
    S:=S+'0';
    S:=S+Chr(PCI.InfoTbl[$3D]+64);
    S:=S+'h';
   End;
   WriteLn(S);
  End;
End;

Procedure InfoPCI;
Var
 I:Integer;
 K:Word;
 Bus:Byte;
 DeviceId:Byte;
 Func:Byte;
 PCIHiBus:Byte;
 PCIVersion:Word;
 PCIChar:Byte;
 Info:Byte;
 Index:Word;
 Failed,Found:Boolean;
 InfoTbl:Array[0..$FF]of Byte;
 VID:Word Absolute InfoTbl;
 PCI:PCIInfoRec;
Begin
 Failed:=True;
 If Test8086<2 Then WriteLn('Processeur 80386 minimum requis!')
  Else
 Begin
  If(UseBIOS)Then ASM
   MOV AX,0B101h
   INT 01Ah
   JC  @exit
   CMP DX,04350h
   JNE @exit
   MOV PCIChar,AL
   MOV PCIHiBus,CL
   MOV PCIVersion,BX
   MOV Failed,False
  @exit:
  END
   Else
  Failed:=False;
  If(Failed)Then WriteLn('PCI non dÇtectÇ par le BIOS')
   Else
  Begin
   WriteLn('Recherche des pÇriphÇriques PCI...');
   Found:=False;
   For Bus:=0to(PciHiBus)do Begin
    For DeviceId:=0to$1F do Begin
     For Func:=0to 7do Begin
      Index:=0;
      Repeat
       If(UseBios)Then Info:=LookUpBios(DeviceId,Func,Bus,Index)
                  Else Info:=LookUpHardware(DeviceId,Func,Bus,Index);
       InfoTbl[Index]:=Info;
       Inc(Index);
       If Index=2Then If VID=$FFFFThen Index:=$100;
      Until Index=$100;
      If VID<>$FFFFThen Begin
       Move(InfoTbl,PCI,SizeOf(InfoTbl));
       PCI.Vendor:='';
       For I:=Low(PCIVendor)to High(PCIVendor)do Begin
        If(PCIVendor[I].VID=PCI.VID)Then Begin
         PCI.Vendor:=StrPas(PCIVendor[I].Name);
         Break;
        End;
       End;
       For I:=Low(PCIDevice)to High(PCIDevice)do Begin
        If(PCIDevice[I].VID=PCI.VID)and(PCIDevice[I].DID=PCI.DID)Then Begin
         PCI.Identificator:=StrPas(PCIDevice[I].Name);
        End;
       End;
       ShowPCI(PCI);
       Found:=True;
       If InfoTbl[$E]and$7F=0Then
        If(Func=0)and(InfoTbl[$E]and$80=0)Then Break;
      End;
     End;
    End;
   End;
   If Not(Found)Then WriteLn('Aucun pÇriphÇrique PCI dÇtectÇ.');
  End;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PCIINFO : Cette commande permet de rechercher les pÇriphÇriques ',
          'PCI installÇ dans le micro-ordinateur.');
  WriteLn;
  WriteLn('Syntaxe : PCIINFO [/?] [/USEBIOS]');
  WriteLn;
  WriteLn(' /USEBIOS    Ce paramätre permet d''indiquer qu''il faut utiliser la dÇtection par le BIOS.');
 End
  Else
 Begin
  UseBIOS:=False;
  If ParamCount>0 Then For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/USEBIOS'Then UseBIOS:=True
    Else
   Begin
    WriteLn('Paramätre inconnu : ',ParamStr(I));
    Halt(1);
   End;
  End;
  InfoPCI;
 End;
END.

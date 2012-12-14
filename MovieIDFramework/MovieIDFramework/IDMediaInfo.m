//
//  IDMediaInfo.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDMediaInfo.h"
#import "IDTimecode.h"
#import <QTKit/QTKit.h>
#import <AVFoundation/AVFoundation.h>

static NSMutableDictionary *iso639codes;

@implementation IDMediaInfo

+ (void)load
{
	iso639codes = [[NSMutableDictionary alloc] init];
	
	iso639codes[@"kru"] = @"Kurukh";
	iso639codes[@"men"] = @"Mende";
	iso639codes[@"bin"] = @"Bini";
	iso639codes[@"baq"] = @"Basque";
	iso639codes[@"iii"] = @"Sichuan Yi";
	iso639codes[@"tmh"] = @"Tamashek";
	iso639codes[@"pag"] = @"Pangasinan";
	iso639codes[@"nno"] = @"Norwegian Nynorsk";
	iso639codes[@"bas"] = @"Basa";
	iso639codes[@"mul"] = @"Multiple";
	iso639codes[@"tel"] = @"Telugu";
	iso639codes[@"fur"] = @"Friulian";
	iso639codes[@"jbo"] = @"Lojban";
	iso639codes[@"bat"] = @"Baltic";
	iso639codes[@"vol"] = @"Volapük";
	iso639codes[@"tem"] = @"Timne";
	iso639codes[@"crp"] = @"Creoles and pidgins";
	iso639codes[@"nob"] = @"Bokmål, Norwegian";
	iso639codes[@"goh"] = @"German, Old High";
	iso639codes[@"mun"] = @"Munda";
	iso639codes[@"ssw"] = @"Swati";
	iso639codes[@"bis"] = @"Bislama";
	iso639codes[@"csb"] = @"Kashubian";
	iso639codes[@"iba"] = @"Iban";
	iso639codes[@"bra"] = @"Braj";
	iso639codes[@"byn"] = @"Blin";
	iso639codes[@"slk"] = @"Slovak";
	iso639codes[@"uga"] = @"Ugaritic";
	iso639codes[@"mnc"] = @"Manchu";
	iso639codes[@"pal"] = @"Pahlavi";
	iso639codes[@"elx"] = @"Elamite";
	iso639codes[@"tuk"] = @"Turkmen";
	iso639codes[@"pam"] = @"Pampanga";
	iso639codes[@"nwc"] = @"Classical Newari";
	iso639codes[@"lua"] = @"Luba-Lulua";
	iso639codes[@"gwi"] = @"Gwich'in";
	iso639codes[@"pan"] = @"Panjabi";
	iso639codes[@"ter"] = @"Tereno";
	iso639codes[@"lub"] = @"Luba-Katanga";
	iso639codes[@"nog"] = @"Nogai";
	iso639codes[@"bre"] = @"Breton";
	iso639codes[@"slo"] = @"Slovak";
	iso639codes[@"mus"] = @"Creek";
	iso639codes[@"tum"] = @"Tumbuka";
	iso639codes[@"gon"] = @"Gondi";
	iso639codes[@"pap"] = @"Papiamento";
	iso639codes[@"tet"] = @"Tetum";
	iso639codes[@"sma"] = @"Southern Sami";
	iso639codes[@"ira"] = @"Iranian";
	iso639codes[@"wak"] = @"Wakashan";
	iso639codes[@"vot"] = @"Votic";
	iso639codes[@"mni"] = @"Manipuri";
	iso639codes[@"tup"] = @"Tupi";
	iso639codes[@"wal"] = @"Wolaitta";
	iso639codes[@"lug"] = @"Ganda";
	iso639codes[@"tur"] = @"Turkish";
	iso639codes[@"hai"] = @"Haida";
	iso639codes[@"gor"] = @"Gorontalo";
	iso639codes[@"sme"] = @"Northern Sami";
	iso639codes[@"pau"] = @"Palauan";
	iso639codes[@"lui"] = @"Luiseno";
	iso639codes[@"non"] = @"Norse, Old";
	iso639codes[@"tut"] = @"Altaic";
	iso639codes[@"slv"] = @"Slovenian";
	iso639codes[@"ain"] = @"Ainu";
	iso639codes[@"got"] = @"Gothic";
	iso639codes[@"pra"] = @"Prakrit";
	iso639codes[@"mga"] = @"Irish, Middle";
	iso639codes[@"ltz"] = @"Luxembourgish";
	iso639codes[@"aar"] = @"Afar";
	iso639codes[@"mno"] = @"Manobo";
	iso639codes[@"war"] = @"Waray";
	iso639codes[@"hye"] = @"Armenian";
	iso639codes[@"dua"] = @"Duala";
	iso639codes[@"smi"] = @"Sami";
	iso639codes[@"sel"] = @"Selkup";
	iso639codes[@"was"] = @"Washo";
	iso639codes[@"ibo"] = @"Igbo";
	iso639codes[@"smj"] = @"Lule Sami";
	iso639codes[@"sem"] = @"Semitic";
	iso639codes[@"efi"] = @"Efik";
	iso639codes[@"eus"] = @"Basque";
	iso639codes[@"hil"] = @"Hiligaynon";
	iso639codes[@"nor"] = @"Norwegian";
	iso639codes[@"eng"] = @"English";
	iso639codes[@"aym"] = @"Aymara";
	iso639codes[@"him"] = @"Himachali";
	iso639codes[@"lun"] = @"Lunda";
	iso639codes[@"ara"] = @"Arabic";
	iso639codes[@"luo"] = @"Luo";
	iso639codes[@"ijo"] = @"Ijo";
	iso639codes[@"hin"] = @"Hindi";
	iso639codes[@"kmb"] = @"Kimbundu";
	iso639codes[@"gaa"] = @"Ga";
	iso639codes[@"suk"] = @"Sukuma";
	iso639codes[@"arc"] = @"Aramaic";
	iso639codes[@"smn"] = @"Inari Sami";
	iso639codes[@"tvl"] = @"Tuvalu";
	iso639codes[@"del"] = @"Delaware";
	iso639codes[@"kua"] = @"Kuanyama";
	iso639codes[@"vie"] = @"Vietnamese";
	iso639codes[@"ice"] = @"Icelandic";
	iso639codes[@"iro"] = @"Iroquoian";
	iso639codes[@"smo"] = @"Samoan";
	iso639codes[@"hat"] = @"Haitian";
	iso639codes[@"vai"] = @"Vai";
	iso639codes[@"lus"] = @"Lushai";
	iso639codes[@"abk"] = @"Abkhazian";
	iso639codes[@"den"] = @"Slave";
	iso639codes[@"hau"] = @"Hausa";
	iso639codes[@"sna"] = @"Shona";
	iso639codes[@"moh"] = @"Mohawk";
	iso639codes[@"sun"] = @"Sundanese";
	iso639codes[@"zen"] = @"Zenaga";
	iso639codes[@"fon"] = @"Fon";
	iso639codes[@"enm"] = @"English, Middle";
	iso639codes[@"lez"] = @"Lezghian";
	iso639codes[@"arg"] = @"Aragonese";
	iso639codes[@"qaa-qtz"] = @"Reserved for local use";
	iso639codes[@"hit"] = @"Hittite";
	iso639codes[@"haw"] = @"Hawaiian";
	iso639codes[@"aze"] = @"Azerbaijani";
	iso639codes[@"sms"] = @"Skolt Sami";
	iso639codes[@"snd"] = @"Sindhi";
	iso639codes[@"zul"] = @"Zulu";
	iso639codes[@"pro"] = @"Provençal, Old";
	iso639codes[@"dum"] = @"Dutch, Middle";
	iso639codes[@"ceb"] = @"Cebuano";
	iso639codes[@"nia"] = @"Nias";
	iso639codes[@"tog"] = @"Tonga";
	iso639codes[@"sus"] = @"Susu";
	iso639codes[@"zun"] = @"Zuni";
	iso639codes[@"tgk"] = @"Tajik";
	iso639codes[@"mon"] = @"Mongolian";
	iso639codes[@"deu"] = @"German";
	iso639codes[@"nic"] = @"Niger-Kordofanian";
	iso639codes[@"mwl"] = @"Mirandese";
	iso639codes[@"bla"] = @"Siksika";
	iso639codes[@"tgl"] = @"Tagalog";
	iso639codes[@"arm"] = @"Armenian";
	iso639codes[@"aka"] = @"Akan";
	iso639codes[@"cmc"] = @"Chamic";
	iso639codes[@"arn"] = @"Mapudungun";
	iso639codes[@"znd"] = @"Zande";
	iso639codes[@"nah"] = @"Nahuatl";
	iso639codes[@"ace"] = @"Achinese";
	iso639codes[@"twi"] = @"Twi";
	iso639codes[@"snk"] = @"Soninke";
	iso639codes[@"kum"] = @"Kumyk";
	iso639codes[@"nai"] = @"North American Indian";
	iso639codes[@"gil"] = @"Gilbertese";
	iso639codes[@"arp"] = @"Arapaho";
	iso639codes[@"nya"] = @"Chichewa";
	iso639codes[@"sux"] = @"Sumerian";
	iso639codes[@"ewe"] = @"Ewe";
	iso639codes[@"isl"] = @"Icelandic";
	iso639codes[@"mos"] = @"Mossi";
	iso639codes[@"dut"] = @"Dutch";
	iso639codes[@"tha"] = @"Thai";
	iso639codes[@"oji"] = @"Ojibwa";
	iso639codes[@"gba"] = @"Gbaya";
	iso639codes[@"ton"] = @"Tonga";
	iso639codes[@"ach"] = @"Acoli";
	iso639codes[@"sga"] = @"Irish, Old";
	iso639codes[@"mwr"] = @"Marwari";
	iso639codes[@"cel"] = @"Celtic";
	iso639codes[@"art"] = @"Artificial";
	iso639codes[@"ori"] = @"Oriya";
	iso639codes[@"kur"] = @"Kurdish";
	iso639codes[@"ita"] = @"Italian";
	iso639codes[@"rum"] = @"Romanian";
	iso639codes[@"uig"] = @"Uighur";
	iso639codes[@"run"] = @"Rundi";
	iso639codes[@"ile"] = @"Interlingue";
	iso639codes[@"kut"] = @"Kutenai";
	iso639codes[@"nap"] = @"Neapolitan";
	iso639codes[@"iku"] = @"Inuktitut";
	iso639codes[@"arw"] = @"Arawak";
	iso639codes[@"hsb"] = @"Upper Sorbian";
	iso639codes[@"akk"] = @"Akkadian";
	iso639codes[@"swa"] = @"Swahili";
	iso639codes[@"grb"] = @"Grebo";
	iso639codes[@"rup"] = @"Aromanian";
	iso639codes[@"orm"] = @"Oromo";
	iso639codes[@"grc"] = @"Greek, Ancient";
	iso639codes[@"btk"] = @"Batak";
	iso639codes[@"gay"] = @"Gayo";
	iso639codes[@"mac"] = @"Macedonian";
	iso639codes[@"ada"] = @"Adangme";
	iso639codes[@"ewo"] = @"Ewondo";
	iso639codes[@"lol"] = @"Mongo";
	iso639codes[@"ces"] = @"Czech";
	iso639codes[@"sog"] = @"Sogdian";
	iso639codes[@"gre"] = @"Greek";
	iso639codes[@"mad"] = @"Madurese";
	iso639codes[@"rus"] = @"Russian";
	iso639codes[@"nqo"] = @"N'Ko";
	iso639codes[@"hrv"] = @"Croatian";
	iso639codes[@"osa"] = @"Osage";
	iso639codes[@"nau"] = @"Nauru";
	iso639codes[@"swe"] = @"Swedish";
	iso639codes[@"nym"] = @"Nyamwezi";
	iso639codes[@"tpi"] = @"Tok Pisin";
	iso639codes[@"asm"] = @"Assamese";
	iso639codes[@"nav"] = @"Navajo";
	iso639codes[@"mic"] = @"Mi'kmaq";
	iso639codes[@"nyn"] = @"Nyankole";
	iso639codes[@"ido"] = @"Ido";
	iso639codes[@"que"] = @"Quechua";
	iso639codes[@"nyo"] = @"Nyoro";
	iso639codes[@"mag"] = @"Magahi";
	iso639codes[@"fij"] = @"Fijian";
	iso639codes[@"oci"] = @"Occitan";
	iso639codes[@"niu"] = @"Niuean";
	iso639codes[@"alb"] = @"Albanian";
	iso639codes[@"egy"] = @"Egyptian";
	iso639codes[@"bua"] = @"Buriat";
	iso639codes[@"mah"] = @"Marshallese";
	iso639codes[@"sgn"] = @"Sign";
	iso639codes[@"fan"] = @"Fang";
	iso639codes[@"pli"] = @"Pali";
	iso639codes[@"mai"] = @"Maithili";
	iso639codes[@"fil"] = @"Filipino";
	iso639codes[@"cus"] = @"Cushitic";
	iso639codes[@"fao"] = @"Faroese";
	iso639codes[@"mya"] = @"Burmese";
	iso639codes[@"ilo"] = @"Iloko";
	iso639codes[@"som"] = @"Somali";
	iso639codes[@"ale"] = @"Aleut";
	iso639codes[@"tib"] = @"Tibetan";
	iso639codes[@"son"] = @"Songhai";
	iso639codes[@"doi"] = @"Dogri";
	iso639codes[@"nbl"] = @"Ndebele, South";
	iso639codes[@"fin"] = @"Finnish";
	iso639codes[@"bej"] = @"Beja";
	iso639codes[@"mak"] = @"Makasar";
	iso639codes[@"alg"] = @"Algonquian";
	iso639codes[@"mal"] = @"Malayalam";
	iso639codes[@"ast"] = @"Asturian";
	iso639codes[@"grn"] = @"Guarani";
	iso639codes[@"bel"] = @"Belarusian";
	iso639codes[@"spa"] = @"Spanish";
	iso639codes[@"fas"] = @"Persian";
	iso639codes[@"bug"] = @"Buginese";
	iso639codes[@"tah"] = @"Tahitian";
	iso639codes[@"man"] = @"Mandingo";
	iso639codes[@"bem"] = @"Bemba";
	iso639codes[@"roa"] = @"Romance";
	iso639codes[@"fat"] = @"Fanti";
	iso639codes[@"urd"] = @"Urdu";
	iso639codes[@"tai"] = @"Tai";
	iso639codes[@"mao"] = @"Maori";
	iso639codes[@"ben"] = @"Bengali";
	iso639codes[@"uzb"] = @"Uzbek";
	iso639codes[@"tig"] = @"Tigre";
	iso639codes[@"ath"] = @"Athapascan";
	iso639codes[@"epo"] = @"Esperanto";
	iso639codes[@"map"] = @"Austronesian";
	iso639codes[@"zha"] = @"Zhuang";
	iso639codes[@"nzi"] = @"Nzima";
	iso639codes[@"fra"] = @"French";
	iso639codes[@"min"] = @"Minangkabau";
	iso639codes[@"sot"] = @"Sotho, Southern";
	iso639codes[@"dgr"] = @"Dogrib";
	iso639codes[@"loz"] = @"Lozi";
	iso639codes[@"mar"] = @"Marathi";
	iso639codes[@"fiu"] = @"Finno-Ugrian";
	iso639codes[@"kok"] = @"Konkani";
	iso639codes[@"bul"] = @"Bulgarian";
	iso639codes[@"tam"] = @"Tamil";
	iso639codes[@"mas"] = @"Masai";
	iso639codes[@"ber"] = @"Berber";
	iso639codes[@"wln"] = @"Walloon";
	iso639codes[@"ota"] = @"Turkish, Ottoman";
	iso639codes[@"fre"] = @"French";
	iso639codes[@"lad"] = @"Ladino";
	iso639codes[@"kom"] = @"Komi";
	iso639codes[@"roh"] = @"Romansh";
	iso639codes[@"kha"] = @"Khasi";
	iso639codes[@"kon"] = @"Kongo";
	iso639codes[@"mis"] = @"Uncoded";
	iso639codes[@"myn"] = @"Mayan";
	iso639codes[@"oss"] = @"Ossetian";
	iso639codes[@"shn"] = @"Shan";
	iso639codes[@"lah"] = @"Lahnda";
	iso639codes[@"bur"] = @"Burmese";
	iso639codes[@"alt"] = @"Southern Altai";
	iso639codes[@"may"] = @"Malay";
	iso639codes[@"heb"] = @"Hebrew";
	iso639codes[@"kor"] = @"Korean";
	iso639codes[@"tat"] = @"Tatar";
	iso639codes[@"ina"] = @"Interlingua";
	iso639codes[@"sad"] = @"Sandawe";
	iso639codes[@"rom"] = @"Romany";
	iso639codes[@"tir"] = @"Tigrinya";
	iso639codes[@"kos"] = @"Kosraean";
	iso639codes[@"ady"] = @"Adyghe";
	iso639codes[@"ron"] = @"Romanian";
	iso639codes[@"peo"] = @"Persian, Old";
	iso639codes[@"kpe"] = @"Kpelle";
	iso639codes[@"gla"] = @"Gaelic";
	iso639codes[@"inc"] = @"Indic";
	iso639codes[@"frm"] = @"French, Middle";
	iso639codes[@"amh"] = @"Amharic";
	iso639codes[@"sid"] = @"Sidamo";
	iso639codes[@"ind"] = @"Indonesian";
	iso639codes[@"sag"] = @"Sango";
	iso639codes[@"khi"] = @"Khoisan";
	iso639codes[@"lam"] = @"Lamba";
	iso639codes[@"mri"] = @"Maori";
	iso639codes[@"zho"] = @"Chinese";
	iso639codes[@"wel"] = @"Welsh";
	iso639codes[@"fro"] = @"French, Old";
	iso639codes[@"per"] = @"Persian";
	iso639codes[@"myv"] = @"Erzya";
	iso639codes[@"ine"] = @"Indo-European";
	iso639codes[@"sah"] = @"Yakut";
	iso639codes[@"tiv"] = @"Tiv";
	iso639codes[@"sai"] = @"South American Indian";
	iso639codes[@"lao"] = @"Lao";
	iso639codes[@"gle"] = @"Irish";
	iso639codes[@"cha"] = @"Chamorro";
	iso639codes[@"lim"] = @"Limburgan";
	iso639codes[@"wen"] = @"Sorbian";
	iso639codes[@"chb"] = @"Chibcha";
	iso639codes[@"inh"] = @"Ingush";
	iso639codes[@"khm"] = @"Central Khmer";
	iso639codes[@"frr"] = @"Northern Frisian";
	iso639codes[@"lin"] = @"Lingala";
	iso639codes[@"syc"] = @"Classical Syriac";
	iso639codes[@"kaa"] = @"Kara-Kalpak";
	iso639codes[@"oto"] = @"Otomian";
	iso639codes[@"glg"] = @"Galician";
	iso639codes[@"sal"] = @"Salishan";
	iso639codes[@"cop"] = @"Coptic";
	iso639codes[@"frs"] = @"Eastern Frisian";
	iso639codes[@"afa"] = @"Afro-Asiatic";
	iso639codes[@"kab"] = @"Kabyle";
	iso639codes[@"nde"] = @"Ndebele, North";
	iso639codes[@"nso"] = @"Pedi";
	iso639codes[@"kho"] = @"Khotanese";
	iso639codes[@"sam"] = @"Samaritan Aramaic";
	iso639codes[@"kac"] = @"Kachin";
	iso639codes[@"che"] = @"Chechen";
	iso639codes[@"san"] = @"Sanskrit";
	iso639codes[@"tyv"] = @"Tuvinian";
	iso639codes[@"cor"] = @"Cornish";
	iso639codes[@"lat"] = @"Latin";
	iso639codes[@"sqi"] = @"Albanian";
	iso639codes[@"nld"] = @"Dutch";
	iso639codes[@"yor"] = @"Yoruba";
	iso639codes[@"pus"] = @"Pushto";
	iso639codes[@"gsw"] = @"Swiss German";
	iso639codes[@"cos"] = @"Corsican";
	iso639codes[@"msa"] = @"Malay";
	iso639codes[@"mkd"] = @"Macedonian";
	iso639codes[@"chg"] = @"Chagatai";
	iso639codes[@"dak"] = @"Dakota";
	iso639codes[@"lav"] = @"Latvian";
	iso639codes[@"bod"] = @"Tibetan";
	iso639codes[@"cpe"] = @"Creoles and pidgins, English based";
	iso639codes[@"sin"] = @"Sinhala";
	iso639codes[@"lit"] = @"Lithuanian";
	iso639codes[@"bnt"] = @"Bantu";
	iso639codes[@"ava"] = @"Avaric";
	iso639codes[@"cpf"] = @"Creoles and pidgins, French-based";
	iso639codes[@"sio"] = @"Siouan";
	iso639codes[@"hmn"] = @"Hmong";
	iso639codes[@"chi"] = @"Chinese";
	iso639codes[@"fry"] = @"Western Frisian";
	iso639codes[@"ukr"] = @"Ukrainian";
	iso639codes[@"afh"] = @"Afrihili";
	iso639codes[@"hmo"] = @"Hiri Motu";
	iso639codes[@"her"] = @"Herero";
	iso639codes[@"dan"] = @"Danish";
	iso639codes[@"sas"] = @"Sasak";
	iso639codes[@"mkh"] = @"Mon-Khmer";
	iso639codes[@"chk"] = @"Chuukese";
	iso639codes[@"aus"] = @"Australian";
	iso639codes[@"sat"] = @"Santali";
	iso639codes[@"ang"] = @"English, Old";
	iso639codes[@"hun"] = @"Hungarian";
	iso639codes[@"ave"] = @"Avestan";
	iso639codes[@"zap"] = @"Zapotec";
	iso639codes[@"din"] = @"Dinka";
	iso639codes[@"chm"] = @"Mari";
	iso639codes[@"zxx"] = @"No linguistic content";
	iso639codes[@"hup"] = @"Hupa";
	iso639codes[@"kal"] = @"Kalaallisut";
	iso639codes[@"chn"] = @"Chinook";
	iso639codes[@"ndo"] = @"Ndonga";
	iso639codes[@"dar"] = @"Dargwa";
	iso639codes[@"sit"] = @"Sino-Tibetan";
	iso639codes[@"eka"] = @"Ekajuk";
	iso639codes[@"ypk"] = @"Yupik";
	iso639codes[@"kam"] = @"Kamba";
	iso639codes[@"cho"] = @"Choctaw";
	iso639codes[@"kik"] = @"Kikuyu";
	iso639codes[@"kan"] = @"Kannada";
	iso639codes[@"chp"] = @"Chipewyan";
	iso639codes[@"srd"] = @"Sardinian";
	iso639codes[@"cad"] = @"Caddo";
	iso639codes[@"syr"] = @"Syriac";
	iso639codes[@"raj"] = @"Rajasthani";
	iso639codes[@"udm"] = @"Udmurt";
	iso639codes[@"ven"] = @"Venda";
	iso639codes[@"nds"] = @"Low German";
	iso639codes[@"glv"] = @"Manx";
	iso639codes[@"chr"] = @"Cherokee";
	iso639codes[@"dra"] = @"Dravidian";
	iso639codes[@"kin"] = @"Kinyarwanda";
	iso639codes[@"cpp"] = @"Creoles and pidgins, Portuguese-based";
	iso639codes[@"gmh"] = @"German, Middle High";
	iso639codes[@"kar"] = @"Karen";
	iso639codes[@"afr"] = @"Afrikaans";
	iso639codes[@"tsi"] = @"Tsimshian";
	iso639codes[@"yid"] = @"Yiddish";
	iso639codes[@"tkl"] = @"Tokelau";
	iso639codes[@"anp"] = @"Angika";
	iso639codes[@"kas"] = @"Kashmiri";
	iso639codes[@"div"] = @"Divehi";
	iso639codes[@"chu"] = @"Church Slavic";
	iso639codes[@"day"] = @"Land Dayak";
	iso639codes[@"mdf"] = @"Moksha";
	iso639codes[@"kbd"] = @"Kabardian";
	iso639codes[@"zza"] = @"Zaza";
	iso639codes[@"gem"] = @"Germanic";
	iso639codes[@"cai"] = @"Central American Indian";
	iso639codes[@"kat"] = @"Georgian";
	iso639codes[@"chv"] = @"Chuvash";
	iso639codes[@"nub"] = @"Nubian";
	iso639codes[@"jpn"] = @"Japanese";
	iso639codes[@"kir"] = @"Kirghiz";
	iso639codes[@"bos"] = @"Bosnian";
	iso639codes[@"kau"] = @"Kanuri";
	iso639codes[@"rap"] = @"Rapanui";
	iso639codes[@"geo"] = @"Georgian";
	iso639codes[@"awa"] = @"Awadhi";
	iso639codes[@"guj"] = @"Gujarati";
	iso639codes[@"zbl"] = @"Blissymbols";
	iso639codes[@"umb"] = @"Umbundu";
	iso639codes[@"kaw"] = @"Kawi";
	iso639codes[@"chy"] = @"Cheyenne";
	iso639codes[@"mlg"] = @"Malagasy";
	iso639codes[@"tsn"] = @"Tswana";
	iso639codes[@"dyu"] = @"Dyula";
	iso639codes[@"rar"] = @"Rarotongan";
	iso639codes[@"krc"] = @"Karachay-Balkar";
	iso639codes[@"srn"] = @"Sranan Tongo";
	iso639codes[@"tso"] = @"Tsonga";
	iso639codes[@"jpr"] = @"Judeo-Persian";
	iso639codes[@"ger"] = @"German";
	iso639codes[@"pol"] = @"Polish";
	iso639codes[@"kaz"] = @"Kazakh";
	iso639codes[@"srp"] = @"Serbian";
	iso639codes[@"yao"] = @"Yao";
	iso639codes[@"ssa"] = @"Nilo-Saharan";
	iso639codes[@"pon"] = @"Pohnpeian";
	iso639codes[@"yap"] = @"Yapese";
	iso639codes[@"srr"] = @"Serer";
	iso639codes[@"nep"] = @"Nepali";
	iso639codes[@"car"] = @"Galibi Carib";
	iso639codes[@"bho"] = @"Bhojpuri";
	iso639codes[@"tlh"] = @"Klingon";
	iso639codes[@"xho"] = @"Xhosa";
	iso639codes[@"cat"] = @"Catalan";
	iso639codes[@"tli"] = @"Tlingit";
	iso639codes[@"wol"] = @"Wolof";
	iso639codes[@"por"] = @"Portuguese";
	iso639codes[@"bad"] = @"Banda";
	iso639codes[@"mdr"] = @"Mandar";
	iso639codes[@"cau"] = @"Caucasian";
	iso639codes[@"cym"] = @"Welsh";
	iso639codes[@"dsb"] = @"Lower Sorbian";
	iso639codes[@"gez"] = @"Geez";
	iso639codes[@"krl"] = @"Karelian";
	iso639codes[@"dzo"] = @"Dzongkha";
	iso639codes[@"ipk"] = @"Inupiaq";
	iso639codes[@"scn"] = @"Sicilian";
	iso639codes[@"est"] = @"Estonian";
	iso639codes[@"apa"] = @"Apache";
	iso639codes[@"phi"] = @"Philippine";
	iso639codes[@"sco"] = @"Scots";
	iso639codes[@"new"] = @"Nepal Bhasa";
	iso639codes[@"kro"] = @"Kru";
	iso639codes[@"bai"] = @"Bamileke";
	iso639codes[@"mlt"] = @"Maltese";
	iso639codes[@"cre"] = @"Cree";
	iso639codes[@"bih"] = @"Bihari";
	iso639codes[@"bak"] = @"Bashkir";
	iso639codes[@"jav"] = @"Javanese";
	iso639codes[@"ell"] = @"Greek, Modern";
	iso639codes[@"bal"] = @"Baluchi";
	iso639codes[@"sla"] = @"Slavic";
	iso639codes[@"jrb"] = @"Judeo-Arabic";
	iso639codes[@"cze"] = @"Czech";
	iso639codes[@"paa"] = @"Papuan";
	iso639codes[@"crh"] = @"Crimean Tatar";
	iso639codes[@"phn"] = @"Phoenician";
	iso639codes[@"xal"] = @"Kalmyk";
	iso639codes[@"bam"] = @"Bambara";
//iso639codes[@"und"] = @"Undetermined";
	iso639codes[@"ful"] = @"Fulah";
	iso639codes[@"bik"] = @"Bikol";
	iso639codes[@"ban"] = @"Balinese";
}

/**
 *
 *
 */
- (id)initWithFilePath:(NSString *)filePath
{
	self = [super init];
	
	if (self) {
		NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
		
		self.filepath = filePath;
		self.filesize = @(attrs.fileSize);
		self.mtime = attrs.fileModificationDate;
		self.languages = [[NSMutableArray alloc] init];
		
		if (FALSE == [self getMovieInfo_AVFoundation])
			if (FALSE == [self getMovieInfo_QTKit])
				return nil;
	}
	
	return self;
}

/**
 *
 *
 */
- (BOOL)getMovieInfo_QTKit
{
	BOOL ntsc;
	double timebase, fractional, integral;
	NSError *error = nil;
	QTMovie *qtmovie = [[QTMovie alloc] initWithURL:[NSURL fileURLWithPath:self.filepath] error:&error];
	
	if (!qtmovie) {
		NSLog(@"%s.. failed to QTMovie::initWithURL(%@), %@", __PRETTY_FUNCTION__, self.filepath, error.localizedDescription);
		return FALSE;
	}
	
	// get a list of all of the video tracks
	NSArray *tracks = [qtmovie tracksOfMediaType:QTMediaTypeVideo];
	
	if (tracks.count == 0) {
		NSLog(@"%s.. no video tracks [%@]", __PRETTY_FUNCTION__, self.filepath);
		return FALSE;
	}
	
	QTTrack *qttrack = [tracks objectAtIndex:0];
	QTMedia *qtmedia = [qttrack media];
	
	// get the duration and sample count from the media
	QTTime qtduration = [[qtmedia attributeForKey:QTMediaDurationAttribute] QTTimeValue];
	long samples = [[qtmedia attributeForKey:QTMediaSampleCountAttribute] longValue];
	
	// get the fraction and integral parts of the duration
	fractional = modf((double)samples / ((double)qtduration.timeValue / (double)qtduration.timeScale), &integral);
	
	if (samples == qtduration.timeValue) {
		timebase = qtduration.timeScale;
		ntsc = FALSE;
	}
	else if (0.01 > fabs(0. - fractional)) {
		timebase = integral;
		ntsc = FALSE;
	}
	else if (0.5 > fractional) {
		timebase = integral;
		ntsc = FALSE;
	}
	else {
		timebase = integral + 1.;
		ntsc = TRUE;
	}
	
	IDTimecode *timecode = [IDTimecode timecodeWithFrames:samples framerate:timebase ntsc:ntsc];
	
	self.duration = @(timecode.duration);
	
	NSSize movieSize = ((NSValue *)qtmovie.movieAttributes[QTMovieNaturalSizeAttribute]).sizeValue;
	NSNumber *dataSize = qtmovie.movieAttributes[QTMovieDataSizeAttribute];
	
	if (movieSize.width && movieSize.height) {
		self.width = [NSNumber numberWithInteger:movieSize.width];
		self.height = [NSNumber numberWithInteger:movieSize.height];
	}
	
	if (dataSize.longLongValue && timecode.duration)
		self.bitrate = @(8 * (dataSize.longLongValue / timecode.duration));
	
	return TRUE;
}

/**
 *
 *
 */
- (BOOL)getMovieInfo_AVFoundation
{
	AVAsset *avasset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.filepath]];
	
	if (!avasset || !avasset.tracks.count)
		return FALSE;
	
	// audio tracks
	{
		NSArray *audioTracks = [avasset tracksWithMediaType:AVMediaTypeAudio];
		NSMutableDictionary *languages = [[NSMutableDictionary alloc] init];
		
		[audioTracks enumerateObjectsUsingBlock:^ (id trackObj, NSUInteger trackNdx, BOOL *trackStop) {
			AVAssetTrack *avtrack = trackObj;
			NSString *language = avtrack.languageCode;
			
			if (language)
				languages[language] = language;
		}];
		
		[languages.allValues enumerateObjectsUsingBlock:^ (id languageObj, NSUInteger languageNdx, BOOL *languageStop) {
			NSString *language = iso639codes[languageObj];
			
			if (language.length)
				[_languages addObject:language];
		}];
	}
	
	// video tracks
	{
		NSArray *videoTracks = [avasset tracksWithMediaType:AVMediaTypeVideo];
		
		[videoTracks enumerateObjectsUsingBlock:^ (id trackObj, NSUInteger trackNdx, BOOL *trackStop) {
			AVAssetTrack *avtrack = trackObj;
			CGSize size = avtrack.naturalSize;
			CMTimeRange range = avtrack.timeRange;
			
			if (kCMTimeFlags_Valid & range.duration.flags)
				self.duration = @((NSUInteger)(range.duration.value / range.duration.timescale));
			
			self.width = @(size.width);
			self.height = @(size.height);
			self.framerate = @(avtrack.nominalFrameRate);
		}];
	}
	
	if (self.duration.integerValue > 0)
		self.bitrate = @((8 * self.filesize.longLongValue) / self.duration.integerValue);
	
	return TRUE;
}

@end

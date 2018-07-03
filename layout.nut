// Dal1980
fe.load_module("animate");
fe.load_module("conveyor");
fe.load_module("scrollingtext"); 

class UserConfig {
  </ label="Region Flag", help="Choose to show or hide the region flag" options="show,hide" order=1 /> regionFlag="hide";
  </ label="Marquee Speed", help="Choose the speed of the marquee" options="VSlow,Slow,Medium,Fast,VFast" order=2 /> marqueeSpeed="Medium";
}

local layoutPath = FeConfigDirectory + "layouts/mvs-insertcoin/"; //lets get the current working path for the layout

fe.layout.width = 1280;
fe.layout.height = 1024;

local myConfig = fe.get_config();
local marqueeSpeedInt = 0.4;
local flx = fe.layout.width;
local fly = fe.layout.height;
local flw = fe.layout.width;
local flh = fe.layout.height;

local _f = null;
local _blb = null;
local binChar = null;
local curChar = null;
local regionsName = [];
local regionsID = [];
local tempObj = {};
local tempArray = [];
local fileEntry = "";
local lockLine = false; //used for comment handling

_f = file( layoutPath + "parts/region.ini", "r" ); //create file resource
_blb = _f.readblob( 100000 ); //pulls in 10,000 characters
for(local i = 0; i < _blb.len(); i++){  
    binChar = _blb.readn( 'b' );
    curChar = binChar.tochar();
    if(curChar == "#") lockLine = true;
    if(curChar == "\n") lockLine = false;
    if(!lockLine){
        if(curChar != "," && curChar != " " && curChar != "\n" && curChar != "\r") fileEntry += curChar;
        if(curChar == "\n"){
            tempArray = split( fileEntry, "=" );
            if(tempArray.len() == 2){
              regionsID.push(tempArray[0]);
              regionsName.push(tempArray[1]);
              fileEntry = "";
            }
        }
    }

}

//set bg
local bg1 = fe.add_text( "", 0, 0, flw, flh).set_bg_rgb( 255, 0, 14) //- Neo-Geo Red;
local bg2 = fe.add_image("parts/neo-geo.png", 0, 0, flw, flh ); //overlay
local crtBack = fe.add_image("parts/crtback.png", flw*0.780, 0, flw*0.221, flh*0.370 ); //overlay
crtBack.preserve_aspect_ratio = true;

local VidSnap = fe.add_artwork( "snap", flw*0.800, flh*0.010, flw*0.180, flh*0.280 ); //cab video snap
VidSnap.preserve_aspect_ratio = false;
VidSnap.pinch_y = -60;
local crt = fe.add_image("parts/crt.png", flw*0.780, 0, flw*0.221, flh*0.370 ); //overlay
crt.preserve_aspect_ratio = true;

// wheel
//                 [x]   [x]      [x]        [1]         [2]         [3]      ****4****      [5]         [6]         [7]        [x]   
local wheel_x = [   0,    0,  0,          flw*0.010,  flw*0.070,  flw*0.190,  flw*0.335,  flw*0.590,  flw*0.740,  flw*0.850,    flw*0.999]; 
local wheel_y = [   0,    0,  flh*0.385,  flh*0.365,  flh*0.325,  flh*0.285,  flh*0.245,  flh*0.285,  flh*0.325,  flh*0.365,    flh*0.385];
local wheel_w = [   0,    0,  flw*0.090,  flw*0.140,  flw*0.190,  flw*0.240,  flw*0.360,  flw*0.240,  flw*0.190,  flw*0.140,    flw*0.090 ];     
local wheel_h = [   0,    0,  flh*0.180,  flh*0.280,  flh*0.380,  flh*0.480,  flh*0.580,  flh*0.480,  flh*0.380,  flh*0.280,    flh*0.180];
local wheel_a = [   0,    0,  0,          255,        255,        255,        255,        255,        255,        255,          0 ];
local wheel_r = [   0,    0,  0,          0,          0,          0,          0,          0,          0,          0,            0 ];

local num_arts = 10;
class WheelEntry extends ConveyorSlot {
     
     constructor() {
          base.constructor( ::fe.add_artwork("flyer"));
     }

     function on_progress( progress, var ) {

          local p = progress / 0.1;
          local slot = p.tointeger();
          p -= slot;
          slot++;

          if ( slot <= 0 ) slot=0;
          if ( slot >= 9 ) slot=9;

          if(m_obj.file_name == ""){
               m_obj.file_name = "parts/no_image.png";
               m_obj.preserve_aspect_ratio = true;
          }
          m_obj.x = wheel_x[slot];
          m_obj.y = wheel_y[slot] + p * ( wheel_y[slot+1] - wheel_y[slot] );
          m_obj.width = wheel_w[slot] + p * ( wheel_w[slot+1] - wheel_w[slot] );
          m_obj.height = wheel_h[slot] + p * ( wheel_h[slot+1] - wheel_h[slot] );
          m_obj.rotation = wheel_r[slot] + p * ( wheel_r[slot+1] - wheel_r[slot] );
          m_obj.alpha = wheel_a[slot] + p * ( wheel_a[slot+1] - wheel_a[slot] );
          m_obj.preserve_aspect_ratio = true;
     }
}

local wheel_entries = [];
for ( local i=0; i < 6; i++ )
wheel_entries.push( WheelEntry() );
local remaining = num_arts - wheel_entries.len();
// we do it this way so that the last wheelentry created is the middle one showing the current
// selection (putting it at the top of the draw order)
for ( local i=0; i < 4; i++ )
wheel_entries.insert( 5, WheelEntry() );

local conveyor = Conveyor();
conveyor.set_slots( wheel_entries );
conveyor.transition_ms = 55;

//larger logo
local logo = fe.add_artwork( "wheel", flw*0.040, flh*0.81, flw*0.300, flh*0.180);
logo.preserve_aspect_ratio = true;

function simpleCat( ioffset ) {
  local m = fe.game_info(Info.Category, ioffset);
  local temp = split( m, " / " );
  if(temp.len() > 0) return temp[0];
  else return "";
}

function getPlayersIcon( ioffset) {
  local m = fe.game_info(Info.Players, ioffset);
  m = m.tolower();
  local strArray = split( m, " " );
  local newStr = "";
  for(local i = 0; i < strArray.len(); i++){
    if(i + 1 < strArray.len()) newStr += strArray[i] + "-";
    else newStr += strArray[i];
  }
  return "parts/icons/" + newStr + ".png";
}

function getFavs(index_offset){
  if(fe.game_info( Info.Favourite, index_offset ) == "1") return "parts/icons/fav.png";
  else return "";
}
local romFav = fe.add_image(getFavs(0), flw*0.478, flh*0.945, flw*0.045, flh*0.065 );


function getCurrentRegion( ioffset){
  local romName = fe.game_info(Info.Name, ioffset);
  romName = romName.tolower(); //just in case
  local returnRegion = "";
  for(local i = 0; i < regionsID.len(); i++){
    if(regionsID[i] == romName) returnRegion = regionsName[i];
  }
  if(returnRegion == "") returnRegion = "world";
  returnRegion.tolower();
  return "mame-regions-" + returnRegion + ".png";
}

if(myConfig["regionFlag"] == "show") {
  local mapExample = fe.add_image( "parts/[!getCurrentRegion]", flw*0.650, flh*0.860, flw*0.100, flh*0.100);
  mapExample.preserve_aspect_ratio = true;
}

local ledOverlay = fe.add_image("parts/led-overlay.png", flw*0.775, flh*0.839, flw*0.1705, flh*0.119 );
ledOverlay.preserve_aspect_ratio = true;
local animConfig = {
                when = Transition.ToNewSelection,
                property = "alpha",
                start = 255,
                end = 100,
                time = 200,
                loop = true,
                delay = 20, //wait X ms to run this one
            }
local animConfig2 = {
                when = Transition.ToNewSelection,
                property = "alpha",
                start = 255,
                end = 0,
                time = 500,
                loop = true,
                delay = 20, //wait X ms to run this one
            }
animation.add( PropertyAnimation( ledOverlay, animConfig ) );

fe.layout.font = "TickingTimebombBB";
local titleTxt = fe.add_text("[Name]", flw*0.350, flh*0.085, flw, flh*0.045);
titleTxt.align = Align.Left;

local plyTime = fe.add_text("[PlayedTime] ([PlayedCount])", flw*0.350, flh*0.150, flw, flh*0.045);
plyTime.align = Align.Left;

//label for current game number (LED box)
fe.layout.font = "TickingTimebombBB";
local curRomNum = fe.add_text("[ListEntry]", flw*0.760, flh*0.850, flw*0.200, flh*0.075 );
curRomNum.set_rgb(255,16,16);
curRomNum.align = Align.Centre;

local insertCoinTxt = fe.add_text("insert coin", flw*0.400, flh*0.930, flw*0.200, flh*0.045 );
insertCoinTxt.set_rgb(255,255,255);
insertCoinTxt.align = Align.Centre;
animation.add( PropertyAnimation( insertCoinTxt, animConfig2 ) );

//label for total available games
local curRomNum = fe.add_text("[ListSize] Av.Games", flw*0.760, flh*0.952, flw*0.200, flh*0.040 );
curRomNum.set_rgb(255,255,255);
curRomNum.align = Align.Centre;

local displayIcon = fe.add_image("parts/icons/[Status].png", flw*0.775, flh*0.810, flw*0.012, flh*0.015);
local playerIcon = fe.add_image("[!getPlayersIcon]", flw*0.360, flh*0.003, flw*0.080, flh*0.065);

local txtMarquee = "*** [Title] *** Manufactured by [Manufacturer] in [Year] *** Listed Category: [!simpleCat]";
local scroller = ScrollingText.add( txtMarquee + " ***", flw*0.450, flh*0.001, flw*0.370, flh*0.055 );
scroller.set_rgb( 255, 255, 255 );
scroller.settings.delay = 0;
scroller.settings.loop = -1;

//This will be depending on graphics card (vfast on some is actuall slow on other older cards)
if(myConfig["marqueeSpeed"] == "VSlow") marqueeSpeedInt = 0.4;
else if(myConfig["marqueeSpeed"] == "Slow") marqueeSpeedInt = 1;
else if(myConfig["marqueeSpeed"] == "Medium") marqueeSpeedInt = 3;
else if(myConfig["marqueeSpeed"] == "Fast") marqueeSpeedInt = 7;
else if(myConfig["marqueeSpeed"] == "VFast") marqueeSpeedInt = 10;
scroller.settings.speed_x = marqueeSpeedInt;

fe.add_transition_callback( "update_my_list" );
function update_my_list( ttype, var, ttime )
{
    if(ttype == Transition.ToNewSelection){
        romFav.file_name = getFavs(var);
    }
    return false;
}

fe.add_signal_handler( "updateFavs" );
function updateFavs( signal_str )
{
    if(signal_str == "add_favourite"){
        if(romFav.file_name != "") romFav.file_name = "";
        else romFav.file_name = "parts/icons/fav.png";
    }
}

// Dal1980
// MVS-InsertCoin V1.1

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

//Conveyor Settings
const FLYER_WIDTH = 200;
const FLYER_HEIGHT = 700;
local num_sats = fe.layout.page_size = 11;
local progress_correction = 1.0 / ( num_sats * 2 );
local spin_ms = 120;
local nSlot = -6;

//
// Create a class to contain an orbit artwork
//
function get_y( x ){ return ( 280 + sqrt( 72900 - pow( x - 300, 1 ) )); }

class Satallite extends ConveyorSlot
{
     //the first 3 and the last 3 positions are not really used
     static x_lookup =   [80,    80,    80, //not applicable 
                         120,    250,   450,            640,                840,   1040,  1170,
                         1170,   1170,  1170]; //not applicable 
     static s_lookup =   [0.300, 0.400, 0.500, //not applicable 
                         1.000,  1.300, 1.800,          2.000,              1.800, 1.300, 1.000,
                         0.500,  0.400, 0.300 ]; //not applicable 

     constructor()
     {
          //print("> " + nSlot + " " + fe.get_art("flyer", nSlot) + "\n");
          if(fe.get_art("flyer", nSlot) != ""){
               local o = fe.add_artwork( "flyer" );
               o.preserve_aspect_ratio = true;
               base.constructor( o );
          }
          else{
               local o = fe.add_image("parts/no_image.png");
               o.preserve_aspect_ratio = true;
               base.constructor( o );
          }
     }

     //
     // Place, scale and set the colour of the artwork based
     // on the value of "progress" which ranges from 0.0-1.0
     //
     function on_progress( progress, var )
     {
          local scale;
          local new_x;
          progress += progress_correction;

          if ( progress >= 1.0 )
          {
               scale = s_lookup[ 12 ];
               new_x = x_lookup[ 12 ];
          }
          else if ( progress < 0 )
          {
               scale = s_lookup[ 0 ];
               new_x = x_lookup[ 0 ];
          }
          else
          {
               local slice = ( progress * 12.0 ).tointeger();
               local factor = ( progress - ( slice / 12.0 ) ) * 12.0;

               scale = s_lookup[ slice ]
                    + (s_lookup[slice+1] - s_lookup[slice]) * factor;

               new_x = x_lookup[ slice ]
                    + (x_lookup[slice+1] - x_lookup[slice]) * factor;
          }

          if(m_obj.file_name == "") m_obj.file_name = "parts/no_image.png";
          
          m_obj.width = FLYER_WIDTH * scale;
          m_obj.height = FLYER_HEIGHT * scale;
          m_obj.x = new_x - m_obj.width / 2;
          m_obj.y = get_y( new_x ) - m_obj.height / 2;
     }
}

//
// Initialize the orbit artworks with selection at the top
// of the draw order
//
local sats = [];

for ( local i=0; i < num_sats  / 2; i++ ){
     nSlot++;
     sats.append( Satallite() );
}
nSlot = 6;
for ( local i=0; i < ( num_sats + 1 ) / 2; i++ ){
     nSlot--;
     sats.insert( num_sats / 2, Satallite() );
}

//
// Initialize a conveyor to control the artworks
//
local orbital = Conveyor();
orbital.transition_ms = spin_ms;
orbital.transition_swap_point = 1.0;
orbital.set_slots( sats );

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

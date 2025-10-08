print("main.lua begins...")
print("SC2MAKER Ver: ", __VERSION__, " Compilation date ", __DATE__, " ", __TIME__, " Commit:", __GITHASH__)
package.path = "?.lua"

Conquest.rpcbind()

S = {
  X=704;
  Y=480;
}

S.XM=S.X/2;
S.YM=S.Y/2;

local V = Screen.getMode()
Screen.setMode(V.mode, S.X, S.Y, V.colorMode, V.interlace, V.field)

if doesFileExist("lng/override.lng") then
  dofile("lang/override.lng")
else
  dofile("lang/english.lng")
end

if type(LNG) ~= "table" then
  error("Failed to access language file")
end
require("assets")

CN = {--GENERAL CONSTANTS
  MC_normal = 1;
  MC_conquest = 2;
  MC_unknown = 0;
  MCDUMP_NOECC = 0x800000;
  MCDUMP_ECC   = 0x840000;
  MC_AMMOUNT_OF_PAGES = 0x4000;
  MC_PAGESIZE_NECC = 0x200;
  MC_PAGESIZE_ECC = 0x210;
}

function Font.ftPrintMultiLineAligned(font, x, y, spacing, width, height, text, color)
  local internal_y = y
  local COL = 128
  if type(color) == "number" then COL = color end
  for line in text:gmatch("([^\n]*)\n?") do
    Font.ftPrint(font, x, internal_y, 8, width, height, line, COL)
    internal_y = internal_y+spacing
  end
end

GPAD = 0
OPAD = 0
DPAD = 7
function Pads.update()
  if DPAD > 0 then
    DPAD = DPAD-1
  else
    local pad = Pads.get()
    if pad ~= GPAD then
      OPAD = GPAD
      GPAD = pad
      DPAD = 7
      return GPAD
    end
  end
  return 0
end

CARD = {
  authstate=0;--- 0:failed to auth. 1:successfull auth, new card inserted. 2:successfull auth, same card than last auth present
  cardtype=0;
  specs = {
    pagesize=0;
    blocksize=0;
    cardsize=0;
    cardflags=0;
  };
  info = {
    type = -1;
	  freemem = -1;
	  format = -1;
	  result = -1;
  };
}

C = {
  GREY=Color.new(128,128,128);
  RED=Color.new(200,20,20);
  YELLOW=Color.new(200,200,0);
  WGREY=Color.new(100,100,100,120);
  SWHITE=Color.new(250,250,250);
  GREEN=Color.new(10, 200, 10);
  BASE=Color.new(128, 128, 128);
}

function CLAMP(a, MIN, MAX)
  if a < MIN then return MIN end
  if a > MAX then return MAX end
  return a
end

function CYCLE_CLAMP(a, MIN, MAX)
  if a < MIN then return MAX end
  if a > MAX then return MIN end
  return a
end

function DrawbarNbg(x, y, prog, col)
	Graphics.drawRect(x-(prog*2), y, prog*4, 5, col)
end

function HEXDUMP(DATA)
  local LOL = 0
  local MESSAGE = ""
  for b in DATA:gmatch('.') do
    MESSAGE = MESSAGE..string.format(('%02X '):format(b:byte()))
    --DIGEST =  DIGEST..('%c '):format(b:byte())
    LOL = LOL+1
    if (LOL%16)==0 then
      MESSAGE = MESSAGE.."\n"
    end
  end
  return MESSAGE
end

function CardIsSuitable()
  if CARD.specs.pagesize ~= 0x200 then return -1 end
  if CARD.specs.cardsize < 0x4000 then return -2 end
  if not (CARD.specs.cardflags & 1) then return -3 end
  return 0
end
--- when dumping/creating/verifying conquest card, only update the screen every `PROG_UPDATE_INTERVAL` pages processed
PROG_UPDATE_INTERVAL = 8

function ProgressDisplay(progress, color, message, message2, imgaug)
  Screen.clear()
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  if type(imgaug) == "number" then
    Graphics.drawScaleImage(imgaug, 0, 0, S.X, S.Y, Color.new(128,128,128, math.floor(progress)))
  end
  if type(message ) == "string" then Font.ftPrint(FNT[1], S.XM, S.YM-45, 8, S.X, S.Y, message ) end
  if type(message2) == "string" then Font.ftPrint(FNT[3], S.XM, S.YM-20, 8, S.X, S.Y, message2) end
  DrawbarNbg(S.XM, S.YM, 100, Color.new(100,100,100,50))
  DrawbarNbg(S.XM, S.YM, math.floor(progress), color)
   --math.floor() makes sure the bar expansion is centered and not ugly growing one side then the other due to floating point coord
  Screen.flip()
end

function NewCardEntry(pad, P)
    Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
    Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.CARD_CHANGER)
    Font.ftPrint(FNT[3], S.XM, 150, 8, S.X, S.Y, LNG.CHANGE_MC1_NOW)
    Font.ftPrint(FNT[3], S.XM, 170, 8, S.X, S.Y, LNG.CARDCHANGE_SELECT2PROCEED)
    Graphics.drawScaleImage(IMG.mc_ps2, S.XM-50, S.YM-50, 100, 100, Color.new(128,128,128,P))
end

function MainMenu(pad, sel)
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  local opts = {
    LNG.LAB_CONVERTCARD,
    LNG.LAB_REPAIRCARD,
    LNG.LAB_CHECKCARD,
    LNG.LAB_DUMPCARD,
    LNG.LAB_CREDITS,
  }  local desc = {
    LNG.CAP_CONVERTCARD,
    LNG.FEATURE_NOT_YET_AVAILABLE,--LNG.CAP_REPAIRCARD,
    LNG.CAP_CHECKCARD,
    LNG.CAP_DUMPCARD,
    LNG.CAP_CREDITS,
  }
  for i = 1, #opts do
    Font.ftPrint(FNT[3], i == sel and 52 or 50, (i*20)+50, 0, S.X, S.Y, opts[i], i == sel and C.YELLOW or C.GREY)
  end
  local validsize = CARD.specs.pagesize == 0x200 and C.GREEN or C.RED
  local validpagec = CARD.specs.cardsize == 0x4000 and C.GREEN or C.RED
  local validflags = (CARD.specs.cardflags & 1) and C.GREEN or C.RED
  Graphics.drawRect(480, 100, S.X-480, 200, Color.new(0,0,0,40))
  Font.ftPrint(FNT[2], 490, 100, 0, S.X, S.Y, LNG.CURRENT_CARD)
  local MCIMG = {}
  MCIMG[0] = IMG.mc_empty
  MCIMG[1] = IMG.mc_ps2
  MCIMG[2] = IMG.mc_sc2
  if CARD.info.type == 2 then
    Font.ftPrint(FNT[3], 491, 120, 0, S.X, S.Y, (LNG.FMT_PAGES_PER_BLOCK):format(CARD.specs.blocksize), C.GREEN)
    Font.ftPrint(FNT[3], 491, 140, 0, S.X, S.Y, (LNG.FMT_CARDFLAGS):format(CARD.specs.cardflags), validflags)
    Font.ftPrint(FNT[3], 491, 160, 0, S.X, S.Y, (LNG.FMT_PAGES_IN_CARD):format(CARD.specs.cardsize), validpagec)
    Font.ftPrint(FNT[3], 491, 180, 0, S.X, S.Y, (LNG.FMT_PAGESIZE):format(CARD.specs.pagesize), validsize)
    if (validsize ~= C.GREEN or validpagec ~= C.GREEN or validflags ~= C.GREEN) then
      Font.ftPrint(FNT[2], 490, 200, 0, S.X, S.Y, LNG.CARD_UNUSABLE, C.RED)
    end
    Graphics.drawScaleImage(MCIMG[CARD.cardtype], 500, 220, 80, 80)
  elseif CARD.info.type == 0 then
    Font.ftPrint(FNT[3], 491, 120, 0, S.X, S.Y, LNG.NOTHING_CONNECTED, C.RED)
    Graphics.drawScaleImage(IMG.mc_empty, 500, 220, 80, 80)
  else
    Font.ftPrint(FNT[3], 491, 120, 0, S.X, S.Y, LNG.NOT_PS2MC, C.RED)
  end
  Font.ftPrint(FNT[3], 50, 400, 0, S.X, S.Y, desc[sel], C.WGREY)

  Font.ftPrint(FNT[3], 50, 420, 0, S.X, S.Y, "SELECT: "..LNG.LAB_SWAPCARD)
end

function GenericNotif(prompt, prompt2)
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  Font.ftPrint(FNT[1], S.XM, 50, 8, S.X, S.Y, prompt)
  if type(prompt2) == "string" then Font.ftPrint(FNT[2], S.XM, 80, 8, S.X, S.Y, prompt2) end
end

function GenericPrompt(pad, prompt, prompt2)
  GenericNotif(prompt, prompt2)
  Font.ftPrint(FNT[3], 40, 400, 0, S.X, S.Y, "O:"..LNG.CANCEL.."  X:"..LNG.CONTINUE)
  if Pads.check(pad, PAD_CIRCLE) then return -1 end
  if Pads.check(pad, PAD_CROSS) then return 1 end
  return 0
end

function CardPrompt(prompt, pad, needs_to_be)
  Refresh_cardstate(true, false, false)
  if CARD.authstate == 2 then
    return 1
  elseif CARD.authstate == 1 then
    Refresh_cardstate(false, false, true)
    return 1
  elseif CARD.authstate == 0 then
    return -1
  end
  return 0
end

function CheckDongleConnected()
  local T = System.getMCInfo(0)
  if T.type == 2 then
    return true
  end
  return false
end

function Refresh_cardstate(auth, specs, cardtype)
  if auth then
    --CARD.authstate = Conquest.authcard(1,0)
    CARD.info = System.getMCInfo(1)
    print(("CardInfo mc%d, ret:%d, %d %d %d"):format(1, CARD.info.result, CARD.info.format, CARD.info.freemem, CARD.info.type))
  end
  if specs then
    CARD.specs = Conquest.get_cardspecs(1, 0)
    print(("spects for mc%d: (r:%d) %X %X %X %X"):format(1, CARD.specs.ret, CARD.specs.blocksize, CARD.specs.cardflags, CARD.specs.cardsize, CARD.specs.pagesize))
  end
  if cardtype then
    CARD.cardtype = Conquest.identify_card(1, 0)
    print("card ident: "..CARD.cardtype)
  end
end

function FDprintf(fd, x, ...)
  local buf = string.format(x, ...)
  System.writeFile(fd, buf, string.len(buf))
end

function CreateConquestCard(port)
  ProgressDisplay(0,C.SWHITE, LNG.STARTING_OVERRIDE);
  local fd = System.openFile("cardmaterial.bin", FREAD)

  local ret = 0
  local r
  local retstr = ""
  local buf
  local pages_per_block = CARD.specs.blocksize
  if System.sizeFile(fd) == CN.MCDUMP_ECC then
    for i = 0, CN.MC_AMMOUNT_OF_PAGES-1, 1 do
      local progi = (i * 100) / CN.MC_AMMOUNT_OF_PAGES
      if (i%PROG_UPDATE_INTERVAL)==0 then ProgressDisplay(progi, C.SWHITE, LNG.CREATING_NEW_CARD, ("%.0f%%"):format(progi), IMG.soulc) end
      buf = System.readFile(fd, CN.MC_PAGESIZE_ECC)
      if (i % pages_per_block)==0 then
        local blocknum = (i/pages_per_block)
        r = Conquest.eraseblock(port, 0, blocknum)
        if r ~= 0 then
          ret = 1
          retstr = (LNG.FMT_IOERR_ERASINGPAGE):format(i)
          break
        end
      end
      r = Conquest.writepage(port, 0, i, buf)
      if r ~= 1 then
        ret = 1
        retstr = (LNG.FMT_IOERR_WRITEPAGE):format(i)
        break
      end
    end
  else
    ret = 1
    retstr = LNG.ERR_INVALID_CARDMATERIAL_SIZE
  end
  System.closeFile(fd)
  return ret, retstr
end

function DumpConquestCard(port)
  local ret = 1
  ProgressDisplay(0,C.SWHITE, LNG.CREATING_DUMPFILE);
  System.createDirectory("card_dumps")
  local filee = ""
  for i = 0, 32, 1 do
    filee="card_dumps/dump"..i..".bin"
    if not doesFileExist(filee) then
      break
    end
  end
  local fd = System.openFile(filee, FCREATE | TRUNC)--xor O_TRUNC
  local buf
    for i = 0, CN.MC_AMMOUNT_OF_PAGES-1, 1 do
      local progi = (i * 100) / CN.MC_AMMOUNT_OF_PAGES
      if (i%PROG_UPDATE_INTERVAL)==0 then ProgressDisplay(progi, C.SWHITE, LNG.DUMPING, ("%.0f%%"):format(progi)) end--
      ret, buf = Conquest.readpage(port, 0, i, 1)
      local written = System.writeFile(fd, buf, CN.MC_PAGESIZE_ECC)
      if written ~= CN.MC_PAGESIZE_ECC then
        ret = 0
      end
    end
  System.closeFile(fd)
  return ret
end

--- list of memory card pages that soulcalibur2 reads before the "insert coin" screen
--- assume them as important for the games assesment of the card validity
local RCP = {
  0x00, 0x10, 0x11, 0x12, 0x20, 0x70, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A,
  0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A,
  0x3B, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
  0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D,
  0x5E, 0x5F, 0x60, 0x61,
}
local RELEVANT_CARDPAGES = {}
for i = 1, #RCP do
  RELEVANT_CARDPAGES[RCP[i]] = true
end

function VerifyConquestCard(port)
  local mismatches = { }
  local ret = false
  local calchash, localhash
    for i = 0, CN.MC_AMMOUNT_OF_PAGES-1, 1 do
      local progi = (i * 100) / CN.MC_AMMOUNT_OF_PAGES
      if (i%PROG_UPDATE_INTERVAL)==0 then ProgressDisplay(progi, C.SWHITE, LNG.VERIFYING_CARD, ("%.0f%%"):format(progi)) end--
      calchash, localhash = Conquest.verify_page(port, 0, i)
      if calchash ~= localhash then
        local unit = {
          page=i;--the page
          chash = calchash; --the hash we think is the correct
          lhash = localhash;--the hash declared on the card
          critical = false
        }
        if RELEVANT_CARDPAGES[i] == true then unit.critical = true end
        table.insert(mismatches, unit);
      end
    end
  return mismatches
end

function Opening()
  for i = 1, 128, 1 do
    Screen.clear()
    Greeting1(i)
    Screen.flip()
  end
  Refresh_cardstate(true, true, true)
  System.sleep(1)
  for i = 128, 1, -1 do
    Screen.clear()
    Graphics.drawScaleImage(IMG.background_error, 0, 0, S.X, S.Y)
    Greeting1(i)
    Screen.flip()
  end
  for i = 1, 128, 1 do
    Screen.clear()
    Greeting2(i, false)
    Screen.flip()
  end
  System.sleep(2)
  for i = 128, 1, -1 do
    Screen.clear()
    Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
    Greeting2(i, true)
    Screen.flip()
  end
end

function DAEMONWarn(i)
  C1 = Color.new(128,128,128,i)
  Graphics.drawScaleImage(IMG.background_error, 0, 0, S.X, S.Y, C1)
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.ERR_DAEMON_MISSING[1], C1)
  local X = 0
  for x = 2, #LNG.ERR_DAEMON_MISSING do
    Font.ftPrint(FNT[3], S.XM, 50+(25*x) , 8, S.X, S.Y, LNG.ERR_DAEMON_MISSING[x], C1)
    X = x
  end
  Graphics.drawScaleImage(IMG.helpqr, S.XM-64, 80+(25*#LNG.ERR_DAEMON_MISSING), 128, 128, C1)
end

function Greeting1(i)
  C1 = Color.new(128,128,128,i)
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y, C1)
  Graphics.drawScaleImage(IMG.soulc, 0, 0, S.X, S.Y, C1)
  Graphics.drawRect(0, 140, S.X, 190, Color.new(0,0,0,CLAMP(i, 0, 60)))
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.PROGTITLE, C1)
  for x = 1, #LNG.CREDITS do
    Font.ftPrint(FNT[3], S.XM, 130+(25*x) , 8, S.X, S.Y, LNG.CREDITS[x], C1)
  end
end

function Greeting2(i, f)
  C1 = Color.new(128,128,128,i)
  Graphics.drawScaleImage(IMG.background_error, 0, 0, S.X, S.Y, f and C1 or Color.new(128,128,128))
  --Graphics.drawRect(0, 40, S.X, 220, Color.new(0,0,0,CLAMP(i, 0, 60)))
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.WARNING_HEADING, C1)
  Font.ftPrint(FNT[3], S.XM, 150, 8, S.X, S.Y, LNG.SPECIAL_FORMAT_INSTRUCTIONS[1], C1)
  Font.ftPrint(FNT[3], S.XM, 170, 8, S.X, S.Y, LNG.SPECIAL_FORMAT_INSTRUCTIONS[2], C1)
  Font.ftPrint(FNT[3], S.XM, 200, 8, S.X, S.Y, LNG.SPECIAL_FORMAT_INSTRUCTIONS[4], C1)
  if not console_is_arcade then
    Font.ftPrint(FNT[3], S.XM, 220, 8, S.X, S.Y, LNG.SPECIAL_FORMAT_INSTRUCTIONS[3], C1)
    Font.ftPrintMultiLineAligned(FNT[3], S.XM, 250, 20, S.X, S.Y, LNG.ARCADE_KEYS_NOTICE, C1)
  end
end

function ChecksumReportWritten(reports)
  if #reports > 12 then
    local fd = System.openFile("card_verification.log", FCREATE)
    local l = "------{ "..LNG.VERIFSUMMARY_HEADING.." }------\n"
    System.writeFile(fd, l, string.len(l))
    for i = 1, #reports do
      l = (LNG.FMT_VERIFSUMMARY):format(reports[i].page, reports[i].chash, reports[i].lhash)
      if reports[i].critical == true then
        l=l.." <IMPORTANT PAGE>\n"
      else
        l=l.."\n"
      end
      System.writeFile(fd, l, string.len(l))
    end
    System.closeFile(fd)
  end
end

function ChecksumReport(reports)
  Screen.clear()
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  --Graphics.drawRect(0, 40, S.X, 220, Color.new(0,0,0,CLAMP(i, 0, 60)))
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.CONQUEST_CARD_VERIF)
  if #reports > 0 then
    Font.ftPrint(FNT[2], S.XM, 100 , 8, S.X, S.Y, (LNG.FMT_ERR_PAGEMISMATCHES):format(#reports), C.RED)
    Font.ftPrint(FNT[3], 60, 370, 0, S.X, S.Y, LNG.MISMATCHES_DO_NOT_MEAN_UNUSABLE, C.WGREY)
    if #reports < 12 then
      for i = 1, #reports do
        Font.ftPrint(FNT[3], 70, 120+(i*20), 0, S.X, S.Y, (LNG.FMT_VERIFSUMMARY):format(reports[i].page, reports[i].chash, reports[i].lhash), reports[i].critical and C.RED or C.WGREY)
      end
    else
      Font.ftPrint(FNT[3], S.XM, 150 , ALIGN_CENTER, S.X, S.Y, LNG.OFFER_LOGFILE, C.WGREY)
      Font.ftPrint(FNT[3], S.XM, 170 , ALIGN_CENTER, S.X, S.Y, LNG.OFFER_LOGFILE1, C.WGREY)
    end
  else
    Font.ftPrint(FNT[2], S.XM, 100 , 8, S.X, S.Y, LNG.SUCCESS_VERIFY)
    Font.ftPrint(FNT[2], S.XM, 120 , 8, S.X, S.Y, LNG.SUCCESS_VERIFYC)
  end
  Screen.flip()
  while Pads.get() == 0 do end
end

function ConvertionReport(ret, retstr)
  Screen.clear()
  --Graphics.drawRect(0, 40, S.X, 220, Color.new(0,0,0,CLAMP(i, 0, 60)))
  if ret ~= 0 then
    Graphics.drawScaleImage(IMG.background_error, 0, 0, S.X, S.Y)
    Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.CONVERTION_FAILED)
    Font.ftPrint(FNT[3], S.XM, 150 , 8, S.X, S.Y, retstr)
  else
    Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
    Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.CONVERTION_FINISHED)
  end
  Screen.flip()
  while Pads.get() == 0 do
  end
end

function Credits(t)
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.PROGTITLE)
  Font.ftPrint(FNT[3], S.XM, 70 , 8, S.X, S.Y, "v"..__VERSION__.." Commit: "..__GITHASH__.." Build:"..__DATE__, C.WGREY)
  for i = 1, #LNG.CREDITS do
    Font.ftPrint(FNT[2], S.XM, 75+(25*i) , 8, S.X, S.Y, LNG.CREDITS[i])
  end
  Graphics.drawScaleImage(IMG.helpqr, S.XM-64, 100+(25*#LNG.CREDITS), 128, 128)
end

UI = {
  MAINMENU = 1;
  CONVERTCARD = 2;
  CONVERTCARD_CONFIRM = 20;
  REPAIRCARD = 3;
  VERIFYCARD = 4;
  DUMPCARD = 5;
  CREDITS = 6;
  SWAPCARD = 7;
}

CanFormatCards = VerifyCardMaterial()

if console_is_arcade and not CheckDongleConnected() then
  GenericNotif(LNG.ERR_MISSINGDONGLE[1], LNG.ERR_MISSINGDONGLE[2])
end

UISTATE = UI.MAINMENU
local mms = 1
Opening()
while true do
  local sel = Pads.update()
  Screen.clear()
  if UISTATE == UI.MAINMENU then
    MainMenu(sel, mms)
    if Pads.check(sel, PAD_SELECT) then
      UISTATE = UI.SWAPCARD
    elseif Pads.check(sel, PAD_DOWN) then
      mms=CYCLE_CLAMP(mms+1, 1, 5)
    elseif Pads.check(sel, PAD_UP) then
      mms=CYCLE_CLAMP(mms-1, 1, 5)
    elseif Pads.check(sel, PAD_CROSS) then
      local opts = {UI.CONVERTCARD_CONFIRM, UI.MAINMENU, UI.VERIFYCARD, UI.DUMPCARD, UI.CREDITS}
      UISTATE = opts[mms]
      mms=1
    end
  elseif UISTATE == UI.CONVERTCARD_CONFIRM then
    local a = GenericPrompt(sel, LNG.CONVERTION_CONFIRM, LNG.THIS_WILL_WIPE_CARD)
    if a ~= 0 then
      if a == 1 then
        UISTATE = UI.CONVERTCARD
      else
        UISTATE = UI.MAINMENU
      end
    end
  elseif UISTATE == UI.CONVERTCARD then
    if CardIsSuitable() == 0 then
      local a, b
      a, b = CreateConquestCard(1)
      ConvertionReport(a, b)
      Refresh_cardstate(true,true,true)
      UISTATE = UI.MAINMENU
      goto continue
    else
      GenericNotif(LNG.INVALID_CARD_FOR_CONVERTION)
      if sel ~= 0 then
        UISTATE=UI.MAINMENU
        goto continue
      end
    end
  elseif UISTATE == UI.VERIFYCARD then
    if CARD.info.type == 2 and CARD.cardtype == 2 then
      local L = VerifyConquestCard(1)
      ChecksumReport(L)
      if Pads.check(GPAD, PAD_CROSS) then
        ChecksumReportWritten(L)
      end
      UISTATE = 1
      goto continue
    else
      GenericNotif(LNG.NOT_A_CONQUEST_CARD)
      if sel ~= 0 then
        UISTATE=UI.MAINMENU
        goto continue
      end
    end
  elseif UISTATE == UI.DUMPCARD then
    if CARD.info.type == 2 and CARD.cardtype == 2 then
        DumpConquestCard(1)
        UISTATE = 1
    else
      GenericNotif(LNG.NOT_A_CONQUEST_CARD)
      if sel ~= 0 then
        UISTATE=UI.MAINMENU
        goto continue
        end
    end
  elseif UISTATE == UI.CREDITS then
    Credits()
    if sel ~= 0 then UISTATE = UI.MAINMENU end
  elseif UISTATE == UI.SWAPCARD then
    mms = CYCLE_CLAMP(mms+1, 0, 128)
    NewCardEntry(sel, mms)
    if Pads.check(sel, PAD_SELECT) then
      Refresh_cardstate(true, true, true)
      mms=1
      UISTATE=UI.MAINMENU
    end
  end
  Screen.flip()
    ::continue::
end

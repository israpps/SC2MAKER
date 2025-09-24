package.path = "?.lua"

S = {
  X=704;
  Y=480;
}

S.XM=S.X/2;
S.YM=S.Y/2;
local V = Screen.getMode()
Screen.setMode(V.mode, S.X, S.Y, V.colorMode, V.interlace, V.field)

dofile("lang/english.lua")

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

Conquest.rpcbind()


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
  --local DIGEST = ""
  for b in DATA:gmatch('.') do
    MESSAGE = MESSAGE..string.format(('%02X '):format(b:byte()))
    --DIGEST =  DIGEST..('%c '):format(b:byte())
    LOL = LOL+1
    if (LOL%16)==0 then
      MESSAGE = MESSAGE..--[[" | "..DIGEST..]]"\n"
      --DIGEST=""
    end
  end
  return MESSAGE
end

function ProgressDisplay(progress, color, message, message2)
  Screen.clear()
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  if type(message ) == "string" then Font.ftPrint(FNT[1], S.XM, S.YM-45, 8, S.X, S.Y, message ) end
  if type(message2) == "string" then Font.ftPrint(FNT[3], S.XM, S.YM-20, 8, S.X, S.Y, message2) end
  DrawbarNbg(S.XM, S.YM, 100, Color.new(100,100,100,50))
  DrawbarNbg(S.XM, S.YM, progress, color)
  Screen.flip()
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
    LNG.CAP_REPAIRCARD,
    LNG.CAP_CHECKCARD,
    LNG.CAP_DUMPCARD,
    LNG.CAP_CREDITS,
  }
  for i = 1, #opts do
    Font.ftPrint(FNT[3], i == sel and 52 or 50, (i*20)+50, 0, S.X, S.Y, opts[i], i == sel and C.YELLOW or C.GREY)
  end
  Font.ftPrint(FNT[2], 490, 100, 0, S.X, S.Y, "Current Card:")
  Font.ftPrint(FNT[3], 500, 120, 0, S.X, S.Y, ("specret:%d\nPages Per Block:0x%X\nCardFlags:0x%X\nCardSize:0x%X\nPageSize:0x%X"):format(
    CARD.specs.ret, CARD.specs.blocksize, CARD.specs.cardflags, CARD.specs.cardsize, CARD.specs.pagesize), C.WGREY)
  Font.ftPrint(FNT[3], 50, 400, 0, S.X, S.Y, desc[sel], C.WGREY)

  Font.ftPrint(FNT[3], 50, 420, 0, S.X, S.Y, "SELECT: "..LNG.LAB_SWAPCARD)
end

function GenericPrompt(pad, prompt)
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  Font.ftPrint(FNT[1], S.XM, 0, 8, S.X, S.Y, prompt)
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

function Refresh_cardstate(auth, specs, cardtype)
  if auth then
    --CARD.authstate = Conquest.authcard(1,0)
    CARD.info = System.getMCInfo(1)
    print(("CardInfo mc%d, ret:%d, %d %d %d"):format(1, CARD.info.result, CARD.info.format, CARD.info.freemem, CARD.info.type))
  end
  if specs then
    CARD.specs = Conquest.get_cardspecs(1, 0)
    print(("spects for mc%d: %X %X %X %X"):format(1, CARD.specs.blocksize, CARD.specs.cardflags, CARD.specs.cardsize, CARD.specs.pagesize))
  end
  if cardtype then
    CARD.cardtype = Conquest.identify_card(1, 0)
  end
end

function CreateConquestCard(port)
  ProgressDisplay(0,C.SWHITE, "Starting card override progress");
  local fd = System.openFile("cardmaterial.bin", FREAD)
  local ret = 0
  local retstr = ""
  local buf
  local pages_per_block = CARD.specs.blocksize
  if System.sizeFile(fd) == CN.MCDUMP_ECC then
    for i = 0, CN.MC_AMMOUNT_OF_PAGES-1, 1 do
      local progi = (i * 100) / CN.MC_AMMOUNT_OF_PAGES
      if (i%8)==0 then ProgressDisplay(progi, C.SWHITE, LNG.CREATING_NEW_CARD, ("%.0f%%"):format(progi)) end
      buf = System.readFile(fd, CN.MC_PAGESIZE_NECC)
      if (i%pages_per_block)==0 then
        ret = Conquest.erasepage(port, 0, i/pages_per_block)
        if ret ~= 1 then
          ret = 1
          retstr = ("I/O Error on erasing page %d"):format(i)
          break
        end
      end
      ret = Conquest.writepage(port, 0, i, buf)
      if ret ~= 1 then
        ret = 1
        retstr = ("I/O Error on writing page %d"):format(i)
        break
      end
    end
  else
    ret = 1
    retstr = "invalid size for 'cardmaterial.bin'"
  end
  System.closeFile(fd)
  return ret, retstr
end

function DumpConquestCard(port)
  local ret = false
  ProgressDisplay(0,C.SWHITE, LNG.CREATING_DUMPFILE);
  local i = 0
  local filee = ""
  for i = 0, 32, 1 do
    filee="dumpcard_"..i..".bin"
    if not doesFileExist(filee) then
      break
    end
  end
  local fd = System.openFile(filee, FCREATE | TRUNC)--xor O_TRUNC
  local buf
    for i = 0, CN.MC_AMMOUNT_OF_PAGES-1, 1 do
      local progi = (i * 100) / CN.MC_AMMOUNT_OF_PAGES
      if (i%8)==0 then ProgressDisplay(progi, C.SWHITE, LNG.DUMPING, ("%.0f%%"):format(progi)) end--
      ret, buf = Conquest.readpage(port, 0, i, 1)
      local written = System.writeFile(fd, buf, CN.MC_PAGESIZE_ECC)
      if written ~= CN.MC_PAGESIZE_ECC then
        print("MISMATCH WRITE AT PAGE "..i)
      end
    end
  System.closeFile(fd)
end

function VerifyConquestCard(port)
  local mismatches = { }
  local ret = false
  local calchash, localhash
    for i = 0, CN.MC_AMMOUNT_OF_PAGES-1, 1 do
      local progi = (i * 100) / CN.MC_AMMOUNT_OF_PAGES
      if (i%8)==0 then ProgressDisplay(progi, C.SWHITE, LNG.VERIFYING_CARD, ("%.0f%%"):format(progi)) end--
      calchash, localhash = Conquest.verify_page(port, 0, i)
      if calchash ~= localhash then
        local unit = {
          page=i;--the page
          chash = calchash; --the hash we think is the correct
          lhash = localhash;--the hash declared on the card
        }
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
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, "WARNING!!!", C1)
  Font.ftPrint(FNT[3], S.XM, 150, 8, S.X, S.Y, "Due to the unique format of the conquest cards", C1)
  Font.ftPrint(FNT[3], S.XM, 170, 8, S.X, S.Y, "special methods for accessing it are being used", C1)
  Font.ftPrint(FNT[3], S.XM, 200, 8, S.X, S.Y, "For design simplicity, this program will handle the card found on port 2 only", C1)
  Font.ftPrint(FNT[3], S.XM, 220, 8, S.X, S.Y, "Only remove/insert a card when program asks to do it or by pressing select on the main menu", C1)
end

function ChecksumReport(reports)
  Screen.clear()
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  --Graphics.drawRect(0, 40, S.X, 220, Color.new(0,0,0,CLAMP(i, 0, 60)))
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, "Conquest Card Verification")
  if #reports > 0 then
    Font.ftPrint(FNT[2], S.XM, 100 , 8, S.X, S.Y, ("%d card pages have a mismatching checksum"):format(#reports), C.RED)
    Font.ftPrint(FNT[3], 60, 400, 0, S.X, S.Y, "This does not mean this conquest card is damaged\nSome working original conquest cards have checksum mismatches on some blocks", C.WGREY)
    if #reports < 12 then
      for i = 1, #reports do
        Font.ftPrint(FNT[3], 70, 120+(i*20), 0, S.X, S.Y, ("page %05d: Checksum 0x%08X | Declared Checksum 0x%08X"):format(reports[1].page, reports[1].chash, reports[1].lhash), C.WGREY)
      end
    end
  else
    Font.ftPrint(FNT[2], S.XM, 100 , 8, S.X, S.Y, "Verification was a success!")
    Font.ftPrint(FNT[2], S.XM, 120 , 8, S.X, S.Y, "All blocks have been successfully verified")
  end
  Screen.flip()
  while Pads.update() == 0 do
  end
end

function ConvertionReport(ret, retstr)
  Screen.clear()
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  --Graphics.drawRect(0, 40, S.X, 220, Color.new(0,0,0,CLAMP(i, 0, 60)))
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, "Convertion finished")
  Font.ftPrint(FNT[3], S.XM, 150 , 8, S.X, S.Y, retstr)
  Screen.flip()
  while Pads.update() == 0 do
  end
end

function MemoryCardChange()
  Screen.clear()
end

function Credits(t)
  Graphics.drawScaleImage(IMG.background, 0, 0, S.X, S.Y)
  Font.ftPrint(FNT[1], S.XM, 50 , 8, S.X, S.Y, LNG.PROGTITLE)
  Graphics.drawRect(0, 175, S.X, 2, C.SWHITE)
  Graphics.drawRect(0, 255, S.X, 2, C.SWHITE)
  for i = 1, #LNG.CREDITS do
    Font.ftPrint(FNT[3], S.XM, 130+(25*i) , 8, S.X, S.Y, LNG.CREDITS[i])
  end
end

UI = {
  MAINMENU = 1;
  CONVERTCARD = 2;
  REPAIRCARD = 3;
  VERIFYCARD = 4;
  DUMPCARD = 5;
  CREDITS = 6;
}
UISTATE = UI.MAINMENU
local mms = 1
--Opening()
Refresh_cardstate(true, false, false)
Refresh_cardstate(true, false, false)
Refresh_cardstate(true, false, false)
Refresh_cardstate(false, true, false)
--Refresh_cardstate(true, true, true) --TODO: remove me when Opening() is uncommented

while true do
  local sel = Pads.update()
  Screen.clear()
  if UISTATE == UI.MAINMENU then
    MainMenu(sel, mms)
    if Pads.check(sel, PAD_SELECT) then
      UISTATE = 99
    elseif Pads.check(sel, PAD_DOWN) then
      mms=CYCLE_CLAMP(mms+1, 1, 5)
    elseif Pads.check(sel, PAD_UP) then
      mms=CYCLE_CLAMP(mms-1, 1, 5)
    elseif Pads.check(sel, PAD_CROSS) then
      local opts = {UI.CONVERTCARD, UI.REPAIRCARD, UI.VERIFYCARD, UI.DUMPCARD, UI.CREDITS}
      UISTATE = opts[mms]
      mms=1
    end
  elseif UISTATE == UI.CONVERTCARD or UISTATE == UI.REPAIRCARD then
    local a, b
    a, b = CreateConquestCard(1)
    ConvertionReport(a, b)
    UISTATE = UI.MAINMENU
  elseif UISTATE == UI.VERIFYCARD then
    local a = CardPrompt()
    if a ~= nil then
      local L = VerifyConquestCard(1)
      ChecksumReport(L)
      UISTATE = 1
    end
  elseif UISTATE == UI.DUMPCARD then
    local a = CardPrompt()
    if a ~= nil then
      if a == -1 then UISTATE = 1 end
      if a == 0 or a == 1 then
        DumpConquestCard(1)
        UISTATE =1
      end
    end
  elseif UISTATE == UI.CREDITS then
    Credits()
    if sel ~= 0 then UISTATE = UI.MAINMENU end
  end
  Screen.flip()
end

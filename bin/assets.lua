--- FILES MUST HAVE EXTENSION. filename is parsed to create the access key: USB.PNG will be accesed by typing `IMG["USB"]`
local IMGS = {
  "background.png",
  "background_error.png",
  "soulc.png",
  "mc_empty.png",
  "mc_ps2.png",
  "mc_sc2.png",
--"select.png",
--"start.png",
--"circle.png",
--"cross.png",
--"down.png",
--"L1.png",
--"L2.png",
--"left.png",
--"R1.png",
--"R2.png",
--"right.png",
--"square.png",
--"triangle.png",
--"up.png",
  "helpqr.png",
--"R3.png",
--"L3.png",
}
IMG = {}
for x=1, #IMGS do
  local INDX = IMGS[x]:match("(.+)%..+$")
  IMG[INDX] = Graphics.loadImage("common/"..IMGS[x])
  if IMG[INDX] == nil then error("Could not load 'common/"..IMGS[x].."'") end
  Graphics.setImageFilters(IMG[INDX], LINEAR)
end

local FNTT = "font.ttf"
if LNG.ALTFONT ~= nil then
  --Translation file needs alternative font
  FNTT = LNG.ALTFONT
end
Font.ftInit()
FNT = {}
for i = 1, 3 do
  FNT[i] = Font.ftLoad(FNTT)
end

Font.ftSetCharSize(FNT[2], 940, 940)
Font.ftSetCharSize(FNT[3], 840, 840)

ALIGN_TOP     = (0 << 0)
ALIGN_BOTTOM  = (1 << 0)
ALIGN_VCENTER = (2 << 0)
ALIGN_LEFT    = (0 << 2)
ALIGN_RIGHT   = (1 << 2)
ALIGN_HCENTER = (2 << 2)
ALIGN_NONE    = (ALIGN_TOP | ALIGN_LEFT)
ALIGN_CENTER  = (ALIGN_VCENTER | ALIGN_HCENTER)

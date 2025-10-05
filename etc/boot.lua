


function VerifyCardMaterial()
  local ret = true
  local veriftable = {
    {p=0x0;c=0;ec=0x8253F0DD;},
    {p=0x14A0;c=0;ec=0x73D9A91D;},
    {p=0x2100;c=0;ec=0x79A35AED;},
  }
  local _fd = System.openFile("cardmaterial.bin", FREAD)

  for i = 1, #veriftable do
    System.seekFile(_fd, veriftable[i].p, SET)
    local tstr = System.readFile(_fd, CN.MC_PAGESIZE_NECC)
    if System.CRCStr(tstr) ~= veriftable[i].ec then
      ret = false
      break
    end
  end
  System.closeFile(_fd)
  return ret
end


dofile("main.lua")
error("end of script")

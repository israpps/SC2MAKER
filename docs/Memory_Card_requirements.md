Any official (Sony) or Licensed (HORI / KATANA / etc...) card can be used

It must NOT be a generic card clone, since the card needs to support arcade magicgate in order to be accepted by the system246 unit(1) 
{ .annotate }

1.  to make your things simpler, when SC2Maker runs from a normal PS2. it will only detect cards that support arcade magicgate. this ensures whatever card you transform works perfectly on a System246

Although all original cards share the same specs, this program will actively check some of them: more specifically:

- Page size: must be 0x200 bytes
- Card Flags: card must support ECC
- Card size: must be 8mb

if the card does not meet any of these requirements: the program will let you know, in which case, you should report to us, since there are no known original/licensed cards that have different specs
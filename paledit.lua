
function _init()
 mainpal=0
 borderpal=0
 selectedpal=0
 selectedidx=0
 oldclick=0
 mousex=-8
 mousey=-8
 poke(0x5f2d,1)
end

function click(x,y)
 if (x>=8 and x<40 and
   y>=112 and y<128) then
  selectedpal=flr((y-112)/8)
  selectedidx=flr((x-8)/8)
 elseif (x>=80 and x<112 and
   y>=88 and y<120) then
  local c=flr((x-80)/8)+
   4*flr((y-88)/8)
  local palidx
  if selectedpal==0 then
   palidx=mainpal
  else
   palidx=borderpal
  end
  sset(palidx,8+selectedidx,c)
 end
end


function _update()
 if (btnp(0,0) and mainpal>0) mainpal-=1
 if (btnp(1,0) and mainpal<31) mainpal+=1
 if (btnp(2,0) and borderpal>0) borderpal-=1
 if (btnp(3,0) and borderpal<31) borderpal+=1
 mousex=stat(32)
 mousey=stat(33)
 local newclick=stat(34)
 if newclick==1 and oldclick==0 then
  click(mousex,mousey)
 end
 oldclick=newclick
end

function _draw()
 pal()
 palt()
 palt(0,false)
 cls()
 setpal(mainpal)
 map(0,0)
 setpal(borderpal)
 palt(3,true)
 map(16,0,-4,-4)
 pal()
 palt()
 palt(0,false)
 for i=0,3 do
  rectfill(8+i*8,112,15+i*8,119,sget(mainpal,8+i))
  rectfill(8+i*8,120,15+i*8,127,sget(borderpal,8+i))
 end
 print(mainpal,0,112,7,5)
 print(borderpal,0,120,7,5)
 rect(
  7+selectedidx*8,
  112+selectedpal*8,
  16+selectedidx*8,
  120+selectedpal*8,
  7)
 for i=0,15 do
  local x,y=i%4,flr(i/4)
  rectfill(80+8*x,88+8*y,87+8*x,95+8*y,i)
 end
 circ(mousex,mousey,3,7)
end

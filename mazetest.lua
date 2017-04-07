function contains(arr, v)
 for x in all(arr) do
  if (x==v) return true
 end
 return false
end

function test_pickpop()
 local xs={1,2,3}
 local x=pickpop(xs)
 assert(x==1 or x==2 or x==3)
 assert(#xs==2)
 assert(not contains(xs, x))
 printh('test_pickpop ok')
end

function test_logbits()
 assert(logbits(1)==0)
 assert(logbits(2)==1)
 assert(logbits(3)==2)
 assert(logbits(4)==2)
 assert(logbits(5)==3)
 assert(logbits(7)==3)
 assert(logbits(8)==3)
 assert(logbits(9)==4)
 assert(logbits(16)==4)
 assert(logbits(17)==5)
 printh('test_logbits ok')
end

function test_getbits()
 assert(getbits(0x7d,0,4)==0xd)
 assert(getbits(0x7d,4,4)==0x7)
 assert(getbits(0x7d,8,4)==0)
 assert(getbits(0x7d,2,2)==0x3)
 printh('test_getbits ok')
end

function test_grid()
 local x,y,ori
 local g=grid(4,4)
 assert(g.offs(0,0)==0)
 assert(g.offs(1,0)==1)
 assert(g.offs(3,0)==3)
 assert(g.offs(1,1)==5)
 assert(g.offs(2,3)==14)
 assert(g.offs(3,3)==15)
 x,y=g.xy(14)
 assert(x==2 and y==3)
 x,y=g.xy(3)
 assert(x==3 and y==0)
 local links=g.alllinks()
 assert(#links==24)
 assert(contains(links,g.encl(0,0,0)))
 assert(contains(links,g.encl(2,0,0)))
 assert(contains(links,g.encl(3,0,1)))
 assert(contains(links,g.encl(0,3,0)))
 printh('test_grid ok')
end

function test_maze()
 -- It's pretty hard to test this
 -- thoroughly. For now let's
 -- settle for the maze having
 -- the right number of links.
 -- It should always be one less
 -- than the number of cells.
 local g=grid(4,4)
 local m=maze(g)
 m.kruskal()
 local links=m.alllinks()
 assert(#links==15)
 links=m.alllinks(false)
 assert(#links==9)
 g=grid(16,16)
 m=maze(g)
 m.kruskal()
 links=m.alllinks()
 assert(#links==255)
 links=m.alllinks(false)
 assert(#links==225)
 m.tighten(50)
 links=m.alllinks()
 assert(#links==305)
 links=m.alllinks(false)
 assert(#links==175)
 m.draw()
 printh('test_maze ok')
end

function _init()
 cls()
 test_pickpop()
 test_logbits()
 test_getbits()
 test_grid()
 test_maze()
end

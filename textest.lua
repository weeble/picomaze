
function _init()
 build_plt(plt_addr)
 --setup_room(
 -- dark_biome,
 -- darker_biome,
 -- forest_biome)
 setup_room(
  rndbiome(),
  rndbiome(),
  rndbiome())
end

function _draw()
 draw_map()
 pal()
 palt()
 palt(0,false)
 --slow_shadow(73,72,72)
end

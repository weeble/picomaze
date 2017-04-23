cat sortlib.lua mazelib.lua mazetest.lua | picobuild update mazetest.p8 --lua -
cat sortlib.lua mazelib.lua texlib.lua textest.lua | picobuild update textest.p8 --lua -
cat sortlib.lua texlib.lua paledit.lua | picobuild update paledit.p8 --lua -
cat profile.lua | picobuild update profile.p8  --lua -
cat sortlib.lua | picobuild update sorttest.p8  --lua -

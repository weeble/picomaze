function identity(x)
 return x
end

function sort(t,key)
 if (key==nil) key=identity
 msort(t,1,#t,key)
end

function msort(t,a,b,key)
 if (a==b) return
 local sp=flr((a+b)/2)
 if b-a>=2 then
  msort(t,a,sp,key)
  msort(t,sp+1,b,key)
 end
 local ai,bi=a,sp+1
 local ex={}
 function exa()
  add(ex,t[ai])
  ai+=1
 end
 function exb()
  add(ex,t[bi])
  bi+=1
 end
 while ai<=sp and bi<=b do
  if key(t[ai])>key(t[bi]) then
   exb()
  else
   exa()
  end
 end
 while ai<=sp do exa() end
 while bi<=b do exb() end
 ai=1
 for i=a,b do
  t[i]=ex[ai]
  ai+=1
 end
end





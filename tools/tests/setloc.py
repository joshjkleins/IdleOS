# usage: setloc.py <stats.gd> <Location> "Name:key=val,...;Name2:..."   (val 'traits=a|b' sets the traits array)
import sys,re
p,loc,spec=sys.argv[1],sys.argv[2],sys.argv[3]
s=open(p,encoding='utf-8').read()
order=["School","Lawfirm","Hospital","Bank","Police Station","Government"]
i=s.index('"name": "%s"'%loc); nxt=order[order.index(loc)+1] if order.index(loc)+1<len(order) else None
j=s.index('"name": "%s"'%nxt, i) if nxt else s.index('func _ready', i)
sec=s[i:j]
for part in spec.split(';'):
    if not part.strip(): continue
    name,kv=part.split(':',1)
    a=sec.index('"name": "%s"'%name); b=sec.index('"loot"',a)
    blk=sec[a:b]
    for pair in kv.split(','):
        k,v=pair.split('=')
        if k=='traits':
            arr='['+', '.join('"%s"'%t for t in v.split('|') if t)+']'
            if '"traits":' in blk:
                blk=re.sub(r'"traits": \[[^\]]*\]', '"traits": '+arr, blk, count=1)
            else:
                blk=blk.replace('"firewall reboot":', '"traits": %s,\n\t\t\t\t"firewall reboot":'%arr,1)
            continue
        blk,n=re.subn(r'("%s": )[0-9.]+'%re.escape(k), r'\g<1>'+v, blk, count=1)
        assert n==1,(name,k)
    sec=sec[:a]+blk+sec[b:]
open(p,'w',encoding='utf-8').write(s[:i]+sec+s[j:])

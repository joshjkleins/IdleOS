import json,sys
d=json.load(open(sys.argv[1])); U=json.load(open(sys.argv[2]))
K=float(sys.argv[3]) if len(sys.argv)>3 else 1.0
roles={}
for t in d['tiers']:
  p=t['states']['arrive']['procs']
  g=lambda pre:[v for k,v in p.items() if k.startswith(pre)][0]
  m,pa,cr,ma=g('mine'),g('parse'),g('crack'),g('match')
  log=m['seconds']/sum(m['out'].values()); logn=list(m['out'])[0]
  ps=(pa['seconds']+sum(pa['inp'].values())*log)/sum(pa['out'].values())
  enc=list(cr['inp'])[0]; crn=list(cr['out'])[0]
  cs=cr['seconds']+ps*cr['inp'][enc]
  partner=[k for k in ma['inp'] if k!=crn][0]
  other=[k for k in pa['out'] if k not in (enc,partner)][0]
  ms=(ma['seconds']+sum(v*(cs if k==crn else ps) for k,v in ma['inp'].items()))/sum(ma['out'].values())
  mn=list(ma['out'])[0]
  roles[t['tier']]={'logs':(logn,log),'enc':(enc,ps),'other':(other,ps),'partner':(partner,ps),'cracked':(crn,cs),'matched':(mn,ms)}
MAP={'decoding.speed':'logs','decoding.efficiency':'logs','decoding.yield':'enc','decoding.rare_tracker':'cracked',
 'decoding.salvage_sweep':'matched','decoding.field_notes':'partner',
 'system.cooling_amount':'logs','system.heat_reduction':'logs','system.background_services':'other','system.kernel_modules':'partner',
 'system.defrag_duration':'enc','system.defrag_cooldown':'cracked','system.vm_snapshot':'matched'}
CAP=['logs','other','cracked','matched']
def conv(amount,tier,role):
  n,s=roles[tier][role]; ln,lsec=roles[tier]['logs']
  return n,max(1,int(round(amount*lsec/s*(1 if role=='logs' else K))))
out=[]
for pk in U['packages']:
  if pk['group'] not in ('Decoding','System'): continue
  for l in pk['levels']:
    c=l['costs']
    if len(c)!=1 or c[0]['item'].startswith('@'): continue
    old=c[0]['amount']; t=l['tier']
    if pk['type']=='capstone':
      new=[]
      for r in CAP:
        n,a=conv(old/len(CAP)*(K if r=='logs' else 1),t,r); new.append({'item':n,'amount':a})
    else:
      n,a=conv(old,t,MAP[pk['id']]); new=[{'item':n,'amount':a}]
    out.append((pk['id'],t,l['slot'],old,c[0]['item'],new))
    if len(sys.argv)>4: l['costs']=new
if len(sys.argv)>4:
  json.dump(U,open(sys.argv[4],'w'),indent=1)
for o in out:
  if o[1] in (1,6): print(o[0],'T%d'%o[1],'%d %s ->'%(o[3],o[4]),', '.join('%d %s'%(x['amount'],x['item']) for x in o[5]))

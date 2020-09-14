load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin
;----------------------------------------------------------------------
; Set some plot resources
;----------------------------------------------------------------------
res                    = True
res@gsnDraw            = False       ; Don't draw plot
res@gsnFrame           = False       ; Don't advance frame
res@vpXF              = 0.12
res@vpYF              = 0.95
res@vpWidthF          = 0.7
res@vpHeightF         = 0.525
res@tmBorderThicknessF= 3
res@tmXTMajorThicknessF=3
res@tmXTMinorThicknessF=2
res@tmXBMajorThicknessF=3
res@tmXBMinorThicknessF=2
res@tmYLMajorThicknessF=3
res@tmYLMinorThicknessF=2
res@tmYRMajorThicknessF=3
res@tmYRMinorThicknessF=2
res@tmYLAutoPrecision  =False
res@tmYLPrecision      =2
res@tmXBPrecision      =2

res2=res

;---Resources for X/Y axes.
res@trXMinF            =  10.0
res@trXMaxF            =  32.0
res@trYMinF            =  -0.7
res@trYMaxF            =  0.0
res@tiXAxisString     = "Salinity Difference (psu)"
res@tiYAxisString     = "Freshwater Transport (Sv)"
res@tiYAxisOffsetXF   = 0.02

res1=res

DIR_in0    = getenv("CLMREF")
DIR_in1    = getenv("CLMREF")
DIR_out    = getenv("FIGREF")
lat0       = stringtofloat(getenv("LAT0"))
models = str_split(getenv("CMIP5_CLIM_MODELS"), " ,")

num_model=dimsizes(models)
;print(""+models)
;print(""+num_model)

MFWT=new((/num_model/),"double",1e20)
Sdiff=new((/num_model/),"double",1e20)

;order=ispan(0,num_model-1,1)
;marker=mod(order,10)+3
marker=(/3,4,5,6,7,8,10,11,12,16,3,4,5,6,7,8,10,11,12,16/)

res@xyMarkLineMode     = "Markers"
res@xyMarkerSizeF      = 0.01
res@xyMarkerThicknessF = 2.
res@xyMonoMarkerColor  = False
res@xyMarkers          = marker
res@xyMarkerColors     = "white"

res0=res
res0@gsMarkerThicknessF = 5.0
res0@gsMarkerSizeF      = 0.02
delete(res0@gsnDraw)
delete(res0@gsnFrame)
  
rrr=new(118,double,1e20)
yyy=new(118,float,1e20)
;do j=1,118
do j=1,1
;  lat0=-30.+(j-1)*1 
;  lat0=26

  yyy(j-1)=lat0

do mm=0,num_model-1
  model=models(mm)
  DIR_in=DIR_in0
  nc=model+".MFWT.clim.nc"
  fil = addfile(DIR_in+nc,"r")
  latT=fil->lat
  jjj=minind(abs(lat0-latT))
  tmp=fil->MFWT(0,jjj,0)
  if(max(abs(tmp)).gt.100)then
    tmp=tmp/1e3
  end if
  if(max(abs(tmp)).gt.100)then
    tmp=tmp/1e3
  end if
  MFWT(mm)=tmp
  delete(tmp)

  nc=model+".so_wgt.clim.nc"
  fil =  addfile(DIR_in+nc,"r")
  tmp1 = fil->so(0,jjj,3)
  tmp2 = fil->so(3,jjj,3)
  tmp = tmp1
  tmp = tmp1 - tmp2
  replace_ieeenan (tmp, tmp@_FillValue, 0)
  Sdiff(mm)=tmp
  print(models(mm)+" "+latT(jjj)+" "+MFWT(mm)+" "+Sdiff(mm)+" "+tmp1+" "+tmp2)
  delete(latT)
  delete(tmp)
  delete(tmp1)
  delete(tmp2)
end do  ;;; model loop
;printMinMax(MFWT,False)
;printMinMax(Sdiff,False)

plot  = new(num_model,graphic)
plot0 = new(1,graphic)
plot1 = new(1,graphic)
plot2 = new(1,graphic)
plot3 = new(1,graphic)
plot4 = new(1,graphic)
plot5 = new(1,graphic)

wks = gsn_open_wks("pdf",DIR_out+"/MFWT_vs_Sdiff_lat0_dots")
if(num_model.le.20)then
  gsn_define_colormap(wks,"xbxu")
  colors=floattoint(fspan(2,21,num_model+1))
else
  gsn_define_colormap(wks,"amwg256")
  colors=floattoint(fspan(2,255,num_model))
end if
print(""+dimsizes(colors))

res@trYMinF   =  toint((min(MFWT)-0.05)*10.)/10.
res@trYMaxF   =  toint((max(MFWT)+0.05)*10.)/10.
res@trXMinF   =  toint((min(Sdiff)-0.05)*10.)/10.
res@trXMaxF   =  toint((max(Sdiff)+0.05)*10.)/10.
print("&&&&&&&&&&&&&&&&&&&&&&&&"+res@trYMinF+" "+res@trYMaxF)
plot0 = gsn_csm_xy (wks,Sdiff,MFWT,res)
printMinMax(Sdiff,False)
printMinMax(MFWT,False)
nn=0
xx = Sdiff
yy = MFWT
do mm=0,num_model-1
  res0@gsMarkerIndex = marker(mm)
  res0@gsMarkerColor = colors(mm)
  if(.not.ismissing(Sdiff(mm)) .and. .not.ismissing(MFWT(mm)))
    plot(mm) = gsn_add_polymarker(wks,plot0,Sdiff(mm),MFWT(mm),res0)
    xx(nn)=Sdiff(mm)
    yy(nn)=MFWT(mm)
    nn=nn+1
  end if
end do
res0@gsMarkerIndex = 4 
res0@gsMarkerColor = 1 
x=xx(0:nn-1)
y=yy(0:nn-1)
delete(xx)
delete(yy)
plot4 = gsn_add_polymarker(wks,plot0,avg(x),avg(y),res0)
;======================================================================
; qq(m,k,i)
; m ---> model
; k ---> Upper, Middle, Lower
; i ---> All, Pos, Neg
;======================================================================
x0=avg(x)
y0=avg(y)
print(x+" "+y)
rc =  regline_stats(x,y)
rrr(j-1)=(/rc/)

nx   = dimsizes(rc@Yest)
xis = x(0:nx-1)
pltarry = new ( (/1,nx/), typeof(x))
;printVarSummary(pltarry)
;print(rc@Yest)
pltarry(0,:) = rc@Yest

res1@xyMarkLineModes= "Lines"
res1@xyDashPatterns = 0  ; solid line 
res1@xyLineThicknesses   = (/1/)
res1@xyLineColors   = (/"black"/)
res1@trXMinF   =  res@trXMinF
res1@trXMaxF   =  res@trXMaxF
plot1  = gsn_csm_xy (wks,xis,pltarry,res1) ; create plot
overlay(plot0,plot1)
delete(pltarry)

txres = True ; Text resources
txres@txFontHeightF = 0.012
txres@txJust= "CenterLeft"
xpos = 0.3
if(abs(rc@tval(1)).gt.2.093)then
sig="Yes"
else
sig="No"
end if

rcf=sprintf("%5.2f",rc*100.)
tval=sprintf("%5.2f",rc@tval(1))

ypos = 0.25
;gsn_text_ndc(wks,"Reg Coef="+rcf+" "+sig, xpos,ypos,txres)
;print("Reg Coef="+rcf*100.)
yintercept=sprintf("%6.2f",rc@yintercept*100.)
print("Y="+rcf+"*X+"+yintercept)
ypos = 0.2
;gsn_text_ndc(wks,"Tval="+tval+" Tref=1.734", xpos,ypos,txres)
if(abs(rc@tval(1)).gt.2.093)then
  sig="Yes"
else
  sig="No"
end if
print(lat0+" Tval="+tval+" "+sig)
delete(ypos)
delete(rc)

;----------------------------------------------------------------------
; Draw some markers and text.
;----------------------------------------------------------------------

plres = True
plres@gsLineColor = "black"
plres@gsLineDashPattern = 16
plres@gsLineThicknessF = 3 
xx=(/0.,0./)
yy=(/res@trYMinF,res@trYMaxF/)
xx=(/res@trXMinF,res@trXMaxF/)
;yy=(/0.,0./)
;======================================= hycom =======================================
nc = "HYCOM.MFWT.clim.nc"
fil = addfile(DIR_in1+nc,"r")
latT=fil->lat
jjj=minind(abs(lat0-latT))
delete(latT)
tmp=fil->MFWT(0,0,jjj,0)
if(max(abs(tmp)).gt.100)then
  tmp=tmp/1e3
end if
if(max(abs(tmp)).gt.100)then
  tmp=tmp/1e3
end if
MFWT0=tmp
delete(tmp)

nc = "HYCOM.so_wgt.clim.nc"
;print("Now,the nc is: "+nc)
fil= addfile(DIR_in1+nc,"r")
lat= fil->lat
jjj=ind_nearest_coord(lat0,lat,0)
tmp1 = fil->so(0,0,jjj,3)
tmp2 = fil->so(0,2,jjj,3)
Sdiff0 = tmp1
Sdiff0 = tmp1 - tmp2

delete(lat)
res0@gsMarkerIndex = 16
res0@gsMarkerColor = 1 
plot3 = gsn_add_polymarker(wks,plot0,Sdiff0,MFWT0,res0)

;======================================= model being analyzed =======================================
DIR_in2 = getenv("OUTDIR")
model = getenv("CASENAME")
nc = model+".MFWT.clim.nc"
fil = addfile(DIR_in2+nc,"r")
latT=fil->lat
jjj=minind(abs(lat0-latT))
delete(latT)
tmp=fil->MFWT(0,jjj,0)
if(max(abs(tmp)).gt.100)then
  tmp=tmp/1e3
end if
if(max(abs(tmp)).gt.100)then
  tmp=tmp/1e3
end if
MFWT0=tmp
delete(tmp)

nc = model+".so_wgt.clim.nc"
;print("Now,the nc is: "+nc)
fil= addfile(DIR_in2+nc,"r")
lat= fil->lat
jjj=ind_nearest_coord(lat0,lat,0)
tmp1 = fil->so(0,jjj,3)
tmp2 = fil->so(2,jjj,3)
Sdiff0 = tmp1
Sdiff0 = tmp1 - tmp2

delete(lat)
res0@gsMarkerIndex = 12
res0@gsMarkerColor = 1 
plot5 = gsn_add_polymarker(wks,plot0,Sdiff0,MFWT0,res0)

;====================================================================================================
mkres = True
txres = True ; Text resources
txres@txFontHeightF = 0.012
txres@txJust= "CenterLeft"

markers=new(num_model+3,typeof(marker))
colorss=new(num_model+3,typeof(colors))
modelss=new(num_model+3,typeof(models))
markers(0:num_model-1)=(/marker/)
colorss(0:num_model)=(/colors/)
modelss(0:num_model-1)=(/models/)
markers(num_model)=4
colorss(num_model)=1
modelss(num_model)="20-CMIP5 average"
markers(num_model+1)=16
colorss(num_model+1)=1
modelss(num_model+1)="HYCOM"
markers(num_model+2)=12
colorss(num_model+2)=1
modelss(num_model+2)="This model:~C~"+getenv("CASENAME")

xpos= 0.85
ypos=fspan(0.425,0.95,num_model+3)
ypos=ypos(::-1)
;print(""+ypos)
do mm=0,num_model+2
  mkres@gsMarkerThicknessF = 3.0 
  mkres@gsMarkerSizeF= 0.015
  mkres@gsMarkerIndex= markers(mm)
  mkres@gsMarkerColor= colorss(mm)
;  mkres@gsMarkerIndex= marker(mm)
;  mkres@gsMarkerColor= colors(mm)
  xx0 = xpos
  yy0 = ypos(mm)
; print("x,y:"+xx0+""+yy0)
  gsn_polymarker_ndc(wks, xx0,yy0,mkres)
  gsn_text_ndc(wks,modelss(mm), xx0+0.02,yy0,txres)
end do
;----------------------------------------------------------------------------------------------------
txres               = True                     ; text mods desired
txres@txFontHeightF = 0.035
txres@txFontColor   = "black"
;txt = gsn_add_text(wks,plot0,"c)",11.0,-0.05,txres)
;----------------------------------------------------------------------------------------------------

pres=True
pres@gsnPanelDebug =True
maximize_output(wks,pres)
end do   ;;; lat loop

end
10 REM ================================================
20 REM   MANDELBROT SET  -  ASCII ART
30 REM   EhBASIC 68000 Edition
40 REM ================================================
50 REM
60 REM  Characters: sparse(outside) --> dense(inside)
70 REM  Real  axis: -2.3 to  0.9  (72 columns)
80 REM  Imag  axis: -1.15 to 1.15  (44 rows)
90 REM
100 W=72:H=44:MX=64
110 XMN=-2.3:XMX=0.9
120 YMN=-1.15:YMX=1.15
130 REM --- Gradient character set (light to dark) ---
140 A$=" .`',-_:;+|i!rnczuvxXYUJCLQ0OZmwqpdbkhao*#%MW&8B@"
150 NL=LEN(A$)
160 DX=(XMX-XMN)/W
170 DY=(YMX-YMN)/H
180 REM
190 PRINT "================================================"
200 PRINT " MANDELBROT SET   EhBASIC 68000"
210 PRINT "================================================"
220 PRINT " Real: ";XMN;" to ";XMX
230 PRINT " Imag: ";YMN;" to ";YMX
240 PRINT " Size: ";W;"x";H;"  MaxIter: ";MX
250 PRINT "================================================"
260 PRINT
270 REM --- Render ---
280 CI=YMN
290 FOR J=0 TO H-1
300   CR=XMN
310   FOR I=0 TO W-1
320     ZR=0:ZI=0:N=0
330     FOR K=1 TO MX
340       T=ZR*ZR-ZI*ZI+CR
350       ZI=2*ZR*ZI+CI
360       ZR=T
370       IF ZR*ZR+ZI*ZI>4 THEN N=K:K=MX
380     NEXT K
390     IF N=0 THEN PRINT "@"; ELSE PRINT MID$(A$,1+INT(N*(NL-1)/MX),1);
400     CR=CR+DX
410   NEXT I
420   PRINT
430   CI=CI+DY
440 NEXT J
450 PRINT
460 PRINT "================================================"
470 PRINT " Done!"
480 PRINT "================================================"
490 END

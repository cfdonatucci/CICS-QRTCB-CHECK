*ASM XOPTS(SP)                                                           
*----------------------------------------------------------------*
*  Licensed Materials - Property of IBM  Argentina               *
*  Author Carlos Donatucci                                       *
*  (c) Copyright IBM Corp. 2020 All Rights Reserved              *
*  US Government Users Restricted Rights - Use, duplication or   *
*  disclosure restricted by GSA ADP Schedule Contract with       *
*  IBM Corp                                                      *
*----------------------------------------------------------------*
* ADMIN TRANSACTION                                                     00013200
*                                                                       00014000
* QRADSHO          -> Shows STATUS                                      00015044
* QRADSTO          -> Stops CHECKING                                    00015144
* QRADINTMMSS      -> Sets  CHECKING INTERVAL QRADINT0030 30"           00015244
*                                                                       00016018
WORKING  DSECT                                                          00020000
INTCHK   DS    CL8                00003000 HHMMSS00                     00021007
STATUS   DS    CL1                                                      00022000
STACTI   EQU   C'A'                                                     00023000
STINAC   EQU   C'I'                                                     00023100
STSTOP   EQU   C'S'                                                     00023200
*                                                                       00023300
DFHEISTG DSECT                                                          00024000
WSADDR   DS    A                                                        00024101
WTOMSG   DS    CL50                                                     00025051
         DS    0F                                                       00040000
CICSNAM  DS    CL(8)                                                    00050000
WAREA    DS    0CL11                                                    00060029
WTRAN    DS    CL4              TRANSACTION                             00070000
WCODE    DS    CL3              INI/STO/ENA/DIS/INT                     00080000
WINTD    DS    CL4                                                      00090029
WSENDMS  DS    CL(80)                                                   00090300
*//////////////////////////////////////////////////////////             00090439
         DFHREGS                                                        00090548
QRCHADM  CSECT                                                          00090600
QRCHADM  AMODE 31                                                       00090700
QRCHADM  RMODE ANY                                                      00090800
         EXEC CICS READQ TS QUEUE('QRCH') ITEM(1)                      X00090900
               INTO(WSADDR) LENGTH(WSADDRL) NOHANDLE                    00091026
         CLC   EIBRESP,DFHRESP(NORMAL)        READQ TO GET COMMON       00091147
         BE    QEUEUOK                        AREA ADDRESS              00091239
         MVC   WTOMSG(L'WTOMSG),WTOERR04                                00091351
         B     RETURN                                                   00091426
QEUEUOK  EQU   *                                                        00091626
         L     R4,WSADDR                                                00091748
         USING WORKING,R4                                               00091848
         MVC   WSENDMS,SENDMSOK                                         00093000
         EXEC CICS INQUIRE SYSTEM JOBNAME(CICSNAM)                      00094010
         EXEC CICS RECEIVE INTO(WAREA) LENGTH(WLEN11)  NOHANDLE         00095050
         CLC   EIBRESP,DFHRESP(LENGERR)   Receive Parms                 00095349
         BNE   SEEFUNC                    IF LENGTH > 11 ERROR          00095449
         MVC   WTOMSG,WTOERR01            OTHERWISE CHECK FUNCTION      00095551
         B     RETURN                                                   00095610
*                                                                       00096000
SEEFUNC  EQU   *                                                        00250039
         CLC   WCODE(3),=CL3'SHO'         SHOW FUNCTION                 00260039
         BNE   STOP                                                     00270000
         MVC   WTOSHO+17(9),INTCHK                                      00271012
         MVC   WTOMSG(L'WTOMSG),WTOSHO                                  00273051
         B     RETURN                                                   00276000
STOP     EQU   *                                                        00276100
         CLC   WCODE(3),=CL3'STO'         STOP FUNCTION                 00276239
         BNE   SETINT                                                   00276338
         MVI   STATUS,STSTOP                                            00276400
         MVC   WTOMSG(L'WTOMSG),WTOSTO                                  00276551
         B     RETURN                                                   00276800
SETINT   EQU   *                         SET INTERVAL FUNCTION          00280739
         CLC   WCODE(3),=CL3'INT'        IF NOT INT                     00280839
         BNE   INVFUNC                   INVALID FUNCTION CODE          00280939
         BAL   R5,VALIDATE               GO TO VALIDATE INPUT           00281248
         MVC   INTCHK+2(4),WINTD         FORMAT OK                      00281330
         MVC   WTOINT+39(4),WINTD                                       00282032
         MVC   WTOMSG(L'WTOMSG),WTOINT                                  00282151
         B     RETURN                                                   00282500
INVFUNC  EQU   *                                                        00282639
         MVC   WTOMSG(L'WTOMSG),WTOERR02       INVALID FUNCTION CODE    00282851
RETURN   EQU   *                                                        00283100
         MVC   WTOMSG+8(8),CICSNAM                                      00283251
         EXEC CICS WRITE OPERATOR TEXT(WTOMSG) TEXTLENGTH(L'WTOMSG)     00283351
*                                                                       00283410
         CLI   EIBTRMID,0                RUNNING ON TERMINAL?           00284039
         BE    EXIT                                                     00285000
         EXEC CICS SEND FROM(WSENDMS) LENGTH(80)  NOHANDLE              00286000
*                                                                       00287000
EXIT     EQU   *                                                        00288000
         EXEC CICS RETURN                                               00289000
*//////////////////////////////////////////////////////////////         00290028
* VALIDATE INPUT CONSISTENCY AS 0005<MMSS<0259                          00290139
*                                                                       00290228
VALIDATE DS  0H                                                         00290328
         CLC  WINTD(4),=C'0005'        LESS THAN 5'?                    00291233
         BL   VALNOOK                                                   00291339
         CLC  WINTD(4),=C'0259'        MORE THAN 2'59"?                 00291436
         BH   VALNOOK                                                   00291539
         CLC  WINTD(2),=C'00'          VALIDATE 00<MM                   00291739
         BL   VALNOOK                                                   00291839
         CLC  WINTD(2),=C'02'          NO MORE THAN 2 MIN               00292037
         BH   VALNOOK                                                   00292139
         CLC  WINTD+2(2),=C'00'        VALIDATE 00<SS<59                00292339
         BL   VALNOOK                                                   00292437
         CLC  WINTD+2(2),=C'59'                                         00292537
         BH   VALNOOK                                                   00292637
         BR    R5                      INPUT OK                         00292848
VALNOOK  EQU   *                                                        00292936
         MVC   WTOMSG(L'WTOMSG),WTOERR03     INPUT ERROR                00293051
         B     RETURN                                                   00293136
*/////////////////////////////////////////////////////                  00294028
         LTORG                                                          00300000
WLEN11   DC  H'11'                                                      00310029
WSADDRL  DC  H'4'                                                       00311000
*............... 0....+....1....+....2....+....3....+....4....+....5    00340020
WTOSTO   DC CL50'QRC011I XXXXXXXX QRCHECK Finalization Scheduled    '   00350044
WTOENA   DC CL50'QRC012I XXXXXXXX QRCHECK Enabled                   '   00370044
WTODIS   DC CL50'QRC013I XXXXXXXX QRCHECK Disabled                  '   00380044
WTOINT   DC CL50'QRC014I XXXXXXXX QRCHECK Interval Set  0000 {mmss} '   00390044
WTOSHO   DC CL50'QRC015I XXXXXXXX                                   '   00391024
WTOERR01 DC CL50'QRC016E XXXXXXXX Input command longer than allowed '   00411044
WTOERR02 DC CL50'QRC017E XXXXXXXX Invalid function code or param    '   00411144
WTOERR03 DC CL50'QRC019E XXXXXXXX Ivalid  interval. 0005<INT<0259   '   00411244
WTOERR04 DC CL50'QRC020E XXXXXXXX Error reading queue QRCH          '   00411344
SENDMSOK DC CL80'QRC018I FUNCTION OK                                '   00412024
*                                                                       00420000
         END   QRCHADM                                                  00430000

*ASM XOPTS(SP)                                                          00000110
*----------------------------------------------------------------*
*  Licensed Materials - Property of IBM                          *
*  Author Carlos Donatucci                                       *
*  (c) Copyright IBM Corp. 2020 All Rights Reserved              *
*  US Government Users Restricted Rights - Use, duplication or   *
*  disclosure restricted by GSA ADP Schedule Contract with       *
*  IBM Corp                                                      *
*----------------------------------------------------------------*
* Must be defined in RDO as API(OPENAPI) EXECKEY(CICS) THREADSAFE       00021019
* Runs on OPEN (L8) TCB to check:                                       00022000
* QR  Loop, Field CSATODP                                               00030000
* SOS Cond, Field CSASOSON                                              00030100
* MXT Cond, Field CSAMXTON                                              00030200
*                                                                       00032000
* CSA Address--> CSACIREL                                               00033228
*                CSATODP                                                00036028
*                CSASOSON                                               00037028
*                CSAMXTON                                               00038028
*//////////////////////////////////////////////////////////////////     00041000
         DFHCSAD TYPE=DSECT                                             00060021
         DFHAFCD TYPE=DSECT                                             00070027
WORKING  DSECT                                                          00090000
INTCHK   DS    D                                                        00090100
STATUS   DS    CL1                                                      00090300
STACTI   EQU   C'A'                                                     00090400
STSTOP   EQU   C'S'                                                     00090600
CICSNAM  DS    CL(8)                                                    00090800
WTOAREA  DS    CL(WTOLEN)                                               00090900
WTOAMSG  EQU   WTOAREA+4,51                                             00091000
JOBNAME  EQU   WTOAREA+12,8                                             00091100
TASK     EQU   WTOAREA+26,5                                             00091200
TRANS    EQU   WTOAREA+37,4                                             00091300
PROG     EQU   WTOAREA+47,8                                             00091400
*                                                                       00091500
DFHEISTG DSECT                                                          00092000
WSADDR   DS    A                                                        00093000
         DFHREGS                                                        00094011
QRCHECK  CSECT                                                          00150000
QRCHECK  AMODE 31                                                       00160000
QRCHECK  RMODE ANY                                                      00170000
*////////////////////////////////////////////////                       00170100
* Readq to get COMMON AREA ADDRESS                                      00170207
*                                                                       00170400
         EXEC CICS HANDLE ABEND LABEL(TRNABND)                          00171000
         EXEC CICS READQ TS QUEUE('QRCH') ITEM(1)                      X00180000
               INTO(WSADDR) LENGTH(WSADDRL) NOHANDLE                    00190000
         CLC   EIBRESP,DFHRESP(NORMAL)                                  00191008
         BE    CHECKST                                                  00192000
         WTO   MF=(E,WTOCMD)                                            00193100
         B     RETCMD                                                   00194000
*////////////////////////////////////////////////                       00194100
CHECKST  EQU   *                                                        00196000
         L     R4,WSADDR                        ADDRESSING              00196111
         USING WORKING,R4                                               00196211
         CLI   STATUS,STSTOP                    STATUS STOPPED?         00196300
         BE    RETURN                           Y, LEAVE                00196400
*                                                                       00196500
         EXEC CICS INQUIRE SYSTEM JOBNAME(CICSNAM)                      00197000
         MVC   WTOAREA,WTOCMD                   MOVE WTO SENTENCE       00198000
         MVC   WTOAMSG,WTOINI                   INIT MESSAGE            00199000
         MVC   JOBNAME,CICSNAM                                          00199100
         WTO   MF=(E,WTOAREA)                   ISSUE INIT MESSAGE      00199200
*                                                                       00199300
         DFHCSAD TYPE=LOCATE,REG=R9             CSA address             00251222
         USING DFHCSABA,R9                      Addressing              00252012
*                                                                       00271100
*/////////////////////////////////////////                              00295000
* Main LOOP to detect QR-Loop/MXT/SOS                                   00296015
* Exit if CICS is SHUTTING DOWN or if STATUS FLAG is S (STOP)           00297000
*                                                                       00298000
LOOP     EQU   *                                                        00300000
         TM    CSASSI2,CSASTIM                  CICS SHUTTING DOWN?     00300119
         BO    RETURN                           Y, LEAVE                00300219
         CLI   STATUS,STSTOP                    STATUS STOPPED?         00300324
         BE    RETURN                           Y, LEAVE                00300424
         L     R8,CSATODP                       SAVE CSATODP            00300512
         STIMER WAIT,DINTVL=INTCHK              WAIT INTERVAL           00300600
*                                                                       00301019
         CL    R8,CSATODP                       CSATODP EQUAL?          00324218
         BE    WTOLOOP                          Y, Send WTO LOOP        00324318
         TM    CSASSI2,CSAMXTON                 MXT SIGNAL ON?          00324429
         BO    WTOMXTM                          Y, Send WTO MXT         00324529
         TM    CSASSI1,CSASOSON                 SOS SIGNAL ON?          00324616
         BO    WTOSOSM                          Y, Send WTO SOS         00324718
         B     LOOP                                                     00324916
*////////////////////////////////////////                               00325516
WTOLOOP  EQU   *                                                        00326016
         MVC   WTOAMSG,WTOSCH                                           00450300
         MVC   JOBNAME,CICSNAM                                          00450400
         MVC   WTOAMSG+39(4),INTCHK+2                                   00450500
         WTO   MF=(E,WTOAREA)                                           00460000
         B     LOOP                                                     00470000
*////////////////////////////////////////                               00471000
WTOSOSM  EQU   *                                                        00471318
         MVC   WTOAMSG,WTOSOS                                           00471600
         MVC   JOBNAME,CICSNAM                                          00471700
         WTO   MF=(E,WTOAREA)                                           00471800
         B     LOOP                                                     00471900
*////////////////////////////////////////                               00472000
WTOMXTM  EQU   *                                                        00472218
         MVC   WTOAMSG,WTOMXT                                           00472500
         MVC   JOBNAME,CICSNAM                                          00472600
         WTO   MF=(E,WTOAREA)                                           00472700
         B     LOOP                                                     00472800
*////////////////////////////////////////                               00472900
RETURN   EQU   *                                                        00473000
         MVC   WTOAMSG,WTOEND                                           00473100
         MVC   JOBNAME,CICSNAM                                          00474000
         WTO   MF=(E,WTOAREA)                                           00475000
         EXEC CICS FREEMAIN DATA(WORKING)   NOHANDLE                    00475100
         EXEC CICS DELETEQ TS QUEUE('QRCH') NOHANDLE                    00475200
RETCMD   EQU   *                                                        00475300
         EXEC CICS RETURN                                               00475400
*////////////////////////////////////////                               00475500
* ABEND Message                                                         00475620
TRNABND  EQU   *                                                        00476100
         MVC   WTOAMSG,WTOABE                                           00476200
         MVC   JOBNAME,CICSNAM                                          00476300
         WTO   MF=(E,WTOAREA)                                           00476400
         B     RETURN                                                   00476500
*//////////////////////////////////                                     00476600
         DS    0D                                                       00477000
WSADDRL  DC    H'4'                                                     00478100
*..............1...+....1....+....2....+....3....+....4....+....5.      00479000
WTOCMD   WTO 'QRC017I Error reading TSQUEUE QRCH                 ',MF=L 00480000
WTOLEN   EQU  *-WTOCMD                                                  00490000
WTOSCH   DC  C'QRC001E XXXXXXXX QR TCB TOD unchanged  xxxx {mmss} '     00490103
WTOSOS   DC  C'QRC002E XXXXXXXX SOS condition detected            '     00491000
WTOMXT   DC  C'QRC003E XXXXXXXX MXT condition detected            '     00492000
WTOINI   DC  C'QRC004I XXXXXXXX QRCHECK Started  - Maint 18/02/16 '     00493025
WTOEND   DC  C'QRC005I XXXXXXXX QRCHECK Stopped                   '     00494000
WTOABE   DC  C'QRC006E XXXXXXXX Abend detected                    '     00496000
MYTRANS  DC  CL4'QRCH'                                                  00500000
*                                                                       00511000
         END   QRCHECK                                                  00530000

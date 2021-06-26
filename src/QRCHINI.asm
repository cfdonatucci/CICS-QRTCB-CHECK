*ASM XOPTS(SP)                                                          00000112
*----------------------------------------------------------------*
*  Licensed Materials - Property of IBM                          *
*  Author Carlos Donatucci                                       *
*  (c) Copyright IBM Corp. 2018 All Rights Reserved              *
*  US Government Users Restricted Rights - Use, duplication or   *
*  disclosure restricted by GSA ADP Schedule Contract with       *
*  IBM Corp                                                      *
*----------------------------------------------------------------* 
*                                                                       00020000
* GETMAINS 128B COMMON AREA ADDRESS                                     00031000
* WRITES QUEUE QRCH WITH COMMON AREA ADDRESS                            00032000
* STARTS QRCH TRANSACTION                                               00033000
* LOADS TABLE QRCHTAB TO GET CHECKING INTERVAL PER REGION               00040008
*                                                                       00050001
WORKING  DSECT                                                          00051000
INTCHK   DS    D                  00003000 HHMMSS00                     00052000
STATUS   DS    CL1                                                      00053000
STACTI   EQU   C'A'                                                     00054000
STINAC   EQU   C'I'                                                     00055000
STSTOP   EQU   C'S'                                                     00056000
DFHEISTG DSECT                                                          00057000
CICSNAM  DS    CL8                                                      00057101
WTOMSG   DS    CL50                                                     00057206
WSADDR   DS    A                                                        00058000
*///////////////////////////////////////////////////////                00059000
         DFHREGS                                                        00059115
QRCHINI  CSECT                                                          00060000
QRCHINI  AMODE 31                                                       00070000
QRCHINI  RMODE ANY                                                      00080000
         EXEC CICS HANDLE ABEND LABEL(TRNABND)                          00080106
         EXEC CICS READQ TS QUEUE('QRCH') ITEM(WITEM)                  X00081000
               INTO(WSADDR) LENGTH(WSADDRL)  NOHANDLE                   00082000
         CLC   EIBRESP,DFHRESP(NORMAL) Readq to get common area         00090018
         BNE   INITALL                IF THERE IS NO QUEUE GO INITALL   00090100
         L     R4,WSADDR              ADDRESSING                        00090217
         USING WORKING,R4                                               00090315
         CLI   STATUS,STACTI          IS ALREADY ACTIVE?                00090400
         BNE   SETVAL                    N, SET INTERVAL                00090516
         MVC   WTOMSG(L'WTOMSG),WTOMS0   Y, ERROR                       00090716
         B     WTOMSGM                                                  00090806
SETVAL   EQU   *                                                        00091500
         BAL   R9,SETINT              SET INTERVAL VALUE                00091616
         MVI   STATUS,STACTI          SET ACTIVE                        00091800
         B     DOSTART                                                  00091900
INITALL  EQU   *                                                        00092000
         EXEC CICS GETMAIN SET(4) FLENGTH(128) CICSDATAKEY SHARED      X00092100
               NOHANDLE                                                 00092200
         CLC   EIBRESP,DFHRESP(NORMAL) GETMAIN 128B SHARED CICS         00092313
         BE    INISTG2                 OK, GO ON                        00092413
         MVC   WTOMSG(L'WTOMSG),WTOMS1 NO, GETMAIN ERROR                00092516
         B     WTOMSGM                                                  00092606
INISTG2  EQU   *                                                        00092707
         USING WORKING,R4             ADDRESSING                        00092815
         BAL   R9,SETINT              SET INTERVAL VALUE                00092915
         MVI   STATUS,STACTI          STATUS ACTIVE                     00094000
         ST    R4,WSADDR              STORE ADD AND WRITEQ              00095015
         EXEC CICS WRITEQ TS QUEUE('QRCH') FROM(WSADDR) LENGTH(4)      X00095100
               ITEM(WITEM) MAIN  NOHANDLE                               00095200
         CLC   EIBRESP,DFHRESP(NORMAL)                                  00095313
         BE    DOSTART                                                  00095400
         MVC   WTOMSG(L'WTOMSG),WTOMS2                                  00095516
         B     WTOMSGM                                                  00095617
*                                                                       00096000
DOSTART  EQU  *                                                         00096102
         EXEC CICS START TRANSID(MYTRANS) NOHANDLE                      00096207
         MVC   WTOMSG(L'WTOMSG),WTOMS3                                  00097016
         MVC   WTOMSG+38(8),INTCHK                                      00097106
         EXEC CICS WRITE OPERATOR TEXT(WTOMSG) TEXTLENGTH(50)           00097206
         EXEC CICS RETURN                                               00110000
*                                                                       00120017
*///////////////////////////////////////////////////                    00120717
* GET DEFAULT CHECKING INTERVAL FROM QRCHTAB                            00120817
*                                                                       00120917
SETINT   EQU   *                                                        00121017
         EXEC CICS INQUIRE SYSTEM JOBNAME(CICSNAM)                      00121117
         MVC   INTCHK,=C'00003000'       MOVE DEF VALUE 30"             00121217
         EXEC CICS LOAD PROGRAM(QRCHTAB) SET(R6) HOLD NOHANDLE          00121317
         CLC   EIBRESP,DFHRESP(NORMAL)   LOAD TABLE, RC=0?              00121417
         BE    CHREGNA                   Y, GO FIND REGIONNAME          00121517
         BR    R9                        N, RETURN TO CALLER            00121617
*******  SEARCH FOR REGION NAME CICSXXXX0000N000                        00121701
CHREGNA  EQU   *                                                        00121816
         CLC   0(8,R6),CICSNAM           IS CURRENT REGION?             00121916
         BE    GETINT                    Y, GET INTERVAL                00122001
         LA    R6,16(R6)                 N, GET NEXT ENTRY              00122115
         CLC   0(8,R6),=C'FFFFFFFF'      IS LAST ENTRY?                 00122215
         BNE   CHREGNA                   N, CHECK AGAIN                 00122301
         B     RETINT                    Y, RETURN                      00122401
GETINT   EQU   *                                                        00122501
         MVC   INTCHK(8),8(R6)           MOVE INT AND RELEASE TABLE     00122615
RETINT   EQU   *                                                        00122716
         EXEC CICS RELEASE PROGRAM(QRCHTAB) NOHANDLE                    00122816
         BR    R9                                                       00122916
*////////////////////////////////////////                               00123016
* ABEND DETECTED                                                        00123116
*                                                                       00123216
TRNABND  EQU   *                                                        00123316
         MVC   WTOMSG(L'WTOMSG),WTOMS4                                  00123416
***      B     WTOMSGM                                                  00123817
*///////////////////////////////////////////////////                    00123917
* Send WTO Message                                                      00124017
*                                                                       00124117
WTOMSGM  EQU  *                                                         00124217
         EXEC CICS WRITE OPERATOR TEXT(WTOMSG) TEXTLENGTH(50)           00124317
         EXEC CICS RETURN                                               00124417
*                                                                       00124517
*////////////////////////////////////////                               00124606
WITEM    DC    H'01'                                                    00124706
MYTRANS  DC    C'QRCH'                                                  00124806
QRCHTAB  DC    C'QRCHTAB '                                              00124906
WSADDRL  DC    H'4'                                                     00125006
*............... 0....+....1....+....2....+....3....+....4....+....5    00125102
WTOMS0   DC    C'QRC008I QRCH transaction already ACTIVE            '   00125209
WTOMS1   DC    C'QRC009E QRCH initialization ERROR. GETMAIN failed  '   00125309
WTOMS2   DC    C'QRC010E QRCH initialization ERROR. WRITEQ error    '   00125409
WTOMS3   DC    C'QRC021I QRCH checking interval SET as              '   00125509
WTOMS4   DC    C'QRC006E QRCH INIT Abend detected                   '   00126009
*                                                                       00140017
         END   QRCHINI                                                  00160000

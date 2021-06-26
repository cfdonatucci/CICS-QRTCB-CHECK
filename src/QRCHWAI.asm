*ASM XOPTS(SP)                                                          00000105
*----------------------------------------------------------------*
*  Licensed Materials - Property of IBM                          *
*  Author Carlos Donatucci                                       *
*  (c) Copyright IBM Corp. 2018 All Rights Reserved              *
*  US Government Users Restricted Rights - Use, duplication or   *
*  disclosure restricted by GSA ADP Schedule Contract with       *
*  IBM Corp                                                      *
*----------------------------------------------------------------*
DFHEISTG DSECT                                                          00092000
WSADDR   DS    A                                                        00093000
QRCHWAI  CSECT                                                          00150001
QRCHWAI  AMODE 31                                                       00160001
QRCHWAI  RMODE ANY                                                      00170001
*                              HHMMSS00                                 00180002
         STIMER WAIT,BINTVL==F'00003000'   3'                           00300202
RETURN   EQU   *                                                        00473000
         EXEC CICS RETURN                                               00475400
         DS    0D                                                       00477000
WSADDRL  DC    H'4'                                                     00478100
*............. 0....+....1....+....2....+....3....+....4....+....5      00479000
         LTORG                                                          00510000
*                                                                       00511000
         END   QRCHWAI                                                  00530001

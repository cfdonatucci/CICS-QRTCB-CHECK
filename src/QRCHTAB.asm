*----------------------------------------------------------------*
*  Licensed Materials - Property of IBM                          *
*  Author Carlos Donatucci                                       *
*  (c) Copyright IBM Corp. 2018 All Rights Reserved              *
*  US Government Users Restricted Rights - Use, duplication or   *
*  disclosure restricted by GSA ADP Schedule Contract with       *
*  IBM Corp                                                      *
*----------------------------------------------------------------*
* Optional Interval Table
*                                                                      
* HEADER RECORD : 16 BYTES DE HEADER                                    
* ENTRY  RECORD : 01-08 CICS REGION NAME                                
*               : 09-16 CHECKING INTERVAL                               
*                                                                       
*...................0.......8......15                                   
         DC    CL16'QRCHTAB*ADDC    '                                   
         DC    CL16'CICSTX  00001000'                                   
         DC    CL16'CICSDT3 00003500'                                   
         DC    CL16'CICSDT5 00003500'                                   
         DC    CL16'FFFFFFFFFFFFFFFF'                                   
         END                                                            

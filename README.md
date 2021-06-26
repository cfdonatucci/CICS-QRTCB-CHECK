# CICS-QRTCB-CHECK

Sample CICS application to monitor QR TCB status and detect SOS and MXT conditions.

## Repository structure
* [`src/`](src) - Assembler CICS program source.
* [`etc/`](etc) - Installation, messages, RDO definitions, compilation JCL

## General Information                                                            
The application has three main assembler programs, `QRCHINI`,  `QRCHECK` and `QRCHADM`.  
                                                                               
**QRCHINI - Initialization program**

* Gets 128 bytes of CICS shared memory and records the address in main temporary storage queue QRCH and sets default interval of 30s. The memory is used to communicate with the main program QRCHECK.              
* Loads table QRCHTAB which is used to define specific intervals for some regions.               
* Starts transaction QRCH associated with QRCHECK. 
* QRCHINI can be added to the PLTPI program list table to be run at initialization.                                                                
                                                                                
**QRCHECK - Main control program**                                                                         
This is the long running control program. It reads the TSQ and gets memory address and takes a control data area. This area has two parameters.                                          

* CHECKING INTERVAL, format HHMMSS00, default 00003000, 30s                    
* Status A ACTIVE S STOPPED. The status is used to stop the main program and to validate it's started.                                                     
                                                                                
The program starts a checking LOOP according to the interval value.        
The program doesn't use any CICS function in that loop.                         
The program uses an MVS STIMER macro to wait for the next check.   

The main loop has three checks

* `CSATOD` to check if the QR TCB TOD has been updated. This provides the ability to detect QR TCB loops or stalls.                                         
* `MXT` flag condition.                                                          
* `SOS` flag condition.                                                          
                                                                                
The program sends a WTO to the syslog if any of these conditions are detected.
The program checks the STOP flag in each loop, and terminates if CICS is stopping. It frees memory and purges the TSQ at finalization. 
In some cases the QR TOD may not updated because the region has not been dispatched by z/OS. This situation will be trapped.    
The program handles any CICS abends in order to free memory and delete the TSQ queue before terminating.
The program also checks the CICS SHUTDOWN flag, ensuring that it stops itself at shutdown as follows:
                                                                                
```																			
  +DFHTM1781 CICSxxxx CICS shutdown cannot complete because some non-system user tasks have not terminated.
  +QRC005I CICSxxxx QRCHECK STOPPED
  +DFHTM1782I CICSxxxx All non-system tasks have been successfully terminated                
  +DFHZC2305I CICSxxxx Termination of VTAM sessions beginning  
```
                                                                               
**QRCHADM - Administrative program**                                                                        

This program provides the following 3 administrative functions:                                                                               

1. QUERY STATUS/INTERVAL
```
F CICSxxxx,QRADSHO                                                
+QRC013I CICSxxxx 00003000A  <-- 30" INT ACTIVE             
+QRC012I FUNCTION OK 
```
                                                                               
2. STOP CHECKING                                                      
```
F CICSxxxx,QRADSTO
+QRC013I CICSxxxx QRCHECK FINALIZATION SCHEDULED                               
+QRC012I FUNCTION OK          
+QRC005I CICSxxxx QRCHECK STOPPED 
```
                                                                               
3. SET CHECKING INTERVAL
```
F CICSxxxx,QRADINT0020
+QRC010I CICSxxxx QRCHECK INTERVAL SET  0020 {mmss}  
+QRC012I FUNCTION OK
```

Validation is performed to accept intervals between 0005s and 02m59s

## License
This project is licensed under [Apache License Version 2.0](LICENSE).

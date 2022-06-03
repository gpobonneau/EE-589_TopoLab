#ifndef RTW_HEADER_model_h_
#define RTW_HEADER_model_h_
#include <stddef.h>
#include <float.h>
#include <string.h>
#include "rtw_modelmap_simtarget.h"
#ifndef model_COMMON_INCLUDES_
#define model_COMMON_INCLUDES_
#include <stdio.h>
#include <stdlib.h>
#include "rtwtypes.h"
#include "sigstream_rtw.h"
#include "simtarget/slSimTgtSigstreamRTW.h"
#include "simtarget/slSimTgtSlioCoreRTW.h"
#include "simtarget/slSimTgtSlioClientsRTW.h"
#include "simtarget/slSimTgtSlioSdiRTW.h"
#include "simstruc.h"
#include "fixedpoint.h"
#include "raccel.h"
#include "slsv_diagnostic_codegen_c_api.h"
#include "rt_logging_simtarget.h"
#include "dt_info.h"
#include "ext_work.h"
#endif
#include "model_types.h"
#include "multiword_types.h"
#include "mwmathutil.h"
#include "rt_defines.h"
#include "rtGetInf.h"
#include "rt_nonfinite.h"
#define MODEL_NAME model
#define NSAMPLE_TIMES (2) 
#define NINPUTS (0)       
#define NOUTPUTS (0)     
#define NBLOCKIO (18) 
#define NUM_ZC_EVENTS (0) 
#ifndef NCSTATES
#define NCSTATES (2)   
#elif NCSTATES != 2
#error Invalid specification of NCSTATES defined in compiler command
#endif
#ifndef rtmGetDataMapInfo
#define rtmGetDataMapInfo(rtm) (*rt_dataMapInfoPtr)
#endif
#ifndef rtmSetDataMapInfo
#define rtmSetDataMapInfo(rtm, val) (rt_dataMapInfoPtr = &val)
#endif
#ifndef IN_RACCEL_MAIN
#endif
typedef struct { real_T hqfzfrz2lc ; real_T d5ftbwwamr ; real_T ik4ntg31yl ;
real_T a5bgezcw3b ; real_T d0tzttk1mn ; real_T gzr2fdlbpz ; real_T lxfwukbk51
; real_T ctqngoka2z ; real_T gylwilku4q ; real_T bmouv522ru ; real_T
jm3x34yiq2 ; real_T jcn4tvno4j ; real_T a1zkc411uy ; real_T eiqbbzcufr ;
real_T owhgqxukez ; real_T pfgbdbk5tc ; real_T glakw2iqkt ; real_T lzq3c4siad
; } B ; typedef struct { struct { real_T modelTStart ; } dsukx5k2uj ; struct
{ void * TimePtr ; void * DataPtr ; void * RSimInfoPtr ; } mhbew2z00k ;
struct { void * LoggedData [ 3 ] ; } aykvyxjcmh ; struct { void * LoggedData
[ 2 ] ; } kvlp5j1hli ; struct { void * LoggedData [ 2 ] ; } g0apie1od5 ;
struct { void * LoggedData [ 2 ] ; } lxnmt3w50p ; struct { void *
TUbufferPtrs [ 2 ] ; } h2j1mpvchh ; struct { void * TimePtr ; void * DataPtr
; void * RSimInfoPtr ; } bxpkwc15hx ; struct { void * TimePtr ; void *
DataPtr ; void * RSimInfoPtr ; } g4hbqczu43 ; struct { int_T PrevIndex ; }
dd0lddrxds ; struct { int_T Tail ; int_T Head ; int_T Last ; int_T
CircularBufSize ; int_T MaxNewBufSize ; } kkhgv1gz0b ; struct { int_T
PrevIndex ; } jvgjspjuxn ; struct { int_T PrevIndex ; } oqndo05can ; int_T
dixkiqm3la ; } DW ; typedef struct { real_T ipgqgubrjo ; real_T fvh2m2gbte ;
} X ; typedef struct { real_T ipgqgubrjo ; real_T fvh2m2gbte ; } XDot ;
typedef struct { boolean_T ipgqgubrjo ; boolean_T fvh2m2gbte ; } XDis ;
typedef struct { real_T ipgqgubrjo ; real_T fvh2m2gbte ; } CStateAbsTol ;
typedef struct { real_T ipgqgubrjo ; real_T fvh2m2gbte ; } CXPtMin ; typedef
struct { real_T ipgqgubrjo ; real_T fvh2m2gbte ; } CXPtMax ; typedef struct {
real_T omnfvlf3zz ; } ZCV ; typedef struct { rtwCAPI_ModelMappingInfo mmi ; }
DataMapInfo ; struct P_ { real_T CQ0 ; real_T CQ1 ; real_T CT0 ; real_T CT1 ;
real_T Ke ; real_T Td ; real_T uJsf_A ; real_T uJsf_C ; real_T
advanceratio_Time0 [ 988 ] ; real_T advanceratio_Data0 [ 988 ] ; real_T
uLsR_A ; real_T uLsR_C ; real_T TransportDelay_InitOutput ; real_T
throttle_Time0 [ 988 ] ; real_T throttle_Data0 [ 988 ] ; real_T Gain_Gain ;
real_T voltage_Time0 [ 988 ] ; real_T voltage_Data0 [ 988 ] ; real_T
Constant_Value ; } ; extern const char * RT_MEMORY_ALLOCATION_ERROR ; extern
B rtB ; extern X rtX ; extern DW rtDW ; extern P rtP ; extern mxArray *
mr_model_GetDWork ( ) ; extern void mr_model_SetDWork ( const mxArray * ssDW
) ; extern mxArray * mr_model_GetSimStateDisallowedBlocks ( ) ; extern const
rtwCAPI_ModelMappingStaticInfo * model_GetCAPIStaticMap ( void ) ; extern
SimStruct * const rtS ; extern const int_T gblNumToFiles ; extern const int_T
gblNumFrFiles ; extern const int_T gblNumFrWksBlocks ; extern rtInportTUtable
* gblInportTUtables ; extern const char * gblInportFileName ; extern const
int_T gblNumRootInportBlks ; extern const int_T gblNumModelInputs ; extern
const int_T gblInportDataTypeIdx [ ] ; extern const int_T gblInportDims [ ] ;
extern const int_T gblInportComplex [ ] ; extern const int_T
gblInportInterpoFlag [ ] ; extern const int_T gblInportContinuous [ ] ;
extern const int_T gblParameterTuningTid ; extern DataMapInfo *
rt_dataMapInfoPtr ; extern rtwCAPI_ModelMappingInfo * rt_modelMapInfoPtr ;
void MdlOutputs ( int_T tid ) ; void MdlOutputsParameterSampleTime ( int_T
tid ) ; void MdlUpdate ( int_T tid ) ; void MdlTerminate ( void ) ; void
MdlInitializeSizes ( void ) ; void MdlInitializeSampleTimes ( void ) ;
SimStruct * raccel_register_model ( ssExecutionInfo * executionInfo ) ;
#endif

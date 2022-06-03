#include "rt_logging_mmi.h"
#include "model_capi.h"
#include <math.h>
#include "model.h"
#include "model_private.h"
#include "model_dt.h"
extern void * CreateDiagnosticAsVoidPtr_wrapper ( const char * id , int nargs
, ... ) ; RTWExtModeInfo * gblRTWExtModeInfo = NULL ; void
raccelForceExtModeShutdown ( boolean_T extModeStartPktReceived ) { if ( !
extModeStartPktReceived ) { boolean_T stopRequested = false ;
rtExtModeWaitForStartPkt ( gblRTWExtModeInfo , 1 , & stopRequested ) ; }
rtExtModeShutdown ( 1 ) ; }
#include "slsv_diagnostic_codegen_c_api.h"
#include "slsa_sim_engine.h"
const int_T gblNumToFiles = 0 ; const int_T gblNumFrFiles = 0 ; const int_T
gblNumFrWksBlocks = 3 ;
#ifdef RSIM_WITH_SOLVER_MULTITASKING
boolean_T gbl_raccel_isMultitasking = 1 ;
#else
boolean_T gbl_raccel_isMultitasking = 0 ;
#endif
boolean_T gbl_raccel_tid01eq = 0 ; int_T gbl_raccel_NumST = 2 ; const char_T
* gbl_raccel_Version = "10.3 (R2021a) 14-Nov-2020" ; void
raccel_setup_MMIStateLog ( SimStruct * S ) {
#ifdef UseMMIDataLogging
rt_FillStateSigInfoFromMMI ( ssGetRTWLogInfo ( S ) , & ssGetErrorStatus ( S )
) ;
#else
UNUSED_PARAMETER ( S ) ;
#endif
} static DataMapInfo rt_dataMapInfo ; DataMapInfo * rt_dataMapInfoPtr = &
rt_dataMapInfo ; rtwCAPI_ModelMappingInfo * rt_modelMapInfoPtr = & (
rt_dataMapInfo . mmi ) ; const int_T gblNumRootInportBlks = 0 ; const int_T
gblNumModelInputs = 0 ; extern const char * gblInportFileName ; extern
rtInportTUtable * gblInportTUtables ; const int_T gblInportDataTypeIdx [ ] =
{ - 1 } ; const int_T gblInportDims [ ] = { - 1 } ; const int_T
gblInportComplex [ ] = { - 1 } ; const int_T gblInportInterpoFlag [ ] = { - 1
} ; const int_T gblInportContinuous [ ] = { - 1 } ; int_T enableFcnCallFlag [
] = { 1 , 1 } ; const char * raccelLoadInputsAndAperiodicHitTimes ( SimStruct
* S , const char * inportFileName , int * matFileFormat ) { return
rt_RAccelReadInportsMatFile ( S , inportFileName , matFileFormat ) ; }
#include "simstruc.h"
#include "fixedpoint.h"
#include "slsa_sim_engine.h"
#include "simtarget/slSimTgtSLExecSimBridge.h"
B rtB ; X rtX ; DW rtDW ; static SimStruct model_S ; SimStruct * const rtS =
& model_S ;
#ifndef __RTW_UTFREE__  
extern void * utMalloc ( size_t ) ;
#endif
void * rt_TDelayCreateBuf ( int_T numBuffer , int_T bufSz , int_T elemSz ) {
return ( ( void * ) utMalloc ( numBuffer * bufSz * elemSz ) ) ; }
#ifndef __RTW_UTFREE__  
extern void * utMalloc ( size_t ) ; extern void utFree ( void * ) ;
#endif
boolean_T rt_TDelayUpdateTailOrGrowBuf ( int_T * bufSzPtr , int_T * tailPtr ,
int_T * headPtr , int_T * lastPtr , real_T tMinusDelay , real_T * * uBufPtr ,
boolean_T isfixedbuf , boolean_T istransportdelay , int_T * maxNewBufSzPtr )
{ int_T testIdx ; int_T tail = * tailPtr ; int_T bufSz = * bufSzPtr ; real_T
* tBuf = * uBufPtr + bufSz ; real_T * xBuf = ( NULL ) ; int_T numBuffer = 2 ;
if ( istransportdelay ) { numBuffer = 3 ; xBuf = * uBufPtr + 2 * bufSz ; }
testIdx = ( tail < ( bufSz - 1 ) ) ? ( tail + 1 ) : 0 ; if ( ( tMinusDelay <=
tBuf [ testIdx ] ) && ! isfixedbuf ) { int_T j ; real_T * tempT ; real_T *
tempU ; real_T * tempX = ( NULL ) ; real_T * uBuf = * uBufPtr ; int_T
newBufSz = bufSz + 1024 ; if ( newBufSz > * maxNewBufSzPtr ) { *
maxNewBufSzPtr = newBufSz ; } tempU = ( real_T * ) utMalloc ( numBuffer *
newBufSz * sizeof ( real_T ) ) ; if ( tempU == ( NULL ) ) { return ( false )
; } tempT = tempU + newBufSz ; if ( istransportdelay ) tempX = tempT +
newBufSz ; for ( j = tail ; j < bufSz ; j ++ ) { tempT [ j - tail ] = tBuf [
j ] ; tempU [ j - tail ] = uBuf [ j ] ; if ( istransportdelay ) tempX [ j -
tail ] = xBuf [ j ] ; } for ( j = 0 ; j < tail ; j ++ ) { tempT [ j + bufSz -
tail ] = tBuf [ j ] ; tempU [ j + bufSz - tail ] = uBuf [ j ] ; if (
istransportdelay ) tempX [ j + bufSz - tail ] = xBuf [ j ] ; } if ( * lastPtr
> tail ) { * lastPtr -= tail ; } else { * lastPtr += ( bufSz - tail ) ; } *
tailPtr = 0 ; * headPtr = bufSz ; utFree ( uBuf ) ; * bufSzPtr = newBufSz ; *
uBufPtr = tempU ; } else { * tailPtr = testIdx ; } return ( true ) ; } real_T
rt_TDelayInterpolate ( real_T tMinusDelay , real_T tStart , real_T * uBuf ,
int_T bufSz , int_T * lastIdx , int_T oldestIdx , int_T newIdx , real_T
initOutput , boolean_T discrete , boolean_T minorStepAndTAtLastMajorOutput )
{ int_T i ; real_T yout , t1 , t2 , u1 , u2 ; real_T * tBuf = uBuf + bufSz ;
if ( ( newIdx == 0 ) && ( oldestIdx == 0 ) && ( tMinusDelay > tStart ) )
return initOutput ; if ( tMinusDelay <= tStart ) return initOutput ; if ( (
tMinusDelay <= tBuf [ oldestIdx ] ) ) { if ( discrete ) { return ( uBuf [
oldestIdx ] ) ; } else { int_T tempIdx = oldestIdx + 1 ; if ( oldestIdx ==
bufSz - 1 ) tempIdx = 0 ; t1 = tBuf [ oldestIdx ] ; t2 = tBuf [ tempIdx ] ;
u1 = uBuf [ oldestIdx ] ; u2 = uBuf [ tempIdx ] ; if ( t2 == t1 ) { if (
tMinusDelay >= t2 ) { yout = u2 ; } else { yout = u1 ; } } else { real_T f1 =
( t2 - tMinusDelay ) / ( t2 - t1 ) ; real_T f2 = 1.0 - f1 ; yout = f1 * u1 +
f2 * u2 ; } return yout ; } } if ( minorStepAndTAtLastMajorOutput ) { if (
newIdx != 0 ) { if ( * lastIdx == newIdx ) { ( * lastIdx ) -- ; } newIdx -- ;
} else { if ( * lastIdx == newIdx ) { * lastIdx = bufSz - 1 ; } newIdx =
bufSz - 1 ; } } i = * lastIdx ; if ( tBuf [ i ] < tMinusDelay ) { while (
tBuf [ i ] < tMinusDelay ) { if ( i == newIdx ) break ; i = ( i < ( bufSz - 1
) ) ? ( i + 1 ) : 0 ; } } else { while ( tBuf [ i ] >= tMinusDelay ) { i = (
i > 0 ) ? i - 1 : ( bufSz - 1 ) ; } i = ( i < ( bufSz - 1 ) ) ? ( i + 1 ) : 0
; } * lastIdx = i ; if ( discrete ) { double tempEps = ( DBL_EPSILON ) *
128.0 ; double localEps = tempEps * muDoubleScalarAbs ( tBuf [ i ] ) ; if (
tempEps > localEps ) { localEps = tempEps ; } localEps = localEps / 2.0 ; if
( tMinusDelay >= ( tBuf [ i ] - localEps ) ) { yout = uBuf [ i ] ; } else {
if ( i == 0 ) { yout = uBuf [ bufSz - 1 ] ; } else { yout = uBuf [ i - 1 ] ;
} } } else { if ( i == 0 ) { t1 = tBuf [ bufSz - 1 ] ; u1 = uBuf [ bufSz - 1
] ; } else { t1 = tBuf [ i - 1 ] ; u1 = uBuf [ i - 1 ] ; } t2 = tBuf [ i ] ;
u2 = uBuf [ i ] ; if ( t2 == t1 ) { if ( tMinusDelay >= t2 ) { yout = u2 ; }
else { yout = u1 ; } } else { real_T f1 = ( t2 - tMinusDelay ) / ( t2 - t1 )
; real_T f2 = 1.0 - f1 ; yout = f1 * u1 + f2 * u2 ; } } return ( yout ) ; }
#ifndef __RTW_UTFREE__  
extern void utFree ( void * ) ;
#endif
void rt_TDelayFreeBuf ( void * buf ) { utFree ( buf ) ; } void MdlInitialize
( void ) { rtX . ipgqgubrjo = 0.0 ; rtX . fvh2m2gbte = 0.0 ; } void MdlStart
( void ) { { bool externalInputIsInDatasetFormat = false ; void *
pISigstreamManager = rt_GetISigstreamManager ( rtS ) ;
rtwISigstreamManagerGetInputIsInDatasetFormat ( pISigstreamManager , &
externalInputIsInDatasetFormat ) ; if ( externalInputIsInDatasetFormat ) { }
} { FWksInfo * fromwksInfo ; if ( ( fromwksInfo = ( FWksInfo * ) calloc ( 1 ,
sizeof ( FWksInfo ) ) ) == ( NULL ) ) { ssSetErrorStatus ( rtS ,
"from workspace STRING(Name) memory allocation error" ) ; } else {
fromwksInfo -> origWorkspaceVarName = "j" ; fromwksInfo -> origDataTypeId = 0
; fromwksInfo -> origIsComplex = 0 ; fromwksInfo -> origWidth = 1 ;
fromwksInfo -> origElSize = sizeof ( real_T ) ; fromwksInfo -> data = ( void
* ) rtP . advanceratio_Data0 ; fromwksInfo -> nDataPoints = 988 ; fromwksInfo
-> time = ( double * ) rtP . advanceratio_Time0 ; rtDW . mhbew2z00k . TimePtr
= fromwksInfo -> time ; rtDW . mhbew2z00k . DataPtr = fromwksInfo -> data ;
rtDW . mhbew2z00k . RSimInfoPtr = fromwksInfo ; } rtDW . dd0lddrxds .
PrevIndex = 0 ; } { char ptrKey [ 1024 ] ; { real_T * pBuffer = ( real_T * )
rt_TDelayCreateBuf ( 2 , 1024 , sizeof ( real_T ) ) ; if ( pBuffer == ( NULL
) ) { ssSetErrorStatus ( rtS , "tdelay memory allocation error" ) ; return ;
} rtDW . kkhgv1gz0b . Tail = 0 ; rtDW . kkhgv1gz0b . Head = 0 ; rtDW .
kkhgv1gz0b . Last = 0 ; rtDW . kkhgv1gz0b . CircularBufSize = 1024 ; pBuffer
[ 0 ] = rtP . TransportDelay_InitOutput ; pBuffer [ 1024 ] = ssGetT ( rtS ) ;
rtDW . h2j1mpvchh . TUbufferPtrs [ 0 ] = ( void * ) & pBuffer [ 0 ] ; sprintf
( ptrKey , "model/CTRL/Transport\nDelay_TUbuffer%d" , 0 ) ;
slsaSaveRawMemoryForSimTargetOP ( rtS , ptrKey , ( void * * ) ( & rtDW .
h2j1mpvchh . TUbufferPtrs [ 0 ] ) , 2 * 1024 * sizeof ( real_T ) , NULL ,
NULL ) ; } } { FWksInfo * fromwksInfo ; if ( ( fromwksInfo = ( FWksInfo * )
calloc ( 1 , sizeof ( FWksInfo ) ) ) == ( NULL ) ) { ssSetErrorStatus ( rtS ,
"from workspace STRING(Name) memory allocation error" ) ; } else {
fromwksInfo -> origWorkspaceVarName = "u" ; fromwksInfo -> origDataTypeId = 0
; fromwksInfo -> origIsComplex = 0 ; fromwksInfo -> origWidth = 1 ;
fromwksInfo -> origElSize = sizeof ( real_T ) ; fromwksInfo -> data = ( void
* ) rtP . throttle_Data0 ; fromwksInfo -> nDataPoints = 988 ; fromwksInfo ->
time = ( double * ) rtP . throttle_Time0 ; rtDW . bxpkwc15hx . TimePtr =
fromwksInfo -> time ; rtDW . bxpkwc15hx . DataPtr = fromwksInfo -> data ;
rtDW . bxpkwc15hx . RSimInfoPtr = fromwksInfo ; } rtDW . jvgjspjuxn .
PrevIndex = 0 ; } { FWksInfo * fromwksInfo ; if ( ( fromwksInfo = ( FWksInfo
* ) calloc ( 1 , sizeof ( FWksInfo ) ) ) == ( NULL ) ) { ssSetErrorStatus (
rtS , "from workspace STRING(Name) memory allocation error" ) ; } else {
fromwksInfo -> origWorkspaceVarName = "v" ; fromwksInfo -> origDataTypeId = 0
; fromwksInfo -> origIsComplex = 0 ; fromwksInfo -> origWidth = 1 ;
fromwksInfo -> origElSize = sizeof ( real_T ) ; fromwksInfo -> data = ( void
* ) rtP . voltage_Data0 ; fromwksInfo -> nDataPoints = 988 ; fromwksInfo ->
time = ( double * ) rtP . voltage_Time0 ; rtDW . g4hbqczu43 . TimePtr =
fromwksInfo -> time ; rtDW . g4hbqczu43 . DataPtr = fromwksInfo -> data ;
rtDW . g4hbqczu43 . RSimInfoPtr = fromwksInfo ; } rtDW . oqndo05can .
PrevIndex = 0 ; } MdlInitialize ( ) ; } void MdlOutputs ( int_T tid ) {
real_T phqsqdiygo ; real_T f5iezae2bw ; rtB . hqfzfrz2lc = 0.0 ; rtB .
hqfzfrz2lc += rtP . uJsf_C * rtX . ipgqgubrjo ; rtB . d5ftbwwamr = rtB .
hqfzfrz2lc * rtB . hqfzfrz2lc ; { real_T * pDataValues = ( real_T * ) rtDW .
mhbew2z00k . DataPtr ; real_T * pTimeValues = ( real_T * ) rtDW . mhbew2z00k
. TimePtr ; int_T currTimeIndex = rtDW . dd0lddrxds . PrevIndex ; real_T t =
ssGetTaskTime ( rtS , 0 ) ; int numPoints , lastPoint ; FWksInfo *
fromwksInfo = ( FWksInfo * ) rtDW . mhbew2z00k . RSimInfoPtr ; numPoints =
fromwksInfo -> nDataPoints ; lastPoint = numPoints - 1 ; if ( t <=
pTimeValues [ 0 ] ) { currTimeIndex = 0 ; } else if ( t >= pTimeValues [
lastPoint ] ) { currTimeIndex = lastPoint - 1 ; } else { if ( t < pTimeValues
[ currTimeIndex ] ) { while ( t < pTimeValues [ currTimeIndex ] ) {
currTimeIndex -- ; } } else { while ( t >= pTimeValues [ currTimeIndex + 1 ]
) { currTimeIndex ++ ; } } } rtDW . dd0lddrxds . PrevIndex = currTimeIndex ;
{ real_T t1 = pTimeValues [ currTimeIndex ] ; real_T t2 = pTimeValues [
currTimeIndex + 1 ] ; if ( t1 == t2 ) { if ( t < t1 ) { rtB . ik4ntg31yl =
pDataValues [ currTimeIndex ] ; } else { rtB . ik4ntg31yl = pDataValues [
currTimeIndex + 1 ] ; } } else { real_T f1 = ( t2 - t ) / ( t2 - t1 ) ;
real_T f2 = 1.0 - f1 ; real_T d1 ; real_T d2 ; int_T TimeIndex =
currTimeIndex ; d1 = pDataValues [ TimeIndex ] ; d2 = pDataValues [ TimeIndex
+ 1 ] ; rtB . ik4ntg31yl = ( real_T ) rtInterpolate ( d1 , d2 , f1 , f2 ) ;
pDataValues += numPoints ; } } } rtB . a5bgezcw3b = rtB . d5ftbwwamr * rtB .
ik4ntg31yl ; rtB . d0tzttk1mn = rtP . CQ1 * rtB . a5bgezcw3b + rtP . CQ0 *
rtB . d5ftbwwamr ; rtB . gzr2fdlbpz = rtP . CT0 * rtB . d5ftbwwamr ; rtB .
lxfwukbk51 = rtP . CT1 * rtB . a5bgezcw3b ; rtB . ctqngoka2z = rtB .
gzr2fdlbpz + rtB . lxfwukbk51 ; if ( ssIsMajorTimeStep ( rtS ) ) { rtDW .
dixkiqm3la = ( rtB . ctqngoka2z >= 0.0 ) ; } rtB . gylwilku4q = rtDW .
dixkiqm3la > 0 ? rtB . ctqngoka2z : - rtB . ctqngoka2z ; rtB . bmouv522ru =
0.0 ; rtB . bmouv522ru += rtP . uLsR_C * rtX . fvh2m2gbte ; rtB . jm3x34yiq2
= rtP . Ke * rtB . bmouv522ru ; rtB . jcn4tvno4j = rtB . jm3x34yiq2 - rtB .
gylwilku4q ; rtB . a1zkc411uy = rtP . Ke * rtB . hqfzfrz2lc ; { real_T * *
uBuffer = ( real_T * * ) & rtDW . h2j1mpvchh . TUbufferPtrs [ 0 ] ; real_T
simTime = ssGetT ( rtS ) ; real_T tMinusDelay = simTime - rtP . Td ; rtB .
eiqbbzcufr = rt_TDelayInterpolate ( tMinusDelay , 0.0 , * uBuffer , rtDW .
kkhgv1gz0b . CircularBufSize , & rtDW . kkhgv1gz0b . Last , rtDW . kkhgv1gz0b
. Tail , rtDW . kkhgv1gz0b . Head , rtP . TransportDelay_InitOutput , 0 , (
boolean_T ) ( ssIsMinorTimeStep ( rtS ) && ( ssGetTimeOfLastOutput ( rtS ) ==
ssGetT ( rtS ) ) ) ) ; } rtB . owhgqxukez = rtB . eiqbbzcufr - rtB .
a1zkc411uy ; { real_T * pDataValues = ( real_T * ) rtDW . bxpkwc15hx .
DataPtr ; real_T * pTimeValues = ( real_T * ) rtDW . bxpkwc15hx . TimePtr ;
int_T currTimeIndex = rtDW . jvgjspjuxn . PrevIndex ; real_T t =
ssGetTaskTime ( rtS , 0 ) ; int numPoints , lastPoint ; FWksInfo *
fromwksInfo = ( FWksInfo * ) rtDW . bxpkwc15hx . RSimInfoPtr ; numPoints =
fromwksInfo -> nDataPoints ; lastPoint = numPoints - 1 ; if ( t <=
pTimeValues [ 0 ] ) { currTimeIndex = 0 ; } else if ( t >= pTimeValues [
lastPoint ] ) { currTimeIndex = lastPoint - 1 ; } else { if ( t < pTimeValues
[ currTimeIndex ] ) { while ( t < pTimeValues [ currTimeIndex ] ) {
currTimeIndex -- ; } } else { while ( t >= pTimeValues [ currTimeIndex + 1 ]
) { currTimeIndex ++ ; } } } rtDW . jvgjspjuxn . PrevIndex = currTimeIndex ;
{ real_T t1 = pTimeValues [ currTimeIndex ] ; real_T t2 = pTimeValues [
currTimeIndex + 1 ] ; if ( t1 == t2 ) { if ( t < t1 ) { phqsqdiygo =
pDataValues [ currTimeIndex ] ; } else { phqsqdiygo = pDataValues [
currTimeIndex + 1 ] ; } } else { real_T f1 = ( t2 - t ) / ( t2 - t1 ) ;
real_T f2 = 1.0 - f1 ; real_T d1 ; real_T d2 ; int_T TimeIndex =
currTimeIndex ; d1 = pDataValues [ TimeIndex ] ; d2 = pDataValues [ TimeIndex
+ 1 ] ; phqsqdiygo = ( real_T ) rtInterpolate ( d1 , d2 , f1 , f2 ) ;
pDataValues += numPoints ; } } } rtB . pfgbdbk5tc = phqsqdiygo - rtP .
Constant_Value ; rtB . glakw2iqkt = rtP . Gain_Gain * rtB . pfgbdbk5tc ; {
real_T * pDataValues = ( real_T * ) rtDW . g4hbqczu43 . DataPtr ; real_T *
pTimeValues = ( real_T * ) rtDW . g4hbqczu43 . TimePtr ; int_T currTimeIndex
= rtDW . oqndo05can . PrevIndex ; real_T t = ssGetTaskTime ( rtS , 0 ) ; int
numPoints , lastPoint ; FWksInfo * fromwksInfo = ( FWksInfo * ) rtDW .
g4hbqczu43 . RSimInfoPtr ; numPoints = fromwksInfo -> nDataPoints ; lastPoint
= numPoints - 1 ; if ( t <= pTimeValues [ 0 ] ) { currTimeIndex = 0 ; } else
if ( t >= pTimeValues [ lastPoint ] ) { currTimeIndex = lastPoint - 1 ; }
else { if ( t < pTimeValues [ currTimeIndex ] ) { while ( t < pTimeValues [
currTimeIndex ] ) { currTimeIndex -- ; } } else { while ( t >= pTimeValues [
currTimeIndex + 1 ] ) { currTimeIndex ++ ; } } } rtDW . oqndo05can .
PrevIndex = currTimeIndex ; { real_T t1 = pTimeValues [ currTimeIndex ] ;
real_T t2 = pTimeValues [ currTimeIndex + 1 ] ; if ( t1 == t2 ) { if ( t < t1
) { f5iezae2bw = pDataValues [ currTimeIndex ] ; } else { f5iezae2bw =
pDataValues [ currTimeIndex + 1 ] ; } } else { real_T f1 = ( t2 - t ) / ( t2
- t1 ) ; real_T f2 = 1.0 - f1 ; real_T d1 ; real_T d2 ; int_T TimeIndex =
currTimeIndex ; d1 = pDataValues [ TimeIndex ] ; d2 = pDataValues [ TimeIndex
+ 1 ] ; f5iezae2bw = ( real_T ) rtInterpolate ( d1 , d2 , f1 , f2 ) ;
pDataValues += numPoints ; } } } rtB . lzq3c4siad = f5iezae2bw * rtB .
glakw2iqkt ; UNUSED_PARAMETER ( tid ) ; } void MdlOutputsTID1 ( int_T tid ) {
UNUSED_PARAMETER ( tid ) ; } void MdlUpdate ( int_T tid ) { { real_T * *
uBuffer = ( real_T * * ) & rtDW . h2j1mpvchh . TUbufferPtrs [ 0 ] ; real_T
simTime = ssGetT ( rtS ) ; rtDW . kkhgv1gz0b . Head = ( ( rtDW . kkhgv1gz0b .
Head < ( rtDW . kkhgv1gz0b . CircularBufSize - 1 ) ) ? ( rtDW . kkhgv1gz0b .
Head + 1 ) : 0 ) ; if ( rtDW . kkhgv1gz0b . Head == rtDW . kkhgv1gz0b . Tail
) { if ( ! rt_TDelayUpdateTailOrGrowBuf ( & rtDW . kkhgv1gz0b .
CircularBufSize , & rtDW . kkhgv1gz0b . Tail , & rtDW . kkhgv1gz0b . Head , &
rtDW . kkhgv1gz0b . Last , simTime - rtP . Td , uBuffer , ( boolean_T ) 0 ,
false , & rtDW . kkhgv1gz0b . MaxNewBufSize ) ) { ssSetErrorStatus ( rtS ,
"tdelay memory allocation error" ) ; return ; }
slsaSaveRawMemoryForSimTargetOP ( rtS ,
"model/CTRL/Transport\nDelay_TUbuffer0" , ( void * * ) ( & uBuffer [ 0 ] ) ,
2 * rtDW . kkhgv1gz0b . CircularBufSize * sizeof ( real_T ) , NULL , NULL ) ;
} ( * uBuffer + rtDW . kkhgv1gz0b . CircularBufSize ) [ rtDW . kkhgv1gz0b .
Head ] = simTime ; ( * uBuffer ) [ rtDW . kkhgv1gz0b . Head ] = rtB .
lzq3c4siad ; } UNUSED_PARAMETER ( tid ) ; } void MdlUpdateTID1 ( int_T tid )
{ UNUSED_PARAMETER ( tid ) ; } void MdlDerivatives ( void ) { XDot * _rtXdot
; _rtXdot = ( ( XDot * ) ssGetdX ( rtS ) ) ; _rtXdot -> ipgqgubrjo = 0.0 ;
_rtXdot -> ipgqgubrjo += rtP . uJsf_A * rtX . ipgqgubrjo ; _rtXdot ->
ipgqgubrjo += rtB . jcn4tvno4j ; _rtXdot -> fvh2m2gbte = 0.0 ; _rtXdot ->
fvh2m2gbte += rtP . uLsR_A * rtX . fvh2m2gbte ; _rtXdot -> fvh2m2gbte += rtB
. owhgqxukez ; } void MdlProjection ( void ) { } void MdlZeroCrossings ( void
) { ZCV * _rtZCSV ; _rtZCSV = ( ( ZCV * ) ssGetSolverZcSignalVector ( rtS ) )
; _rtZCSV -> omnfvlf3zz = rtB . ctqngoka2z ; } void MdlTerminate ( void ) {
rt_FREE ( rtDW . mhbew2z00k . RSimInfoPtr ) ; rt_TDelayFreeBuf ( rtDW .
h2j1mpvchh . TUbufferPtrs [ 0 ] ) ; rt_FREE ( rtDW . bxpkwc15hx . RSimInfoPtr
) ; rt_FREE ( rtDW . g4hbqczu43 . RSimInfoPtr ) ; } static void
mr_model_cacheDataAsMxArray ( mxArray * destArray , mwIndex i , int j , const
void * srcData , size_t numBytes ) ; static void mr_model_cacheDataAsMxArray
( mxArray * destArray , mwIndex i , int j , const void * srcData , size_t
numBytes ) { mxArray * newArray = mxCreateUninitNumericMatrix ( ( size_t ) 1
, numBytes , mxUINT8_CLASS , mxREAL ) ; memcpy ( ( uint8_T * ) mxGetData (
newArray ) , ( const uint8_T * ) srcData , numBytes ) ; mxSetFieldByNumber (
destArray , i , j , newArray ) ; } static void
mr_model_restoreDataFromMxArray ( void * destData , const mxArray * srcArray
, mwIndex i , int j , size_t numBytes ) ; static void
mr_model_restoreDataFromMxArray ( void * destData , const mxArray * srcArray
, mwIndex i , int j , size_t numBytes ) { memcpy ( ( uint8_T * ) destData , (
const uint8_T * ) mxGetData ( mxGetFieldByNumber ( srcArray , i , j ) ) ,
numBytes ) ; } static void mr_model_cacheBitFieldToMxArray ( mxArray *
destArray , mwIndex i , int j , uint_T bitVal ) ; static void
mr_model_cacheBitFieldToMxArray ( mxArray * destArray , mwIndex i , int j ,
uint_T bitVal ) { mxSetFieldByNumber ( destArray , i , j ,
mxCreateDoubleScalar ( ( double ) bitVal ) ) ; } static uint_T
mr_model_extractBitFieldFromMxArray ( const mxArray * srcArray , mwIndex i ,
int j , uint_T numBits ) ; static uint_T mr_model_extractBitFieldFromMxArray
( const mxArray * srcArray , mwIndex i , int j , uint_T numBits ) { const
uint_T varVal = ( uint_T ) mxGetScalar ( mxGetFieldByNumber ( srcArray , i ,
j ) ) ; return varVal & ( ( 1u << numBits ) - 1u ) ; } static void
mr_model_cacheDataToMxArrayWithOffset ( mxArray * destArray , mwIndex i , int
j , mwIndex offset , const void * srcData , size_t numBytes ) ; static void
mr_model_cacheDataToMxArrayWithOffset ( mxArray * destArray , mwIndex i , int
j , mwIndex offset , const void * srcData , size_t numBytes ) { uint8_T *
varData = ( uint8_T * ) mxGetData ( mxGetFieldByNumber ( destArray , i , j )
) ; memcpy ( ( uint8_T * ) & varData [ offset * numBytes ] , ( const uint8_T
* ) srcData , numBytes ) ; } static void
mr_model_restoreDataFromMxArrayWithOffset ( void * destData , const mxArray *
srcArray , mwIndex i , int j , mwIndex offset , size_t numBytes ) ; static
void mr_model_restoreDataFromMxArrayWithOffset ( void * destData , const
mxArray * srcArray , mwIndex i , int j , mwIndex offset , size_t numBytes ) {
const uint8_T * varData = ( const uint8_T * ) mxGetData ( mxGetFieldByNumber
( srcArray , i , j ) ) ; memcpy ( ( uint8_T * ) destData , ( const uint8_T *
) & varData [ offset * numBytes ] , numBytes ) ; } static void
mr_model_cacheBitFieldToCellArrayWithOffset ( mxArray * destArray , mwIndex i
, int j , mwIndex offset , uint_T fieldVal ) ; static void
mr_model_cacheBitFieldToCellArrayWithOffset ( mxArray * destArray , mwIndex i
, int j , mwIndex offset , uint_T fieldVal ) { mxSetCell ( mxGetFieldByNumber
( destArray , i , j ) , offset , mxCreateDoubleScalar ( ( double ) fieldVal )
) ; } static uint_T mr_model_extractBitFieldFromCellArrayWithOffset ( const
mxArray * srcArray , mwIndex i , int j , mwIndex offset , uint_T numBits ) ;
static uint_T mr_model_extractBitFieldFromCellArrayWithOffset ( const mxArray
* srcArray , mwIndex i , int j , mwIndex offset , uint_T numBits ) { const
uint_T fieldVal = ( uint_T ) mxGetScalar ( mxGetCell ( mxGetFieldByNumber (
srcArray , i , j ) , offset ) ) ; return fieldVal & ( ( 1u << numBits ) - 1u
) ; } mxArray * mr_model_GetDWork ( ) { static const char * ssDWFieldNames [
3 ] = { "rtB" , "rtDW" , "NULL_PrevZCX" , } ; mxArray * ssDW =
mxCreateStructMatrix ( 1 , 1 , 3 , ssDWFieldNames ) ;
mr_model_cacheDataAsMxArray ( ssDW , 0 , 0 , ( const void * ) & ( rtB ) ,
sizeof ( rtB ) ) ; { static const char * rtdwDataFieldNames [ 6 ] = {
"rtDW.dsukx5k2uj" , "rtDW.dd0lddrxds" , "rtDW.kkhgv1gz0b" , "rtDW.jvgjspjuxn"
, "rtDW.oqndo05can" , "rtDW.dixkiqm3la" , } ; mxArray * rtdwData =
mxCreateStructMatrix ( 1 , 1 , 6 , rtdwDataFieldNames ) ;
mr_model_cacheDataAsMxArray ( rtdwData , 0 , 0 , ( const void * ) & ( rtDW .
dsukx5k2uj ) , sizeof ( rtDW . dsukx5k2uj ) ) ; mr_model_cacheDataAsMxArray (
rtdwData , 0 , 1 , ( const void * ) & ( rtDW . dd0lddrxds ) , sizeof ( rtDW .
dd0lddrxds ) ) ; mr_model_cacheDataAsMxArray ( rtdwData , 0 , 2 , ( const
void * ) & ( rtDW . kkhgv1gz0b ) , sizeof ( rtDW . kkhgv1gz0b ) ) ;
mr_model_cacheDataAsMxArray ( rtdwData , 0 , 3 , ( const void * ) & ( rtDW .
jvgjspjuxn ) , sizeof ( rtDW . jvgjspjuxn ) ) ; mr_model_cacheDataAsMxArray (
rtdwData , 0 , 4 , ( const void * ) & ( rtDW . oqndo05can ) , sizeof ( rtDW .
oqndo05can ) ) ; mr_model_cacheDataAsMxArray ( rtdwData , 0 , 5 , ( const
void * ) & ( rtDW . dixkiqm3la ) , sizeof ( rtDW . dixkiqm3la ) ) ;
mxSetFieldByNumber ( ssDW , 0 , 1 , rtdwData ) ; } return ssDW ; } void
mr_model_SetDWork ( const mxArray * ssDW ) { ( void ) ssDW ;
mr_model_restoreDataFromMxArray ( ( void * ) & ( rtB ) , ssDW , 0 , 0 ,
sizeof ( rtB ) ) ; { const mxArray * rtdwData = mxGetFieldByNumber ( ssDW , 0
, 1 ) ; mr_model_restoreDataFromMxArray ( ( void * ) & ( rtDW . dsukx5k2uj )
, rtdwData , 0 , 0 , sizeof ( rtDW . dsukx5k2uj ) ) ;
mr_model_restoreDataFromMxArray ( ( void * ) & ( rtDW . dd0lddrxds ) ,
rtdwData , 0 , 1 , sizeof ( rtDW . dd0lddrxds ) ) ;
mr_model_restoreDataFromMxArray ( ( void * ) & ( rtDW . kkhgv1gz0b ) ,
rtdwData , 0 , 2 , sizeof ( rtDW . kkhgv1gz0b ) ) ;
mr_model_restoreDataFromMxArray ( ( void * ) & ( rtDW . jvgjspjuxn ) ,
rtdwData , 0 , 3 , sizeof ( rtDW . jvgjspjuxn ) ) ;
mr_model_restoreDataFromMxArray ( ( void * ) & ( rtDW . oqndo05can ) ,
rtdwData , 0 , 4 , sizeof ( rtDW . oqndo05can ) ) ;
mr_model_restoreDataFromMxArray ( ( void * ) & ( rtDW . dixkiqm3la ) ,
rtdwData , 0 , 5 , sizeof ( rtDW . dixkiqm3la ) ) ; } } mxArray *
mr_model_GetSimStateDisallowedBlocks ( ) { mxArray * data =
mxCreateCellMatrix ( 4 , 3 ) ; mwIndex subs [ 2 ] , offset ; { static const
char * blockType [ 4 ] = { "Scope" , "Scope" , "Scope" , "Scope" , } ; static
const char * blockPath [ 4 ] = { "model/Scope" , "model/AERO/Scope" ,
"model/AERO/Scope1" , "model/BLDC/Scope" , } ; static const int reason [ 4 ]
= { 0 , 0 , 0 , 0 , } ; for ( subs [ 0 ] = 0 ; subs [ 0 ] < 4 ; ++ ( subs [ 0
] ) ) { subs [ 1 ] = 0 ; offset = mxCalcSingleSubscript ( data , 2 , subs ) ;
mxSetCell ( data , offset , mxCreateString ( blockType [ subs [ 0 ] ] ) ) ;
subs [ 1 ] = 1 ; offset = mxCalcSingleSubscript ( data , 2 , subs ) ;
mxSetCell ( data , offset , mxCreateString ( blockPath [ subs [ 0 ] ] ) ) ;
subs [ 1 ] = 2 ; offset = mxCalcSingleSubscript ( data , 2 , subs ) ;
mxSetCell ( data , offset , mxCreateDoubleScalar ( ( double ) reason [ subs [
0 ] ] ) ) ; } } return data ; } void MdlInitializeSizes ( void ) {
ssSetNumContStates ( rtS , 2 ) ; ssSetNumPeriodicContStates ( rtS , 0 ) ;
ssSetNumY ( rtS , 0 ) ; ssSetNumU ( rtS , 0 ) ; ssSetDirectFeedThrough ( rtS
, 0 ) ; ssSetNumSampleTimes ( rtS , 1 ) ; ssSetNumBlocks ( rtS , 27 ) ;
ssSetNumBlockIO ( rtS , 18 ) ; ssSetNumBlockParams ( rtS , 5941 ) ; } void
MdlInitializeSampleTimes ( void ) { ssSetSampleTime ( rtS , 0 , 0.0 ) ;
ssSetOffsetTime ( rtS , 0 , 0.0 ) ; } void raccel_set_checksum ( ) {
ssSetChecksumVal ( rtS , 0 , 1576021846U ) ; ssSetChecksumVal ( rtS , 1 ,
1107556957U ) ; ssSetChecksumVal ( rtS , 2 , 4253704579U ) ; ssSetChecksumVal
( rtS , 3 , 3628593836U ) ; }
#if defined(_MSC_VER)
#pragma optimize( "", off )
#endif
SimStruct * raccel_register_model ( ssExecutionInfo * executionInfo ) {
static struct _ssMdlInfo mdlInfo ; ( void ) memset ( ( char * ) rtS , 0 ,
sizeof ( SimStruct ) ) ; ( void ) memset ( ( char * ) & mdlInfo , 0 , sizeof
( struct _ssMdlInfo ) ) ; ssSetMdlInfoPtr ( rtS , & mdlInfo ) ;
ssSetExecutionInfo ( rtS , executionInfo ) ; { static time_T mdlPeriod [
NSAMPLE_TIMES ] ; static time_T mdlOffset [ NSAMPLE_TIMES ] ; static time_T
mdlTaskTimes [ NSAMPLE_TIMES ] ; static int_T mdlTsMap [ NSAMPLE_TIMES ] ;
static int_T mdlSampleHits [ NSAMPLE_TIMES ] ; static boolean_T
mdlTNextWasAdjustedPtr [ NSAMPLE_TIMES ] ; static int_T mdlPerTaskSampleHits
[ NSAMPLE_TIMES * NSAMPLE_TIMES ] ; static time_T mdlTimeOfNextSampleHit [
NSAMPLE_TIMES ] ; { int_T i ; for ( i = 0 ; i < NSAMPLE_TIMES ; i ++ ) {
mdlPeriod [ i ] = 0.0 ; mdlOffset [ i ] = 0.0 ; mdlTaskTimes [ i ] = 0.0 ;
mdlTsMap [ i ] = i ; mdlSampleHits [ i ] = 1 ; } } ssSetSampleTimePtr ( rtS ,
& mdlPeriod [ 0 ] ) ; ssSetOffsetTimePtr ( rtS , & mdlOffset [ 0 ] ) ;
ssSetSampleTimeTaskIDPtr ( rtS , & mdlTsMap [ 0 ] ) ; ssSetTPtr ( rtS , &
mdlTaskTimes [ 0 ] ) ; ssSetSampleHitPtr ( rtS , & mdlSampleHits [ 0 ] ) ;
ssSetTNextWasAdjustedPtr ( rtS , & mdlTNextWasAdjustedPtr [ 0 ] ) ;
ssSetPerTaskSampleHitsPtr ( rtS , & mdlPerTaskSampleHits [ 0 ] ) ;
ssSetTimeOfNextSampleHitPtr ( rtS , & mdlTimeOfNextSampleHit [ 0 ] ) ; }
ssSetSolverMode ( rtS , SOLVER_MODE_SINGLETASKING ) ; { ssSetBlockIO ( rtS ,
( ( void * ) & rtB ) ) ; ( void ) memset ( ( ( void * ) & rtB ) , 0 , sizeof
( B ) ) ; } { real_T * x = ( real_T * ) & rtX ; ssSetContStates ( rtS , x ) ;
( void ) memset ( ( void * ) x , 0 , sizeof ( X ) ) ; } { void * dwork = (
void * ) & rtDW ; ssSetRootDWork ( rtS , dwork ) ; ( void ) memset ( dwork ,
0 , sizeof ( DW ) ) ; } { static DataTypeTransInfo dtInfo ; ( void ) memset (
( char_T * ) & dtInfo , 0 , sizeof ( dtInfo ) ) ; ssSetModelMappingInfo ( rtS
, & dtInfo ) ; dtInfo . numDataTypes = 14 ; dtInfo . dataTypeSizes = &
rtDataTypeSizes [ 0 ] ; dtInfo . dataTypeNames = & rtDataTypeNames [ 0 ] ;
dtInfo . BTransTable = & rtBTransTable ; dtInfo . PTransTable = &
rtPTransTable ; dtInfo . dataTypeInfoTable = rtDataTypeInfoTable ; }
model_InitializeDataMapInfo ( ) ; ssSetIsRapidAcceleratorActive ( rtS , true
) ; ssSetRootSS ( rtS , rtS ) ; ssSetVersion ( rtS , SIMSTRUCT_VERSION_LEVEL2
) ; ssSetModelName ( rtS , "model" ) ; ssSetPath ( rtS , "model" ) ;
ssSetTStart ( rtS , 0.0 ) ; ssSetTFinal ( rtS , 120.0 ) ; { static RTWLogInfo
rt_DataLoggingInfo ; rt_DataLoggingInfo . loggingInterval = ( NULL ) ;
ssSetRTWLogInfo ( rtS , & rt_DataLoggingInfo ) ; } { { static int_T
rt_LoggedStateWidths [ ] = { 1 , 1 } ; static int_T
rt_LoggedStateNumDimensions [ ] = { 1 , 1 } ; static int_T
rt_LoggedStateDimensions [ ] = { 1 , 1 } ; static boolean_T
rt_LoggedStateIsVarDims [ ] = { 0 , 0 } ; static BuiltInDTypeId
rt_LoggedStateDataTypeIds [ ] = { SS_DOUBLE , SS_DOUBLE } ; static int_T
rt_LoggedStateComplexSignals [ ] = { 0 , 0 } ; static RTWPreprocessingFcnPtr
rt_LoggingStatePreprocessingFcnPtrs [ ] = { ( NULL ) , ( NULL ) } ; static
const char_T * rt_LoggedStateLabels [ ] = { "CSTATE" , "CSTATE" } ; static
const char_T * rt_LoggedStateBlockNames [ ] = { "model/BLDC/1//(Js+f)" ,
"model/BLDC/1//(Ls+R)" } ; static const char_T * rt_LoggedStateNames [ ] = {
"" , "" } ; static boolean_T rt_LoggedStateCrossMdlRef [ ] = { 0 , 0 } ;
static RTWLogDataTypeConvert rt_RTWLogDataTypeConvert [ ] = { { 0 , SS_DOUBLE
, SS_DOUBLE , 0 , 0 , 0 , 1.0 , 0 , 0.0 } , { 0 , SS_DOUBLE , SS_DOUBLE , 0 ,
0 , 0 , 1.0 , 0 , 0.0 } } ; static int_T rt_LoggedStateIdxList [ ] = { 0 , 1
} ; static RTWLogSignalInfo rt_LoggedStateSignalInfo = { 2 ,
rt_LoggedStateWidths , rt_LoggedStateNumDimensions , rt_LoggedStateDimensions
, rt_LoggedStateIsVarDims , ( NULL ) , ( NULL ) , rt_LoggedStateDataTypeIds ,
rt_LoggedStateComplexSignals , ( NULL ) , rt_LoggingStatePreprocessingFcnPtrs
, { rt_LoggedStateLabels } , ( NULL ) , ( NULL ) , ( NULL ) , {
rt_LoggedStateBlockNames } , { rt_LoggedStateNames } ,
rt_LoggedStateCrossMdlRef , rt_RTWLogDataTypeConvert , rt_LoggedStateIdxList
} ; static void * rt_LoggedStateSignalPtrs [ 2 ] ; rtliSetLogXSignalPtrs (
ssGetRTWLogInfo ( rtS ) , ( LogSignalPtrsType ) rt_LoggedStateSignalPtrs ) ;
rtliSetLogXSignalInfo ( ssGetRTWLogInfo ( rtS ) , & rt_LoggedStateSignalInfo
) ; rt_LoggedStateSignalPtrs [ 0 ] = ( void * ) & rtX . ipgqgubrjo ;
rt_LoggedStateSignalPtrs [ 1 ] = ( void * ) & rtX . fvh2m2gbte ; }
rtliSetLogT ( ssGetRTWLogInfo ( rtS ) , "tout" ) ; rtliSetLogX (
ssGetRTWLogInfo ( rtS ) , "" ) ; rtliSetLogXFinal ( ssGetRTWLogInfo ( rtS ) ,
"" ) ; rtliSetLogVarNameModifier ( ssGetRTWLogInfo ( rtS ) , "none" ) ;
rtliSetLogFormat ( ssGetRTWLogInfo ( rtS ) , 4 ) ; rtliSetLogMaxRows (
ssGetRTWLogInfo ( rtS ) , 0 ) ; rtliSetLogDecimation ( ssGetRTWLogInfo ( rtS
) , 1 ) ; rtliSetLogY ( ssGetRTWLogInfo ( rtS ) , "" ) ;
rtliSetLogYSignalInfo ( ssGetRTWLogInfo ( rtS ) , ( NULL ) ) ;
rtliSetLogYSignalPtrs ( ssGetRTWLogInfo ( rtS ) , ( NULL ) ) ; } { static
struct _ssStatesInfo2 statesInfo2 ; ssSetStatesInfo2 ( rtS , & statesInfo2 )
; } { static ssPeriodicStatesInfo periodicStatesInfo ;
ssSetPeriodicStatesInfo ( rtS , & periodicStatesInfo ) ; } { static
ssJacobianPerturbationBounds jacobianPerturbationBounds ;
ssSetJacobianPerturbationBounds ( rtS , & jacobianPerturbationBounds ) ; } {
static ssSolverInfo slvrInfo ; static boolean_T contStatesDisabled [ 2 ] ;
static real_T absTol [ 2 ] = { 1.0E-5 , 1.0E-5 } ; static uint8_T
absTolControl [ 2 ] = { 0U , 0U } ; static real_T
contStateJacPerturbBoundMinVec [ 2 ] ; static real_T
contStateJacPerturbBoundMaxVec [ 2 ] ; static uint8_T zcAttributes [ 1 ] = {
( ZC_EVENT_ALL ) } ; { int i ; for ( i = 0 ; i < 2 ; ++ i ) {
contStateJacPerturbBoundMinVec [ i ] = 0 ; contStateJacPerturbBoundMaxVec [ i
] = rtGetInf ( ) ; } } ssSetSolverRelTol ( rtS , 0.001 ) ; ssSetStepSize (
rtS , 0.0 ) ; ssSetMinStepSize ( rtS , 0.0 ) ; ssSetMaxNumMinSteps ( rtS , -
1 ) ; ssSetMinStepViolatedError ( rtS , 0 ) ; ssSetMaxStepSize ( rtS , 2.4 )
; ssSetSolverMaxOrder ( rtS , 5 ) ; ssSetSolverRefineFactor ( rtS , 1 ) ;
ssSetOutputTimes ( rtS , ( NULL ) ) ; ssSetNumOutputTimes ( rtS , 0 ) ;
ssSetOutputTimesOnly ( rtS , 0 ) ; ssSetOutputTimesIndex ( rtS , 0 ) ;
ssSetZCCacheNeedsReset ( rtS , 0 ) ; ssSetDerivCacheNeedsReset ( rtS , 0 ) ;
ssSetNumNonContDerivSigInfos ( rtS , 0 ) ; ssSetNonContDerivSigInfos ( rtS ,
( NULL ) ) ; ssSetSolverInfo ( rtS , & slvrInfo ) ; ssSetSolverName ( rtS ,
"ode15s" ) ; ssSetVariableStepSolver ( rtS , 1 ) ;
ssSetSolverConsistencyChecking ( rtS , 0 ) ; ssSetSolverAdaptiveZcDetection (
rtS , 0 ) ; ssSetSolverRobustResetMethod ( rtS , 0 ) ; ssSetAbsTolVector (
rtS , absTol ) ; ssSetAbsTolControlVector ( rtS , absTolControl ) ;
ssSetSolverAbsTol_Obsolete ( rtS , absTol ) ;
ssSetSolverAbsTolControl_Obsolete ( rtS , absTolControl ) ;
ssSetJacobianPerturbationBoundsMinVec ( rtS , contStateJacPerturbBoundMinVec
) ; ssSetJacobianPerturbationBoundsMaxVec ( rtS ,
contStateJacPerturbBoundMaxVec ) ; ssSetSolverStateProjection ( rtS , 0 ) ;
ssSetSolverMassMatrixType ( rtS , ( ssMatrixType ) 0 ) ;
ssSetSolverMassMatrixNzMax ( rtS , 0 ) ; ssSetModelOutputs ( rtS , MdlOutputs
) ; ssSetModelLogData ( rtS , rt_UpdateTXYLogVars ) ;
ssSetModelLogDataIfInInterval ( rtS , rt_UpdateTXXFYLogVars ) ;
ssSetModelUpdate ( rtS , MdlUpdate ) ; ssSetModelDerivatives ( rtS ,
MdlDerivatives ) ; ssSetSolverZcSignalAttrib ( rtS , zcAttributes ) ;
ssSetSolverNumZcSignals ( rtS , 1 ) ; ssSetModelZeroCrossings ( rtS ,
MdlZeroCrossings ) ; ssSetSolverConsecutiveZCsStepRelTol ( rtS ,
2.8421709430404007E-13 ) ; ssSetSolverMaxConsecutiveZCs ( rtS , 1000 ) ;
ssSetSolverConsecutiveZCsError ( rtS , 2 ) ; ssSetSolverMaskedZcDiagnostic (
rtS , 1 ) ; ssSetSolverIgnoredZcDiagnostic ( rtS , 1 ) ;
ssSetSolverMaxConsecutiveMinStep ( rtS , 1 ) ;
ssSetSolverShapePreserveControl ( rtS , 2 ) ; ssSetTNextTid ( rtS , INT_MIN )
; ssSetTNext ( rtS , rtMinusInf ) ; ssSetSolverNeedsReset ( rtS ) ;
ssSetNumNonsampledZCs ( rtS , 1 ) ; ssSetContStateDisabled ( rtS ,
contStatesDisabled ) ; ssSetSolverMaxConsecutiveMinStep ( rtS , 1 ) ; }
ssSetChecksumVal ( rtS , 0 , 1576021846U ) ; ssSetChecksumVal ( rtS , 1 ,
1107556957U ) ; ssSetChecksumVal ( rtS , 2 , 4253704579U ) ; ssSetChecksumVal
( rtS , 3 , 3628593836U ) ; { static const sysRanDType rtAlwaysEnabled =
SUBSYS_RAN_BC_ENABLE ; static RTWExtModeInfo rt_ExtModeInfo ; static const
sysRanDType * systemRan [ 1 ] ; gblRTWExtModeInfo = & rt_ExtModeInfo ;
ssSetRTWExtModeInfo ( rtS , & rt_ExtModeInfo ) ;
rteiSetSubSystemActiveVectorAddresses ( & rt_ExtModeInfo , systemRan ) ;
systemRan [ 0 ] = & rtAlwaysEnabled ; rteiSetModelMappingInfoPtr (
ssGetRTWExtModeInfo ( rtS ) , & ssGetModelMappingInfo ( rtS ) ) ;
rteiSetChecksumsPtr ( ssGetRTWExtModeInfo ( rtS ) , ssGetChecksums ( rtS ) )
; rteiSetTPtr ( ssGetRTWExtModeInfo ( rtS ) , ssGetTPtr ( rtS ) ) ; }
slsaDisallowedBlocksForSimTargetOP ( rtS ,
mr_model_GetSimStateDisallowedBlocks ) ; slsaGetWorkFcnForSimTargetOP ( rtS ,
mr_model_GetDWork ) ; slsaSetWorkFcnForSimTargetOP ( rtS , mr_model_SetDWork
) ; rt_RapidReadMatFileAndUpdateParams ( rtS ) ; if ( ssGetErrorStatus ( rtS
) ) { return rtS ; } return rtS ; }
#if defined(_MSC_VER)
#pragma optimize( "", on )
#endif
const int_T gblParameterTuningTid = 1 ; void MdlOutputsParameterSampleTime (
int_T tid ) { MdlOutputsTID1 ( tid ) ; }

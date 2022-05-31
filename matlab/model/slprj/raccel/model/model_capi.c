#include "rtw_capi.h"
#ifdef HOST_CAPI_BUILD
#include "model_capi_host.h"
#define sizeof(s) ((size_t)(0xFFFF))
#undef rt_offsetof
#define rt_offsetof(s,el) ((uint16_T)(0xFFFF))
#define TARGET_CONST
#define TARGET_STRING(s) (s)    
#else
#include "builtin_typeid_types.h"
#include "model.h"
#include "model_capi.h"
#include "model_private.h"
#ifdef LIGHT_WEIGHT_CAPI
#define TARGET_CONST                  
#define TARGET_STRING(s)               (NULL)                    
#else
#define TARGET_CONST                   const
#define TARGET_STRING(s)               (s)
#endif
#endif
static const rtwCAPI_Signals rtBlockSignals [ ] = { { 0 , 0 , TARGET_STRING (
"model/safety1" ) , TARGET_STRING ( "" ) , 0 , 0 , 0 , 0 , 0 } , { 1 , 0 ,
TARGET_STRING ( "model/advance ratio" ) , TARGET_STRING (
"advance ratio w/ω" ) , 0 , 0 , 0 , 0 , 0 } , { 2 , 0 , TARGET_STRING (
"model/Square" ) , TARGET_STRING ( "" ) , 0 , 0 , 0 , 0 , 0 } , { 3 , 0 ,
TARGET_STRING ( "model/AERO/CT0" ) , TARGET_STRING ( "" ) , 0 , 0 , 0 , 0 , 0
} , { 4 , 0 , TARGET_STRING ( "model/AERO/CT1" ) , TARGET_STRING ( "" ) , 0 ,
0 , 0 , 0 , 0 } , { 5 , 0 , TARGET_STRING ( "model/AERO/Product" ) ,
TARGET_STRING ( "" ) , 0 , 0 , 0 , 0 , 0 } , { 6 , 0 , TARGET_STRING (
"model/AERO/Add" ) , TARGET_STRING ( "Thrust" ) , 0 , 0 , 0 , 0 , 0 } , { 7 ,
0 , TARGET_STRING ( "model/AERO/Add1" ) , TARGET_STRING ( "Torque" ) , 0 , 0
, 0 , 0 , 0 } , { 8 , 0 , TARGET_STRING ( "model/BLDC/Ke1" ) , TARGET_STRING
( "Torque [N.m]" ) , 0 , 0 , 0 , 0 , 0 } , { 9 , 0 , TARGET_STRING (
"model/BLDC/Ke2" ) , TARGET_STRING ( "Ui [V]" ) , 0 , 0 , 0 , 0 , 0 } , { 10
, 0 , TARGET_STRING ( "model/BLDC/Sum" ) , TARGET_STRING ( "Torque" ) , 0 , 0
, 0 , 0 , 0 } , { 11 , 0 , TARGET_STRING ( "model/BLDC/Sum1" ) ,
TARGET_STRING ( "" ) , 0 , 0 , 0 , 0 , 0 } , { 12 , 0 , TARGET_STRING (
"model/BLDC/1//(Js+f)" ) , TARGET_STRING ( "ω [rad/s]" ) , 0 , 0 , 0 , 0 , 0
} , { 13 , 0 , TARGET_STRING ( "model/BLDC/1//(Ls+R)" ) , TARGET_STRING ( ""
) , 0 , 0 , 0 , 0 , 0 } , { 14 , 0 , TARGET_STRING ( "model/CTRL/Gain" ) ,
TARGET_STRING ( "" ) , 0 , 0 , 0 , 0 , 0 } , { 15 , 0 , TARGET_STRING (
"model/CTRL/Product" ) , TARGET_STRING ( "" ) , 0 , 0 , 0 , 0 , 0 } , { 16 ,
0 , TARGET_STRING ( "model/CTRL/Sum" ) , TARGET_STRING ( "" ) , 0 , 0 , 0 , 0
, 0 } , { 17 , 0 , TARGET_STRING ( "model/CTRL/Transport Delay" ) ,
TARGET_STRING ( "" ) , 0 , 0 , 0 , 0 , 0 } , { 0 , 0 , ( NULL ) , ( NULL ) ,
0 , 0 , 0 , 0 , 0 } } ; static const rtwCAPI_BlockParameters
rtBlockParameters [ ] = { { 18 , TARGET_STRING ( "model/advance ratio" ) ,
TARGET_STRING ( "Time0" ) , 0 , 1 , 0 } , { 19 , TARGET_STRING (
"model/advance ratio" ) , TARGET_STRING ( "Data0" ) , 0 , 1 , 0 } , { 20 ,
TARGET_STRING ( "model/throttle" ) , TARGET_STRING ( "Time0" ) , 0 , 1 , 0 }
, { 21 , TARGET_STRING ( "model/throttle" ) , TARGET_STRING ( "Data0" ) , 0 ,
1 , 0 } , { 22 , TARGET_STRING ( "model/voltage" ) , TARGET_STRING ( "Time0"
) , 0 , 1 , 0 } , { 23 , TARGET_STRING ( "model/voltage" ) , TARGET_STRING (
"Data0" ) , 0 , 1 , 0 } , { 24 , TARGET_STRING ( "model/BLDC/1//(Js+f)" ) ,
TARGET_STRING ( "A" ) , 0 , 0 , 0 } , { 25 , TARGET_STRING (
"model/BLDC/1//(Js+f)" ) , TARGET_STRING ( "C" ) , 0 , 0 , 0 } , { 26 ,
TARGET_STRING ( "model/BLDC/1//(Ls+R)" ) , TARGET_STRING ( "A" ) , 0 , 0 , 0
} , { 27 , TARGET_STRING ( "model/BLDC/1//(Ls+R)" ) , TARGET_STRING ( "C" ) ,
0 , 0 , 0 } , { 28 , TARGET_STRING ( "model/CTRL/Constant" ) , TARGET_STRING
( "Value" ) , 0 , 0 , 0 } , { 29 , TARGET_STRING ( "model/CTRL/Gain" ) ,
TARGET_STRING ( "Gain" ) , 0 , 0 , 0 } , { 30 , TARGET_STRING (
"model/CTRL/Transport Delay" ) , TARGET_STRING ( "InitialOutput" ) , 0 , 0 ,
0 } , { 0 , ( NULL ) , ( NULL ) , 0 , 0 , 0 } } ; static int_T
rt_LoggedStateIdxList [ ] = { - 1 } ; static const rtwCAPI_Signals
rtRootInputs [ ] = { { 0 , 0 , ( NULL ) , ( NULL ) , 0 , 0 , 0 , 0 , 0 } } ;
static const rtwCAPI_Signals rtRootOutputs [ ] = { { 0 , 0 , ( NULL ) , (
NULL ) , 0 , 0 , 0 , 0 , 0 } } ; static const rtwCAPI_ModelParameters
rtModelParameters [ ] = { { 31 , TARGET_STRING ( "CQ0" ) , 0 , 0 , 0 } , { 32
, TARGET_STRING ( "CQ1" ) , 0 , 0 , 0 } , { 33 , TARGET_STRING ( "CT0" ) , 0
, 0 , 0 } , { 34 , TARGET_STRING ( "CT1" ) , 0 , 0 , 0 } , { 35 ,
TARGET_STRING ( "Ke" ) , 0 , 0 , 0 } , { 36 , TARGET_STRING ( "Td" ) , 0 , 0
, 0 } , { 0 , ( NULL ) , 0 , 0 , 0 } } ;
#ifndef HOST_CAPI_BUILD
static void * rtDataAddrMap [ ] = { & rtB . gylwilku4q , & rtB . ik4ntg31yl ,
& rtB . d5ftbwwamr , & rtB . gzr2fdlbpz , & rtB . lxfwukbk51 , & rtB .
a5bgezcw3b , & rtB . ctqngoka2z , & rtB . d0tzttk1mn , & rtB . jm3x34yiq2 , &
rtB . a1zkc411uy , & rtB . jcn4tvno4j , & rtB . owhgqxukez , & rtB .
hqfzfrz2lc , & rtB . bmouv522ru , & rtB . glakw2iqkt , & rtB . lzq3c4siad , &
rtB . pfgbdbk5tc , & rtB . eiqbbzcufr , & rtP . advanceratio_Time0 [ 0 ] , &
rtP . advanceratio_Data0 [ 0 ] , & rtP . throttle_Time0 [ 0 ] , & rtP .
throttle_Data0 [ 0 ] , & rtP . voltage_Time0 [ 0 ] , & rtP . voltage_Data0 [
0 ] , & rtP . uJsf_A , & rtP . uJsf_C , & rtP . uLsR_A , & rtP . uLsR_C , &
rtP . Constant_Value , & rtP . Gain_Gain , & rtP . TransportDelay_InitOutput
, & rtP . CQ0 , & rtP . CQ1 , & rtP . CT0 , & rtP . CT1 , & rtP . Ke , & rtP
. Td , } ; static int32_T * rtVarDimsAddrMap [ ] = { ( NULL ) } ;
#endif
static TARGET_CONST rtwCAPI_DataTypeMap rtDataTypeMap [ ] = { { "double" ,
"real_T" , 0 , 0 , sizeof ( real_T ) , SS_DOUBLE , 0 , 0 , 0 } } ;
#ifdef HOST_CAPI_BUILD
#undef sizeof
#endif
static TARGET_CONST rtwCAPI_ElementMap rtElementMap [ ] = { { ( NULL ) , 0 ,
0 , 0 , 0 } , } ; static const rtwCAPI_DimensionMap rtDimensionMap [ ] = { {
rtwCAPI_SCALAR , 0 , 2 , 0 } , { rtwCAPI_VECTOR , 2 , 2 , 0 } } ; static
const uint_T rtDimensionArray [ ] = { 1 , 1 , 988 , 1 } ; static const real_T
rtcapiStoredFloats [ ] = { 0.0 } ; static const rtwCAPI_FixPtMap rtFixPtMap [
] = { { ( NULL ) , ( NULL ) , rtwCAPI_FIX_RESERVED , 0 , 0 , 0 } , } ; static
const rtwCAPI_SampleTimeMap rtSampleTimeMap [ ] = { { ( const void * ) &
rtcapiStoredFloats [ 0 ] , ( const void * ) & rtcapiStoredFloats [ 0 ] , 0 ,
0 } } ; static rtwCAPI_ModelMappingStaticInfo mmiStatic = { { rtBlockSignals
, 18 , rtRootInputs , 0 , rtRootOutputs , 0 } , { rtBlockParameters , 13 ,
rtModelParameters , 6 } , { ( NULL ) , 0 } , { rtDataTypeMap , rtDimensionMap
, rtFixPtMap , rtElementMap , rtSampleTimeMap , rtDimensionArray } , "float"
, { 1576021846U , 1107556957U , 4253704579U , 3628593836U } , ( NULL ) , 0 ,
0 , rt_LoggedStateIdxList } ; const rtwCAPI_ModelMappingStaticInfo *
model_GetCAPIStaticMap ( void ) { return & mmiStatic ; }
#ifndef HOST_CAPI_BUILD
void model_InitializeDataMapInfo ( void ) { rtwCAPI_SetVersion ( ( *
rt_dataMapInfoPtr ) . mmi , 1 ) ; rtwCAPI_SetStaticMap ( ( *
rt_dataMapInfoPtr ) . mmi , & mmiStatic ) ; rtwCAPI_SetLoggingStaticMap ( ( *
rt_dataMapInfoPtr ) . mmi , ( NULL ) ) ; rtwCAPI_SetDataAddressMap ( ( *
rt_dataMapInfoPtr ) . mmi , rtDataAddrMap ) ; rtwCAPI_SetVarDimsAddressMap (
( * rt_dataMapInfoPtr ) . mmi , rtVarDimsAddrMap ) ;
rtwCAPI_SetInstanceLoggingInfo ( ( * rt_dataMapInfoPtr ) . mmi , ( NULL ) ) ;
rtwCAPI_SetChildMMIArray ( ( * rt_dataMapInfoPtr ) . mmi , ( NULL ) ) ;
rtwCAPI_SetChildMMIArrayLen ( ( * rt_dataMapInfoPtr ) . mmi , 0 ) ; }
#else
#ifdef __cplusplus
extern "C" {
#endif
void model_host_InitializeDataMapInfo ( model_host_DataMapInfo_T * dataMap ,
const char * path ) { rtwCAPI_SetVersion ( dataMap -> mmi , 1 ) ;
rtwCAPI_SetStaticMap ( dataMap -> mmi , & mmiStatic ) ;
rtwCAPI_SetDataAddressMap ( dataMap -> mmi , NULL ) ;
rtwCAPI_SetVarDimsAddressMap ( dataMap -> mmi , NULL ) ; rtwCAPI_SetPath (
dataMap -> mmi , path ) ; rtwCAPI_SetFullPath ( dataMap -> mmi , NULL ) ;
rtwCAPI_SetChildMMIArray ( dataMap -> mmi , ( NULL ) ) ;
rtwCAPI_SetChildMMIArrayLen ( dataMap -> mmi , 0 ) ; }
#ifdef __cplusplus
}
#endif
#endif

/**********************************************************************
* Copyright (c) 2006-2018 SmarAct GmbH
*
* File name: SCU3DControl.h
* Author   : Marc Schiffner, Roland Piechocki, Edwin Moehlheinrich
* Version  : 1.5.7
*
* This is the software interface to the SCU product family.
* Please refer to the SCU Programmers Guide document
* for a detailed documentation.
*
* THIS  SOFTWARE, DOCUMENTS, FILES AND INFORMATION ARE PROVIDED 'AS IS'
* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
* BUT  NOT  LIMITED  TO,  THE  IMPLIED  WARRANTIES  OF MERCHANTABILITY,
* FITNESS FOR A PURPOSE, OR THE WARRANTY OF NON-INFRINGEMENT.
* THE  ENTIRE  RISK  ARISING OUT OF USE OR PERFORMANCE OF THIS SOFTWARE
* REMAINS WITH YOU.
* IN  NO  EVENT  SHALL  THE  SMARACT  GMBH  BE  LIABLE  FOR ANY DIRECT,
* INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL OR OTHER DAMAGES ARISING
* OUT OF THE USE OR INABILITY TO USE THIS SOFTWARE.
**********************************************************************/

#ifndef SCU3DCONTROL_H
#define SCU3DCONTROL_H

#define SA_SCU3DCONTROL_VERSION_MAJOR					1
#define SA_SCU3DCONTROL_VERSION_MINOR					5
#define SA_SCU3DCONTROL_VERSION_UPDATE					7

#if defined(_WIN32)
#  define SCU3DCONTROL_PLATFORM_WINDOWS
#elif defined(__linux__)
#  define SCU3DCONTROL_PLATFORM_LINUX
#else
#  error "unsupported platform"
#endif


#if defined(SCU3DCONTROL_PLATFORM_WINDOWS)
#  ifdef SCU3DCONTROL_EXPORTS
#    define SCU3DCONTROL_API __declspec(dllexport)
#  else
#    define SCU3DCONTROL_API __declspec(dllimport)
#  endif
#else
#  define SCU3DCONTROL_API __attribute__ ((visibility ("default")))
#endif

typedef unsigned int SA_STATUS;
typedef unsigned int SA_INDEX;
typedef unsigned int SA_PACKET_TYPE;

// defines a data packet for the asynchronous mode
typedef struct SA_packet {
    SA_PACKET_TYPE packetType;  // type of packet (see below)
    SA_INDEX channelIndex;      // source channel
    unsigned int data1;         // data field
    signed int data2;           // data field
    signed int data3;           // data field
} SA_PACKET;

// general defines
#define SA_FALSE                                        0
#define SA_TRUE                                         1

// configuration flags for SA_InitDevices
#define SA_SYNCHRONOUS_COMMUNICATION                    0
#define SA_ASYNCHRONOUS_COMMUNICATION                   1
#define SA_HARDWARE_RESET                               2

// configuration flags for SA_SetReportOnComplete_A
#define SA_NO_REPORT_ON_COMPLETE                        0
#define SA_REPORT_ON_COMPLETE                           1

// function status return types
#define SA_OK                                           0
#define SA_INITIALIZATION_ERROR                         1
#define SA_NOT_INITIALIZED_ERROR                        2
#define SA_NO_DEVICES_FOUND_ERROR                       3
#define SA_TOO_MANY_DEVICES_ERROR                       4
#define SA_INVALID_DEVICE_INDEX_ERROR                   5
#define SA_INVALID_CHANNEL_INDEX_ERROR                  6
#define SA_TRANSMIT_ERROR                               7
#define SA_WRITE_ERROR                                  8
#define SA_INVALID_PARAMETER_ERROR                      9
#define SA_READ_ERROR                                   10
#define SA_INTERNAL_ERROR                               12
#define SA_WRONG_MODE_ERROR                             13
#define SA_PROTOCOL_ERROR                               14
#define SA_TIMEOUT_ERROR                                15
#define SA_NOTIFICATION_ALREADY_SET_ERROR               16
#define SA_ID_LIST_TOO_SMALL_ERROR                      17
#define SA_DEVICE_ALREADY_ADDED_ERROR                   18
#define SA_DEVICE_NOT_FOUND_ERROR                       19
#define SA_INVALID_COMMAND_ERROR                        128
#define SA_COMMAND_NOT_SUPPORTED_ERROR                  129
#define SA_NO_SENSOR_PRESENT_ERROR                      130
#define SA_WRONG_SENSOR_TYPE_ERROR                      131
#define SA_END_STOP_REACHED_ERROR                       132
#define SA_COMMAND_OVERRIDDEN_ERROR                     133
#define SA_HV_RANGE_ERROR                               134
#define SA_TEMP_OVERHEAT_ERROR                          135
#define SA_CALIBRATION_FAILED_ERROR                     136
#define SA_REFERENCING_FAILED_ERROR                     137
#define SA_NOT_PROCESSABLE_ERROR                        138
#define SA_OTHER_ERROR                                  255

// packet types (for asynchronous mode)
#define SA_NO_PACKET_TYPE                               0
#define SA_ERROR_PACKET_TYPE                            1
#define SA_POSITION_PACKET_TYPE                         2
#define SA_ANGLE_PACKET_TYPE                            3
#define SA_COMPLETED_PACKET_TYPE                        4
#define SA_STATUS_PACKET_TYPE                           5
#define SA_CLOSED_LOOP_FREQUENCY_PACKET_TYPE            6
#define SA_SENSOR_TYPE_PACKET_TYPE                      7
#define SA_SENSOR_PRESENT_PACKET_TYPE                   8
#define SA_AMPLITUDE_PACKET_TYPE                        9
#define SA_POSITIONER_ALIGNMENT_PACKET_TYPE             10
#define SA_SAFE_DIRECTION_PACKET_TYPE                   11
#define SA_SCALE_PACKET_TYPE                            12
#define SA_PHYSICAL_POSITION_KNOWN_PACKET_TYPE          13
#define SA_CHANNEL_PROPERTY_PACKET_TYPE                 14
#define SA_SYSTEM_PROPERTY_PACKET_TYPE                  15
#define SA_INVALID_PACKET_TYPE                          255

// channel status codes
#define SA_STOPPED_STATUS                               0
#define SA_SETTING_AMPLITUDE_STATUS                     1
#define SA_MOVING_STATUS                                2
#define SA_TARGETING_STATUS                             3
#define SA_HOLDING_STATUS                               4
#define SA_CALIBRATING_STATUS                           5
#define SA_MOVING_TO_REFERENCE_STATUS                   6

// movement directions (for SA_MoveToEndStop_X and SA_SetSafeDirection_X)
#define SA_BACKWARD_DIRECTION                           0
#define SA_FORWARD_DIRECTION                            1

// auto zero (for SA_MoveToEndStop_X)
#define SA_NO_AUTO_ZERO                                 0
#define SA_AUTO_ZERO                                    1

// sensor presence (for SA_GetSensorPresent_X)
#define SA_NO_SENSOR_PRESENT                            0
#define SA_SENSOR_PRESENT                               1

// physical position known (for SA_GetPhysicalPositionKnown_X)
#define SA_PHYSICAL_POSITION_UNKNOWN                    0
#define SA_PHYSICAL_POSITION_KNOWN                      1

// sensor types (for SA_SetSensorType_S)
#define SA_M_SENSOR_TYPE                                1   // standard linear positioner
#define SA_GA_SENSOR_TYPE                               2   // goniometer with 43.5mm radius
#define SA_GB_SENSOR_TYPE                               3   // goniometer with 56.0mm raidus
#define SA_GC_SENSOR_TYPE                               4   // rotary positioner with end stops, 85mm radius
#define SA_GD_SENSOR_TYPE                               5   // goniometer with 60.5mm radius
#define SA_GE_SENSOR_TYPE                               6   // goniometer with 77.5mm raidus
#define SA_RA_SENSOR_TYPE                               7   // rotary with absolute position
#define SA_GF_SENSOR_TYPE                               8   // rotary positioner with end stops, type SR1209m
#define SA_RB_SENSOR_TYPE                               9   // rotary positioner, type SR1910m
#define SA_SR36M_SENSOR_TYPE                            10  // rotary positioner, type SR3610m
#define SA_SR36ME_SENSOR_TYPE                           11  // rotary positioner, type SR3610m, end stops
#define SA_SR50M_SENSOR_TYPE                            12  // rotary positioner, type SR5018m
#define SA_SR50ME_SENSOR_TYPE                           13  // rotary positioner, type SR5018m, end stops
#define SA_MM50_SENSOR_TYPE                             14  // magnetic linear, end stops
#define SA_G935M_SENSOR_TYPE                            15  // goniometer with 104.75mm radius
#define SA_MD_SENSOR_TYPE                               16  // like m type but with double piezo
#define SA_TT254_SENSOR_TYPE                            17  // Tip tilt sensor with 5° range
#define SA_LC_SENSOR_TYPE_CODE                          18  // distance coded linear positioner
#define SA_LR_SENSOR_TYPE_CODE                          19  // single coded rotary positioner
#define SA_LCD_SENSOR_TYPE_CODE                         20  // LC Type with double piezo
#define SA_L_SENSOR_TYPE_CODE                           21  // single coded linear positioner
#define SA_LD_SENSOR_TYPE_CODE                          22  // L Type with double piezo
#define SA_LE_SENSOR_TYPE_CODE                          23  // L Type with end stop reference
#define SA_LED_SENSOR_TYPE_CODE                         24  // LE Type with double piezo
#define SA_SL_S1I1E1_POSITIONER_TYPE_CODE               25  // Linear positioner, inductive sensor with 293nm resolution
#define SA_SL_D1I1E1_POSITIONER_TYPE_CODE               26  // Like SL...S1I1E1, but with large actuator
#define SA_SL_S1I2E2_POSITIONER_TYPE_CODE               27  // Like SL...S1I1E1, but with 73nm resolution
#define SA_SL_D1I2E2_POSITIONER_TYPE_CODE               28  // Like SL...S1I2E2, but with large actuator
#define SA_ST_S1I1E2_POSITIONER_TYPE_CODE               29  // 25.4mm mirror tip-tilt axis, inductive sensor with 73uDegree resolution
#define SA_ST_S1I2E2_POSITIONER_TYPE_CODE               37  // 50.8mm mirror tip-tilt axis, inductive sensor with 78uDegree resolution
#define SA_SG_D1L1S_POSITIONER_TYPE_CODE                30  // Goniometer, 60.5mm radius, double piezo element, L type sensor, single coded reference
#define SA_SG_D1L1E_POSITIONER_TYPE_CODE                31  // Goniometer, 60.5mm radius, double piezo element, L type sensor, end stop reference
#define SA_SG_D1L2S_POSITIONER_TYPE_CODE                32  // Goniometer, 77.5mm radius, double piezo element, L type sensor, single coded reference
#define SA_SG_D1L2E_POSITIONER_TYPE_CODE                33  // Goniometer, 77.5mm radius, double piezo element, L type sensor, end stop reference
#define SA_SG_D1M1E_POSITIONER_TYPE_CODE                34  // Goniometer, 60.5mm radius, double piezo element, M type sensor, end stop reference
#define SA_SG_D1M2E_POSITIONER_TYPE_CODE                35  // Goniometer, 77.5mm radius, double piezo element, M type sensor, end stop reference
#define SA_SI_S1L1S_POSITIONER_TYPE_CODE                36  // Iris-Diaphragm, 21.42mm radius, single piezo element, L type sensor, single coded reference

// positioner alignments (for SA_SetPositionerAlignment_X)
#define SA_HORIZONTAL_ALIGNMENT                         0
#define SA_VERTICAL_ALIGNMENT                           1

// compatibility definitions
#define SA_NO_SENSOR_TYPE                               0
#define SA_L180_SENSOR_TYPE                             1
#define SA_G180R435_SENSOR_TYPE                         2
#define SA_G180R560_SENSOR_TYPE                         3
#define SA_G50R85_SENSOR_TYPE                           4

// system properties
#define SA_INTERNAL_TEMPERATURE_PROP                    1
#define SA_INTERNAL_VOLTAGE_PROP                        2
#define SA_HARDWARE_VERSION_CODE_PROP                   3

// channel properties
#define SA_TARGET_READCHED_THRESHOLD_PROP               3
#define SA_KP_PROP                                      5
#define SA_KPD_PROP                                     6
#define SA_DEFAULT_MAX_CLOSED_LOOP_FREQUENCY_PROP       15
#define SA_ADVANCED_STEPPING_MODE_ENABLED_PROP          21


#ifdef __cplusplus
extern "C" {
#endif

/************************************************************************
*************************************************************************
**                 Section I: Initialization Functions                 **
*************************************************************************
************************************************************************/

SCU3DCONTROL_API
SA_STATUS SA_GetDLLVersion(unsigned int *version);

SCU3DCONTROL_API
SA_STATUS SA_GetAvailableDevices(unsigned int *idList, unsigned int *idListSize);

SCU3DCONTROL_API
SA_STATUS SA_AddDeviceToInitDevicesList(unsigned int deviceId);

SCU3DCONTROL_API
SA_STATUS SA_ClearInitDevicesList();

SCU3DCONTROL_API
SA_STATUS SA_InitDevices(unsigned int configuration);

SCU3DCONTROL_API
SA_STATUS SA_ReleaseDevices();

SCU3DCONTROL_API
SA_STATUS SA_GetNumberOfDevices(unsigned int *number);

SCU3DCONTROL_API
SA_STATUS SA_GetDeviceID(SA_INDEX deviceIndex, unsigned int *deviceId);

SCU3DCONTROL_API
SA_STATUS SA_GetDeviceFirmwareVersion(SA_INDEX deviceIndex, unsigned int *version);


/************************************************************************
*************************************************************************
**        Section IIa:  Functions for SYNCHRONOUS communication        **
*************************************************************************
************************************************************************/

/*************************************************
**************************************************
**    Section IIa.1: Configuration Functions    **
**************************************************
*************************************************/
SCU3DCONTROL_API
SA_STATUS SA_SetClosedLoopMaxFrequency_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int frequency);

SCU3DCONTROL_API
SA_STATUS SA_GetClosedLoopMaxFrequency_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int *frequency);

SCU3DCONTROL_API
SA_STATUS SA_SetZero_S(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_GetSensorPresent_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int *present);

SCU3DCONTROL_API
SA_STATUS SA_SetSensorType_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int type);

SCU3DCONTROL_API
SA_STATUS SA_GetSensorType_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int *type);

SCU3DCONTROL_API
SA_STATUS SA_SetPositionerAlignment_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int alignment, unsigned int forwardAmplitude, unsigned int backwardAmplitude);

SCU3DCONTROL_API
SA_STATUS SA_GetPositionerAlignment_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int *alignment, unsigned int *forwardAmplitude, unsigned int *backwardAmplitude);

SCU3DCONTROL_API
SA_STATUS SA_SetSafeDirection_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int direction);

SCU3DCONTROL_API
SA_STATUS SA_GetSafeDirection_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int *direction);

SCU3DCONTROL_API
SA_STATUS SA_SetScale_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int scale, unsigned int inverted);

SCU3DCONTROL_API
SA_STATUS SA_GetScale_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int *scale, unsigned int *inverted);

SCU3DCONTROL_API
SA_STATUS SA_SetChannelProperty_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int key, signed int value);

SCU3DCONTROL_API
SA_STATUS SA_GetChannelProperty_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int key, signed int *value);

SCU3DCONTROL_API
SA_STATUS SA_SetSystemProperty_S(SA_INDEX deviceIndex, signed int key, signed int value);

SCU3DCONTROL_API
SA_STATUS SA_GetSystemProperty_S(SA_INDEX deviceIndex, signed int key, signed int *value);


/*************************************************
**************************************************
**  Section IIa.2: Movement Control Functions   **
**************************************************
*************************************************/
SCU3DCONTROL_API
SA_STATUS SA_MoveStep_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int steps, unsigned int amplitude, unsigned int frequency);

SCU3DCONTROL_API
SA_STATUS SA_SetAmplitude_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int amplitude);

SCU3DCONTROL_API
SA_STATUS SA_MovePositionAbsolute_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int position, unsigned int holdTime);

SCU3DCONTROL_API
SA_STATUS SA_MovePositionRelative_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int diff, unsigned int holdTime);

SCU3DCONTROL_API
SA_STATUS SA_MoveAngleAbsolute_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int angle, signed int revolution, unsigned int holdTime);

SCU3DCONTROL_API
SA_STATUS SA_MoveAngleRelative_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int angleDiff, signed int revolutionDiff, unsigned int holdTime);

SCU3DCONTROL_API
SA_STATUS SA_CalibrateSensor_S(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_MoveToReference_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int holdTime, unsigned int autoZero);

SCU3DCONTROL_API
SA_STATUS SA_MoveToEndStop_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int direction, unsigned int holdTime, unsigned int autoZero);

SCU3DCONTROL_API
SA_STATUS SA_Stop_S(SA_INDEX deviceIndex, SA_INDEX channelIndex);

/************************************************
*************************************************
**  Section IIa.3: Channel Feedback Functions  **
*************************************************
*************************************************/
SCU3DCONTROL_API
SA_STATUS SA_GetStatus_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int *status);

SCU3DCONTROL_API
SA_STATUS SA_GetAmplitude_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int *amplitude);

SCU3DCONTROL_API
SA_STATUS SA_GetPosition_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int *position);

SCU3DCONTROL_API
SA_STATUS SA_GetAngle_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int *angle, signed int *revolution);

SCU3DCONTROL_API
SA_STATUS SA_GetPhysicalPositionKnown_S(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int *known);

/************************************************************************
*************************************************************************
**       Section IIb:  Functions for ASYNCHRONOUS communication        **
*************************************************************************
************************************************************************/

/*************************************************
**************************************************
**    Section IIb.1: Configuration Functions    **
**************************************************
*************************************************/
SCU3DCONTROL_API
SA_STATUS SA_SetClosedLoopMaxFrequency_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int frequency);

SCU3DCONTROL_API
SA_STATUS SA_GetClosedLoopMaxFrequency_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_SetZero_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_GetSensorPresent_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_SetSensorType_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int type);

SCU3DCONTROL_API
SA_STATUS SA_GetSensorType_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_SetPositionerAlignment_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int alignment, unsigned int forwardAmplitude, unsigned int backwardAmplitude);

SCU3DCONTROL_API
SA_STATUS SA_GetPositionerAlignment_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_SetSafeDirection_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int direction);

SCU3DCONTROL_API
SA_STATUS SA_GetSafeDirection_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_SetScale_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int scale, unsigned int inverted);

SCU3DCONTROL_API
SA_STATUS SA_GetScale_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_SetReportOnComplete_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int report);

SCU3DCONTROL_API
SA_STATUS SA_SetChannelProperty_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int key, signed int value);

SCU3DCONTROL_API
SA_STATUS SA_GetChannelProperty_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int key);

SCU3DCONTROL_API
SA_STATUS SA_SetSystemProperty_A(SA_INDEX deviceIndex, signed int key, signed int value);

SCU3DCONTROL_API
SA_STATUS SA_GetSystemProperty_A(SA_INDEX deviceIndex, signed int key);

/*************************************************
**************************************************
**  Section IIb.2: Movement Control Functions   **
**************************************************
*************************************************/
SCU3DCONTROL_API
SA_STATUS SA_MoveStep_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int steps, unsigned int amplitude, unsigned int frequency);

SCU3DCONTROL_API
SA_STATUS SA_SetAmplitude_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int amplitude);

SCU3DCONTROL_API
SA_STATUS SA_MovePositionAbsolute_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int position, unsigned int holdTime);

SCU3DCONTROL_API
SA_STATUS SA_MovePositionRelative_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int diff, unsigned int holdTime);

SCU3DCONTROL_API
SA_STATUS SA_MoveAngleAbsolute_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int angle, signed int revolution, unsigned int holdTime);

SCU3DCONTROL_API
SA_STATUS SA_MoveAngleRelative_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, signed int angleDiff, signed int revolutionDiff, unsigned int holdTime);

SCU3DCONTROL_API
SA_STATUS SA_CalibrateSensor_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_MoveToReference_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int holdTime, unsigned int autoZero);

SCU3DCONTROL_API
SA_STATUS SA_MoveToEndStop_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int direction, unsigned int holdTime, unsigned int autoZero);

SCU3DCONTROL_API
SA_STATUS SA_Stop_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

/************************************************
*************************************************
**  Section IIb.3: Channel Feedback Functions  **
*************************************************
************************************************/
SCU3DCONTROL_API
SA_STATUS SA_GetStatus_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_GetAmplitude_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_GetPosition_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_GetAngle_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

SCU3DCONTROL_API
SA_STATUS SA_GetPhysicalPositionKnown_A(SA_INDEX deviceIndex, SA_INDEX channelIndex);

/******************
* Answer retrieval
******************/
SCU3DCONTROL_API
SA_STATUS SA_SetReceiveNotification_A(SA_INDEX deviceIndex, void *event);

SCU3DCONTROL_API
SA_STATUS SA_ReceiveNextPacket_A(SA_INDEX deviceIndex, unsigned int timeout, SA_PACKET *packet);

SCU3DCONTROL_API
SA_STATUS SA_ReceiveNextPacketIfChannel_A(SA_INDEX deviceIndex, SA_INDEX channelIndex, unsigned int timeout, SA_PACKET *packet);

SCU3DCONTROL_API
SA_STATUS SA_LookAtNextPacket_A(SA_INDEX deviceIndex, unsigned int timeout, SA_PACKET *packet);

SCU3DCONTROL_API
SA_STATUS SA_DiscardPacket_A(SA_INDEX deviceIndex);


#ifdef __cplusplus
}
#endif

#endif /* HCU3DCONTROL_H */

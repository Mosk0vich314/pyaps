//
//
//		Header for LUCI_10.dll
//
//		for use with LUCI-10 USB Interface
//
//	
//		Version		1.10		
//		Date		18.03.10
//		Author		Christian Grundel
//
//		(c) FEMTO Messtechnik GmbH Berlin/Germany 2010		
//
//		www.femto.de
//
//		


#ifndef _FEMTO_LUCI10_H_
#define _FEMTO_LUCI10_H_

//	Error return codes
#define LUCI_OK				0	//	Function returns successful
#define LUCI_ERROR_INDEX	-1	//	Error, selected LUCI-10 not in list
#define LUCI_ERROR_HID		-2	//	Error, LUCI-10 doesnt respond

//	return value of GetStatusPin
#define	STATUS_PIN_LOW		0	//	probed Pin is logical 0	(TTL low  0 Volt)
#define STATUS_PIN_HIGH		1	//	probed Pin is logical 1	(TTL high 5 Volt)

//	name of the DLL to be loaded
#define FEMTO_LUCI10_DLL "LUCI_10"

//	Implement the DLL export/import mechanism and allow a C-written program
//	to use this DLL
#ifdef	FEMTO_LUCI10_EXPORTS
#define FEMTO_LUCI10_API extern "C" __declspec(dllexport)
#else
#define FEMTO_LUCI10_API extern "C" __declspec(dllimport)
#endif


//
//	list of exported functions
//
FEMTO_LUCI10_API int EnumerateUsbDevices();
FEMTO_LUCI10_API int LedOn(int index);
FEMTO_LUCI10_API int LedOff(int index);
FEMTO_LUCI10_API int ReadAdapterID(int index, int *id);
FEMTO_LUCI10_API int WriteAdapterID(int index, int id);
FEMTO_LUCI10_API int FirmwareUpdate(int index);
FEMTO_LUCI10_API int WriteData(int index, int data_low, int data_high);
FEMTO_LUCI10_API int GetStatusPin5(int index, int *status);
FEMTO_LUCI10_API int GetStatusPin6(int index, int *status);
FEMTO_LUCI10_API int GetStatusPin7(int index, int *status);
FEMTO_LUCI10_API int GetProductString(int index, unsigned char *string, int size);


#endif  // _FEMTO_LUCI10_H_
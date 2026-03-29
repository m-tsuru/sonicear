#pragma once
#include "Headphones.h"
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Battery
int mdrHeadphonesGetBatteryLeft(MDRHeadphones* hp, uint8_t* level, uint8_t* charging);
int mdrHeadphonesGetBatteryRight(MDRHeadphones* hp, uint8_t* level, uint8_t* charging);
int mdrHeadphonesGetBatteryCase(MDRHeadphones* hp, uint8_t* level, uint8_t* charging);

// NC/ASM
int mdrHeadphonesGetNcAsmEnabled(MDRHeadphones* hp, int* enabled);
int mdrHeadphonesSetNcAsmEnabled(MDRHeadphones* hp, int enabled);
int mdrHeadphonesGetNcAsmMode(MDRHeadphones* hp, int* mode);
int mdrHeadphonesSetNcAsmMode(MDRHeadphones* hp, int mode);
int mdrHeadphonesGetAmbientLevel(MDRHeadphones* hp, int* level);
int mdrHeadphonesSetAmbientLevel(MDRHeadphones* hp, int level);
int mdrHeadphonesGetFocusOnVoice(MDRHeadphones* hp, int* enabled);
int mdrHeadphonesSetFocusOnVoice(MDRHeadphones* hp, int enabled);

// EQ
int mdrHeadphonesGetEqPreset(MDRHeadphones* hp, int* preset);
int mdrHeadphonesSetEqPreset(MDRHeadphones* hp, int preset);
int mdrHeadphonesGetClearBass(MDRHeadphones* hp, int* level);
int mdrHeadphonesSetClearBass(MDRHeadphones* hp, int level);
int mdrHeadphonesGetEqBands(MDRHeadphones* hp, int* bands, int* count);
int mdrHeadphonesSetEqBands(MDRHeadphones* hp, const int* bands, int count);

// DSEE
int mdrHeadphonesGetUpscalingEnabled(MDRHeadphones* hp, int* enabled);
int mdrHeadphonesSetUpscalingEnabled(MDRHeadphones* hp, int enabled);

// Audio Priority
int mdrHeadphonesGetAudioPriority(MDRHeadphones* hp, int* mode);
int mdrHeadphonesSetAudioPriority(MDRHeadphones* hp, int mode);

// Device Info (returns length written, or < 0 on error)
int mdrHeadphonesGetModelName(MDRHeadphones* hp, char* buf, int bufSize);
int mdrHeadphonesGetFWVersion(MDRHeadphones* hp, char* buf, int bufSize);
int mdrHeadphonesGetUniqueId(MDRHeadphones* hp, char* buf, int bufSize);
int mdrHeadphonesGetAudioCodec(MDRHeadphones* hp, int* codec);

// Playback
int mdrHeadphonesGetVolume(MDRHeadphones* hp, int* volume);
int mdrHeadphonesSetVolume(MDRHeadphones* hp, int volume);
int mdrHeadphonesGetPlaybackStatus(MDRHeadphones* hp, int* status);
int mdrHeadphonesSetPlaybackControl(MDRHeadphones* hp, int control);
int mdrHeadphonesGetTrackTitle(MDRHeadphones* hp, char* buf, int bufSize);
int mdrHeadphonesGetTrackArtist(MDRHeadphones* hp, char* buf, int bufSize);
int mdrHeadphonesGetTrackAlbum(MDRHeadphones* hp, char* buf, int bufSize);

// Speak to Chat
int mdrHeadphonesGetSpeakToChatEnabled(MDRHeadphones* hp, int* enabled);
int mdrHeadphonesSetSpeakToChatEnabled(MDRHeadphones* hp, int enabled);

// General Settings
int mdrHeadphonesGetMultipointEnabled(MDRHeadphones* hp, int* enabled);
int mdrHeadphonesSetMultipointEnabled(MDRHeadphones* hp, int enabled);
int mdrHeadphonesGetAutoPauseEnabled(MDRHeadphones* hp, int* enabled);
int mdrHeadphonesSetAutoPauseEnabled(MDRHeadphones* hp, int enabled);

// Power
int mdrHeadphonesSetShutdown(MDRHeadphones* hp);

#ifdef __cplusplus
}
#endif

#include <mdr-c/HeadphonesProperties.h>
#include <mdr/Headphones.hpp>
#include <cstring>
#include <algorithm>

static mdr::MDRHeadphones* cast(MDRHeadphones* hp)
{
    return reinterpret_cast<mdr::MDRHeadphones*>(hp);
}

static int copyString(const mdr::String& src, char* buf, int bufSize)
{
    if (!buf || bufSize <= 0)
        return -1;
    int len = static_cast<int>(std::min(src.size(), static_cast<size_t>(bufSize - 1)));
    std::memcpy(buf, src.data(), len);
    buf[len] = '\0';
    return len;
}

// Battery

int mdrHeadphonesGetBatteryLeft(MDRHeadphones* hp, uint8_t* level, uint8_t* charging)
{
    auto* h = cast(hp);
    *level = h->mBatteryL.level;
    *charging = static_cast<uint8_t>(h->mBatteryL.charging);
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetBatteryRight(MDRHeadphones* hp, uint8_t* level, uint8_t* charging)
{
    auto* h = cast(hp);
    *level = h->mBatteryR.level;
    *charging = static_cast<uint8_t>(h->mBatteryR.charging);
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetBatteryCase(MDRHeadphones* hp, uint8_t* level, uint8_t* charging)
{
    auto* h = cast(hp);
    *level = h->mBatteryCase.level;
    *charging = static_cast<uint8_t>(h->mBatteryCase.charging);
    return MDR_RESULT_OK;
}

// NC/ASM

int mdrHeadphonesGetNcAsmEnabled(MDRHeadphones* hp, int* enabled)
{
    *enabled = cast(hp)->mNcAsmEnabled.current ? 1 : 0;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetNcAsmEnabled(MDRHeadphones* hp, int enabled)
{
    cast(hp)->mNcAsmEnabled.desired = enabled != 0;
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetNcAsmMode(MDRHeadphones* hp, int* mode)
{
    *mode = static_cast<int>(cast(hp)->mNcAsmMode.current);
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetNcAsmMode(MDRHeadphones* hp, int mode)
{
    cast(hp)->mNcAsmMode.desired = static_cast<mdr::v2::t1::NcAsmMode>(mode);
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetAmbientLevel(MDRHeadphones* hp, int* level)
{
    *level = cast(hp)->mNcAsmAmbientLevel.current;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetAmbientLevel(MDRHeadphones* hp, int level)
{
    cast(hp)->mNcAsmAmbientLevel.desired = level;
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetFocusOnVoice(MDRHeadphones* hp, int* enabled)
{
    *enabled = cast(hp)->mNcAsmFocusOnVoice.current ? 1 : 0;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetFocusOnVoice(MDRHeadphones* hp, int enabled)
{
    cast(hp)->mNcAsmFocusOnVoice.desired = enabled != 0;
    return MDR_RESULT_OK;
}

// EQ

int mdrHeadphonesGetEqPreset(MDRHeadphones* hp, int* preset)
{
    *preset = static_cast<int>(cast(hp)->mEqPresetId.current);
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetEqPreset(MDRHeadphones* hp, int preset)
{
    cast(hp)->mEqPresetId.desired = static_cast<mdr::v2::t1::EqPresetId>(preset);
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetClearBass(MDRHeadphones* hp, int* level)
{
    *level = cast(hp)->mEqClearBass.current;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetClearBass(MDRHeadphones* hp, int level)
{
    cast(hp)->mEqClearBass.desired = level;
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetEqBands(MDRHeadphones* hp, int* bands, int* count)
{
    auto* h = cast(hp);
    const auto& currentBands = h->mEqConfig.current;
    int n = static_cast<int>(currentBands.size());
    if (bands) {
        int toCopy = std::min(n, *count);
        for (int i = 0; i < toCopy; i++) {
            bands[i] = currentBands[i];
        }
        *count = toCopy;
    } else {
        *count = n;
    }
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetEqBands(MDRHeadphones* hp, const int* bands, int count)
{
    auto* h = cast(hp);
    mdr::Vector<int> newBands(count);
    for (int i = 0; i < count; i++) {
        newBands[i] = bands[i];
    }
    h->mEqConfig.desired = newBands;
    return MDR_RESULT_OK;
}

// DSEE

int mdrHeadphonesGetUpscalingEnabled(MDRHeadphones* hp, int* enabled)
{
    *enabled = cast(hp)->mUpscalingEnabled.current ? 1 : 0;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetUpscalingEnabled(MDRHeadphones* hp, int enabled)
{
    cast(hp)->mUpscalingEnabled.desired = enabled != 0;
    return MDR_RESULT_OK;
}

// Audio Priority

int mdrHeadphonesGetAudioPriority(MDRHeadphones* hp, int* mode)
{
    *mode = static_cast<int>(cast(hp)->mAudioPriorityMode.current);
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetAudioPriority(MDRHeadphones* hp, int mode)
{
    cast(hp)->mAudioPriorityMode.desired = static_cast<mdr::v2::t1::PriorMode>(mode);
    return MDR_RESULT_OK;
}

// Device Info

int mdrHeadphonesGetModelName(MDRHeadphones* hp, char* buf, int bufSize)
{
    return copyString(cast(hp)->mModelName, buf, bufSize);
}

int mdrHeadphonesGetFWVersion(MDRHeadphones* hp, char* buf, int bufSize)
{
    return copyString(cast(hp)->mFWVersion, buf, bufSize);
}

int mdrHeadphonesGetUniqueId(MDRHeadphones* hp, char* buf, int bufSize)
{
    return copyString(cast(hp)->mUniqueId, buf, bufSize);
}

int mdrHeadphonesGetAudioCodec(MDRHeadphones* hp, int* codec)
{
    *codec = static_cast<int>(cast(hp)->mAudioCodec);
    return MDR_RESULT_OK;
}

// Playback

int mdrHeadphonesGetVolume(MDRHeadphones* hp, int* volume)
{
    *volume = cast(hp)->mPlayVolume.current;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetVolume(MDRHeadphones* hp, int volume)
{
    cast(hp)->mPlayVolume.desired = volume;
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetPlaybackStatus(MDRHeadphones* hp, int* status)
{
    *status = static_cast<int>(cast(hp)->mPlayPause);
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetPlaybackControl(MDRHeadphones* hp, int control)
{
    cast(hp)->mPlayControl.desired = static_cast<mdr::v2::t1::PlaybackControl>(control);
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetTrackTitle(MDRHeadphones* hp, char* buf, int bufSize)
{
    return copyString(cast(hp)->mPlayTrackTitle, buf, bufSize);
}

int mdrHeadphonesGetTrackArtist(MDRHeadphones* hp, char* buf, int bufSize)
{
    return copyString(cast(hp)->mPlayTrackArtist, buf, bufSize);
}

int mdrHeadphonesGetTrackAlbum(MDRHeadphones* hp, char* buf, int bufSize)
{
    return copyString(cast(hp)->mPlayTrackAlbum, buf, bufSize);
}

// Speak to Chat

int mdrHeadphonesGetSpeakToChatEnabled(MDRHeadphones* hp, int* enabled)
{
    *enabled = cast(hp)->mSpeakToChatEnabled.current ? 1 : 0;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetSpeakToChatEnabled(MDRHeadphones* hp, int enabled)
{
    cast(hp)->mSpeakToChatEnabled.desired = enabled != 0;
    return MDR_RESULT_OK;
}

// General Settings

int mdrHeadphonesGetMultipointEnabled(MDRHeadphones* hp, int* enabled)
{
    *enabled = cast(hp)->mGsParamBool2.current ? 1 : 0;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetMultipointEnabled(MDRHeadphones* hp, int enabled)
{
    cast(hp)->mGsParamBool2.desired = enabled != 0;
    return MDR_RESULT_OK;
}

int mdrHeadphonesGetAutoPauseEnabled(MDRHeadphones* hp, int* enabled)
{
    *enabled = cast(hp)->mAutoPauseEnabled.current ? 1 : 0;
    return MDR_RESULT_OK;
}

int mdrHeadphonesSetAutoPauseEnabled(MDRHeadphones* hp, int enabled)
{
    cast(hp)->mAutoPauseEnabled.desired = enabled != 0;
    return MDR_RESULT_OK;
}

// Power

int mdrHeadphonesSetShutdown(MDRHeadphones* hp)
{
    cast(hp)->mShutdown.desired = true;
    return MDR_RESULT_OK;
}

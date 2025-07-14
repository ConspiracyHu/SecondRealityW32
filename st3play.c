/*
** st3play v1.01 - 7th of August 2020 - https://16-bits.org
** =======================================================
**              - NOT BIG ENDIAN SAFE! -
**
** Very accurate C port of Scream Tracker 3.21's replayer,
** by Olav "8bitbubsy" Sørensen. Using the original asm source codes
** by Sami "PSI" Tammilehto (Future Crew) with permission.
**
** This replayer supports 16-bit samples and >64K sample lengths (which ST3 doesn't)!
**
** You need to link winmm.lib for this to compile (-lwinmm).
** Alternatively, you can change out the mixer functions at the bottom with
** your own for your OS.
**
** Example of st3play usage:
** #include "st3play.h"
** #include "songdata.h"
**
** st3play_PlaySong(songData, songDataLength, true, 48000);
** mainLoop();
** st3play_Close();
**
** To turn a song into an include file like in the example, you can use my
** win32 bin2h tool from here: https://16-bits.org/etc/bin2h.zip
**
** Changes in v1.01:
** - setspd() is now more accurate
**
** Changes in v1.00:
** - Cubic spline interpolation changed from 3-tap to 4-tap
**
** Changes in v0.99:
** - Added st3play_GetMasterVol()
**
** Changes in v0.98:
** - Slightly finer volume precision during mixing
** - Added 1-bit triangular dithering to mixed audio output
**
** Changes in v0.97:
** - Kill voice when empty instruments are triggered (non-ST3 behavior)
** - Added Xxx 7-bit panning command (non-ST3)
** - Added surround effect (XA4/S90/S91, non-ST3)
** - Always mix in stereo regardless of stereo flag (some songs with
**   panning commands have the stereo flag cleared...)
**
** Changes in v0.96:
** - Effect Kxx/Lxx didn't remember the last vib/slide effect value properly
** - Fixed some bugs in the "new note"-handler aka. doamiga()
** - Fixed some bugs in effect Qxy (Retrigger Note)
** - Added ST3.21 500-byte loop unrolling, which can make the audio mixer faster
**   for old CPUs on tight sample-loops. It also adds a fade-out at the end of
**   non-looping samples, like ST3.
**
** Changes in v0.94a:
** - Code cleanup
**
** Changes in v0.94:
** - Small mixer optimization for very tight sample loops
**
** Changes in v0.93:
** - Code cleanup (uses the "bool" type now, spaces -> tabs, comment style change)
**
** Changes in v0.92:
** - GUS mixing volume was slightly too loud
** - Read sample c2spd as 32-bit int and clamp to 65535
** - Use a table for low-periods-to-rate look-ups (prevents a ton of divs)
** - st3play can now mix at higher output rates than 65535Hz
**
** Changes in v0.91:
** - Resampling interpolation was changed from 2-tap linear to 3-tap quadratic
**   for less muddy sound.
**
** Changes in v0.90:
** - Removed the soundcard selection in st3play_PlaySong(). Now it auto-scans
**   for whatever soundcard is appropriate. If custom pannings are found,
**   force to GUS.
** - Mastermul is forced to 48 in GUS mode (fixes clipping on some S3Ms)
** - Fixed some errors in the GUS panning table
** - Fixed a bug with panning in SB Pro mode
**
** Changes in v0.89:
** - Bugfix: The last pattern in the order list would not be played!
**
** Changes in v0.88:
** - Rewrote the S3M loader
**
** Changes in v0.87:
** - More audio channel mixer optimizations
**
** Changes in v0.86:
** - Fixed GUS panning positions (now uses a table)
**
** Changes in v0.85:
** - Removed all 64-bit calculations, and made the mixer slightly faster
** - Some code was rewritten to be more correctly ported from the original code
** - st3play_SetMasterVol() now sets mixing vol. instead of the song's mastervol
** - Small code cleanup
**
** Changes in v0.84:
** - Linear interpolation is done with 16-bit fractional precision instead of
**   15-bit.
**
** Changes in v0.83:
** - Prevent stuck loop if order list contains separators (254) only
** - Added a function to retrieve song name
** - Added a function to set master volume (0..256)
**
** Changes in v0.82:
** - Fixed an error in loop wrapping in the audio channel mixer
** - Audio channel mixer is now optimized and fast!
** - WinMM mixer has been rewritten to be safe (don't use syscalls in callback)
** - Some small changes to the st3play functions (easier to use and safer!)
** - Removed all non-ST3 stuff (replayer should act identical to ST3 now).
**   You should use another replayer if you want the non-ST3 features.
** - Some small fixes to the replayer and mixer functions
*/

/* st3play.h:

#pragma once

#include <stdint.h>
#include <stdbool.h>

bool st3play_PlaySong(const uint8_t *moduleData, uint32_t dataLength, bool useInterpolationFlag, uint32_t audioFreq);
void st3play_Close(void);
void st3play_PauseSong(bool flag); // true/false
void st3play_TogglePause(void);
void st3play_SetMasterVol(uint16_t vol); // 0..256
uint16_t st3play_GetMasterVol(void); // 0..256
void st3play_SetInterpolation(bool flag); // true/false
char *st3play_GetSongName(void); // max 28 chars (29 witrh '\0'), string is in code page 437
uint32_t st3play_GetMixerTicks(void); // returns the amount of milliseconds of mixed audio (not realtime)
uint16_t st3play_GetOrder(void); // 0..256
uint16_t st3play_GetRow(void); // 0..256
*/

//#define FORCE_SOUNDCARD_TYPE SOUNDCARD_SBPRO
//#define FORCE_SOUNDCARD_TYPE SOUNDCARD_GUS

//#define USE_ST3_GUS_TEMPO

#define MIX_BUF_SAMPLES 4096

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#define C2FREQ 8363

#define CLAMP(x, low, high) (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

// fast 32-bit -> 16-bit clamp
#define CLAMP16(i) if ((int16_t)(i) != i) i = 0x7FFF ^ (i >> 31)

enum
{
	SOUNDCARD_GUS = 0,
	SOUNDCARD_SBPRO = 1,

	PATT_SEP = 254,
	PATT_END = 255,
};

typedef void (*mixRoutine)(void *, int32_t);

typedef struct
{
	int8_t *memseg, *memsegOrig, vol;
	uint8_t flags, type;
	uint16_t c2spd;
	uint32_t length, lbeg, lend, lend512;
} ins_t;

typedef struct
{
	int8_t aorgvol, avol;
	uint8_t apanpos;
	bool atreon, surround;
	uint8_t channelnum, amixtype, achannelused, aglis, atremor, atrigcnt, anotecutcnt, anotedelaycnt;
	uint8_t avibtretype, note, ins, vol, cmd, info, lastins, lastnote, alastnfo, alasteff, alasteff1;
	int16_t avibcnt, asldspd, aspd, aorgspd;
	uint16_t astartoffset, astartoffset00, ac2spd;
} chn_t;

typedef struct
{
	const int8_t *m_base8;
	const int16_t *m_base16;
	bool m_loopflag;
	int32_t m_vol_l, m_vol_r;
	uint32_t m_pos, m_end, m_origend, m_loopbeg, m_looplen, m_posfrac, m_speed, m_speedrev;
	uint32_t lastMixFuncOffset;
	ins_t *insPtr;
	volatile void (*m_mixfunc)(void *, int32_t); // function pointer to mix routine
} voice_t;

typedef void (*effect_routine)(chn_t *ch);

#define INITIAL_DITHER_SEED 0x12345000

static char songname[28 + 1];
static volatile bool musicPaused, interpolationFlag;
static bool oldstvib, fastvolslide, amigalimits;
static int8_t **smpPtrs, volslidetype, patterndelay, patloopcount, lastachannelused;
static uint8_t order[256], chnsettings[32], *patdata[100], *np_patseg;
static uint8_t musicmax, soundcardtype, breakpat, startrow, musiccount;
static int16_t jmptoord, np_ord, np_row, np_pat, np_patoff, patloopstart, jumptorow, globalvol, aspdmin, aspdmax;
static uint16_t useglobalvol, patmusicrand, ordNum, insNum, patNum;
static int32_t mastermul, mastervol = 256, mixingVol, samplesLeft, soundBufferSize, *mixBufferL, *mixBufferR;
static int32_t prngStateL, prngStateR, randSeed = INITIAL_DITHER_SEED;
static uint32_t samplesPerTick, audioRate, sampleCounter, np_zframe;
static chn_t chn[32];
static voice_t voice[32], tmpGUSVoices[32];
static ins_t ins[100];
static mixRoutine mixRoutineTable[8];
static double dPer2HzDiv;

static const int8_t retrigvoladd[32] =
{
	0, -1, -2, -4, -8,-16,  0,  0,
	0,  1,  2,  4,  8, 16,  0,  0,
	0,  0,  0,  0,  0,  0, 10,  8,
	0,  0,  0,  0,  0,  0, 24, 32
};

static const uint8_t octavediv[16] = 
{
	0, 1, 2, 3, 4, 5, 6, 7,

	// overflow data from "xvol_amiga" table
	0, 5, 11, 17, 27, 32, 42, 47
};

static const int16_t notespd[16] =
{
	1712 * 16, 1616 * 16, 1524 * 16,
	1440 * 16, 1356 * 16, 1280 * 16,
	1208 * 16, 1140 * 16, 1076 * 16,
	1016 * 16,  960 * 16,  907 * 16,
	1712 * 8,

	// overflow data from "adlibiadd" table
	0x0100, 0x0802, 0x0A09
};

static const int16_t vibsin[64] =
{
	 0x00, 0x18, 0x31, 0x4A, 0x61, 0x78, 0x8D, 0xA1,
	 0xB4, 0xC5, 0xD4, 0xE0, 0xEB, 0xF4, 0xFA, 0xFD,
	 0xFF, 0xFD, 0xFA, 0xF4, 0xEB, 0xE0, 0xD4, 0xC5,
	 0xB4, 0xA1, 0x8D, 0x78, 0x61, 0x4A, 0x31, 0x18,
	 0x00,-0x18,-0x31,-0x4A,-0x61,-0x78,-0x8D,-0xA1,
	-0xB4,-0xC5,-0xD4,-0xE0,-0xEB,-0xF4,-0xFA,-0xFD,
	-0xFF,-0xFD,-0xFA,-0xF4,-0xEB,-0xE0,-0xD4,-0xC5,
	-0xB4,-0xA1,-0x8D,-0x78,-0x61,-0x4A,-0x31,-0x18
};

static const uint8_t vibsqu[64] =
{
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

static const int16_t vibramp[64] =
{
	   0, -248,-240,-232,-224,-216,-208,-200,
	-192, -184,-176,-168,-160,-152,-144,-136,
	-128, -120,-112,-104, -96, -88, -80, -72,
	 -64,  -56, -48, -40, -32, -24, -16,  -8,
	   0,    8,  16,  24,  32,  40,  48,  56,
	  64,   72,  80,  88,  96, 104, 112, 120,
	 128,  136, 144, 152, 160, 168, 176, 184,
	 192,  200, 208, 216, 224, 232, 240, 248
};

extern const int16_t fastSincTable[256 * 4];

static void voiceCut(uint8_t voiceNumber);
static void voiceSetVolume(uint8_t voiceNumber, int32_t vol, int32_t pan);

static void s_ret(chn_t *ch);
static void s_setgliss(chn_t *ch);
static void s_setfinetune(chn_t *ch);
static void s_setvibwave(chn_t *ch);
static void s_settrewave(chn_t *ch);
static void s_settrewave(chn_t *ch);
static void s_setpanpos(chn_t *ch);
static void s_soundcntr(chn_t *ch);
static void s_stereocntr(chn_t *ch);
static void s_patloop(chn_t *ch);
static void s_notecut(chn_t *ch);
static void s_notecutb(chn_t *ch);
static void s_notedelay(chn_t *ch);
static void s_notedelayb(chn_t *ch);
static void s_patterdelay(chn_t *ch);
static void s_setspeed(chn_t *ch);
static void s_jmpto(chn_t *ch);
static void s_break(chn_t *ch);
static void s_volslide(chn_t *ch);
static void s_slidedown(chn_t *ch);
static void s_slideup(chn_t *ch);
static void s_toneslide(chn_t *ch);
static void s_vibrato(chn_t *ch);
static void s_tremor(chn_t *ch);
static void s_arp(chn_t *ch);
static void s_vibvol(chn_t *ch);
static void s_tonevol(chn_t *ch);
static void s_retrig(chn_t *ch);
static void s_tremolo(chn_t *ch);
static void s_set7bitpan(chn_t *ch);
static void s_scommand1(chn_t *ch);
static void s_scommand2(chn_t *ch);
static void s_settempo(chn_t *ch);
static void s_finevibrato(chn_t *ch);
static void s_setgvol(chn_t *ch);

static bool openMixer(uint32_t audioFreq);
static void closeMixer(void);

static const effect_routine ssoncejmp[16] =
{
	s_ret,         // 0
	s_setgliss,    // 1
	s_setfinetune, // 2
	s_setvibwave,  // 3
	s_settrewave,  // 4
	s_ret,         // 5
	s_ret,         // 6
	s_ret,         // 7
	s_setpanpos,   // 8
	s_soundcntr,   // 9 (non-ST3)
	s_stereocntr,  // A
	s_patloop,     // B
	s_notecut,     // C
	s_notedelay,   // D
	s_patterdelay, // E
	s_ret          // F
};

static const effect_routine ssotherjmp[16] =
{
	s_ret,        // 0
	s_ret,        // 1
	s_ret,        // 2
	s_ret,        // 3
	s_ret,        // 4
	s_ret,        // 5
	s_ret,        // 6
	s_ret,        // 7
	s_ret,        // 8
	s_ret,        // 9
	s_ret,        // A
	s_ret,        // B
	s_notecutb,   // C
	s_notedelayb, // D
	s_ret,        // E
	s_ret         // F
};

static const effect_routine soncejmp[27] =
{
	s_ret,       // .
	s_setspeed,  // A
	s_jmpto,     // B
	s_break,     // C
	s_volslide,  // D
	s_slidedown, // E
	s_slideup,   // F
	s_ret,       // G
	s_ret,       // H
	s_tremor,    // I
	s_arp,       // J
	s_ret,       // K
	s_ret,       // L
	s_ret,       // M
	s_ret,       // N
	s_ret,       // O - handled in doamiga()
	s_ret,       // P
	s_retrig,    // Q
	s_ret,       // R
	s_scommand1, // S
	s_settempo,  // T
	s_ret,       // U
	s_ret,       // V
	s_ret,       // W
	s_set7bitpan,// X (non-ST3)
	s_ret,       // Y
	s_ret        // Z
};

static const effect_routine sotherjmp[27] =
{
	s_ret,         // .
	s_ret,         // A
	s_ret,         // B
	s_ret,         // C
	s_volslide,    // D
	s_slidedown,   // E
	s_slideup,     // F
	s_toneslide,   // G
	s_vibrato,     // H
	s_tremor,      // I
	s_arp,         // J
	s_vibvol,      // K
	s_tonevol,     // L
	s_ret,         // M
	s_ret,         // N
	s_ret,         // O
	s_ret,         // P
	s_retrig,      // Q
	s_tremolo,     // R
	s_scommand2,   // S
	s_ret,         // T
	s_finevibrato, // U
	s_setgvol,     // V
	s_ret,         // W
	s_ret,         // X
	s_ret,         // Y
	s_ret          // Z
};

// CODE START

static bool optimizeSampleDatasForMixer(void)
{
#define SAMPLE_UNROLL_BYTES (512+2) /* ST3.21 value + 2 more for resampling interpolation window size */

	for (uint32_t i = 0; i < 100; i++)
	{
		ins_t *inst = &ins[i];
		if (inst->memsegOrig == NULL || inst->length == 0)
			continue;

		bool hasloop = inst->flags & 1;
		bool is16bit = (inst->flags >> 2) & 1;
		uint32_t bytesPerSample = 1+is16bit;

		// calculate unrolled loop (up to 500 samples) end
		int32_t loopLen512 = inst->lend-inst->lbeg;
		if (loopLen512 > 0 && loopLen512 < 500)
			loopLen512 *= 1 + (500 / loopLen512);
		inst->lend512 = inst->lbeg + loopLen512;

		int8_t *newPtr8 = (int8_t *)realloc(inst->memsegOrig, 4 + ((inst->length + SAMPLE_UNROLL_BYTES) * bytesPerSample));
		if (newPtr8 == NULL)
			return false;
		inst->memsegOrig = newPtr8;
		inst->memseg = inst->memsegOrig + 4;

		// clear pre-start bytes
		inst->memsegOrig[0] = 0;
		inst->memsegOrig[1] = 0;
		inst->memsegOrig[2] = 0;
		inst->memsegOrig[3] = 0;

		if (hasloop)
		{
			// unroll sample loop

			uint32_t loopLen = inst->lend-inst->lbeg;
			if (is16bit)
			{
				int16_t *loopEndPtr16 = (int16_t *)&inst->memseg[inst->lend*2];
				int16_t *loopBegPtr16 = (int16_t *)&inst->memseg[inst->lbeg*2];

				for (uint32_t j = 0; j < SAMPLE_UNROLL_BYTES; j++)
					loopEndPtr16[j] = loopBegPtr16[j % loopLen];
			}
			else
			{
				int8_t *loopEndPtr8 = &inst->memseg[inst->lend];
				int8_t *loopBegPtr8 = &inst->memseg[inst->lbeg];

				for (uint32_t j = 0; j < SAMPLE_UNROLL_BYTES; j++)
					loopEndPtr8[j] = loopBegPtr8[j % loopLen];
			}

			// if loopStart == 0, fix the sample before it for our 4-tap cubic interpolation
			if (inst->lbeg == 0 && inst->lend > 0)
			{
				if (is16bit)
				{
					int16_t *dst = (int16_t *)&inst->memseg[-2];
					int16_t *src = (int16_t *)&inst->memseg[(inst->lend-1)*2];

					*dst = *src;
				}
				else
				{
					inst->memseg[-1] = inst->memseg[inst->lend-1];
				}
			}
		}
		else
		{
			// fade-out end of non-looping sample to prevent possible end-click

			if (is16bit)
			{
				int16_t *smpEndPtr16 = (int16_t *)&inst->memseg[inst->length*2];
				int16_t lastSmpVal16 = smpEndPtr16[-1];

				for (uint32_t j = 0; j < SAMPLE_UNROLL_BYTES; j++)
				{
					smpEndPtr16[j] = lastSmpVal16;
					if (lastSmpVal16 > 0)
					{
						lastSmpVal16 -= 32768 / 32;
						if (lastSmpVal16 < 0)
							lastSmpVal16 = 0;
					}
					else if (lastSmpVal16 < 0)
					{
						lastSmpVal16 += 32768 / 32;
						if (lastSmpVal16 > 0)
							lastSmpVal16 = 0;
					}
				}
			}
			else
			{
				int8_t *smpEndPtr8 = &inst->memseg[inst->length];
				int8_t lastSmpVal8 = smpEndPtr8[-1];

				for (uint32_t j = 0; j < SAMPLE_UNROLL_BYTES; j++)
				{
					smpEndPtr8[j] = lastSmpVal8;
					if (lastSmpVal8 > 0)
					{
						lastSmpVal8 -= 128 / 32;
						if (lastSmpVal8 < 0)
							lastSmpVal8 = 0;
					}
					else if (lastSmpVal8 < 0)
					{
						lastSmpVal8 += 128 / 32;
						if (lastSmpVal8 > 0)
							lastSmpVal8 = 0;
					}
				}
			}
		}
	}

	return true;
}

static void getlastnfo(chn_t *ch)
{
	if (ch->info == 0)
		ch->info = ch->alastnfo;
}

static void setspeed(uint8_t val)
{
	if (val > 0)
		musicmax = val;
}

static void settempo(uint8_t bpm)
{
	if (bpm <= 32)
		return;

#ifdef USE_ST3_GUS_TEMPO
	int32_t hz = (bpm * 50) / 125;
	if (hz < 19)
		hz = 19;

	const int32_t PITClk = 1193180; // off by one, but this is the value ST3 uses

	const int32_t PITVal = PITClk / hz;
	const float fPITHz = (float)PITClk / PITVal; // true replayer tick rate in Hz

	samplesPerTick = (int32_t)((audioRate / fPITHz) + 0.5f);
#else
	samplesPerTick = (audioRate * 125) / (bpm * 50);
#endif
}

static void setspd(chn_t *ch)
{
	int16_t tmpspd;
	voice_t *v;

	v = &voice[ch->channelnum];

	ch->achannelused |= 0x80;

	if (amigalimits)
	{
		if ((uint16_t)ch->aorgspd > aspdmax)
			ch->aorgspd = aspdmax;

		if (ch->aorgspd < aspdmin)
			ch->aorgspd = aspdmin;
	}

	tmpspd = ch->aspd;
	if ((uint16_t)tmpspd > aspdmax)
	{
		tmpspd = aspdmax;
		if (amigalimits)
			ch->aspd = tmpspd;
	}

	if (tmpspd == 0)
	{
		v->m_speed = 0; // freeze voice (can be activated again by changing frequency)
		v->m_speedrev = UINT32_MAX;
		return;
	}

	if (tmpspd < aspdmin)
	{
		tmpspd = aspdmin;
		if (amigalimits)
			ch->aspd = tmpspd;
	}

	v->m_speed = (int32_t)((dPer2HzDiv / (int32_t)tmpspd) + 0.5);
	v->m_speedrev = UINT32_MAX / v->m_speed; // 8bitbubsy: used in my mixer for calculating sampling limits
}

static void setglobalvol(int8_t vol)
{
	globalvol = vol;

	if ((uint8_t)vol > 64)
		vol = 64;

	useglobalvol = globalvol; // for mixer
}

static void setvol(chn_t *ch, bool volFlag)
{
	if (volFlag)
		ch->achannelused |= 0x80;

	voiceSetVolume(ch->channelnum, ch->avol * useglobalvol, ch->apanpos);
}

static int16_t stnote2herz(uint8_t note)
{
	uint8_t shiftVal;
	uint16_t noteVal;

	if (note == 254)
		return 0; // 0hertz/keyoff

	noteVal = notespd[note & 0x0F];

	shiftVal = octavediv[note >> 4];
	if (shiftVal > 0)
		noteVal >>= shiftVal & 0x1F;

	return noteVal;
}

static int16_t scalec2spd(chn_t *ch, int16_t spd)
{
	int32_t tmpspd;

	tmpspd = spd * C2FREQ;
	if ((tmpspd >> 16) >= ch->ac2spd)
		return 32767; // div error

	tmpspd /= ch->ac2spd;
	if (tmpspd > 32767)
		tmpspd = 32767;

	return (int16_t)tmpspd;
}

// for Gxx with semitones slide flag
static int16_t roundspd(chn_t *ch, int16_t spd)
{
	int8_t octa, newnote;
	int16_t note, notemin, lastspd;
	int32_t newspd;

	newspd = spd * ch->ac2spd;
	if ((newspd >> 16) >= C2FREQ)
		return spd; // div error

	newspd /= C2FREQ;

	// find octave

	octa = 0;
	lastspd = (notespd[12] + notespd[11]) >> 1;

	while (lastspd >= newspd)
	{
		octa++;
		lastspd >>= 1;
	}

	// find note

	newnote = 0;
	notemin = 32767;

	for (int8_t i = 0; i < 11; i++)
	{
		note = notespd[i];
		if (octa > 0)
			note >>= octa;

		note -= (int16_t)newspd;
		if (note < 0)
			note = -note;

		if (note < notemin)
		{
			notemin = note;
			newnote = i;
		}
	}

	// get new speed from new note

	newspd = (stnote2herz((octa << 4) | (newnote & 0x0F))) * C2FREQ;
	if ((newspd >> 16) >= ch->ac2spd)
		return spd; // div error

	newspd /= ch->ac2spd;
	return (int16_t)newspd;
}

static int16_t neworder(void) // rewritten to be more safe
{
	uint8_t patt;
	uint16_t numSep;

	numSep = 0;
	while (true)
	{
		np_ord++;

		patt = order[np_ord-1];
		if (patt == PATT_SEP)
		{
			/* Added security that is not present in ST3: check if a
			** song has pattern separators only, prevent endless loop!
			*/
			if (++numSep >= ordNum)
				return 0;

			continue;
		}

		if (patt == PATT_END)
		{
			// restart song
			np_ord = 0;

			if (order[0] == PATT_END)
				return 0;

			continue;
		}

		break;
	}

	np_pat = patt;
	np_patoff = -1; // force reseek
	np_row = startrow;
	startrow = 0;
	patmusicrand = 0;
	patloopstart = -1;
	jumptorow = -1;

	return np_row;
}

static int8_t getnote1(void)
{
	uint8_t dat, channel;
	int16_t i;
	chn_t *ch;

	if (np_patseg == NULL)
		return 255;

	// added security that is not present in ST3
	if (np_pat >= patNum)
		return 255;

	channel = 0;

	i = np_patoff;
	while (true)
	{
		dat = np_patseg[i++];
		if (dat == 0)
		{
			np_patoff = i;
			return 255;
		}

		if ((chnsettings[dat & 0x1F] & 0x80) == 0)
		{
			channel = dat & 0x1F;
			break;
		}

		// channel off, skip
		if (dat & 0x20) i += 2;
		if (dat & 0x40) i += 1;
		if (dat & 0x80) i += 2;
	}

	ch = &chn[channel];

	// NOTE/INSTRUMENT
	if (dat & 0x20)
	{
		ch->note = np_patseg[i++];
		ch->ins = np_patseg[i++];

		if (ch->note != 255) ch->lastnote = ch->note;
		if (ch->ins > 0) ch->lastins = ch->ins;
	}

	// VOLUME
	if (dat & 0x40)
		ch->vol = np_patseg[i++];

	// COMMAND/INFO
	if (dat & 0x80)
	{
		ch->cmd = np_patseg[i++];
		ch->info = np_patseg[i++];
	}

	np_patoff = i;
	return channel;
}

static void triggerVoice(voice_t *v) // 8bitbubsy: custom routine
{
	ins_t *inst = v->insPtr; // last set instrument pointer
	if (inst == NULL)
		return;

	bool hasloop = inst->flags & 1;
	bool is16bit = (inst->flags >> 2) & 1;

	v->m_loopbeg = inst->lbeg;
	v->m_looplen = inst->lend512 - inst->lbeg; // unrolled loop-length

	if (hasloop && v->m_looplen > 0)
	{
		v->m_origend = inst->lend - inst->lbeg; // original loop end
		v->m_end = inst->lend512; // unrolled loop end
		v->m_loopflag = true;
	}
	else
	{
		v->m_origend = inst->length;
		v->m_end = inst->length + 32; // extra fadeout for GUS (8bitbubsy: but also applies for SB!)
		v->m_loopflag = false;
	}

	if (is16bit)
		v->m_base16 = (int16_t *)inst->memseg;
	else
		v->m_base8 = inst->memseg;

	v->lastMixFuncOffset = (is16bit << 2) + (interpolationFlag << 1) + v->m_loopflag;

	v->m_mixfunc = mixRoutineTable[v->lastMixFuncOffset]; // start voice
}

static void doamiga(uint8_t channel)
{
	chn_t *ch;
	voice_t *v;
	ins_t *inst;

	ch = &chn[channel];
	v = &voice[channel];

	// ***INSTRUMENT***
	if (ch->ins > 0)
	{
		ch->astartoffset = 0;

		ch->lastins = ch->ins;
		if (ch->ins <= 99) // 8bitbubsy: added for safety reasons
		{
			inst = &ins[ch->ins-1];
			if (inst->type != 0)
			{
				if (inst->type == 1) // sample
				{
					ch->ac2spd = inst->c2spd;
					ch->avol = inst->vol; // 8bitbubsy: clamped to 0..63 in loader (ST3 clamps to 0..63 here)
					ch->aorgvol = ch->avol;
					setvol(ch, true);

					// 8bitbubsy: some custom logic to fix GUS/SB behavior differences
					v->insPtr = inst;
					if (soundcardtype == SOUNDCARD_SBPRO)
						triggerVoice(v); // trigger sample here in SB mode
				}
				else // not sample (8bitbubsy: adlib melody or adlib drum)
				{
					ch->lastins = 0;
				}
			}
		}
	}

	// continue only if we have an active instrument on this channel
	if (ch->lastins == 0)
		return;

	if (ch->cmd == 'O'-64)
	{
		if (ch->info == 0)
			ch->astartoffset = ch->astartoffset00;
		else
			ch->astartoffset00 = ch->astartoffset = ch->info << 8;
	}

	// ***NOTE***
	if (ch->note != 255)
	{
		if (ch->note == 254) // ^^
		{
			// end sample

			ch->aspd = 0;
			setspd(ch);

			ch->avol = 0;
			setvol(ch, true);

			voiceCut(channel);

			ch->asldspd = 65535; // 8bitbubsy: label jump bug causes this
		}
		else
		{
			// restart sample
			if (ch->cmd != 'G'-64 && ch->cmd != 'L'-64)
			{
				v->m_pos = ch->astartoffset;
				v->m_posfrac = 0;

				/* 8bitbubsy: custom logic to handle GUS/SB differences in ST3.
				** This is quite the hack, but I wanted it to behave 100% the same as ST3.21...
				*/
				if (soundcardtype == SOUNDCARD_GUS)
				{
					triggerVoice(v); // in GUS mode, trigger sample here instead (intentionally disables "sample swapping")

					/* Handle Oxx (Set Sample Offset) overflow:
					** GUS w/ looping samples: wrap around unrolled loop points
					** GUS w/ non-looping samples: cut voice if >= end+512 (fadeout part), happens in mixer instead
					*/
					if (v->m_pos >= v->m_end && ch->astartoffset > 0 && v->m_loopflag && v->m_looplen > 0)
						v->m_pos = v->m_loopbeg + ((v->m_pos - v->m_end) % v->m_looplen); // wrap around loop points
				}
				else
				{
					/* Handle Oxx (Set Sample Offset) overflow:
					** SB w/ looping samples: cut voice if >= *non*-unrolled loop end point
					** SB w/ non-looping samples: cut voice if >= end+512 (fadeout part), happens in mixer instead
					*/
					if (v->m_pos > v->m_origend && ch->astartoffset > 0 && v->m_loopflag)
						v->m_mixfunc = NULL;
				}
			}

			// 8bitbubsy: patch to kill voice on empty instruments
			if (ch->ins > 0 && ch->ins <= 99 && ins[ch->ins-1].type == 0)
				voiceCut(channel);

			// calc note speed

			ch->lastnote = ch->note;

			int16_t newspd = scalec2spd(ch, stnote2herz(ch->note));
			if (ch->aorgspd == 0 || (ch->cmd != 'G'-64 && ch->cmd != 'L'-64))
			{
				ch->aspd = newspd;
				setspd(ch);
				ch->avibcnt = 0;
				ch->aorgspd = newspd; // original speed if true one changed with vibrato etc.
			}

			ch->asldspd = newspd; // destination for toneslide (G/L)
		}
	}

	// ***VOLUME***
	if (ch->vol != 255)
	{
		ch->avol = ch->vol;
		setvol(ch, true);

		ch->aorgvol = ch->vol;
	}
}

static void donewnote(uint8_t channel, bool notedelayflag)
{
	chn_t *ch = &chn[channel];

	if (notedelayflag)
	{
		ch->achannelused = 0x81;
	}
	else
	{
		if (ch->channelnum > lastachannelused)
		{
			lastachannelused = ch->channelnum + 1;
			if (lastachannelused > 31) // added security that is not present in ST3
				lastachannelused = 31;
		}

		ch->achannelused = 0x01;

		if (ch->cmd == 'S'-64)
		{
			if ((ch->info & 0xF0) == 0xD0)
				return;
		}
	}

	doamiga(channel);
}

static void donotes(void)
{
	uint8_t channel, dat;
	int16_t i, j;
	chn_t *ch;

	for (i = 0; i < 32; i++)
	{
		ch = &chn[i];

		ch->note = 255;
		ch->vol = 255;
		ch->ins = 0;
		ch->cmd = 0;
		ch->info = 0;
	}

	// find np_row from pattern
	if (np_patoff == -1)
	{
		np_patseg = patdata[np_pat];
		if (np_patseg != NULL)
		{
			j = 0;
			if (np_row > 0)
			{
				i = np_row;
				while (i > 0)
				{
					dat = np_patseg[j++];
					if (dat == 0)
					{
						i--;
					}
					else
					{
						if (dat & 0x20) j += 2;
						if (dat & 0x40) j += 1;
						if (dat & 0x80) j += 2;
					}
				}
			}

			np_patoff = j;
		}
	}

	while (true)
	{
		channel = getnote1();
		if (channel == 255)
			break; // end of row/channels

		if ((chnsettings[channel] & 0x7F) < 16) // only handle PCM channels for now
			donewnote(channel, false);
	}
}

// tick 0 commands
static void docmd1(void)
{
	chn_t *ch;

	int8_t oldvolslidetype = volslidetype;
	for (uint8_t i = 0; i < lastachannelused+1; i++)
	{
		ch = &chn[i];

		if (ch->achannelused)
		{
			if (ch->info > 0)
				ch->alastnfo = ch->info;

			if (ch->cmd > 0)
			{
				ch->achannelused |= 0x80;

				if (ch->cmd == 'D'-64)
				{
					// fix trigger D

					ch->atrigcnt = 0;

					// fix speed if tone port noncomplete
					if (ch->aspd != ch->aorgspd)
					{
						ch->aspd = ch->aorgspd;
						setspd(ch);
					}
				}
				else
				{
					if (ch->cmd != 'I'-64)
					{
						ch->atremor = 0;
						ch->atreon  = true;
					}

					if (ch->cmd != 'H'-64 && ch->cmd != 'U'-64 && ch->cmd != 'K'-64 && ch->cmd != 'R'-64)
						ch->avibcnt |= 128;
				}

				if (ch->cmd < 27)
				{
					volslidetype = 0;
					soncejmp[ch->cmd](ch);
				}
			}
			else
			{
				// fix trigger 0

				ch->atrigcnt = 0;

				// fix speed if tone port noncomplete
				if (ch->aspd != ch->aorgspd)
				{
					ch->aspd = ch->aorgspd;
					setspd(ch);
				}

				if (!amigalimits && ch->cmd < 27)
				{
					volslidetype = 0;
					soncejmp[ch->cmd](ch);
				}
			}
		}
	}
	volslidetype = oldvolslidetype;
}

static void docmd2(void) // tick >0 commands
{
	chn_t *ch;

	int8_t oldvolslidetype = volslidetype;
	for (uint8_t i = 0; i < lastachannelused+1; i++)
	{
		ch = &chn[i];
		if (ch->achannelused && ch->cmd > 0)
		{
			ch->achannelused |= 0x80;

			if (ch->cmd < 27)
			{
				volslidetype = 0;
				sotherjmp[ch->cmd](ch);
			}
		}
	}
	volslidetype = oldvolslidetype;
}

static void dorow(void)
{
  np_zframe++;

	patmusicrand = (((patmusicrand * 0xCDEF) >> 16) + 0x1727) & 0xFFFF;

	if (np_pat == 255)
		return; // 8bitbubsy: there are no patterns in the song!

	if (musiccount == 0)
	{
		if (patterndelay > 0)
		{
			np_row--;
			docmd1();
			patterndelay--;
		}
		else
		{
			donotes(); // new notes
			docmd1(); // also does 0volcut
		}
	}
	else
	{
		docmd2(); // effects only
	}

	if (++musiccount >= musicmax)
	{
		// next row
		np_row++;

		if (jumptorow != -1)
		{
			np_row = jumptorow;
			jumptorow = -1;
		}

		if (np_row >= 64 || (patloopcount == 0 && breakpat > 0))
		{
			// next pattern
			if (breakpat == 255)
			{
				breakpat = 0;
				return;
			}

			breakpat = 0;

			if (jmptoord != -1)
			{
				np_ord = jmptoord;
				jmptoord = -1;
			}

			np_row = neworder(); // if breakpat, np_row = break row
		}

		musiccount = 0;
	}
}

// EFFECTS

static void s_ret(chn_t *ch)
{
	(void)ch;
}

static void s_setgliss(chn_t *ch)
{
	ch->aglis = ch->info & 0x0F;
}

static void s_setfinetune(chn_t *ch)
{
	// this has a bug in ST3 that makes this effect do nothing!
	(void)ch;
}

static void s_setvibwave(chn_t *ch)
{
	ch->avibtretype = (ch->avibtretype & 0xF0) | ((ch->info << 1) & 0x0F);
}

static void s_settrewave(chn_t *ch)
{
	ch->avibtretype = ((ch->info << 5) & 0xF0) | (ch->avibtretype & 0x0F);
}

static void s_setpanpos(chn_t *ch)
{
	if (soundcardtype == SOUNDCARD_GUS)
	{
		ch->surround = false;
		ch->apanpos = ((ch->info & 0xF) << 4) | (ch->info & 0xF);
		setvol(ch, false);
	}
}

static void s_soundcntr(chn_t *ch)
{
	if (soundcardtype == SOUNDCARD_GUS)
	{
		uint8_t info = ch->info & 0xF;
		if (info == 0) // surround off
		{
			ch->surround = false;
			setvol(ch, false);
		}
		else if (info == 1) // surround on
		{
			ch->surround = true;
			ch->apanpos = 128;
			setvol(ch, false);
		}
	}
}

static void s_stereocntr(chn_t *ch)
{
	/* Sound Blaster mix selector (buggy, undocumented ST3 effect):
	** - SA0 = normal  mix
	** - SA1 = swapped mix (L<->R)
	** - SA2 = normal  mix (broken mixing)
	** - SA3 = swapped mix (broken mixing)
	** - SA4 = center  mix (broken mixing)
	** - SA5 = center  mix (broken mixing)
	** - SA6 = center  mix (broken mixing)
	** - SA7 = center  mix (broken mixing)
	** - SA8..F = changes nothing
	*/

	if (soundcardtype == SOUNDCARD_SBPRO && (ch->info & 0x0F) < 8)
	{
		ch->amixtype = ch->info & 0x0F;
		setvol(ch, false);
	}
}

static void s_patloop(chn_t *ch)
{
	if ((ch->info & 0x0F) == 0)
	{
		patloopstart = np_row;
		return;
	}

	if (patloopcount == 0)
	{
		patloopcount = (ch->info & 0x0F) + 1;
		if (patloopstart == -1)
			patloopstart = 0; // default loopstart
	}

	if (patloopcount > 1)
	{
		patloopcount--;
		jumptorow = patloopstart;
		np_patoff = -1; // force reseek
	}
	else
	{
		patloopcount = 0;
		patloopstart = np_row + 1;
	}
}

static void s_notecut(chn_t *ch)
{
	ch->anotecutcnt = ch->info & 0x0F;
}

static void s_notecutb(chn_t *ch)
{
	if (ch->anotecutcnt > 0)
	{
		if (--ch->anotecutcnt == 0)
			voice[ch->channelnum].m_speed = 0; // shut down voice (recoverable by using pitch effects)
	}
}

static void s_notedelay(chn_t *ch)
{
	ch->anotedelaycnt = ch->info & 0x0F;
}

static void s_notedelayb(chn_t *ch)
{
	if (ch->anotedelaycnt > 0)
	{
		if (--ch->anotedelaycnt == 0)
			donewnote(ch->channelnum, true);
	}
}

static void s_patterdelay(chn_t *ch)
{
	if (patterndelay == 0)
		patterndelay = ch->info & 0x0F;
}

static void s_setspeed(chn_t *ch)
{
	setspeed(ch->info);
}

static void s_jmpto(chn_t *ch)
{
	if (ch->info == 0xFF)
	{
		breakpat = 255;
	}
	else
	{
		breakpat = 1;
		jmptoord = ch->info;
	}
}

static void s_break(chn_t *ch)
{
	uint8_t hi, lo;

	hi = ch->info >> 4;
	lo = ch->info & 0x0F;

	if (hi <= 9 && lo <= 9)
	{
		startrow = (hi * 10) + lo;
		breakpat = 1;
	}
}

static void s_vibvol(chn_t *ch)
{
	volslidetype = 2;
	s_volslide(ch);
}

static void s_tonevol(chn_t *ch)
{
	volslidetype = 1;
	s_volslide(ch);
}

static void s_volslide(chn_t *ch)
{
	uint8_t infohi;
	uint8_t infolo;

	getlastnfo(ch);

	infohi = ch->info >> 4;
	infolo = ch->info & 0x0F;

	if (infolo == 0x0F)
	{
		     if (infohi == 0) ch->avol -= infolo;
		else if (musiccount == 0) ch->avol += infohi;
	}
	else if (infohi == 0x0F)
	{
		     if (infolo == 0) ch->avol += infohi;
		else if (musiccount == 0) ch->avol -= infolo;
	}
	else if (fastvolslide || musiccount > 0)
	{
		if (infolo == 0)
			ch->avol += infohi;
		else
			ch->avol -= infolo;
	}
	else
	{
		return; // illegal slide
	}

	ch->avol = CLAMP(ch->avol, 0, 63);
	setvol(ch, true);

	// these are set on Kxy/Lxx
	     if (volslidetype == 1) s_toneslide(ch);
	else if (volslidetype == 2) s_vibrato(ch);
}

static void s_slidedown(chn_t *ch)
{
	if (ch->aorgspd <= 0)
		return;

	getlastnfo(ch);

	if (musiccount > 0)
	{
		if (ch->info >= 0xE0)
			return; // no fine slides here

		ch->aspd += ch->info << 2;
		if ((uint16_t)ch->aspd > 32767)
			ch->aspd = 32767;
	}
	else
	{
		if (ch->info <= 0xE0)
			return; // only fine slides here

		if (ch->info <= 0xF0)
		{
			ch->aspd += ch->info & 0x0F;
			if ((uint16_t)ch->aspd > 32767)
				ch->aspd = 32767;
		}
		else
		{
			ch->aspd += (ch->info & 0x0F) << 2;
			if ((uint16_t)ch->aspd > 32767)
				ch->aspd = 32767;
		}
	}

	ch->aorgspd = ch->aspd;
	setspd(ch);
}

static void s_slideup(chn_t *ch)
{
	if (ch->aorgspd <= 0)
		return;

	getlastnfo(ch);

	if (musiccount > 0)
	{
		if (ch->info >= 0xE0)
			return; // no fine slides here

		ch->aspd -= ch->info << 2;
		if (ch->aspd < 0)
			ch->aspd = 0;
	}
	else
	{
		if (ch->info <= 0xE0)
			return; // only fine slides here

		if (ch->info <= 0xF0)
		{
			ch->aspd -= ch->info & 0x0F;
			if (ch->aspd < 0)
				ch->aspd = 0;
		}
		else
		{
			ch->aspd -= (ch->info & 0x0F) << 2;
			if (ch->aspd < 0)
				ch->aspd = 0;
		}
	}

	ch->aorgspd = ch->aspd;
	setspd(ch);
}

static void s_toneslide(chn_t *ch)
{
	uint8_t toneinfo;

	if (volslidetype == 1) // we came from an Lxy (toneslide+volslide)
	{
		toneinfo = ch->alasteff1;
	}
	else
	{
		if (ch->aorgspd == 0)
		{
			if (ch->asldspd == 0)
				return;

			ch->aorgspd = ch->asldspd;
			ch->aspd = ch->asldspd;
		}

		if (ch->info == 0)
			ch->info = ch->alasteff1;
		else
			ch->alasteff1 = ch->info;

		toneinfo = ch->info;
	}

	if (ch->aorgspd != ch->asldspd)
	{
		if (ch->aorgspd < ch->asldspd)
		{
			ch->aorgspd += toneinfo << 2;
			if ((uint16_t)ch->aorgspd > (uint16_t)ch->asldspd)
				ch->aorgspd = ch->asldspd;
		}
		else
		{
			ch->aorgspd -= toneinfo << 2;
			if (ch->aorgspd < ch->asldspd)
				ch->aorgspd = ch->asldspd;
		}

		if (ch->aglis)
			ch->aspd = roundspd(ch, ch->aorgspd);
		else
			ch->aspd = ch->aorgspd;

		setspd(ch);
	}
}

static void s_vibrato(chn_t *ch)
{
	int8_t type;
	uint8_t vibinfo;
	int16_t cnt;
	int32_t dat;

	if (volslidetype == 2) // we came from a Kxy (vibrato+volslide)
	{
		vibinfo = ch->alasteff;
	}
	else
	{
		if (ch->info == 0)
			ch->info = ch->alasteff;

		if ((ch->info & 0xF0) == 0)
			ch->info = (ch->alasteff & 0xF0) | (ch->info & 0x0F);

		vibinfo = ch->alasteff = ch->info;
	}

	if (ch->aorgspd > 0)
	{
		cnt  = ch->avibcnt;
		type = (ch->avibtretype & 0x0E) >> 1;
		dat  = 0;

		// sine
		if (type == 0 || type == 4)
		{
			if (type == 4)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsin[cnt >> 1];
		}

		// ramp
		else if (type == 1 || type == 5)
		{
			if (type == 5)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibramp[cnt >> 1];
		}

		// square
		else if (type == 2 || type == 6)
		{
			if (type == 6)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsqu[cnt >> 1];
		}

		// random
		else if (type == 3 || type == 7)
		{
			if (type == 7)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsin[cnt >> 1];
			cnt += (patmusicrand & 0x1E);
		}

		if (oldstvib)
			ch->aspd = ch->aorgspd + ((int16_t)(dat * (vibinfo & 0x0F)) >> 4);
		else
			ch->aspd = ch->aorgspd + ((int16_t)(dat * (vibinfo & 0x0F)) >> 5);

		setspd(ch);

		ch->avibcnt = (cnt + ((vibinfo >> 4) << 1)) & 126;
	}
}

static void s_tremor(chn_t *ch)
{
	getlastnfo(ch);

	if (ch->atremor > 0)
	{
		ch->atremor--;
		return;
	}

	if (ch->atreon)
	{
		// set to off
		ch->atreon = false;

		ch->avol = 0;
		setvol(ch, true);

		ch->atremor = ch->info & 0x0F;
	}
	else
	{
		// set to on
		ch->atreon = true;

		ch->avol = ch->aorgvol;
		setvol(ch, true);

		ch->atremor = ch->info >> 4;
	}
}

static void s_arp(chn_t *ch)
{
	int8_t note, octa, noteadd;
	uint8_t tick;

	getlastnfo(ch);

	tick = musiccount % 3;

	     if (tick == 1) noteadd = ch->info >> 4;
	else if (tick == 2) noteadd = ch->info & 0x0F;
	else noteadd = 0;

	// check for octave overflow
	octa =  ch->lastnote & 0xF0;
	note = (ch->lastnote & 0x0F) + noteadd;

	while (note >= 12)
	{
		note -= 12;
		octa += 16;
	}

	ch->aspd = scalec2spd(ch, stnote2herz(octa | note));
	setspd(ch);
}

static void s_retrig(chn_t *ch)
{
	voice_t *v = &voice[ch->channelnum];
	uint8_t infohi;

	getlastnfo(ch);
	infohi = ch->info >> 4;

	if ((ch->info & 0x0F) == 0 || (ch->info & 0x0F) > ch->atrigcnt)
	{
		ch->atrigcnt++;
		return;
	}

	ch->atrigcnt = 0;
	v->m_pos = 0;

	// 8bitbubsy: in ST3.21, only GUS mode can properly retrigger a voice that had ended
	if (soundcardtype != SOUNDCARD_GUS)
	{
		v->m_posfrac = 0; // yes, position frac is only reset in GUS mode
		if (v->m_mixfunc == NULL && (v->m_base8 != NULL || v->m_base16 != NULL))
			v->m_mixfunc = mixRoutineTable[v->lastMixFuncOffset]; // retrigger ended voice
	}

	if (retrigvoladd[infohi+16] == 0)
		ch->avol += retrigvoladd[infohi]; // add/sub
	else
		ch->avol = (int8_t)((ch->avol * retrigvoladd[infohi+16]) >> 4);

	ch->avol = CLAMP(ch->avol, 0, 63);
	setvol(ch, true);

	ch->atrigcnt++; // 8bitbubsy: probably a bug? but it makes it sound correct...
}

static void s_tremolo(chn_t *ch)
{
	int8_t type;
	int16_t cnt, dat;

	getlastnfo(ch);

	if ((ch->info & 0xF0) == 0)
		ch->info = (ch->alastnfo & 0xF0) | (ch->info & 0x0F);

	ch->alastnfo = ch->info;

	if (ch->aorgvol > 0)
	{
		cnt = ch->avibcnt;
		type = ch->avibtretype >> 5;
		dat = 0;

		// sine
		if (type == 0 || type == 4)
		{
			if (type == 4)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsin[cnt >> 1];
		}

		// ramp
		else if (type == 1 || type == 5)
		{
			if (type == 5)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibramp[cnt >> 1];
		}

		// square
		else if (type == 2 || type == 6)
		{
			if (type == 6)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsqu[cnt >> 1];
		}

		// random
		else if (type == 3 || type == 7)
		{
			if (type == 7)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsin[cnt >> 1];
			cnt += (patmusicrand & 0x1E);
		}

		dat = ch->aorgvol + (int8_t)((dat * (ch->info & 0x0F)) >> 7);
		dat = CLAMP(dat, 0, 63);

		ch->avol = (int8_t)dat;
		setvol(ch, true);

		ch->avibcnt = (cnt + ((ch->info & 0xF0) >> 3)) & 126;
	}
}

static void s_set7bitpan(chn_t *ch)
{
	if (soundcardtype == SOUNDCARD_GUS)
	{
		if (ch->info == 0xA4)
		{
			ch->surround = true;
			ch->apanpos = 128;
			setvol(ch, false);
		}
		else if (ch->info <= 0x7F)
		{
			ch->surround = false;
			ch->apanpos = ch->info << 1;
			setvol(ch, false);
		}
	}
}

static void s_scommand1(chn_t *ch)
{
	getlastnfo(ch);
	ssoncejmp[ch->info >> 4](ch);
}

static void s_scommand2(chn_t *ch)
{
	getlastnfo(ch);
	ssotherjmp[ch->info >> 4](ch);
}

static void s_settempo(chn_t *ch)
{
	if (!musiccount && ch->info >= 0x20)
		settempo(ch->info);
}

static void s_finevibrato(chn_t *ch)
{
	int8_t type;
	int16_t cnt;
	int32_t dat;

	if (ch->info == 0)
		ch->info = ch->alasteff;

	if ((ch->info & 0xF0) == 0)
		ch->info = (ch->alasteff & 0xF0) | (ch->info & 0x0F);

	ch->alasteff = ch->info;

	if (ch->aorgspd > 0)
	{
		cnt = ch->avibcnt;
		type = (ch->avibtretype & 0x0E) >> 1;
		dat = 0;

		// sine
		if (type == 0 || type == 4)
		{
			if (type == 4)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsin[cnt >> 1];
		}

		// ramp
		else if (type == 1 || type == 5)
		{
			if (type == 5)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibramp[cnt >> 1];
		}

		// square
		else if (type == 2 || type == 6)
		{
			if (type == 6)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsqu[cnt >> 1];
		}

		// random
		else if (type == 3 || type == 7)
		{
			if (type == 7)
			{
				cnt &= 0x7F;
			}
			else
			{
				if (cnt & 0x80)
					cnt = 0;
			}

			dat = vibsin[cnt >> 1];
			cnt += (patmusicrand & 0x1E);
		}

		if (oldstvib)
			ch->aspd = ch->aorgspd + ((int16_t)(dat * (ch->info & 0x0F)) >> 6);
		else
			ch->aspd = ch->aorgspd + ((int16_t)(dat * (ch->info & 0x0F)) >> 7);

		setspd(ch);

		ch->avibcnt = (cnt + ((ch->info >> 4) << 1)) & 126;
	}
}

static void s_setgvol(chn_t *ch)
{
	if (ch->info <= 64)
		setglobalvol(ch->info);
}

static void voiceCut(uint8_t voiceNumber)
{
	voice_t *v = &voice[voiceNumber];

	v->m_mixfunc = NULL;
	v->m_pos = 0;
	v->m_posfrac = 0;
}

static void voiceSetVolume(uint8_t voiceNumber, int32_t vol, int32_t pan)
{
	int32_t panL, panR, tmpPan;
	voice_t *v;
	chn_t *ch;

	v = &voice[voiceNumber];
	ch = &chn[voiceNumber];

	panL = pan ^ 0xFF; // 255 - pan
	panR = pan;

	// in SB stereo mode, you can use effect SAx to control certain things
	if (ch->amixtype > 0 && soundcardtype == SOUNDCARD_SBPRO)
	{
		const int32_t centerPanVal = 128;

		if (ch->amixtype >= 4)
		{
			// center mixing
			panL = centerPanVal;
			panR = centerPanVal;
		}
		else if ((ch->amixtype & 1) == 1)
		{
			// swap L/R
			tmpPan = panL;
			panL = panR;
			panR = tmpPan;
		}
	}

	if (ch->surround)
		panR = -panR;

	vol <<= 8; // 0..4032 -> 0..1032192

	v->m_vol_l = vol * panL; // 0..1032192 * 0..255 = 0..263208960
	v->m_vol_r = vol * panR; // 0..1032192 * 0..255 = 0..263208960
}

/* ----------------------------------------------------------------------- */
/*                          GENERAL MIXER MACROS                           */
/* ----------------------------------------------------------------------- */

#define GET_MIXER_VARS \
	audioMixL = mixBufferL; \
	audioMixR = mixBufferR; \
	realPos = v->m_pos; \
	pos = v->m_posfrac; /* 16.16 fixed point */ \
	delta = v->m_speed; \

#define SET_BASE8 \
	base = v->m_base8; \
	smpPtr = base + realPos; \

#define SET_BASE16 \
	base = v->m_base16; \
	smpPtr = base + realPos; \

#define SET_BACK_MIXER_POS \
	v->m_posfrac = pos; \
	v->m_pos = realPos; \

#define GET_VOL \
	volL = v->m_vol_l; \
	volR = v->m_vol_r; \

#define INC_POS \
	pos += delta; \
	smpPtr += pos >> 16; \
	pos &= 0xFFFF; \

/* ----------------------------------------------------------------------- */
/*                          SAMPLE RENDERING MACROS                        */
/* ----------------------------------------------------------------------- */

// 4-tap cubic spline interpolation

// in: int32_t s0,s1,s2,s3 = -128..127 | f = 0..65535 (frac) | out: 16-bit s0 (will exceed 16-bits because of overshoot)
#define INTERPOLATE8(s0, s1, s2, s3, f) \
{ \
	const int16_t *t = fastSincTable + ((f >> 6) & 0x3FC); \
	s0 = ((s0 * t[0]) + (s1 * t[1]) + (s2 * t[2]) + (s3 * t[3])) >> (14 - 8); \
} \

// in: int32_t s0,s1,s2,s3 = -32768..32767 | f = 0..65535 (frac) | out: 16-bit s0 (will exceed 16-bits because of overshoot)
#define INTERPOLATE16(s0, s1, s2, s3, f) \
{ \
	const int16_t *t = fastSincTable + ((f >> 6) & 0x3FC); \
	s0 = ((s0 * t[0]) + (s1 * t[1]) + (s2 * t[2]) + (s3 * t[3])) >> 14; \
} \

#define RENDER_8BIT_SMP \
	sample = *smpPtr << (12 + 8); \
	*audioMixL++ += ((int64_t)sample * volL) >> 32; \
	*audioMixR++ += ((int64_t)sample * volR) >> 32; \

#define RENDER_16BIT_SMP \
	sample = *smpPtr << 12; \
	*audioMixL++ += ((int64_t)sample * volL) >> 32; \
	*audioMixR++ += ((int64_t)sample * volR) >> 32; \

#define RENDER_8BIT_SMP_INTRP \
	sample = smpPtr[-1]; \
	sample2 = smpPtr[0]; \
	sample3 = smpPtr[1]; \
	sample4 = smpPtr[2]; \
	INTERPOLATE8(sample, sample2, sample3, sample4, pos) \
	sample <<= 12; \
	*audioMixL++ += ((int64_t)sample * volL) >> 32; \
	*audioMixR++ += ((int64_t)sample * volR) >> 32; \

#define RENDER_16BIT_SMP_INTRP \
	sample = smpPtr[-1]; \
	sample2 = smpPtr[0]; \
	sample3 = smpPtr[1]; \
	sample4 = smpPtr[2]; \
	INTERPOLATE16(sample, sample2, sample3, sample4, pos) \
	sample <<= 12; \
	*audioMixL++ += ((int64_t)sample * volL) >> 32; \
	*audioMixR++ += ((int64_t)sample * volR) >> 32; \

/* ----------------------------------------------------------------------- */
/*                     SAMPLES-TO-MIX LIMITING MACROS                      */
/* ----------------------------------------------------------------------- */

#define LIMIT_MIX_NUM \
	i = (v->m_end - 1) - realPos; \
	if (i > 65535) \
		i = 65535; \
	\
	samplesToMix = (((((uint64_t)i << 16) | (pos ^ 0xFFFF)) * v->m_speedrev) >> 32) + 1; \
	if (samplesToMix > (uint32_t)samplesToRender) \
		samplesToMix = samplesToRender; \
	\
	samplesToRender -= samplesToMix; \

#define HANDLE_SAMPLE_END \
	realPos = (uint32_t)(smpPtr - base); \
	if (realPos >= v->m_end) \
	{ \
		v->m_mixfunc = NULL; /* shut down voice */ \
		return; \
	} \

#define WRAP_LOOP \
	realPos = (uint32_t)(smpPtr - base); \
	while (realPos >= v->m_end) \
		realPos -= v->m_looplen; \
	smpPtr = base + realPos; \

#define VOL0_OPTIMIZATION_NO_LOOP \
	pos = v->m_posfrac + ((v->m_speed & 0xFFFF) * numSamples); \
	realPos = v->m_pos + ((v->m_speed >> 16) * numSamples) + (pos >> 16); \
	pos &= 0xFFFF; \
	\
	if (realPos >= v->m_end) \
	{ \
		v->m_mixfunc = NULL; \
		return; \
	} \
	\
	SET_BACK_MIXER_POS \

#define VOL0_OPTIMIZATION_LOOP \
	pos = v->m_posfrac + ((v->m_speed & 0xFFFF) * numSamples); \
	realPos = v->m_pos + ((v->m_speed >> 16) * numSamples) + (pos >> 16); \
	pos &= 0xFFFF; \
	\
	while (realPos >= v->m_end) \
		realPos -= v->m_looplen; \
	\
	SET_BACK_MIXER_POS \

/* ----------------------------------------------------------------------- */
/*                          8-BIT MIXING ROUTINES                          */
/* ----------------------------------------------------------------------- */

static void mix8bNoLoop(voice_t *v, uint32_t numSamples)
{
	const int8_t *base;
	int32_t sample, *audioMixL, *audioMixR, samplesToRender;
	register const int8_t *smpPtr;
	register int32_t volL, volR;
	register uint32_t pos, delta;
	uint32_t realPos, i, samplesToMix;

	if (v->m_vol_l == 0 && v->m_vol_r == 0)
	{
		VOL0_OPTIMIZATION_NO_LOOP
		return;
	}

	GET_VOL
	GET_MIXER_VARS
	SET_BASE8

	samplesToRender = numSamples;
	while (samplesToRender > 0)
	{
		LIMIT_MIX_NUM
		if (samplesToMix & 1)
		{
			RENDER_8BIT_SMP
			INC_POS
		}
		samplesToMix >>= 1;
		for (i = 0; i < samplesToMix; i++)
		{
			RENDER_8BIT_SMP
			INC_POS
			RENDER_8BIT_SMP
			INC_POS
		}
		HANDLE_SAMPLE_END
	}

	SET_BACK_MIXER_POS
}

static void mix8bLoop(voice_t *v, uint32_t numSamples)
{
	const int8_t *base;
	int32_t sample, *audioMixL, *audioMixR, samplesToRender;
	register const int8_t *smpPtr;
	register int32_t volL, volR;
	register uint32_t pos, delta;
	uint32_t realPos, i, samplesToMix;
	
	if (v->m_vol_l == 0 && v->m_vol_r == 0)
	{
		VOL0_OPTIMIZATION_LOOP
		return;
	}

	GET_VOL
	GET_MIXER_VARS
	SET_BASE8

	samplesToRender = numSamples;
	while (samplesToRender > 0)
	{
		LIMIT_MIX_NUM
		if (samplesToMix & 1)
		{
			RENDER_8BIT_SMP
			INC_POS
		}
		samplesToMix >>= 1;
		for (i = 0; i < samplesToMix; i++)
		{
			RENDER_8BIT_SMP
			INC_POS
			RENDER_8BIT_SMP
			INC_POS
		}
		WRAP_LOOP
	}

	SET_BACK_MIXER_POS
}

static void mix8bNoLoopIntrp(voice_t *v, uint32_t numSamples)
{
	const int8_t *base;
	int32_t sample, sample2, sample3, sample4, *audioMixL, *audioMixR, samplesToRender;
	register const int8_t *smpPtr;
	register int32_t volL, volR;
	register uint32_t pos, delta;
	uint32_t realPos, i, samplesToMix;

	if (v->m_vol_l == 0 && v->m_vol_r == 0)
	{
		VOL0_OPTIMIZATION_NO_LOOP
		return;
	}

	GET_VOL
	GET_MIXER_VARS
	SET_BASE8

	samplesToRender = numSamples;
	while (samplesToRender > 0)
	{
		LIMIT_MIX_NUM
		if (samplesToMix & 1)
		{
			RENDER_8BIT_SMP_INTRP
			INC_POS
		}
		samplesToMix >>= 1;
		for (i = 0; i < samplesToMix; i++)
		{
			RENDER_8BIT_SMP_INTRP
			INC_POS
			RENDER_8BIT_SMP_INTRP
			INC_POS
		}
		HANDLE_SAMPLE_END
	}

	SET_BACK_MIXER_POS
}

static void mix8bLoopIntrp(voice_t *v, uint32_t numSamples)
{
	const int8_t *base;
	int32_t sample, sample2, sample3, sample4, *audioMixL, *audioMixR, samplesToRender;
	register const int8_t *smpPtr;
	register int32_t volL, volR;
	register uint32_t pos, delta;
	uint32_t realPos, i, samplesToMix;

	if (v->m_vol_l == 0 && v->m_vol_r == 0)
	{
		VOL0_OPTIMIZATION_LOOP
		return;
	}

	GET_VOL
	GET_MIXER_VARS
	SET_BASE8

	samplesToRender = numSamples;
	while (samplesToRender > 0)
	{
		LIMIT_MIX_NUM
		if (samplesToMix & 1)
		{
			RENDER_8BIT_SMP_INTRP
			INC_POS
		}
		samplesToMix >>= 1;
		for (i = 0; i < samplesToMix; i++)
		{
			RENDER_8BIT_SMP_INTRP
			INC_POS
			RENDER_8BIT_SMP_INTRP
			INC_POS
		}
		WRAP_LOOP
	}

	SET_BACK_MIXER_POS
}

/* ----------------------------------------------------------------------- */
/*                          16-BIT MIXING ROUTINES                         */
/* ----------------------------------------------------------------------- */

static void mix16bNoLoop(voice_t *v, uint32_t numSamples)
{
	const int16_t *base;
	int32_t sample, *audioMixL, *audioMixR, samplesToRender;
	register const int16_t *smpPtr;
	register int32_t volL, volR;
	register uint32_t pos, delta;
	uint32_t realPos, i, samplesToMix;

	if (v->m_vol_l == 0 && v->m_vol_r == 0)
	{
		VOL0_OPTIMIZATION_NO_LOOP
		return;
	}

	GET_VOL
	GET_MIXER_VARS
	SET_BASE16

	samplesToRender = numSamples;
	while (samplesToRender > 0)
	{
		LIMIT_MIX_NUM
		if (samplesToMix & 1)
		{
			RENDER_16BIT_SMP
			INC_POS
		}
		samplesToMix >>= 1;
		for (i = 0; i < samplesToMix; i++)
		{
			RENDER_16BIT_SMP
			INC_POS
			RENDER_16BIT_SMP
			INC_POS
		}
		HANDLE_SAMPLE_END
	}

	SET_BACK_MIXER_POS
}

static void mix16bLoop(voice_t *v, uint32_t numSamples)
{
	const int16_t *base;
	int32_t sample, *audioMixL, *audioMixR, samplesToRender;
	register const int16_t *smpPtr;
	register int32_t volL, volR;
	register uint32_t pos, delta;
	uint32_t realPos, i, samplesToMix;

	if (v->m_vol_l == 0 && v->m_vol_r == 0)
	{
		VOL0_OPTIMIZATION_LOOP
		return;
	}

	GET_VOL
	GET_MIXER_VARS
	SET_BASE16

	samplesToRender = numSamples;
	while (samplesToRender > 0)
	{
		LIMIT_MIX_NUM
		if (samplesToMix & 1)
		{
			RENDER_16BIT_SMP
			INC_POS
		}
		samplesToMix >>= 1;
		for (i = 0; i < samplesToMix; i++)
		{
			RENDER_16BIT_SMP
			INC_POS
			RENDER_16BIT_SMP
			INC_POS
		}
		WRAP_LOOP
	}

	SET_BACK_MIXER_POS
}

static void mix16bNoLoopIntrp(voice_t *v, uint32_t numSamples)
{
	const int16_t *base;
	int32_t sample, sample2, sample3, sample4, *audioMixL, *audioMixR, samplesToRender;
	register const int16_t *smpPtr;
	register int32_t volL, volR;
	register uint32_t pos, delta;
	uint32_t realPos, i, samplesToMix;

	if (v->m_vol_l == 0 && v->m_vol_r == 0)
	{
		VOL0_OPTIMIZATION_NO_LOOP
		return;
	}

	GET_VOL
	GET_MIXER_VARS
	SET_BASE16

	samplesToRender = numSamples;
	while (samplesToRender > 0)
	{
		LIMIT_MIX_NUM
		if (samplesToMix & 1)
		{
			RENDER_16BIT_SMP_INTRP
			INC_POS
		}
		samplesToMix >>= 1;
		for (i = 0; i < samplesToMix; i++)
		{
			RENDER_16BIT_SMP_INTRP
			INC_POS
			RENDER_16BIT_SMP_INTRP
			INC_POS
		}
		HANDLE_SAMPLE_END
	}

	SET_BACK_MIXER_POS
}

static void mix16bLoopIntrp(voice_t *v, uint32_t numSamples)
{
	const int16_t *base;
	int32_t sample, sample2, sample3, sample4, *audioMixL, *audioMixR, samplesToRender;
	register const int16_t *smpPtr;
	register int32_t volL, volR;
	register uint32_t pos, delta;
	uint32_t realPos, i, samplesToMix;

	if (v->m_vol_l == 0 && v->m_vol_r == 0)
	{
		VOL0_OPTIMIZATION_LOOP
		return;
	}

	GET_VOL
	GET_MIXER_VARS
	SET_BASE16

	samplesToRender = numSamples;
	while (samplesToRender > 0)
	{
		LIMIT_MIX_NUM
		if (samplesToMix & 1)
		{
			RENDER_16BIT_SMP_INTRP
			INC_POS
		}
		samplesToMix >>= 1;
		for (i = 0; i < samplesToMix; i++)
		{
			RENDER_16BIT_SMP_INTRP
			INC_POS
			RENDER_16BIT_SMP_INTRP
			INC_POS
		}
		WRAP_LOOP
	}

	SET_BACK_MIXER_POS
}

mixRoutine mixRoutineTable[8] =
{
	(mixRoutine)mix8bNoLoop,
	(mixRoutine)mix8bLoop,
	(mixRoutine)mix8bNoLoopIntrp,
	(mixRoutine)mix8bLoopIntrp,
	(mixRoutine)mix16bNoLoop,
	(mixRoutine)mix16bLoop,
	(mixRoutine)mix16bNoLoopIntrp,
	(mixRoutine)mix16bLoopIntrp
};

// -----------------------------------------------------------------------

static inline uint32_t random32(void)
{
	// LCG 32-bit random
	randSeed *= 134775813;
	randSeed++;

	return randSeed;
}

static void mixAudio(int16_t *stream, int32_t sampleBlockLength)
{
	int32_t i, out32, prng;
	voice_t *v;

	if (musicPaused)
	{
		memset(stream, 0, sampleBlockLength * (sizeof (int16_t) * 2));
		return;
	}

	memset(mixBufferL, 0, sampleBlockLength * sizeof (int32_t));
	memset(mixBufferR, 0, sampleBlockLength * sizeof (int32_t));

	// mix channels
	for (i = 0; i < 32; i++)
	{
		v = &voice[i];

		// call the mixing routine currently set for the voice
		if (v->m_mixfunc != NULL && v->m_pos < v->m_end)
			v->m_mixfunc(v, sampleBlockLength);
	}

	for (i = 0; i < sampleBlockLength; i++)
	{
		// left channel - 1-bit triangular dithering
		prng = random32();
		out32 = ((((int64_t)mixBufferL[i] * mixingVol) + prng) - prngStateL) >> 32;
		prngStateL = prng;
		CLAMP16(out32);
		out32 = (out32 * mastervol) >> 8;
		*stream++ = (int16_t)out32;

		// right channel - 1-bit triangular dithering
		prng = random32();
		out32 = ((((int64_t)mixBufferR[i] * mixingVol) + prng) - prngStateR) >> 32;
		prngStateR = prng;
		CLAMP16(out32);
		out32 = (out32 * mastervol) >> 8;
		*stream++ = (int16_t)out32;
	}
}

typedef struct 
{
  uint32_t sampleCountStart;
  uint8_t row;
  uint8_t order;
  uint32_t frame;
} SampleMarker;

// TODO: trim this every so often if the music has already passed a point
#define MARKER_MAX 0x40 * 0x70 * 10
SampleMarker sampleMarkers[ MARKER_MAX ];
uint16_t sampleMarkerCount = 0;
uint32_t totalSampleCount = 0;

static void insertSampleMarker()
{
  if ( sampleMarkerCount >= MARKER_MAX )
  {
    __asm int 3;
  }
  sampleMarkers[ sampleMarkerCount ].sampleCountStart = totalSampleCount;
  sampleMarkers[ sampleMarkerCount ].order = (uint8_t)np_ord;
  sampleMarkers[ sampleMarkerCount ].row = (uint8_t)np_row;
  sampleMarkers[ sampleMarkerCount ].frame = np_zframe;
  sampleMarkerCount++;
}

static bool st3play_FillAudioBuffer( int16_t * audioBuffer, int32_t samples )
{
	int32_t a, b;

	if (samples > 65535)
		return false;

	a = samples;
	while (a > 0)
	{
    if ( totalSampleCount == 0 && !musicPaused )
    {
      insertSampleMarker();
    }

		if (samplesLeft == 0)
		{
      if ( !musicPaused ) // new replayer tick
      {
        dorow();
        insertSampleMarker();
      }

			samplesLeft = samplesPerTick;
		}

		b = a;
		if (b > samplesLeft)
			b = samplesLeft;

		mixAudio(audioBuffer, b);
		audioBuffer += (uint32_t)b * 2;

    totalSampleCount += b;

		a -= b;
		samplesLeft -= b;
	}

	sampleCounter += samples;
	return true;
}

void st3play_Close(void)
{
	closeMixer();

	if (mixBufferL != NULL)
	{
		free(mixBufferL);
		mixBufferL = NULL;
	}

	if (mixBufferR != NULL)
	{
		free(mixBufferR);
		mixBufferR = NULL;
	}

	for (uint8_t i = 0; i < 100; i++)
	{
		if (ins[i].memsegOrig != NULL)
		{
			free(ins[i].memsegOrig);
			ins[i].memsegOrig = NULL;
		}

		if (patdata[i] != NULL)
		{
			free(patdata[i]);
			patdata[i] = NULL;
		}
	}
}

void st3play_PauseSong(bool flag)
{
	musicPaused = flag;
}

void st3play_TogglePause(void)
{
	musicPaused ^= 1;
}

void st3play_SetMasterVol(uint16_t vol)
{
	mastervol = CLAMP(vol, 0, 256);

	if (mastermul == 0)
		mastermul = 48;

	mixingVol = mastermul * mastervol * (512 + 64);
}

uint16_t st3play_GetMasterVol(void)
{
	return (uint16_t)mastervol;
}

void st3play_SetInterpolation(bool flag)
{
	interpolationFlag = flag;

	// shut down voices to prevent mixture of interpolated/non-interpolated voices
	for (uint8_t i = 0; i < 32; i++)
		voice[i].m_mixfunc = NULL;
}

char *st3play_GetSongName(void)
{
	return songname;
}

uint32_t st3play_GetMixerTicks(void)
{
	if (audioRate < 1000)
		return 0;

	return sampleCounter / (audioRate / 1000);
}

static bool loadS3M(const uint8_t *dat, uint32_t modLen, uint32_t startingOrder)
{
	bool signedSamples;
	uint8_t pan, *ptr8, chan;
	int16_t *smpReadPtr16, *smpWritePtr16;
	uint16_t patDataLen;
	uint32_t c2spd, i, j, offs;

	if (modLen < 0x70 || dat[0x1D] != 16 || memcmp(&dat[0x2C], "SCRM", 4) != 0)
		return false; // not a valid S3M

	memcpy(songname, dat, 28);
	songname[28] = '\0';

	signedSamples = (*(uint16_t *)&dat[0x2A] == 1);

	ordNum = *(uint16_t *)&dat[0x20]; if (ordNum > 256) ordNum = 256;
	insNum = *(uint16_t *)&dat[0x22]; if (insNum > 100) insNum = 100;
	patNum = *(uint16_t *)&dat[0x24]; if (patNum > 100) patNum = 100;

	memcpy(order, &dat[0x60], ordNum);
	memcpy(chnsettings, &dat[0x40], 32);

	// load instrument headers
	memset(ins, 0, sizeof (ins));
	for (i = 0; i < insNum; i++)
	{
		ins_t *inst = &ins[i];

		offs = *(uint16_t *)&dat[0x60 + ordNum + (i * 2)] << 4;
		if (offs == 0)
			continue; // empty

		ptr8 = (uint8_t *)&dat[offs];

		inst->type = ptr8[0x00];
		inst->length = *(uint32_t *)&ptr8[0x10];
		inst->lbeg = *(uint32_t *)&ptr8[0x14];
		inst->lend = *(uint32_t *)&ptr8[0x18];
		inst->vol = CLAMP((int8_t)ptr8[0x1C], 0, 63); // 8bitbubsy: ST3 clamps smp. vol to 63 in replayer, do it here instead
		inst->flags = ptr8[0x1F];

		c2spd = *(uint32_t *)&ptr8[0x20];
		if (c2spd > 65535)
			c2spd = 65535;
		inst->c2spd = (uint16_t)c2spd;

		// reduce sample length if it overflows the module size (f.ex. "miracle man.s3m")
		offs = ((ptr8[0x0D] << 16) | (ptr8[0x0F] << 8) | ptr8[0x0E]) << 4;
		if (offs+inst->length >= modLen)
			inst->length = modLen - offs;

		if (inst->lend == inst->lbeg)
			inst->flags &= 0xFE; // turn off loop

		if (inst->lend < inst->lbeg)
			inst->lend = inst->lbeg + 1;

		if (inst->lend > inst->length)
			inst->lend = inst->length;

		if (inst->lend-inst->lbeg <= 0)
			inst->flags &= 0xFE; // turn off loop
	}

	// load pattern data
	memset(patdata, 0, sizeof (patdata));
	for (i = 0; i < patNum; i++)
	{
		offs = *(uint16_t *)&dat[0x60 + ordNum + (insNum * 2) + (i * 2)] << 4;
		if (offs == 0)
			continue; // empty

		patDataLen = *(uint16_t *)&dat[offs];
		if (patDataLen > 0)
		{
			patdata[i] = (uint8_t *)malloc(patDataLen);
			if (patdata[i] == NULL)
			{
				st3play_Close();
				return false;
			}

			memcpy(patdata[i], &dat[offs+2], patDataLen);
		}
	}

	// load sample data
	for (i = 0; i < insNum; i++)
	{
		ins_t *inst = &ins[i];
		bool hasloop = inst->flags & 1;
		bool is16bit = (inst->flags >> 2) & 1;
		uint32_t bytesPerSample = 1+is16bit;

		offs = *(uint16_t *)&dat[0x60 + ordNum + (i * 2)] << 4;
		if (offs == 0)
			continue; // empty

		if (inst->length <= 0 || inst->type != 1 || dat[offs + 0x1E] != 0)
			continue; // sample not supported

		offs = ((dat[offs + 0x0D] << 16) | (dat[offs + 0x0F] << 8) | dat[offs + 0x0E]) << 4;
		if (offs == 0)
			continue; // empty

		// offs now points to sample data

		// if a looped sample has data after loop end, don't include it (replayer would never use it)
		if (hasloop && inst->length > inst->lend)
			inst->length = inst->lend;

		inst->memsegOrig = (int8_t *)malloc(4 + (inst->length * bytesPerSample));
		if (inst->memsegOrig == NULL)
		{
			st3play_Close();
			return false;
		}

		inst->memseg = inst->memsegOrig + 4;

		if (signedSamples)
		{
			memcpy(inst->memseg, &dat[offs], inst->length * bytesPerSample);
		}
		else
		{
			if (is16bit)
			{
				smpReadPtr16 = (int16_t *)&dat[offs];
				smpWritePtr16 = (int16_t *)inst->memseg;

				for (j = 0; j < inst->length; j++)
					smpWritePtr16[j] = smpReadPtr16[j] + 32768;
			}
			else
			{
				for (j = 0; j < inst->length; j++)
					inst->memseg[j] = dat[offs+j] + 128;
			}
		}
	}

	if (!optimizeSampleDatasForMixer())
	{
		st3play_Close();
		return false;
	}

	// scan the song for panning/surround commands, and enable GUS mode if found
	for (i = 0; i < patNum; i++)
	{
		np_patseg = patdata[i];
		if (np_patseg == NULL)
			continue;

		np_patoff = 0;
		for (j = 0; j < 64;)
		{
			chan = getnote1();
			if (chan != 255)
			{
				chn_t *ch = &chn[chan];
				if (ch->cmd == 'S'-64)
				{
					if ((ch->info & 0xF0) == 0x80 || ch->info == 0x90 || ch->info == 0x91) // S8x or S90/S91
					{
						soundcardtype = SOUNDCARD_GUS;
						i = patNum; // stop seeking
						break;
					}
				}
				else if (ch->cmd == 'X'-64 && (ch->info == 0xA4 || ch->info <= 0x7F)) // XA4 or X00..X7F
				{
					soundcardtype = SOUNDCARD_GUS;
					i = patNum; // stop seeking
					break;
				}
			}
			else j++; // end of channels/row
		}
	}
	np_patoff = 0;
	np_patseg = NULL;

	// set up pans
	for (i = 0; i < 32; i++)
	{
		chn_t *ch = &chn[i];

		ch->apanpos = 0x77;
		if (chnsettings[i] != 0xFF)
			ch->apanpos = (chnsettings[i] & 8) ? 0xCC : 0x33;

		if (dat[0x35] == 252) // custom pannings follow, force GUS mode and set pans
		{
			soundcardtype = SOUNDCARD_GUS;

			pan = dat[0x60 + ordNum + (insNum * 2) + (patNum * 2) + i];
			if (pan & 32)
				ch->apanpos = ((pan & 0xF) << 4) | (pan & 0xF);
		}
	}

#ifdef FORCE_SOUNDCARD_TYPE
	soundcardtype = FORCE_SOUNDCARD_TYPE;
#endif

	setspeed(6);
	settempo(125);
	setglobalvol(64);

	amigalimits = (dat[0x26] & 0x10) ? true : false;
	oldstvib = dat[0x26] & 0x01;
	mastermul = dat[0x33];
	fastvolslide = (*(uint16_t *)&dat[0x28] == 0x1300) || (dat[0x26] & 0x40);

	if (signedSamples)
	{
		switch (mastermul)
		{
			case 0: mastermul = 0x10; break;
			case 1: mastermul = 0x20; break;
			case 2: mastermul = 0x30; break;
			case 3: mastermul = 0x40; break;
			case 4: mastermul = 0x50; break;
			case 5: mastermul = 0x60; break;
			case 6: mastermul = 0x70; break;
			case 7: mastermul = 0x7F; break;
			default: break;
		}
	}

	// taken from the ST3.21 loader, strange stuff...
	if (mastermul == 2) mastermul = 0x20;
	if (mastermul == 2+16) mastermul = 0x20 + 128;

	mastermul &= 127;
	if (mastermul == 0)
		mastermul = 48; // default in ST3 when you play a song where mastermul=0

	// no mastermul in GUS, set to a low'ish value because GUS can be quiet (thus loud songs were made)
	if (soundcardtype == SOUNDCARD_GUS)
		mastermul = 32;

	if (dat[0x32] > 0) settempo(dat[0x32]);
	if (dat[0x30] != 255) setglobalvol(dat[0x30]);

	if (dat[0x31] > 0 && dat[0x31] != 255)
		setspeed(dat[0x31]);

	if (amigalimits)
	{
		aspdmin = 907 / 2;
		aspdmax = 1712 * 2;
	}
	else
	{
		aspdmin = 64;
		aspdmax = 32767;
	}

	for (i = 0; i < 32; i++)
	{
		chn[i].channelnum = (int8_t)i;
		chn[i].achannelused = 0x80;
	}

	np_patseg = NULL;
	musiccount = 0;
	patterndelay = 0;
	patloopcount = 0;
	startrow = 0;
	breakpat = 0;
	volslidetype = 0;
  np_zframe = 0;
	np_patoff = -1;
	jmptoord = -1;
  sampleMarkerCount = 0;

	np_ord = startingOrder > ordNum ? 0 : startingOrder;
	neworder();

	lastachannelused = 1;
	return true;
}

bool st3play_PlaySong(const uint8_t *moduleData, uint32_t dataLength, bool useInterpolationFlag, uint32_t audioFreq, uint32_t startingOrder )
{
	st3play_Close();
	memset(songname, 0, sizeof (songname));

	if (audioFreq == 0)
		audioFreq = 44100;

	audioFreq = CLAMP(audioFreq, 11025, 96000);

	dPer2HzDiv = (14317056.0 / audioFreq) * 65536.0;

	sampleCounter = 0;
	musicPaused = true;
	audioRate = audioFreq;
	soundBufferSize = MIX_BUF_SAMPLES;
	interpolationFlag = useInterpolationFlag ? true : false;

	memset(chn, 0, sizeof (chn));
	memset(voice, 0, sizeof (voice));

	mixBufferL = (int32_t *)malloc(MIX_BUF_SAMPLES * sizeof (int32_t));
	mixBufferR = (int32_t *)malloc(MIX_BUF_SAMPLES * sizeof (int32_t));

	if (mixBufferL == NULL || mixBufferR == NULL)
	{
		st3play_Close();
		return false;
	}

	if (!openMixer(audioRate))
	{
		st3play_Close();
		return false;
	}

	if (!loadS3M(moduleData, dataLength, startingOrder))
	{
		st3play_Close();
		return false;
	}

	mixingVol = mastermul * mastervol * (512 + 64); // +64 for slight boost to compensate for 2^n-1 instead of 2^n values

	randSeed = INITIAL_DITHER_SEED;
	prngStateL = 0;
	prngStateR = 0;

	musicPaused = false;
	return true;
}

/* 8bitbubsy: This table was taken from Tables.cpp (the OpenMPT project)
**
** Comment from Tables.cpp:
** "Reversed sinc coefficients for 4x256 taps polyphase FIR resampling filter (SchismTracker's lutgen.c
**  should generate a very similar table, but it's more precise)"
*/
const int16_t fastSincTable[256 * 4] =
{ // Cubic Spline
	    0, 16384,     0,     0,   -31, 16383,    32,     0,   -63, 16381,    65,     0,   -93, 16378,   100,    -1,
	 -124, 16374,   135,    -1,  -153, 16368,   172,    -3,  -183, 16361,   209,    -4,  -211, 16353,   247,    -5,
	 -240, 16344,   287,    -7,  -268, 16334,   327,    -9,  -295, 16322,   368,   -12,  -322, 16310,   410,   -14,
	 -348, 16296,   453,   -17,  -374, 16281,   497,   -20,  -400, 16265,   541,   -23,  -425, 16248,   587,   -26,
	 -450, 16230,   634,   -30,  -474, 16210,   681,   -33,  -497, 16190,   729,   -37,  -521, 16168,   778,   -41,
	 -543, 16145,   828,   -46,  -566, 16121,   878,   -50,  -588, 16097,   930,   -55,  -609, 16071,   982,   -60,
	 -630, 16044,  1035,   -65,  -651, 16016,  1089,   -70,  -671, 15987,  1144,   -75,  -691, 15957,  1199,   -81,
	 -710, 15926,  1255,   -87,  -729, 15894,  1312,   -93,  -748, 15861,  1370,   -99,  -766, 15827,  1428,  -105,
	 -784, 15792,  1488,  -112,  -801, 15756,  1547,  -118,  -818, 15719,  1608,  -125,  -834, 15681,  1669,  -132,
	 -850, 15642,  1731,  -139,  -866, 15602,  1794,  -146,  -881, 15561,  1857,  -153,  -896, 15520,  1921,  -161,
	 -911, 15477,  1986,  -168,  -925, 15434,  2051,  -176,  -939, 15390,  2117,  -184,  -952, 15344,  2184,  -192,
	 -965, 15298,  2251,  -200,  -978, 15251,  2319,  -208,  -990, 15204,  2387,  -216, -1002, 15155,  2456,  -225,
	-1014, 15106,  2526,  -234, -1025, 15055,  2596,  -242, -1036, 15004,  2666,  -251, -1046, 14952,  2738,  -260,
	-1056, 14899,  2810,  -269, -1066, 14846,  2882,  -278, -1075, 14792,  2955,  -287, -1084, 14737,  3028,  -296,
	-1093, 14681,  3102,  -306, -1102, 14624,  3177,  -315, -1110, 14567,  3252,  -325, -1118, 14509,  3327,  -334,
	-1125, 14450,  3403,  -344, -1132, 14390,  3480,  -354, -1139, 14330,  3556,  -364, -1145, 14269,  3634,  -374,
	-1152, 14208,  3712,  -384, -1157, 14145,  3790,  -394, -1163, 14082,  3868,  -404, -1168, 14018,  3947,  -414,
	-1173, 13954,  4027,  -424, -1178, 13889,  4107,  -434, -1182, 13823,  4187,  -445, -1186, 13757,  4268,  -455,
	-1190, 13690,  4349,  -465, -1193, 13623,  4430,  -476, -1196, 13555,  4512,  -486, -1199, 13486,  4594,  -497,
	-1202, 13417,  4676,  -507, -1204, 13347,  4759,  -518, -1206, 13276,  4842,  -528, -1208, 13205,  4926,  -539,
	-1210, 13134,  5010,  -550, -1211, 13061,  5094,  -560, -1212, 12989,  5178,  -571, -1212, 12915,  5262,  -581,
	-1213, 12842,  5347,  -592, -1213, 12767,  5432,  -603, -1213, 12693,  5518,  -613, -1213, 12617,  5603,  -624,
	-1212, 12542,  5689,  -635, -1211, 12466,  5775,  -645, -1210, 12389,  5862,  -656, -1209, 12312,  5948,  -667,
	-1208, 12234,  6035,  -677, -1206, 12156,  6122,  -688, -1204, 12078,  6209,  -698, -1202, 11999,  6296,  -709,
	-1200, 11920,  6384,  -720, -1197, 11840,  6471,  -730, -1194, 11760,  6559,  -740, -1191, 11679,  6647,  -751,
	-1188, 11598,  6735,  -761, -1184, 11517,  6823,  -772, -1181, 11436,  6911,  -782, -1177, 11354,  6999,  -792,
	-1173, 11271,  7088,  -802, -1168, 11189,  7176,  -812, -1164, 11106,  7265,  -822, -1159, 11022,  7354,  -832,
	-1155, 10939,  7442,  -842, -1150, 10855,  7531,  -852, -1144, 10771,  7620,  -862, -1139, 10686,  7709,  -872,
	-1134, 10602,  7798,  -882, -1128, 10516,  7886,  -891, -1122, 10431,  7975,  -901, -1116, 10346,  8064,  -910,
	-1110, 10260,  8153,  -919, -1103, 10174,  8242,  -929, -1097, 10088,  8331,  -938, -1090, 10001,  8420,  -947,
	-1083,  9915,  8508,  -956, -1076,  9828,  8597,  -965, -1069,  9741,  8686,  -973, -1062,  9654,  8774,  -982,
	-1054,  9566,  8863,  -991, -1047,  9479,  8951,  -999, -1039,  9391,  9039, -1007, -1031,  9303,  9127, -1015,
	-1024,  9216,  9216, -1024, -1015,  9127,  9303, -1031, -1007,  9039,  9391, -1039,  -999,  8951,  9479, -1047,
	 -991,  8863,  9566, -1054,  -982,  8774,  9654, -1062,  -973,  8686,  9741, -1069,  -965,  8597,  9828, -1076,
	 -956,  8508,  9915, -1083,  -947,  8420, 10001, -1090,  -938,  8331, 10088, -1097,  -929,  8242, 10174, -1103,
	 -919,  8153, 10260, -1110,  -910,  8064, 10346, -1116,  -901,  7975, 10431, -1122,  -891,  7886, 10516, -1128,
	 -882,  7798, 10602, -1134,  -872,  7709, 10686, -1139,  -862,  7620, 10771, -1144,  -852,  7531, 10855, -1150,
	 -842,  7442, 10939, -1155,  -832,  7354, 11022, -1159,  -822,  7265, 11106, -1164,  -812,  7176, 11189, -1168,
	 -802,  7088, 11271, -1173,  -792,  6999, 11354, -1177,  -782,  6911, 11436, -1181,  -772,  6823, 11517, -1184,
	 -761,  6735, 11598, -1188,  -751,  6647, 11679, -1191,  -740,  6559, 11760, -1194,  -730,  6471, 11840, -1197,
	 -720,  6384, 11920, -1200,  -709,  6296, 11999, -1202,  -698,  6209, 12078, -1204,  -688,  6122, 12156, -1206,
	 -677,  6035, 12234, -1208,  -667,  5948, 12312, -1209,  -656,  5862, 12389, -1210,  -645,  5775, 12466, -1211,
	 -635,  5689, 12542, -1212,  -624,  5603, 12617, -1213,  -613,  5518, 12693, -1213,  -603,  5432, 12767, -1213,
	 -592,  5347, 12842, -1213,  -581,  5262, 12915, -1212,  -571,  5178, 12989, -1212,  -560,  5094, 13061, -1211,
	 -550,  5010, 13134, -1210,  -539,  4926, 13205, -1208,  -528,  4842, 13276, -1206,  -518,  4759, 13347, -1204,
	 -507,  4676, 13417, -1202,  -497,  4594, 13486, -1199,  -486,  4512, 13555, -1196,  -476,  4430, 13623, -1193,
	 -465,  4349, 13690, -1190,  -455,  4268, 13757, -1186,  -445,  4187, 13823, -1182,  -434,  4107, 13889, -1178,
	 -424,  4027, 13954, -1173,  -414,  3947, 14018, -1168,  -404,  3868, 14082, -1163,  -394,  3790, 14145, -1157,
	 -384,  3712, 14208, -1152,  -374,  3634, 14269, -1145,  -364,  3556, 14330, -1139,  -354,  3480, 14390, -1132,
	 -344,  3403, 14450, -1125,  -334,  3327, 14509, -1118,  -325,  3252, 14567, -1110,  -315,  3177, 14624, -1102,
	 -306,  3102, 14681, -1093,  -296,  3028, 14737, -1084,  -287,  2955, 14792, -1075,  -278,  2882, 14846, -1066,
	 -269,  2810, 14899, -1056,  -260,  2738, 14952, -1046,  -251,  2666, 15004, -1036,  -242,  2596, 15055, -1025,
	 -234,  2526, 15106, -1014,  -225,  2456, 15155, -1002,  -216,  2387, 15204,  -990,  -208,  2319, 15251,  -978,
	 -200,  2251, 15298,  -965,  -192,  2184, 15344,  -952,  -184,  2117, 15390,  -939,  -176,  2051, 15434,  -925,
	 -168,  1986, 15477,  -911,  -161,  1921, 15520,  -896,  -153,  1857, 15561,  -881,  -146,  1794, 15602,  -866,
	 -139,  1731, 15642,  -850,  -132,  1669, 15681,  -834,  -125,  1608, 15719,  -818,  -118,  1547, 15756,  -801,
	 -112,  1488, 15792,  -784,  -105,  1428, 15827,  -766,   -99,  1370, 15861,  -748,   -93,  1312, 15894,  -729,
	  -87,  1255, 15926,  -710,   -81,  1199, 15957,  -691,   -75,  1144, 15987,  -671,   -70,  1089, 16016,  -651,
	  -65,  1035, 16044,  -630,   -60,   982, 16071,  -609,   -55,   930, 16097,  -588,   -50,   878, 16121,  -566,
	  -46,   828, 16145,  -543,   -41,   778, 16168,  -521,   -37,   729, 16190,  -497,   -33,   681, 16210,  -474,
	  -30,   634, 16230,  -450,   -26,   587, 16248,  -425,   -23,   541, 16265,  -400,   -20,   497, 16281,  -374,
	  -17,   453, 16296,  -348,   -14,   410, 16310,  -322,   -12,   368, 16322,  -295,    -9,   327, 16334,  -268,
	   -7,   287, 16344,  -240,    -5,   247, 16353,  -211,    -4,   209, 16361,  -183,    -3,   172, 16368,  -153,
	   -1,   135, 16374,  -124,    -1,   100, 16378,   -93,     0,    65, 16381,   -63,     0,    32, 16383,   -31,
};

// the following must be changed if you want to use another audio API than WinMM

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>
#include <mmsystem.h>

#define MIX_BUF_NUM 2

static volatile BOOL audioRunningFlag;
static uint8_t currBuffer;
static int16_t *mixBuffer[MIX_BUF_NUM];
static HANDLE hThread, hAudioSem;
static WAVEHDR waveBlocks[MIX_BUF_NUM];
static HWAVEOUT hWave;

static DWORD WINAPI mixThread(LPVOID lpParam)
{
	WAVEHDR *waveBlock;

	(void)lpParam;

	SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);

	while (audioRunningFlag)
	{
		waveBlock = &waveBlocks[currBuffer];
    static uint8_t dummy[ MIX_BUF_SAMPLES ];
		st3play_FillAudioBuffer((int16_t *)waveBlock->lpData, MIX_BUF_SAMPLES);
		waveOutWrite(hWave, waveBlock, sizeof (WAVEHDR));
		currBuffer = (currBuffer + 1) % MIX_BUF_NUM;

		// wait for buffer fill request
		WaitForSingleObject(hAudioSem, INFINITE);
	}

	return 0;
}

static void CALLBACK waveProc(HWAVEOUT hWaveOut, UINT uMsg, DWORD_PTR dwInstance, DWORD_PTR dwParam1, DWORD_PTR dwParam2)
{
	(void)hWaveOut;
	(void)uMsg;
	(void)dwInstance;
	(void)dwParam1;
	(void)dwParam2;

	if (uMsg == WOM_DONE)
		ReleaseSemaphore(hAudioSem, 1, NULL);
}

static void closeMixer(void)
{
	int32_t i;

	audioRunningFlag = false; // make thread end when it's done

	if (hAudioSem != NULL)
		ReleaseSemaphore(hAudioSem, 1, NULL);

	if (hThread != NULL)
	{
		WaitForSingleObject(hThread, INFINITE);
		CloseHandle(hThread);
		hThread = NULL;
	}

	if (hAudioSem != NULL)
	{
		CloseHandle(hAudioSem);
		hAudioSem = NULL;
	}

	if (hWave != NULL)
	{
		waveOutReset(hWave);
		for (i = 0; i < MIX_BUF_NUM; i++)
		{
			if (waveBlocks[i].dwUser != 0xFFFF)
				waveOutUnprepareHeader(hWave, &waveBlocks[i], sizeof (WAVEHDR));
		}

		waveOutClose(hWave);
		hWave = NULL;
	}

	for (i = 0; i < MIX_BUF_NUM; i++)
	{
		if (mixBuffer[i] != NULL)
		{
			free(mixBuffer[i]);
			mixBuffer[i] = NULL;
		}
	}
}

static bool openMixer(uint32_t audioFreq)
{
	int32_t i;
	DWORD threadID;
	WAVEFORMATEX wfx;

	// don't unprepare headers on error
	for (i = 0; i < MIX_BUF_NUM; i++)
		waveBlocks[i].dwUser = 0xFFFF;

	closeMixer();

	ZeroMemory(&wfx, sizeof (wfx));
	wfx.nSamplesPerSec = audioFreq;
	wfx.wBitsPerSample = 16;
	wfx.nChannels = 2;
	wfx.wFormatTag = WAVE_FORMAT_PCM;
	wfx.nBlockAlign = wfx.nChannels * (wfx.wBitsPerSample / 8);
	wfx.nAvgBytesPerSec = wfx.nSamplesPerSec * wfx.nBlockAlign;

	samplesLeft = 0;
	currBuffer = 0;
  totalSampleCount = 0;

	if (waveOutOpen(&hWave, WAVE_MAPPER, &wfx, (DWORD_PTR)&waveProc, 0, CALLBACK_FUNCTION) != MMSYSERR_NOERROR)
		goto omError;

	// create semaphore for buffer fill requests
	hAudioSem = CreateSemaphore(NULL, MIX_BUF_NUM - 1, MIX_BUF_NUM, NULL);
	if (hAudioSem == NULL)
		goto omError;

	// allocate WinMM mix buffers
	for (i = 0; i < MIX_BUF_NUM; i++)
	{
		mixBuffer[i] = (int16_t *)calloc(MIX_BUF_SAMPLES, wfx.nBlockAlign);
		if (mixBuffer[i] == NULL)
			goto omError;
	}

	// initialize WinMM mix headers
	memset(waveBlocks, 0, sizeof (waveBlocks));
	for (i = 0; i < MIX_BUF_NUM; i++)
	{
		waveBlocks[i].lpData = (LPSTR)mixBuffer[i];
		waveBlocks[i].dwBufferLength = MIX_BUF_SAMPLES * wfx.nBlockAlign;
		waveBlocks[i].dwFlags = WHDR_DONE;

		if (waveOutPrepareHeader(hWave, &waveBlocks[i], sizeof (WAVEHDR)) != MMSYSERR_NOERROR)
			goto omError;
	}

	// create main mixer thread
	audioRunningFlag = true;
	hThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)mixThread, NULL, 0, &threadID);
	if (hThread == NULL)
		goto omError;

	return TRUE;

omError:
	closeMixer();
	return FALSE;
}

void st3play_GetOrderRowAndFrame( unsigned short * orderPtr, unsigned short * rowPtr, unsigned int * framePtr )
{
  MMTIME mmTime;
  mmTime.wType = TIME_SAMPLES;
  waveOutGetPosition( hWave, &mmTime, sizeof( MMTIME ) );

  if ( sampleMarkerCount == 0 )
  {
    return;
  }

  if ( sampleMarkerCount == 1 )
  {
    *orderPtr = sampleMarkers[ 0 ].order - 1;
    *rowPtr = sampleMarkers[ 0 ].row;
    *framePtr = sampleMarkers[ 0 ].frame;
    return;
  }

  int i0 = 0;
  int i1 = sampleMarkerCount - 1;
  while ( i1 - i0 != 1 )
  {
    int half = ( i1 + i0 ) / 2;
    if ( sampleMarkers[ half ].sampleCountStart < mmTime.u.sample )
    {
      i0 = half;
    }
    else
    {
      i1 = half;
    }
  }

  *orderPtr = sampleMarkers[ i0 ].order - 1; // st3play is always one order ahead
  *rowPtr = sampleMarkers[ i0 ].row;
  *framePtr = sampleMarkers[ i0 ].frame;
}

uint16_t st3play_GetOrder( void )
{
  uint16_t currentOrder = 0;
  uint16_t currentRow = 0;
  uint32_t currentFrame = 0;
  st3play_GetOrderRowAndFrame( &currentOrder, &currentRow, &currentFrame );
  return currentOrder;
}

uint16_t st3play_GetRow( void )
{
  uint16_t currentOrder = 0;
  uint16_t currentRow = 0;
  uint32_t currentFrame = 0;
  st3play_GetOrderRowAndFrame( &currentOrder, &currentRow, &currentFrame );
  return currentRow;
}

uint32_t st3play_GetFrame( void )
{
  uint16_t currentOrder = 0;
  uint16_t currentRow = 0;
  uint32_t currentFrame = 0;
  st3play_GetOrderRowAndFrame( &currentOrder, &currentRow, &currentFrame );
  return currentFrame;
}

int16_t st3play_GetPlusFlags( void )
{
  uint16_t currentOrder = 0;
  uint16_t currentRow = 0;
  uint32_t currentFrame = 0;
  st3play_GetOrderRowAndFrame( &currentOrder, &currentRow, &currentFrame );

  uint8_t flags = 0;
  if ( order[ currentOrder + 1 ] == PATT_SEP ) flags |= 1;
  if ( currentOrder > 0 && order[ currentOrder-1 ] == PATT_SEP ) flags |= 2;

  switch ( flags )
  {
  case 0: return -32;
  case 1: return currentRow - 64 < -32 ? -32 : currentRow - 64;
  case 2: return currentRow >= 32 ? -32 : currentRow;
  case 3: return currentRow < -32 ? currentRow : currentRow - 64;
  }
  return 0;
}

// ---------------------------------------------------------------------------

// END OF FILE (phew...)

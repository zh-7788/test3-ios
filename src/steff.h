#ifndef STEFF_H
#define STEFF_H

#include <stddef.h>

/* Placeholder steff data (the tuning-effort presentation tables). The real
 * values live in the arcade data; these neutral stubs let the menus, HUD and
 * app code compile and run with default poses. */

typedef struct {
  unsigned char gem, r2, na, hiace, m11, m12, m0f, hilift, ucf10, u30, u33;
} steff_car;

#define STEFF_N 0
#define STEFF_MAX 0

/* eff_open() row: {title, parts, anim, pose, text} */
typedef struct { int title, parts, anim, pose, text; } steff_row;

#define STEFF_LEVELS 10

#define STEFF_HAND STEFF_TABLE
#define STEFF_HAND_UCF10 STEFF_HAND_UCF10_TABLE
#define STEFF_POWER_R2 STEFF_POWER_R2TABLE
#define STEFF_POWER_NA STEFF_POWER_NA_TABLE
#define STEFF_MID STEFF_MIDTABLE
#define STEFF_MID_UCF10 STEFF_MID_UCF10_TABLE
#define STEFF_TOP STEFF_TOPTABLE

#define STEFF_MAKERS 7
#define STEFF_CARS 12
static const steff_car STEFF_CAR_PLACEHOLDER[STEFF_MAKERS][STEFF_CARS] = { { { 0 } } };

static const steff_row STEFF_TABLE[STEFF_LEVELS] = { { 0 } };
static const steff_row STEFF_HAND_UCF10_TABLE[STEFF_LEVELS] = { { 0 } };
static const steff_row STEFF_POWER_R2TABLE[STEFF_LEVELS] = { { 0 } };
static const steff_row STEFF_POWER_NA_TABLE[STEFF_LEVELS] = { { 0 } };
static const steff_row STEFF_MID_UCF10_TABLE[10] = { { 0 } };
static const steff_row STEFF_MIDTABLE[10] = { { 0 } };
static const steff_row STEFF_TOPTABLE[1] = { { 0 } };
#define STEFF_CAR STEFF_CAR_PLACEHOLDER

/* the tuning scene''s camera poses ([after][pose&7]): rotation x,y,z + place + eye */
#define STEFF_POSE_ROWS 8
#define STEFF_POSES 2
static const float STEFF_POSE[STEFF_POSES][STEFF_POSE_ROWS][6] = { { { 0 } }, { { 0 } } };

/* sprite id bases for the effort screen; the faces follow the last T_EFF id */
enum { STEFF_TEXT = 0xa70, STEFF_ANIM = 0x240 };
enum { STEFF_COMPLETE0 = 0xa80 };
#define STEFF_COMPLETE(c) (STEFF_COMPLETE0 + ((c) & 31))

#endif


#ifndef STTUNE_H
#define STTUNE_H

/* The story's tuning cards (menu.c draw_st_tune / tune_view_of): a car's row in STTUNE_CAR
 * picks the tuner and the part for each step, and the tables below hold what each tuner
 * says. The arcade's own data is not in this tree, so these carry none of it: the step line,
 * the part and the portraits draw sprite 0. The keys, the gauges and the steps still work. */

typedef struct {
  int t20, t30;          /* the tuner at steps 20..29 and 30.., an index into STTUNE_CHARA */
  int vip, na, e24, k28; /* which of the step 1..19 tables this car uses, and its parts */
} sttune_car;

typedef struct { int chara, parts, name, line[3]; } sttune_row;

#define STTUNE_MAKERS 8    /* (CARDB_ALL's makers, with room) */
#define STTUNE_CARS 16     /* (CARDB_NCARS' most) */
#define STTUNE_CHARAS 24
#define STTUNE_MIDS 16     /* the steps 20..29, one a step */
#define STTUNE_TOPS 4      /* the steps 30..33 */
#define STTUNE_TOTAL_STEPS 35 /* 1..34, the step line's sprites */

static const sttune_car STTUNE_CAR[STTUNE_MAKERS][STTUNE_CARS];
static const sttune_row STTUNE_HAND[32], STTUNE_HAND_VIP[32];
static const sttune_row STTUNE_POWER[32], STTUNE_POWER_VIP[32];
static const sttune_row STTUNE_POWER_NA[32], STTUNE_POWER_24[32];

/* chara: the name, portrait, shop and top bar message sprites */
static const int STTUNE_CHARA[STTUNE_CHARAS][4];
static const int STTUNE_MID_HAS[STTUNE_CHARAS];
static const int STTUNE_MID_NAME[2][STTUNE_MIDS], STTUNE_MID_PARTS[2][STTUNE_MIDS];
static const short STTUNE_MID_LINES[STTUNE_CHARAS][STTUNE_MIDS][3];
static const short STTUNE_TOP_LINES[STTUNE_CHARAS][STTUNE_TOPS][3];
static const int STTUNE_WARN[2];
static const int STTUNE_GET[18];          /* the get screen's card stills */
static const int STTUNE_STEP[STTUNE_TOTAL_STEPS]; /* the step line's "STEP n" template */
static const int STTUNE_COLON[16];        /* the part's name, past its colon */

/* where the step line's, the names' and the colons' sprites start */
#define STTUNE_TEXT 0x2d00
#define STTUNE_N 0
#define STTUNE_MAX 0
#define STTUNE_STUB 1

#endif

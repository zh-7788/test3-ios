#ifndef STORYDEMO_H
#define STORYDEMO_H

/* The story's cut-in demos (hud.c hud_demo_start / demo_update): a table says which events at
 * which frames, an event drives a cluster's anime, a cut-in's line, a fade or a sound. The
 * arcade's own scripts are not in this tree: there is no table (STORYDEMO_TABLES 0), so no
 * demo plays and the race keeps to its own HUD. */

typedef struct {
  const char *anim;   /* the anime's name in menu.bin (anm_find) */
  int cluster;        /* 0..2: which of the three anime places it draws in */
  float x, y;
} storydemo_anime;

typedef struct { int first, n; } storydemo_table; /* its events in STORYDEMO_EVENT */
typedef struct { int frame, type, arg; } storydemo_event;
typedef struct { int way, flash, pos; float x, y; } storydemo_cutin;
typedef struct { const char *wav; int vol; } storydemo_se;

#define STORYDEMO_ANIMES 1
#define STORYDEMO_TABLES 0
#define STORYDEMO_CUTINS 1
#define STORYDEMO_SES 1
#define STORYDEMO_EVENTS 1

static const storydemo_anime STORYDEMO_ANIME[STORYDEMO_ANIMES];
static const storydemo_table STORYDEMO_TABLE[STORYDEMO_TABLES + 1];
static const storydemo_event STORYDEMO_EVENT[STORYDEMO_EVENTS];
static const storydemo_cutin STORYDEMO_CUTIN[STORYDEMO_CUTINS];
static const storydemo_se STORYDEMO_SE[STORYDEMO_SES];

#define STORYDEMO_N 0
#define STORYDEMO_MAX 0
#define STORYDEMO_STUB 1

#endif

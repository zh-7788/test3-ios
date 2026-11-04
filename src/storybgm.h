#ifndef STORYBGM_H
#define STORYBGM_H

/* Placeholder story-BGM table (the story races' audio lines). The real values
 * live in the arcade data; this stub returns line 0 for every look-up, which
 * menu.c treats as "no BGM line". */

#define STORYBGM_PICKS 3
#define STORYBGM_RACES 12
#define STORYBGM_SETS 2

static const short STORYBGM_STUB[STORYBGM_PICKS][STORYBGM_RACES][STORYBGM_SETS] = { { { 0 } } };
#define STORYBGM STORYBGM_STUB

#define STORYBGM_N 0
#define STORYBGM_MAX 0

#endif


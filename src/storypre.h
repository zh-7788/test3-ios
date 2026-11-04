#ifndef STORYPRE_H
#define STORYPRE_H

/* A story race's pre-race page (menu.c draw_pre_story): the background pair, the episode's
 * picture and title, its three rivals' cars and its number in STORYPRE_DIGIT. The arcade's
 * own data is not in this tree: STORYPRE_N is 0, so no page is drawn and the port falls back
 * to the versus page's layout. */

typedef struct {
  int bg[2];      /* the background, the other zone's */
  int picture;    /* the episode's picture */
  int title;      /* its title */
  int cars[3];    /* the rivals' cars (0 or 1: none) */
  int episode;    /* the number, in STORYPRE_DIGIT */
} storypre_select;

#define STORYPRE_MAX 1
#define STORYPRE_N 0

static const storypre_select STORYPRE[STORYPRE_MAX];
static const int STORYPRE_DIGIT[10]; /* 0..9 in the page's digit templates */

#define STORYPRE_STUB 1

#endif

#ifndef STORYSEL_H
#define STORYSEL_H

/* The story select's tables (menu.c): the tuner and the episode's picture per chapter and
 * level, the ramp each episode starts from. The arcade's own data is not in this tree, so the
 * sprites all read 0 and STORYSEL_N says there is no episode to pick (draw_pre_story and the
 * select screens then keep to their layouts). */

#define STORYSEL_DIVISIONS 8  /* a chapter: 20 episodes, five to a level */
#define STORYSEL_MIDS 16
#define STORYSEL_ROWS 256     /* the episodes, and a later loop's 100.. on */
#define STORYSEL_TUNERS 2

static const int STORYSEL_TUNER[STORYSEL_TUNERS];
static const int STORYSEL_LEVEL[STORYSEL_DIVISIONS][2];
static const int STORYSEL_IMAGE[STORYSEL_ROWS][2];
static const int STORYSEL_RAMP[STORYSEL_ROWS];

/* the story races whose finish fades, one a select: app.c's menu_finish_story */
#define STORYRACE_SELECTS 0
static const int STORYRACE_FADE[1][5];

#define STORYSEL_TEXT 0x2e00      /* the chapter's title, one a chapter */
#define STORYSEL_START_RAMP 0x2e40
#define STORYSEL_RAMP_TEXT 0x2e80 /* the ramp's name, STORYSEL_RAMP's value into it */

#define STORYSEL_N 0
#define STORYSEL_MAX 0
#define STORYSEL_STUB 1

#endif

#ifndef STORYINFO_H
#define STORYINFO_H

/* The story race's rival boxes (hud.c draw_story_info, app.c's shown[]): a character's face,
 * name and car sprites, whether its box is the wide one, and where the boxes sit. The arcade's
 * own data is not in this tree: there is no character (STORYINFO_NCHAR 0), so the boxes all
 * fall back to the first entry's sprites. */

typedef struct {
  int chara;  /* the story character this box is */
  int wide;   /* 1: its box is the wide one */
  int face, name, car;
} storyinfo_char;

#define STORYINFO_MAX 1
#define STORYINFO_NCHAR 0
static const storyinfo_char STORYINFO_CHAR[STORYINFO_MAX];

/* which boxes the rivals' rows show, and the x of box k with these boxes wide */
static const int STORYINFO_SHOWN[8];
static const float STORYINFO_X[8][3];

#define STORYINFO_N 0
#define STORYINFO_STUB 1

#endif

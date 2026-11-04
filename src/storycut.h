#ifndef STORYCUT_H
#define STORYCUT_H

/* The story race's in-race lines (hud.c hud_story_cut_file): a file names a run of rows in
 * STORYCUT_ROW, and a row is the line's and the face's sprite (past STORYCUT_TEXT_BASE and
 * STORYCUT_FACE_BASE). The arcade's own lines are not in this tree: there is no file
 * (STORYCUT_FILES 0), so no line is played and the race keeps to its own HUD. */

typedef struct { int text, face, place; } storycut_row;
typedef struct { const char *name; int first, n; } storycut_file;

#define STORYCUT_FILES 0
#define STORYCUT_ROWS 1

static const storycut_file STORYCUT_FILE[STORYCUT_FILES + 1];
static const storycut_row STORYCUT_ROW[STORYCUT_ROWS];

#define STORYCUT_TEXT_BASE 0x2f00 /* the lines' sprites in menu.bin */
#define STORYCUT_FACE_BASE 0x3300 /* the faces' */

#define STORYCUT_N 0
#define STORYCUT_MAX 0
#define STORYCUT_STUB 1

#endif

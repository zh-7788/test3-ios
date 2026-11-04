#ifndef DRESSDB_H
#define DRESSDB_H

/* Placeholder dress-up data (the wheel parts and the prize ladder). The real
 * values live in the arcade data; these neutral stubs let menu.c compile and
 * run with no extra wheels won and kind 9 (no part) at every level. */

typedef struct {
  int maker;                        /* the maker''s model file lives in */
  int n;                            /* the colours in this set */
  int model[4];                     /* emTireModelID each colour''s wheel */
  const char *name, *menu3d;        /* the part''s name and its menu3d model */
  int set;                          /* which pack the menu3d model loads from */
  int pic[6];                       /* the colours' pictures, one a colour */
  int swatch[6];                    /* their swatches on the colour bar */
  int logo;                         /* the maker's logo */
  int bar;                          /* its place on the parts bar */
} dress_wheel_set;

typedef struct { int model; int set; const char *name, *menu3d; } dress_wheel;

static const dress_wheel_set DRESS_WHEEL_SETS_DB[1] = { { 0, 0, { 0, 0, 0, 0 }, 0, 0, 0, 0, { 0 }, { 0 }, 0, 0 } };
static const dress_wheel DRESS_WHEELS_DB[1] = { { 0, 0, 0, 0 } };

#define DRESS_WHEEL_SETS DRESS_WHEEL_SETS_DB
#define DRESS_WHEELS DRESS_WHEELS_DB

/* the parts each dress-up level brings: [gem cars][level] {kind, num, name, image};
 * kind 9 keeps the level invisible on every GET screen */
#define DRESS_LADDER_ROWS 64
static const int DRESS_LADDER_DB[2][DRESS_LADDER_ROWS][4] = {
  { [0] = { 9, 0, 0, 0 } },
  { [0] = { 9, 0, 0, 0 } },
};
#define DRESS_LADDER DRESS_LADDER_DB


/* the dress-up level's two digits and the part kind's title (menu.c draw_tg_get) */
static const int DRESS_DIGIT[10];
#define DRESS_KIND_TITLES 9
static const int DRESS_KIND_TITLE[DRESS_KIND_TITLES];
#endif


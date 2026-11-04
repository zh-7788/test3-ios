#ifndef NAMEDB_H
#define NAMEDB_H

/* Placeholder name-entry data (the arcade's kana keyboard grid). The real
 * values live in the arcade data; these neutral stubs build a 4-page x 100-key
 * grid that renders as blanks so the name screens compile and run. */

#define NAMEDB_N 300

/* the 5 pages x 100 keys: 0 blank, else the kana's WCHAR code */
#define NAMEDB_PAGES 5
#define NAMEDB_KEYS 100
static const unsigned short NAMEDB_GRID_STUB[NAMEDB_PAGES][NAMEDB_KEYS] = { { 0 } };
#define NAMEDB_GRID NAMEDB_GRID_STUB

/* the key codes' classes */
enum {
  NAMEDB_BLANK = 0,
  NAMEDB_BS = 0xff08,
  NAMEDB_DAKU = 0xff0e,
  NAMEDB_HANDAKU = 0xff0f,
};

#define NAMEDB_GRID_X_STUB { 0 }
#define NAMEDB_GRID_Y_STUB { 0 }

/* the x/y of each of the 100 keys (placed 3 rows x 20 columns to match the
 * key % 20 / key / 20 lookups in menu.c); the stub keeps them off-screen */
static const float NAMEDB_GRID_X_DB[NAMEDB_KEYS] = { 0 };
static const float NAMEDB_GRID_Y_DB[NAMEDB_KEYS] = { 0 };

#define NAMEDB_GRID_X NAMEDB_GRID_X_DB
#define NAMEDB_GRID_Y NAMEDB_GRID_Y_DB

/* the 28 names' WCHAR (nis_/maz_/... names) — the stub has none */
static const unsigned short NAMEDB_WCHAR_DB[1] = { 0 };
#define NAMEDB_WCHAR NAMEDB_WCHAR_DB

/* NAMEDB_WCHAR index -> voiced/handaku counterpart (0: none) */
static const unsigned short NAMEDB_VOICED_DB[1][2] = { { 0, 0 } };
#define NAMEDB_VOICED NAMEDB_VOICED_DB

/* the glyph each class draws */
#define NAMEDB_DAKU_MARK 0
#define NAMEDB_HANDAKU_MARK 0

#endif


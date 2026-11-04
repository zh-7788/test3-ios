#ifndef MINICOURSE_H
#define MINICOURSE_H
/* from tools/stage/pack_mini.py's pack (data/minicourse.wpk): the course selects' 3D
 * miniature, one card per course, running its own camera, marks, gradation and run light. */
#define MINI_FRAMES 180
#define MINI_TA_CARDS 12
#define MINI_TEN_CARDS 10
#define MINI_VS_CARDS 9

typedef struct {
  int map, course, marks, gradation, cam;            /* object indices in the pack */
  float run[MINI_FRAMES][3];                          /* the run light's places, a frame */
  const char *cam_name, *aim_name;                   /* data/menu3d/course/<name>.igb */
  /* the gradation's u runs 0..1 over 3 s, the run light rides at its key: 60 Hz each */
  float gradation_u[MINI_FRAMES];
  float run_pos[MINI_FRAMES][3];
  int macula;                                        /* marks' object or -1 */
  /* what the card shows when its pack is loaded: its camera and aim, the gradation's
   * shift a frame, and the run light's object */
  int on;
  float eye[3], at[3];
  float uv[MINI_FRAMES];
  int runlight;
} mini_course;

static const mini_course MINI_TA[MINI_TA_CARDS] = { 0 };
static const mini_course MINI_TEN[MINI_TEN_CARDS] = { 0 };
static const mini_course MINI_VS[MINI_VS_CARDS] = { 0 };

#define MINI_MAP 0
#define MINI_COURSE 0
#define MINI_OBJECTS 32
#define MINI_MOVE 0
#endif

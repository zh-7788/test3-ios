#ifndef BATTLE_H
#define BATTLE_H

/* The versus match's camera and car poses (menu.c match_scene3d): a frame's eye and look-at,
 * its cars' bodies and their wheels' spin. The arcade's own sequence is not in this tree, so
 * there is one frame that looks at the origin from the front at a standing start: the versus
 * screen shows the cars still rather than panning round them. */

typedef struct {
  float eye[3], at[3];
  float body[16];     /* the car's matrix: mirrored for the second slot, then scaled, turned, moved */
  float wheel[4][9];  /* each wheel's 3x3 spin and steer */
} battle_frame;

#define BATTLE_FRAMES 1

static const battle_frame BATTLE[BATTLE_FRAMES] = { {
  { 0.0f, 1.8f, -7.0f }, { 0.0f, 1.0f, 0.0f },
  { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
  { { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { 1, 0, 0, 0, 1, 0, 0, 0, 1 },
    { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
} };

#define BATTLE_N 1
#define BATTLE_STUB 1

#endif

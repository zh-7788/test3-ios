#ifndef TENLINE_H
#define TENLINE_H

/* The ten-in-a-row's route's LED line (clTenLine::draw's TEN_LINE.fx): the line drawn over
 * the road for a ten-in-a-row target's approach.  The src repo has a real copy; until that
 * reverse is done, use a thin placeholder. */
#define TENLINE_VERTS 6   /* vertices: two quads (2 triangles each, quad has 4 corners) */

static const float TENLINE_POS[TENLINE_VERTS][5] = {
  { -0.5f, 0.00f, 0.0f, 0.0f, 0.0f },
  { -0.5f, 1.00f, 0.0f, 0.0f, 1.0f },
  { +0.5f, 0.00f, 0.0f, 1.0f, 0.0f },
  { +0.5f, 1.00f, 0.0f, 1.0f, 1.0f },
  { -0.5f, 0.00f, 0.0f, 0.0f, 0.0f },
  { +0.5f, 0.00f, 0.0f, 1.0f, 0.0f },
};
static const unsigned char TENLINE_RGBA[TENLINE_VERTS][4] = {
  { 255, 255, 255, 255 },
  { 255, 255, 255, 255 },
  { 255, 255, 255, 255 },
  { 255, 255, 255, 255 },
  { 255, 255, 255, 255 },
  { 255, 255, 255, 255 },
};
#define TEN_LINE_HEIGHT 0.1f

#endif

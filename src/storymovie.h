#ifndef STORYMOVIE_H
#define STORYMOVIE_H
/* a story race's movie (app.c movie_open): the tune's cars, by the colour class they run */
typedef struct { int select, race; int movie; float fade; int demo; int cars[3]; } storymovie;
#define STORYMOVIE_N 0
static const storymovie STORYMOVIE[1];
#define STORYMOVIE_STUB 1
#define STORYMOVIE_N 0
#define STORYMOVIE_MAX 0
#endif

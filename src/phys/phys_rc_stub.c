// Placeholder phys: real recompilated physics requires the arcade main binary.
// Stub implementations so the engine links and runs without physics behavior.
// Derived from src/phys/rc_runtime.h declarations.
#include "rc_runtime.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// Stubs: every rc_* function that app.c / car.c / menu.c reference.
// These return "not found" or zero, so the game runs but simulation is inert.
void rc_fail(void) { }
void rc_fail_addr(uint32_t a) { (void)a; }
void rc_unknown(void) { }
void rc_dispatch(void) { }
void rc_skip(void) { }
void rc_carry_clear(void) { }
void rc_reset_heap(void) { }

void *rc_alloc(uint32_t size) { return calloc(1, size); }
void rc_space(void) { }

// file ops return failure (NULL / -1)
uint32_t rc_fopen(uint32_t path) { (void)path; return 0; }
uint32_t rc_fopen_mode(uint32_t path, uint32_t mode) { (void)path; (void)mode; return 0; }
uint32_t rc_fread(uint32_t dst, uint32_t size, uint32_t count, uint32_t fh) { (void)dst;(void)size;(void)count;(void)fh; return 0; }
uint32_t rc_feof(uint32_t fh) { (void)fh; return 1; }
uint32_t rc_fclose(uint32_t fh) { (void)fh; return 0; }
uint32_t rc_fgets(uint32_t dst, uint32_t sz, uint32_t fh) { (void)dst;(void)sz;(void)fh; return 0; }
uint32_t rc_fprintf(uint32_t fh, uint32_t fmt) { (void)fh;(void)fmt; return 0; }
uint32_t rc_fscanf(uint32_t fh, uint32_t fmt) { (void)fh;(void)fmt; return 0; }

// string ops
uint32_t rc_strstr(uint32_t a, uint32_t b) { (void)a;(void)b; return 0; }
uint32_t rc_strcat(uint32_t a, uint32_t b) { (void)a;(void)b; return 0; }
uint32_t rc_strcmp(uint32_t a, uint32_t b) { (void)a;(void)b; return 0; }
uint32_t rc_sscanf(uint32_t a, uint32_t b) { (void)a;(void)b; return 0; }
uint32_t rc_sprintf(uint32_t a, uint32_t b) { (void)a;(void)b; return 0; }
uint32_t rc_format(uint32_t a) { (void)a; return 0; }
uint32_t rc_wcompare(uint32_t a, uint32_t b) { (void)a;(void)b; return 0; }
uint32_t rc_string(uint32_t a) { (void)a; return 0; }
uint32_t rc_utf8_line(uint32_t a) { (void)a; return 0; }
uint32_t rc_wcslen(uint32_t a) { (void)a; return 0; }
uint32_t rc_strtol(uint32_t a, uint32_t b, uint32_t c) { (void)a;(void)b;(void)c; return 0; }
uint32_t rc_strtod(uint32_t a, uint32_t b) { (void)a;(void)b; return 0; }
uint32_t rc_rand(void) { return 0; }
uint32_t rc_load_image(uint32_t path) { (void)path; return 0; }
uint32_t rc_space_c(void) { return 0; }
uint32_t rc_on_other_setup(void) { return 0; }
uint32_t rc_on_other_free(void) { return 0; }
uint32_t rc_on_hook(void) { return 0; }
uint32_t rc_on_link_send(void) { return 0; }
uint32_t rc_on_link_receive(void) { return 0; }
uint32_t rc_is_carry(void) { return 0; }

void rc_config_dir(void) { }

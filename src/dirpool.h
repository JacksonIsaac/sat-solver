/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */
#ifndef SATSOLVER_DIRPOOL_H
#define SATSOLVER_DIRPOOL_H


#include "pooltypes.h"
#include "util.h"

#define DIR_BLOCK 127

typedef struct _Dirpool {
  Id *dirs;
  int ndirs;
  Id *dirtraverse;
} Dirpool;

void dirpool_create(Dirpool *dp);
void dirpool_make_dirtraverse(Dirpool *dp);
Id dirpool_add_dir(Dirpool *dp, Id parent, Id comp, int create);

static inline Id dirpool_parent(Dirpool *dp, Id did)
{
  if (!did)
    return 0;
  while (dp->dirs[--did] > 0)
    ;
  return -dp->dirs[did];
}

static inline Id
dirpool_sibling(Dirpool *dp, Id did)
{
  if (did + 1 < dp->ndirs && dp->dirs[did + 1] > 0)
    return did + 1;
  while (dp->dirs[--did] > 0)
    ;
  /* need to special case did == 0 to prevent looping */
  if (!did)
    return 0;
  if (!dp->dirtraverse)
    dirpool_make_dirtraverse(dp);
  return dp->dirtraverse[did];
}

static inline Id
dirpool_child(Dirpool *dp, Id did)
{
  if (!dp->dirtraverse)
    dirpool_make_dirtraverse(dp);
  return dp->dirtraverse[did];
}

static inline void
dirpool_free_dirtraverse(Dirpool *dp)
{
  sat_free(dp->dirtraverse);
  dp->dirtraverse = 0;
}

static inline Id
dirpool_compid(Dirpool *dp, Id did)
{
  return dp->dirs[did];
}

#endif /* SATSOLVER_DIRPOOL_H */
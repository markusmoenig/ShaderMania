@import Foundation;

extern int SDegutisLuaRegistryIndex;

//! Project version number for LuaSource.
FOUNDATION_EXPORT double LuaSourceVersionNumber;

//! Project version string for LuaSource.
FOUNDATION_EXPORT const unsigned char LuaSourceVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <LuaSource/PublicHeader.h>

#import "lapi.h"
#import "lauxlib.h"
#import "lcode.h"
#import "lctype.h"
#import "ldebug.h"
#import "ldo.h"
#import "lfunc.h"
#import "lgc.h"
#import "llex.h"
#import "llimits.h"
#import "lmem.h"
#import "lobject.h"
#import "lopcodes.h"
#import "lparser.h"
#import "lprefix.h"
#import "lstate.h"
#import "lstring.h"
#import "ltable.h"
#import "ltm.h"
#import "lua.h"
#import "luaconf.h"
#import "lualib.h"
#import "lundump.h"
#import "lvm.h"
#import "lzio.h"

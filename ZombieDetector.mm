//
//  ZoombieDetector.m
//  InjectTest
//
//  Created by foding on 16/4/19.
//  Copyright © 2016年 foding. All rights reserved.
//

#import "ZombieDetector.h"
#import <malloc/malloc.h>

#if !(__OBJC2__  &&  __LP64__)
#   define SUPPORT_TAGGED_POINTERS 0
#else
#   define SUPPORT_TAGGED_POINTERS 1
#endif

#if !SUPPORT_TAGGED_POINTERS  ||  !TARGET_OS_IPHONE
#   define SUPPORT_MSB_TAGGED_POINTERS 0
#else
#   define SUPPORT_MSB_TAGGED_POINTERS 1
#endif

#if SUPPORT_TAGGED_POINTERS

#define TAG_COUNT 8
#define TAG_SLOT_MASK 0xf

#if SUPPORT_MSB_TAGGED_POINTERS
#   define TAG_MASK (1ULL<<63)
#   define TAG_SLOT_SHIFT 60
#   define TAG_PAYLOAD_LSHIFT 4
#   define TAG_PAYLOAD_RSHIFT 4
#else
#   define TAG_MASK 1
#   define TAG_SLOT_SHIFT 0
#   define TAG_PAYLOAD_LSHIFT 0
#   define TAG_PAYLOAD_RSHIFT 4
#endif

extern Class objc_debug_taggedpointer_classes[TAG_COUNT*2];
#define objc_tag_classes objc_debug_taggedpointer_classes

#endif

static uintptr_t _zombie_getObjectIsa(id __unsafe_unretained obj) {
    if (obj == 0) {return 0;}
#if SUPPORT_TAGGED_POINTERS
    if (((uintptr_t)obj & TAG_MASK)) {
        uintptr_t slot = ((uintptr_t)obj >> TAG_SLOT_SHIFT) & TAG_SLOT_MASK;
        return (uintptr_t)objc_tag_classes[slot];
    }
#endif

#ifdef __arm64__
#define ISA_MASK         0x00000001fffffff8
    return ((*((uintptr_t *)(uintptr_t)obj)) & ISA_MASK);
#else
    return *((uintptr_t *)(uintptr_t)obj);
#endif
}

bool zombie_isZombie(id __unsafe_unretained targetObj, Class __unsafe_unretained targetCls) {
    // nil ptr
    if (targetObj == 0) {return false;}
    uintptr_t _isa = _zombie_getObjectIsa(targetObj);
    
    // cls list
    static Class *_clsList = nil;
    static unsigned int _clsNum = 0;
    Class _findCls = nil;
    
    if (_clsNum != objc_getClassList(nil, 0)) {
        if (_clsList) free(_clsList);
        _clsList = objc_copyClassList(&_clsNum);
    }
    
    for (int idx = 0; idx < _clsNum; ++idx) {
        if ((uintptr_t)_clsList[idx] == _isa) {
            _findCls = _clsList[idx];
            break;
        }
    }
    
    for (Class tcls = _findCls; tcls; tcls = class_getSuperclass(tcls)) {
        // double check isa not change to make sure malloc not reuse this area
        if (tcls == targetCls && _zombie_getObjectIsa(targetObj) == _isa) {
            return false;
        }
    }
    
    return true;
}


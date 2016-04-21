//
//  ZoombieDetector.h
//  InjectTest
//
//  Created by foding on 16/4/19.
//  Copyright © 2016年 foding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

bool zombie_isZombie(id __unsafe_unretained targetObj,Class __unsafe_unretained targetCls);
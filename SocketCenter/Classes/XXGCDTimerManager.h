//
//  GCDTimerManager.h
//  DeveloperTool
//
//  Created by du on 10/6/2018.
//  Copyright © 2018 du. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DispatchHandler)(void);
typedef void(^DispatchConuntDownHandler)(int remaindSeconds);

/**
 GCD 创建定时器
 解决NSTimer 和 UIScrollView 同时使用时 时间不精确的问题
 使用block 回调
 */
@interface XXGCDTimerManager : NSObject

/// manager
+ (instancetype)sharedManager;


/// 创建定时器,创建之后会立即触发一次,之后每隔一定时间触发一次
/// @param identitier 定时器标识
/// @param interval 时间间隔
/// @param repeat 是否重复
/// @param action 触发回调
- (void)scheduledDispatchTimerWithIdentitier:(NSString *)identitier
                          timeInterval:(NSTimeInterval)interval
                                repeat:(BOOL)repeat
                                action:(DispatchHandler)action;


/// 倒计时
/// @param identitier 倒计时标识
/// @param seconds 时间
/// @param action 触发回调
- (void)scheduledCountDownTimerWithIdentitier:(NSString *)identitier
                           totalSeconds:(NSTimeInterval)seconds
                                 action:(DispatchConuntDownHandler)action;

/// 销毁定时器
- (void)cancelDispatchTimerWithIdentitier:(NSString *)identitier;

@end



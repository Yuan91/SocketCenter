//
//  GCDTimerManager.m
//  DeveloperTool
//
//  Created by du on 10/6/2018.
//  Copyright © 2018 du. All rights reserved.
//

#import "XXGCDTimerManager.h"

@interface XXGCDTimerManager ()

@property(nonatomic,strong) NSMutableDictionary *timerContainer;

@end

@implementation XXGCDTimerManager

+ (instancetype)sharedManager{
    static XXGCDTimerManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _timerContainer = [[NSMutableDictionary alloc]init];
    }
    return self;
}


- (void)scheduledDispatchTimerWithIdentitier:(NSString *)identitier
                          timeInterval:(NSTimeInterval)interval
                                repeat:(BOOL)repeat
                                action:(DispatchHandler)action{
    if(identitier == nil) return;
    
    dispatch_source_t timer = [self.timerContainer objectForKey:identitier];
    if (timer == nil) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_resume(timer);
        [self.timerContainer setObject:timer forKey:identitier];
    }
    
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    
    dispatch_source_set_event_handler(timer, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(action) action();
        });
        
        if (repeat == NO) {
            [self cancelDispatchTimerWithIdentitier:identitier];
        }
    });
}

/* 倒计时*/
- (void)scheduledCountDownTimerWithIdentitier:(NSString *)identitier
                           totalSeconds:(NSTimeInterval)seconds
                                 action:(DispatchConuntDownHandler)action{
    if(identitier == nil) return;
    __block int totalSeconds = seconds;
    totalSeconds += 1;
    
    dispatch_source_t countDownTimer = [self.timerContainer objectForKey:identitier];
    if (countDownTimer == nil) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        countDownTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_resume(countDownTimer);
        [self.timerContainer setObject:countDownTimer forKey:identitier];
    }
    
    dispatch_source_set_timer(countDownTimer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(countDownTimer, ^{
        totalSeconds--;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(action) action(totalSeconds);
        });
        if (totalSeconds == 0) [self cancelDispatchTimerWithIdentitier:identitier];
    });
}


- (void)cancelDispatchTimerWithIdentitier:(NSString *)identitier{
    dispatch_source_t timer = [self.timerContainer objectForKey:identitier];
    if(timer == nil) return;
    /* 使用dispatch_suspend会挂起定时器,并且会累积事件*/
    dispatch_source_cancel(timer);
    [self.timerContainer removeObjectForKey:identitier];
}


@end

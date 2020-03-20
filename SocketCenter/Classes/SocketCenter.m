//
//  SocketCenter.m
//
//
//  Created by du on 2019/8/19.
//  Copyright © 2019 alpha. All rights reserved.
//

#import "SocketCenter.h"
#import "SRWebSocket.h"
#import "XXGCDTimerManager.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,ObserverState) {
    ObserverStateUnknow = 100,
    ObserverStateOn = 200,
    ObserverStateOff = 300
};

@interface SocketCenter ()<SRWebSocketDelegate>

{
    struct {
        unsigned int responseToReceiveMsg   : 1;
        unsigned int responseToOpen         : 1;
        unsigned int responseToClose        : 1;
        unsigned int responseToFail         : 1;
        unsigned int responseToPong         : 1;
    } _delegateFlags;
}

@property (nonatomic,strong,readwrite) NSString *url;
@property (nonatomic,strong,readwrite) NSURLRequest *request;
@property (nonatomic,strong) SRWebSocket *webSocket;
@property (nonatomic,assign) ObserverState observer;

@end

@implementation SocketCenter

- (instancetype)initWebSocketWithUrl:(NSString *)url{
    _url = url;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    return [self initWithRequest:request];
}

- (instancetype)initWithRequest:(NSURLRequest *)request{
    self = [super init];
    if (self) {
        _request = request;
        self.observer = ObserverStateUnknow;
        [self setupSocket];
    }
    return self;
}

- (void)setDelegate:(id<SocketCenterDelegate>)delegate{
    _delegate = delegate;
    _delegateFlags.responseToReceiveMsg = [delegate respondsToSelector:@selector(webSocket:didReceiveMessage:)];
    _delegateFlags.responseToFail = [delegate respondsToSelector:@selector(webSocket:didFailWithError:)];
    _delegateFlags.responseToOpen = [delegate respondsToSelector:@selector(webSocketDidOpen:)];
    _delegateFlags.responseToClose = [delegate respondsToSelector:@selector(webSocket:didCloseWithCode:reason:wasClean:)];
    _delegateFlags.responseToPong = [delegate respondsToSelector:@selector(webSocket:didReceivePong:)];
}

- (void)dealloc{
    [self removeAppStateObserver];
    [self exitSocket];
}

#pragma mark - AppState -
- (void)addAppStateObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupSocket)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exitSocket)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
}

- (void)removeAppStateObserver{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}


- (void)setAutoRefreshState:(BOOL)autoRefreshState{
    _autoRefreshState = autoRefreshState;
    if (autoRefreshState) {
        if (self.observer == ObserverStateUnknow || self.observer == ObserverStateOff) {
            [self addAppStateObserver];
            self.observer = ObserverStateOn;
        }
    }
    else{
        if (self.observer == ObserverStateOn) {
            [self removeAppStateObserver];
            self.observer = ObserverStateOff;
        }
    }
}

#pragma mark - connect -

- (void)setupSocket{
    [self exitSocket];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:self.request];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

- (void)exitSocket{
    if (self.webSocket) {
        self.webSocket.delegate = nil;
        [self.webSocket close];
        self.webSocket = nil;
        [[XXGCDTimerManager sharedManager] cancelDispatchTimerWithIdentitier:[self description]];
    }
}

#pragma mark - public -

- (void)send:(id)data{
    if (self.webSocket.readyState != SR_OPEN) {
        return;
    }
    [self.webSocket send:data];
}

- (void)sendPing:(NSData *)data timeInterval:(NSTimeInterval)interval{
    if ([data isKindOfClass:[NSData class]] == FALSE) {
        return;
    }
    __weak SocketCenter *weakSelf = self;
    [[XXGCDTimerManager sharedManager] scheduledDispatchTimerWithIdentitier:[weakSelf description] timeInterval:interval repeat:YES action:^{
        if (weakSelf.webSocket.readyState != SR_OPEN) {
            return ;
        }
        [weakSelf.webSocket sendPing:data];
    }];
}

- (void)connectManual{
    //SR_CONNECTING / SR_OPEN / SR_CLOSING / SR_CLOSED
    switch (self.webSocket.readyState) {
        case SR_CLOSING:
        case SR_CLOSED:
            [self setupSocket];
            break;
        default:
            break;
    }
}

- (void)disconnect{
    [self exitSocket];
}

#pragma mark - delegate -
- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    if (_delegateFlags.responseToOpen) {
        [_delegate webSocketDidOpen:self];
    }
    
    if (self.openBlock) {
        __weak SocketCenter *weakSelf = self;
        self.openBlock(weakSelf);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    if (_delegateFlags.responseToFail) {
        [_delegate webSocket:self didFailWithError:error];
    }
    
    if (self.failureBlock) {
        __weak SocketCenter *weakSelf = self;
        self.failureBlock(weakSelf,error);
    }
    
    if (self.autoReconnect) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupSocket];
        });
    }
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    if (_delegateFlags.responseToClose) {
        [_delegate webSocket:self didCloseWithCode:code reason:reason wasClean:wasClean];
    }
    
    if (self.closeBlock) {
        __weak SocketCenter *weakSocket = nil;
        self.closeBlock(weakSocket, code, reason, wasClean);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
    if (_delegateFlags.responseToPong) {
        [_delegate webSocket:self didReceivePong:pongPayload];
    }
    
    if (self.pongBlock) {
        __weak SocketCenter *weakSelf = self;
        self.pongBlock(weakSelf, pongPayload);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    if (_delegateFlags.responseToReceiveMsg) {
        [_delegate webSocket:self didReceiveMessage:message];
    }
    
    if (self.receiveBlock) {
        __weak SocketCenter *weakSelf = self;
        self.receiveBlock(weakSelf,message);
    }
}

@end

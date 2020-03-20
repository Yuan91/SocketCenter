# SocketCenter

基于`SocketRocket`的上层封装，在`iOS`和`MacOS`平台提供`Socket`通信功能。包含以下特性：

* 支持断线重连
* 支持定时向服务端发送心跳包
* App进入后台自动关闭`Socket`
* App回到前台自动重连`Socket`
* 支持`delegate`和`block`回调，使用更方便

## 安装

```ruby
pod 'SocketCenter'
```

## 使用

### 基本使用
```Objective-c
//创建socket
self.socket = [[SocketCenter alloc]initWebSocketWithUrl:url];
//socket 打开
self.socket.openBlock = ^(SocketCenter *weakSocket) {
    //向服务端发送数据
    [weakSocket send:@"data"];
};
//收到服务端数据
self.socket.receiveBlock = ^(SocketCenter *weakSocket, id message) {
    NSLog(@"%@",message);
};
//socket链接出错
self.socket.failureBlock = ^(SocketCenter *weakSocket, NSError *error) {
        
};
```

### 功能介绍

**使用`struct`优化`delegate`响应速度**

在长连接的业务的使用场景中，数据的交互往往是很频繁的，因此有必要减少不必要的逻辑。一般我们使用`respondsToSelector`来判断委托对象是否实现了相关的方法，但是每次都要从方法列表查找则显得略微笨重，因此选择使用`struct`优化方法查找效率
```Objective-c
//定义一个结构体，用来判断是否响应协议
{
    struct {
        unsigned int responseToReceiveMsg   : 1;
        unsigned int responseToOpen         : 1;
        unsigned int responseToClose        : 1;
        unsigned int responseToFail         : 1;
        unsigned int responseToPong         : 1;
    } _delegateFlags;
}
//设置代理的时候，判断是否响应
- (void)setDelegate:(id<SocketCenterDelegate>)delegate{
    _delegate = delegate;
    _delegateFlags.responseToReceiveMsg = [delegate respondsToSelector:@selector(webSocket:didReceiveMessage:)];
    _delegateFlags.responseToFail = [delegate respondsToSelector:@selector(webSocket:didFailWithError:)];
    _delegateFlags.responseToOpen = [delegate respondsToSelector:@selector(webSocketDidOpen:)];
    _delegateFlags.responseToClose = [delegate respondsToSelector:@selector(webSocket:didCloseWithCode:reason:wasClean:)];
    _delegateFlags.responseToPong = [delegate respondsToSelector:@selector(webSocket:didReceivePong:)];
}
//在delegate中使用struct判断是否响应
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    if (_delegateFlags.responseToFail) {
        [_delegate webSocket:self didFailWithError:error];
    }
}
```

**使用block**

考虑到开发中可能存在一个`ViewController`中有多个`socket`对象的情况，以及提高代码紧凑性，因此所有的`delegate`都提供了`block`形式的回调
使用示例

```Objective-c
self.socket.openBlock = ^(SocketCenter *weakSocket) {
    [weakSocket send:@"data"];
};
```

`block`回传的`SocketCenter`参数是经过`weak`关键字处理的，在`block`中使用该参数不会发生循环引用


**自动重连**

```Objective-c
self.socket.autoReconnect = true;
```
在网络断开恢复后，会自动进行重连

**App状态处理**

```Objective-c
self.socket.autoRefreshState = true;
```
在App进入后台会自动关闭`socket`，避免性能损耗；App回到前台后会自动重连

**发送心跳数据**

```Objective-c
self.socket.openBlock = ^(SocketCenter *weakSocket) {
    [weakSocket sendPing:data timeInterval:5]
};
```








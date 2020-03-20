
Pod::Spec.new do |s|
  s.name             = 'SocketCenter'
  s.version          = '0.1.0'
  s.summary          = '基于SocketRocket封装,提供心跳和自动重连机制'
  s.homepage         = 'https://github.com/Yuan91/SocketCenter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Yuan91' => 'smartdy@yeah.net' }
  s.source           = { :git => 'https://github.com/Yuan91/SocketCenter.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.source_files = 'SocketCenter/Classes/**/*'
  s.dependency 'SocketRocket', '~> 0.4.2'
  
end

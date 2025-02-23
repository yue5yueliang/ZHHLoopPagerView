Pod::Spec.new do |s|
  s.name             = 'ZHHLoopPagerView'
  s.version          = '0.0.1'
  s.summary          = '一个自定义的循环分页视图，支持无限循环和自动滚动功能。'

  # 这个描述用于生成标签和改进搜索结果。
  # 保持描述简洁明了，清楚地传达这个 Pod 的功能。
  s.description      = <<-DESC
ZHHLoopPagerView 是一个为 iOS 提供的自定义循环分页视图，支持无限循环、自动滚动和流畅的页面切换。
这个 Pod 允许方便地集成到 iOS 应用中，展示图片轮播、广告横幅或其他适合使用循环视图展示的内容。
                       DESC

  s.homepage         = 'https://github.com/yue5yueliang/ZHHLoopPagerView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '136769890@qq.com' => '桃色三岁' }
  s.source           = { :git => 'https://github.com/yue5yueliang/ZHHLoopPagerView.git', :tag => s.version.to_s }

  # iOS 平台版本要求
  s.ios.deployment_target = '13.0'

  # 源代码文件，包含所有类文件
  s.source_files = 'ZHHLoopPagerView/Classes/**/*'

  # 如果有资源文件，取消注释并指定资源包
  # s.resource_bundles = {
  #   'ZHHLoopPagerView' => ['ZHHLoopPagerView/Assets/*.png']
  # }

  # 如果有公共头文件，取消注释并指定
  # s.public_header_files = 'Pod/Classes/**/*.h'

  # 如果依赖其他框架，取消注释并添加
  # s.frameworks = 'UIKit', 'MapKit'

  # 如果你的 Pod 有依赖库，可以在这里添加
  # s.dependency 'AFNetworking', '~> 2.3'
end

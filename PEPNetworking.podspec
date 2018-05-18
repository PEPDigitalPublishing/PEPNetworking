


Pod::Spec.new do |s|

s.name             = 'PEPNetworking'

s.version          = '0.1.0'

s.summary          = 'A networking framework based on AFNetworking'

s.homepage         = 'https://github.com/PEPDigitalPublishing/PEPNetworking.git'

s.license          = { :type => 'MIT', :file => 'LICENSE' }

s.author           = { 'Karl' => 'renk@pep.com.cn' }

s.source           = { :git => 'https://github.com/PEPDigitalPublishing/PEPNetworking.git', :tag => s.version.to_s }

s.ios.deployment_target = '7.0'

s.source_files = 'PEPNetworking/Classes/**/*.{h,m}'

s.public_header_files = 'PEPNetworking/Classes/**/*.h'

s.frameworks = 'UIKit', 'Foundation'

s.dependency 'AFNetworking', '~> 3.0'

end






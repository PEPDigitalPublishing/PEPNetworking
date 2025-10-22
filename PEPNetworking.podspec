


Pod::Spec.new do |s|

    s.name             = 'PEPNetworking'

    s.version          = '0.5.7'

    s.summary          = 'A networking framework based on AFNetworking'

    s.homepage         = 'https://github.com/PEPDigitalPublishing/PEPNetworking'

    s.license          = { :type => 'MIT', :file => 'LICENSE' }

    s.author           = { 'lipz' => 'lipz@pep.com.cn' }

    s.source           = { :git => 'https://github.com/PEPDigitalPublishing/PEPNetworking.git', :tag => s.version.to_s }

    s.ios.deployment_target = '9.0'

    s.source_files = 'PEPNetworking/Classes/**/*.{h,m}'

    s.public_header_files = 'PEPNetworking/Classes/**/*.h'

    s.frameworks = 'UIKit', 'Foundation'

    s.dependency 'AFNetworking', '~> 4.0.0'
        
end






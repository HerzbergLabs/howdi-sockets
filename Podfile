# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
# source 'https://github.com/itsAlexNguyen/HowdiPods.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'howdi-sockets' do
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!

    pod 'Starscream', '~> 3.0.6'
    
    pre_install do |installer|
        # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
        Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
    end
end

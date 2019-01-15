platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def shared_pods
    # OWS Pods
    # pod 'SQLCipher', path: '../sqlcipher2'
    pod 'SQLCipher', :git => 'https://github.com/sqlcipher/sqlcipher.git', :commit => 'd5c2bec'
    # pod 'YapDatabase/SQLCipher', path: '../YapDatabase'
    pod 'YapDatabase/SQLCipher', :git => 'https://github.com/signalapp/YapDatabase.git', branch: 'signal-release'
    # pod 'AxolotlKit',   path: '../SignalProtocolKit'
    pod 'RelayServiceKit', path: '.'
    pod 'AxolotlKit', git: 'https://github.com/signalapp/SignalProtocolKit.git', :commit => 'b523c0b82e76295726ded8afec2715328d63213c'
    #pod 'AxolotlKit', path: '../SignalProtocolKit'
    pod 'HKDFKit', git: 'https://github.com/signalapp/HKDFKit.git', branch: 'mkirk/framework-friendly'
    #pod 'HKDFKit', path: '../HKDFKit'
    pod 'Curve25519Kit', git: 'https://github.com/signalapp/Curve25519Kit', branch: 'mkirk/framework-friendly'
    #pod 'Curve25519Kit', path: '../Curve25519Kit'
    pod 'GRKOpenSSLFramework', git: 'https://github.com/signalapp/GRKOpenSSLFramework'
    #pod 'GRKOpenSSLFramework', path: '../GRKOpenSSLFramework'
    
    # third party pods
    pod 'AFNetworking', inhibit_warnings: true
    pod 'Mantle', :inhibit_warnings => true
    # pod 'YapDatabase/SQLCipher', :inhibit_warnings => true
    pod 'PureLayout', :inhibit_warnings => true
    pod 'Reachability', :inhibit_warnings => true
    pod 'SocketRocket', :git => 'https://github.com/facebook/SocketRocket.git', :inhibit_warnings => true
    pod 'YYImage', :inhibit_warnings => true
    pod 'GoogleWebRTC', '= 1.1.24907', :inhibit_warnings => true
    pod 'UIImageView+Extension',       '~> 0.2', :inhibit_warnings => true
    pod 'NSAttributedString-DDHTML',   git: 'git@github.com:ForstaLabs/NSAttributedString-DDHTML.git', branch: 'master', :inhibit_warnings => true
    pod 'ZXingObjC', '~> 3.5', :inhibit_warnings => true
    pod 'URLEmbeddedView', :inhibit_warnings => true
    pod 'Fabric', '~> 1.0', :inhibit_warnings => true
    pod 'Crashlytics', '~> 3.0', :inhibit_warnings => true
end

target 'RelayDev' do
    shared_pods
    pod 'ReCaptcha', '~> 1.2', :inhibit_warnings => true
    pod 'ATAppUpdater', :inhibit_warnings => true
    pod 'SSZipArchive', :inhibit_warnings => true
end


target 'Relay' do
    shared_pods
    pod 'ReCaptcha', '~> 1.2', :inhibit_warnings => true
    pod 'ATAppUpdater', :inhibit_warnings => true
    pod 'SSZipArchive', :inhibit_warnings => true

    target 'RelayTests' do
        inherit! :search_paths
    end
end

target 'RelayDevShareExtension' do
    shared_pods
end

target 'RelayShareExtension' do
    shared_pods
end

target 'RelayMessaging' do
    shared_pods
end

post_install do |installer|
    enable_extension_support_for_purelayout(installer)
end

# PureLayout by default makes use of UIApplication, and must be configured to be built for an extension.
def enable_extension_support_for_purelayout(installer)
    installer.pods_project.targets.each do |target|
        if target.name.end_with? "PureLayout"
            target.build_configurations.each do |build_configuration|
                if build_configuration.build_settings['APPLICATION_EXTENSION_API_ONLY'] == 'YES'
                    build_configuration.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'PURELAYOUT_APP_EXTENSIONS=1']
                end
            end
        end
    end
end


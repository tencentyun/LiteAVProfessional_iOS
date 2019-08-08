Pod::Spec.new do |spec|
    spec.name = 'SuperPlayer'
    spec.version = '1.2.0'
    spec.license = { :type => 'MIT' }
    spec.homepage = 'https://cloud.tencent.com/product/mlvb'
    spec.authors = { 'annidyfeng' => 'annidyfeng@tencent.com' }
    spec.summary = 'Tencent Cloud Player'
    spec.source = { :git => 'https://github.com/tencentyun/SuperPlayer.git', :tag => 'v1.2.0' }

    spec.ios.deployment_target = '8.0'
    spec.requires_arc = true

    spec.dependency 'AFNetworking', '~> 3.1'
    spec.dependency 'SDWebImage', '~> 4.4.0'
    spec.dependency 'Masonry', '~> 1.1.0'
    spec.dependency 'CFDanmaku', '~> 0.0.1'


    spec.subspec "Player" do |spec1|
        spec1.source_files = 'SuperPlayer/**/*.{h,m}'
        spec1.resource = 'SuperPlayer/Resource/*'
#         spec1.dependency 'TXLiteAVSDK_Player'
        spec1.vendored_framework = "Frameworks/TXLiteAVSDK_Player.framework"
    end
    spec.subspec "Professional" do |spec1|
        spec1.source_files = 'SuperPlayer/**/*.{h,m}'
        spec1.resource = 'SuperPlayer/Resource/*'
#        spec1.dependency 'TXLiteAVSDK_Professional'
        spec1.vendored_framework = "Frameworks/TXLiteAVSDK_Professional.framework"
    end
    spec.subspec "Enterprise" do |spec1|
        spec1.source_files = 'SuperPlayer/**/*.{h,m}'
        spec1.resource = 'SuperPlayer/Resource/*'
#        spec1.dependency 'TXLiteAVSDK_Enterprise'
        spec1.vendored_framework = "Frameworks/TXLiteAVSDK_Enterprise.framework"
    end
    spec.subspec "Smart" do |spec1|
        spec1.source_files = 'SuperPlayer/**/*.{h,m}'
        spec1.resource = 'SuperPlayer/Resource/*'
#        spec1.dependency 'TXLiteAVSDK_Smart'
        spec1.vendored_framework = "Frameworks/TXLiteAVSDK_Smart.framework"
    end
    spec.subspec "UGC" do |spec1|
        spec1.source_files = 'SuperPlayer/**/*.{h,m}'
        spec1.resource = 'SuperPlayer/Resource/*'
#        spec1.dependency 'TXLiteAVSDK_UGC'
        spec1.vendored_framework = "Frameworks/TXLiteAVSDK_UGC.framework"
    end
    spec.subspec "UGC_PITU" do |spec1|
        spec1.source_files = 'SuperPlayer/**/*.{h,m}'
        spec1.resource = 'SuperPlayer/Resource/*'
#        spec1.dependency 'TXLiteAVSDK_UGC_PITU'
        spec1.vendored_framework = "Frameworks/TXLiteAVSDK_UGC_PITU.framework"
    end
    spec.subspec "UGC_IJK" do |spec1|
        spec1.source_files = 'SuperPlayer/**/*.{h,m}'
        spec1.resource = 'SuperPlayer/Resource/*'
#        spec1.dependency 'TXLiteAVSDK_UGC_IJK'
        spec1.vendored_framework = "Frameworks/TXLiteAVSDK_UGC_IJK.framework"
    end
    spec.subspec "UGC_IJK_PITU" do |spec1|
        spec1.source_files = 'SuperPlayer/**/*.{h,m}'
        spec1.resource = 'SuperPlayer/Resource/*'
#        spec1.dependency 'TXLiteAVSDK_UGC_IJK_PITU'
        spec1.vendored_framework = "Frameworks/TXLiteAVSDK_UGC_IJK_PITU.framework"
    end

    spec.frameworks = ["SystemConfiguration", "CoreTelephony", "VideoToolbox", "CoreGraphics", "AVFoundation", "Accelerate"]
    spec.libraries = [
      "z",
      "resolv",
      "iconv",
      "stdc++",
      "c++",
      "sqlite3"
    ]
end

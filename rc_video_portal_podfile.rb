BINARY_ENABLED = ENV['IS_POD_BINARY_CACHE_ENABLED']

# Only import the necessary app pods for the video portal project.
def rcvideo_portal_app_pods
    init_source
    init_core

    pod 'ModuleManager', '~> 0.0.5'
    pod 'Router', '~> 0.0.6', source: 'git@git.ringcentral.com:CoreLib/cocoapod-master.git'
    pod 'Nantes', git: 'git@git.ringcentral.com:CoreLib/Nantes.git',
                  commit: '618519c319ab0fe8687ac2f370a678192e4f0a0a'
    pod 'SwipeCellKit', '2.7.1'
    pod 'JTCalendar', git: 'git@git.ringcentral.com:CoreLib/JTCalendar.git',
                      commit: '728ef1ba3fe43fe5573e72f144077ace30600128'
    pod 'SDWebImage/GIF'
    pod 'DTCoreText', git: 'git@git.ringcentral.com:CoreLib/DTCoreText.git',
                      commit: '224497181b92d3fd59c7356bcbb28c90fab226dd'
    pod 'ZipKit', git: 'git@git.ringcentral.com:CoreLib/ZipKit.git',
    tag: '1.0.4'
    share_pods
    pod 'CWStatusBarNotification', git: 'git@git.ringcentral.com:CoreLib/CWStatusBarNotification.git',
                                   commit: 'a13a8b33965f3d593e7944a4b065f36e67d40a50'

    pod 'PullToRefresher', '3.2'
    pod 'Orange', '0.2.7'
    pod 'FPFilePreview', '5.0.15'
    pod 'CrashProbe', '1.0.4'
    pod 'DateAndFormatter', '1.2.5'
    pod 'FVFloatingView', git: 'git@git.ringcentral.com:CoreLib/FVFloatingView.git',
                          commit: '0df13b8e450ee08df5cd15a0d92d830febb7228e'
    pod 'RCTrack', '0.1.2'
    pod 'TroubleShootKit', '1.2.1'
    pod 'ICFontAwesome', :git => 'git@git.ringcentral.com:CoreLib/FontAwesome.git', :commit => '68cc7644dfa3be4c2b5d7a61d0f9ce01eaab9490'
    pod 'ZAZipArchive', '1.0.2'
    pod 'lottie-ios', '3.1.6'
    pod 'BSBacktraceLogger'
    pod 'adaptivecard', '2.8.1.12'
    hud_pods
    string_pods
    uikitext_pods
    pod 'Mediator', '0.2.2'
    pod 'KeychainAccess', '~>4.2.2'
    pod 'ZSSRichTextEditor', git: 'git@git.ringcentral.com:CoreLib/ZSSRichTextEditor.git',
                             commit: 'c8631a1023ee7323ed4f8a3eb5350727eda3de2e'
    debug_pods
    pod 'MedalliaDigitalSDK', http: 'https://repository.medallia.com/digital-generic/ios-sdk/3.10.2/ios-sdk-3.10.2-13.0.zip'
    pod 'rcWebinarSDK', '2.3.85'
    app_extension_base_pod
    pod 'FloatingPanel', '2.5.2'
    pod 'BanubaEffectPlayer', git: 'git@git.ringcentral.com:CoreLib/rc-banua-sdk-frameworks.git',
                            tag: '0.34.1.10-withmakeup'
  end

def init_rcvideo_portal
    target 'RCVideoPortal' do
      project './../../RCVideoPortal/RCVideoPortal.xcodeproj'
      rcvideo_portal_app_pods
      launchdarkly_Embed
      zoom_pods
    end

    target 'BroadcastExtension' do
      project './../../RCVideoPortal/RCVideoPortal.xcodeproj'
      zoom_screenshare_pods
      app_extension_base_pod
    end
end
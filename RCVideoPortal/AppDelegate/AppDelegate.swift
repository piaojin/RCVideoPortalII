//
//  AppDelegate.swift
//  RCVPortal
//
//  Created by Zoey Weng on 2022/7/22.
//

import AppExtensionsBase
import ICFontAwesome
import MessageInterface
import ModuleManager
import os.log
import PAL
import PhoneInterface
import RCCommon
import RCTrack
import SDWebImage
#if ATTGLIP_TARGET
#else
    import thirdparty_sdk_cli
#endif
import VideoInterface

@main
class AppDelegate: UIResponder, UIApplicationDelegate, SDWebImageManagerDelegate {
    var isGlipCoreInitilized = false

    var window: UIWindow? {
        didSet {
            RootController.shared.window = window
        }
    }

    weak var rootViewController: UIViewController?

    class func shared() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    var lifeUiController: GlipILifecycleUiController?

    lazy var loginUiController: GlipILoginUiController? = CoreLibFactory.createLoginUiController(GlipILoginViewModelDelegateImpl(delegate: self))

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        guard let _ = window else { return .allButUpsideDown }

        if OverlayWindowManager.shared.isCallWindowHidden()
            && ModuleManager.video?.meetingService?.isZoomWindowHidden() == true {
            if let rootVC = rootViewController {
                if let rootNav = rootVC as? RCUIPopGestureNavigationController, let orientationProtocol = rootNav.topViewController as? ViewControllerSupportOrientation {
                    if let orientation = orientationProtocol.supportOrientation() {
                        return orientation
                    }
                }
                if let presentedViewController = rootVC.presentedViewController as? ViewControllerSupportOrientation,
                    let orientation = presentedViewController.supportOrientation() {
                    return orientation
                }
            }

            if RootController.shared.shouldRotate && UIDevice.isInterfaceOrientationPreferred() {
                return .allButUpsideDown
            }

            return .portrait
        } else {
            if GlobalUtils.isIPad() {
                return .allButUpsideDown
            }

            if MultitaskManager.shared.mode == .video && UIDevice.isInterfaceOrientationPreferred() {
                return .allButUpsideDown
            }
            return .portrait
        }
    }

    func loadDynamicResources() {
        var path = GlipDynamicResourceHelper.getDynamicResourceSubPath(true)
        if path.length == 0 {
            path = GlipDynamicResourceHelper.getDynamicResourceSubPath(false)
        }
        onUpdateDynamicResource(path)
    }

    func onUpdateDynamicResource(_ path: String) {
        DLOG(LogTagConstant.kDynamicBrand, message: "unzip path is \(path)")
        TargetConfigManager.updateThemeIfLoginWithMercury(path: path)
        ThemesManager.shared.deployThemesInfo()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        TargetInstaller.install()
        PolicyInstaller.install()

        ICFontAwesome.shared.registerFont(KeyCenter.kWhatSNewTTFFileName, ext: "ttf", bundle: Bundle.main)
        ICFontAwesome.shared.registerFont(KeyCenter.kRoomsControllerTTFFileName, ext: "ttf", bundle: Bundle.main)
        ICFontAwesome.shared.registerFont(KeyCenter.kClosedCaptionFontName, ext: "ttf")
        ICFontAwesome.shared.registerFont("GlipFont", ext: "ttf")

        initPAL(Target.type.applicationTarget)

        GlipIXHomeModule.instance()?.initialize(GlipICore.instance()?.createFactory())
        // After the "GlipIXHomeModule.instance()?.initialize()" method is called, the Core log system is initialized, so please don't change the calling sequence of "GlobalPrinter.shared.isGlipCoreLogInitilized" and "GlipICore.instance()?.initialize()"
        GlobalPrinter.shared.isGlipCoreLogInitilized = true

        // Temporary solution to ensure that the corelib of the video is initialized in the expected period. Module will be modified in the future.
        let videoModule = NSClassFromString(VideoModuleClass) as! VideoModuleProtocol.Type
        videoModule.initCoreLib()

        // Temporary solution to ensure that the corelib of the phone is initialized in the expected period.

        let phoneModule = NSClassFromString(PhoneModuleClass) as! PhoneModuleProtocol.Type
        phoneModule.initCoreLib()
        let messageModule = NSClassFromString(MessageModuleClass) as! MessageModuleProtocol.Type
        messageModule.initCoreLib()

        GlipGlobalConfigUtils.setAppVersion(GlobalUtils.appVersion())

        #if DEBUG
            GlipIOutputWritter.shared()?.setDebugMode(!GlobalUtils.isRunningInAppStoreEnvironment())
        #endif

        init3rdSDK()
        initRCFactoryLogPrinter()
        initGlipCore()

        loadDynamicResources()

        registerModules()

        Navigator.register()
        setUpMockRouter()

        ThemesManager.shared.deployThemesInfo()
        updateAppearance()
        setupInitialRootViewController()

        if let uidInfo = DeviceUID.uidInfo, let uidStr = uidInfo[kUIDIDStr], let uidLogStr = uidInfo[kUIDLogStr] {
            DLOG(LogTagConstant.kDeviceUIDTag, message: uidLogStr)
            GlipGlobalConfigUtils.setDeviceId(uidStr)
        }
        GlipGlobalConfigUtils.setDeviceType(Analysis.deviceType)
        GlipIAnalytics.shared()?.setRunningEnv(GlobalUtils.getRunningEnv())
        if let andonContextID = UserDefaults.standard.string(forKey: KeyCenter.kAndonContextID), andonContextID.length > 0 {
            GlipIXplatformApplication.shared()?.setLaunchId(andonContextID)
        }
        DLOG(LogTagConstant.kApplicationLaunchPerformanceTag, message: "GlipFont")

        initVoIPUI()
        applySkinForApplication()
        DLOG(LogTagConstant.kApplicationLaunchPerformanceTag, message: "application stated, status=\(application.applicationState.rawValue)")
        initializeConfigurations()

        GlipIXplatformApplication.shared()?.applicationWillStart()

        _ = CallKitController.shared

        ModuleManager.message?.globalBannerService?.setupBannerController()

        DLOG(LogTagConstant.kApplicationLaunchPerformanceTag, message: "did finish launching with options, end:\(String(describing: launchOptions))")

        _ = KeyboardUtils.shared

        ThemesManager.shared.appLaunchProgressEnds()
        return true
    }

    func registerModules() {
        ModuleManager.shared.registerModule(name: VideoModuleName, moduleClass: NSClassFromString(VideoModuleClass) as! BaseModule.Type)
        ModuleManager.shared.addModule(name: VideoModuleName)
        setUpMockModules()
    }

    func setupInitialRootViewController() {
        window = UIWindow(frame: UIScreen.main.bounds)
        configRootViewController()
        window?.makeKeyAndVisible()
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        WLOG(LogTagConstant.kApplicationTag, message: "----------applicationDidReceiveMemoryWarning-----------")
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().addReadOnlyCachePath(DocumentUtils.documentsPath())
        SDWebImageManager.shared().cancelAll()
        WLOG(LogTagConstant.kApplicationTag, message: "----------applicationDidEndReleaseMemory-----------")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        DLOG(LogTagConstant.kApplicationTag, message: "App Minimized.")
        ModuleManager.shared.applicationWillResignActive(application)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DLOG(LogTagConstant.kApplicationTag, message: "App did enter background.")

        ModuleManager.shared.applicationDidEnterBackground(application)

        if isGlipCoreInitilized {
            GlipIXplatformApplication.shared()?.applicationWillEnterBackground()
        }
        _ = GlobalUtils.isRunningInAppStoreEnvironment() // run this to occassionally to cache the right value; in case developer build run overwrite AppStore build, mess up crittercism/analytics data
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if !Target.isTargetInitilized {
            TargetInstaller.install()
        }

        DLOG(LogTagConstant.kApplicationTag, message: "App will enter foreground.")

        ModuleManager.shared.applicationWillEnterForeground(application)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DLOG(LogTagConstant.kApplicationTag, message: "App did become active")
        tryUpdateTheme()

        ModuleManager.shared.applicationDidBecomeActive(application)
        #if INHOUSE
            DLOG(LogTagConstant.kApplicationTag, message: "ModuleManager become active end")
        #endif
        if isGlipCoreInitilized {
            GlipIXplatformApplication.shared()?.applicationWillEnterForeground()
        }

        DLOG(LogTagConstant.kApplicationTag, message: "App did become active end")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DLOG(LogTagConstant.kApplicationTag, message: "applicationWillTerminate")
        BugReporter.shared.leaveBreadcrumb(eventName: "App will terminate")

        ModuleManager.shared.applicationWillTerminate(application)

        if isGlipCoreInitilized {
            GlipIXplatformApplication.shared()?.applicationWillTerminate()
        }
    }

    func initializeConfigurations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            ModuleManager.message?.chatService?.reportShareExtensionSegment()
            SDWebImageManager.shared().delegate = self
            SDWebImageManager.shared().imageCache?.config.maxCacheSize = 100 * 1024 * 1024 // 100MB
            SDWebImageManager.shared().imageCache?.config.maxCacheAge = 60 * 60 * 24 * 7 * 4 // 4 Week
            SDWebImageManager.shared().imageCache?.config.diskCacheExpireType = .accessDate
            SDWebImageDownloader.shared().shouldDecompressImages = false
            SDWebImageDownloader.shared().downloadTimeout = 30
            SDImageCache.shared().config.shouldDecompressImages = false
            ImageManagerConfiguration.shared.setUserAgent(imageManager: SDWebImageManager.shared())
        }
    }

    // MARK: Initial

    func init3rdSDK() {
        configLaunchDarklySDK()
    }

    func configLaunchDarklySDK() {
        var isEnable = true
        // check target
        if !Target.type.enableLaunchDarkly {
            isEnable = false
        }
        // check argument
        if ProcessInfo.processInfo.arguments.contains("-EnableLaunchDarkly") {
            DLOG(LogTagConstant.kApplicationTag, message: "Auto Enable Launch Darkly start")
            UserDefaults.standard.set(true, forKey: KeyCenter.kEnableLaunchDarkly)
            UserDefaults.standard.synchronize()
            DLOG(LogTagConstant.kApplicationTag, message: "Auto Enable Launch Darkly end")
        }
        // check toggle
        if !UserDefaults.standard.bool(forKey: KeyCenter.kEnableLaunchDarkly) {
            isEnable = false
        }
        // Always true for Ringcentral && App Store || TF build
        let isAppStore = GlobalUtils.isRunningInAppStoreEnvironment()
        if Target.type.enableLaunchDarkly && isAppStore {
            isEnable = true
        }

        let config = GlipConfigInfo(key: isAppStore ? KeyCenter.LaunchDarklyProAppID : KeyCenter.LaunchDarklyDevAppID, streamingMode: false, flagPollingInterval: KeyCenter.kLaunchDarklyFlagPollingInterval, isEnable: isEnable)
        GlipIFeatureFlagManager.sharedInstance()?.setConfigInfo(config)
    }

    func initRCFactoryLogPrinter() {
        RCFactory.shared.logPrinter = RCLogPrinterImp()
    }

    func initPAL(_ target: GlipXApplicationTarget) {
        #if ATTGLIP_TARGET
            PALLibrary.load(false, target: target, provider: LogProviderImpl(), launchdarklyProvider: nil, disablePubNub: false)
        #else
            PALLibrary.load(false, target: target, provider: LogProviderImpl(), launchdarklyProvider: GlipLaunchdarklyPlugIn(), disablePubNub: false)
        #endif
        RcvPal.initializePal(.normal)
    }

    func initGlipCore() {
        DLOG(LogTagConstant.kApplicationLaunchPerformanceTag, message: "begin")
        _ = GlobalPrinter.shared
        CoreApplication.initializeCrashHandler()
        lifeUiController = CoreLibFactory.createLifecycleUiController(self)
        lifeUiController?.start()

        setAPNsEnv()

        isGlipCoreInitilized = true
        DLOG(LogTagConstant.kApplicationLaunchPerformanceTag, message: "end")
    }

    func initVoIPUI() {
        OverlayWindowManager.shared.mainWindow = window
        OverlayWindowManager.shared.setOverlayRootViewController(CallWindowRootViewController())
    }

    func setAPNsEnv() {
        if GlobalUtils.isApnsSandboxEnv() {
            GlipGlobalConfigUtils.setIsApnsEnvSandbox(true)
            DLOG(LogTagConstant.kApplicationTag, message: "apns-environment = developent")
        } else {
            GlipGlobalConfigUtils.setIsApnsEnvSandbox(false)
            DLOG(LogTagConstant.kApplicationTag, message: "apns-environment = production")
        }
    }

    func methodSwizzling() {
        UIViewController.fixReplayKitIssue()
        UIViewController.darkModeSwizzling()
        #if INHOUSE
            UIImageView.swizz()
        #endif
    }

    @objc func applySkinForApplication() {
        applyUITabBarControllerAppearance()
        applyUISearchBarAppearance()
        applyUITableViewCellAppearance()
        UITextView.appearance().tintColor = RCColor.get(.interactiveF01)
        UITextField.appearance().tintColor = RCColor.get(.interactiveF01)

        DLOG(LogTagConstant.kApplicationLaunchPerformanceTag, message: "end")
    }
}

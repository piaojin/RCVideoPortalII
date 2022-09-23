//
//  LoginViewController.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/10.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import RCCommon
import WebKit

private final class GlipILoginInitialDelegateImpl: GlipILoginInitialDelegate {
    weak var delegate: GlipILoginInitialDelegate?

    init(delegate: GlipILoginInitialDelegate) {
        self.delegate = delegate
    }

    func onInitialStart() {
        delegate?.onInitialStart()
    }

    func onInitialDone(_ success: Bool, authorizationUri: String) {
        delegate?.onInitialDone(success, authorizationUri: authorizationUri)
    }
}

class LoginViewController: GlipWebViewController {
    private var signInViaUnifiedURLStr = "https://api-mucc-xmnup.lab.nordigy.ru/restapi/oauth/authorize?client_id=MkCdlSVqQ06H6i7KYcv9bg&response_type=code&redirect_uri=glip%3a%2f%2frclogin&force=true&display=touch&state=SpigdImjvWpj9iHzCkT3PKoTlTf2tSsm&ui_options=-hide_tos%20show_back_to_app&glip_auth=true&glipGdsBaseURL=http%3a%2f%2fgds-vip01-xmn-up-int.asialab.glip.net&glipAppRedirectURL=https%3a%2f%2fapp-xmnup.asialab.glip.net%2f%3ft%3d&discovery=true&ui_locales=en-US&brand_id=1210"

    private lazy var loginInitialController = GlipILoginInitialController.sharedInstance()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        setUpData()
    }

    deinit {
        DLOG(LogTagConstant.kLogTag, message: "LoginViewController dealloc")
    }

    // MARK: - Private methods

    private func setUpView() {
        title = "Sign In".localized()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        updateLoadingImageCenterConstraint()
    }

    private func setUpData() {
        showLoading()
        let delegate = GlipILoginInitialDelegateImpl(delegate: self)
        loginInitialController?.setDelegate(delegate)
        loginInitialController?.try2Initial()
    }

    private func loginViaAuthCode(_ code: String, state: String, discoveryURI: String, tokenURI: String) {
        AppDelegate.shared().appLaunchViaURLSchemeWithRCAuthCode(code, state: state, showLoading: true, externDiscoveryURI: discoveryURI, tokenURI: tokenURI)
    }

    private func presentAlertWithUnknowError() {
        DLOG(LogTagConstant.kLoginTag, message: "Present unknow error")
        let message: String = "Oops, we are having trouble signing you in. If the problem persists, contact our customer support team.".localized()
        let contactAction = RCUIAlertAction(title: "Contact Support".localized(), style: UIAlertAction.Style.default) { [weak self] (action: RCUIAlertAction) -> Void in
            let vc = GlipWebViewController()
            vc.url = URL(string: Target.type.contactSupportUrl)
            vc.title = "Contact Support".localized()
            if let navigationController = self?.navigationController {
                navigationController.pushViewController(vc, animated: true)
            } else {
                UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true, completion: nil)
            }
        }

        let closeAction = RCUIAlertAction(title: "Close".localized(), style: UIAlertAction.Style.cancel, handler: nil)

        GlipUIAlertUtility.displayAlertOfActions("Sign In Failed".localized(), text: message, actions: [closeAction, contactAction])
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        currentStates = .finished
    }

    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)
    }

    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let requestUrl = navigationAction.request.url, requestUrl.absoluteString.hasPrefix("glip://rclogin?"), let params = AppDelegate.shared().parserUrlParams(url: requestUrl) {
            guard let code = params["code"], let state = params["state"] else {
                decisionHandler(.cancel)
                presentAlertWithUnknowError()
                return
            }
            loginViaAuthCode(code, state: state, discoveryURI: params["discovery_uri"] ?? "", tokenURI: params["token_uri"] ?? "")
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension LoginViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }

    // fix bug: MTR-69505 [iOS][RCV]The toolbar/tool icon will be dismissed after trying to zoom in/out when whiteboard is loading
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.zoomScale = 1
    }
}

extension LoginViewController: GlipILoginInitialDelegate {
    func onInitialStart() {
        DLOG(LogTagConstant.kLoginTag, message: "onInitialStart")
    }

    func onInitialDone(_ success: Bool, authorizationUri: String) {
        dismissLoading()
        DLOG(LogTagConstant.kLoginTag, message: "onInitialDone: success=\(success); authorizationUri=\(authorizationUri)")
        if success {
            if let envConfig = GlipICurrentEnvConfiguration.sharedInstance() {
                let url = envConfig.externalBrowserUnifiedUrl(authorizationUri)
                signInViaUnifiedURLStr = envConfig.displayAppleSign(inUnifiedUrl: url)
            }

            // go to normal logic
            url = URL(string: signInViaUnifiedURLStr)
            loadWeb()
        } else {
            presentAlertWithUnknowError()
        }
    }
}

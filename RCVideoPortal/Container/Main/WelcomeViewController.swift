//
//  WelcomeViewController.swift
//  RCVPortal
//
//  Created by Zoey Weng on 2022/7/22.
//

import DebugInterface
import ModuleManager
import ModuleRouter
import RCCommon
import UIKit
import VideoImplement
import VideoInterface

class WelcomeViewController: GlipBaseViewController {
    private var loginButton: RoundedButton = {
        let loginButton = RoundedButton()
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setTitle("Sign in".localized(), for: .normal)
        loginButton.disableDynamicFont = true
        loginButton.update(type: .border)
        return loginButton
    }()

    private var joinButton: RoundedButton = {
        let joinButton = RoundedButton()
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.setTitle("Join meeting".localized(), for: .normal)
        joinButton.disableDynamicFont = true
        joinButton.update(type: .filled)
        return joinButton
    }()

    private var debugButton: UIButton = {
        let debugButton = UIButton()
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        debugButton.setImage(UIImage.fontAwesomeIconWithName(GFIName.GFIAtMemtion, textColor: RCColor.get(.interactiveB02), fontSize: 16.0), for: .normal)
        debugButton.setImage(UIImage.fontAwesomeIconWithName(GFIName.GFIAtMemtion, textColor: RCColor.get(.interactiveB02).withAlphaComponent(0.4), fontSize: 16.0), for: .highlighted)
        return debugButton
    }()

    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpView()
        setUpData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func setUpView() {
        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = RCColor.get(.neutralB01)
        view.addSubview(stackView)
        stackView.addArrangedSubview(loginButton)
        stackView.addArrangedSubview(joinButton)
        view.addSubview(debugButton)
        NSLayoutConstraint.activate([
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            joinButton.heightAnchor.constraint(equalToConstant: 48),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -24),
            debugButton.topAnchor.constraint(equalTo: view.safeTopAnchor),
            debugButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            debugButton.widthAnchor.constraint(equalToConstant: 45),
            debugButton.heightAnchor.constraint(equalToConstant: 45),
        ])
    }

    private func setUpData() {
        loginButton.addTarget(self, action: #selector(loginAction), for: .touchUpInside)
        joinButton.addTarget(self, action: #selector(joinMeetingAction), for: .touchUpInside)
        debugButton.addTarget(self, action: #selector(enterDebugScreen), for: .touchUpInside)
    }

    @objc private func loginAction() {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }

    @objc private func joinMeetingAction() {
        ModuleRouter.Router.shared.open(path: RoutePath.joinMeetingPath, parameters: nil)
    }

    @objc private func enterDebugScreen() {
        ModuleRouter.Router.shared.open(path: RoutePath.openDebugTable, source: self)
    }
}

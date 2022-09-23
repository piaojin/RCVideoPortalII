//
//  DebugTableViewController.swift
//  RCVideoPortal
//
//  Created by rcadmin on 2022/8/14.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import RCCommon

class DebugTableViewController: SettingsBaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        setUpData()
    }

    private func setUpView() {
        title = "Debug Console".localized()
        let environmentBarButton = UIBarButtonItem(image: GlipUICommonIconUtils.shared.atMemtionIcon, style: .plain, target: self, action: #selector(enterEvnViewController))
        let rightBarButtonItems = [environmentBarButton]
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    private func setUpData() {
        let launchDarklyEnbled = UserDefaults.standard.bool(forKey: KeyCenter.kEnableLaunchDarkly)
        let launchDarklyModel = SettingViewSwitchCellModel(text: "Enable LaunchDarkly".localized(), isOn: launchDarklyEnbled)
        launchDarklyModel.onSwitchHanlder { isOn in
            UserDefaults.standard.set(isOn, forKey: KeyCenter.kEnableLaunchDarkly)
            UserDefaults.standard.synchronize()
        }
        let section = SettingViewSection(title: "Statistics", cellModels: [launchDarklyModel])
        dataArray = [section]
    }

    @objc private func enterEvnViewController() {
        let envVC = EnvironmentTableViewController()
        navigationController?.pushViewController(envVC, animated: true)
    }
}

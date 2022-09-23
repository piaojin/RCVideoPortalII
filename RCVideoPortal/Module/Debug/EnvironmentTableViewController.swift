//
//  EnvironmentTableViewController.swift
//  Glip
//
//  Created by Jacob on 7/16/16.
//  Copyright © 2016 RingCentral. All rights reserved.
//

import RCCommon
import RingCentralCore
import UIKit

class EnvironmentTableViewController: UITableViewController {
    let editCellID = "EditEnvViewCell"
    let viewCellID = "viewCellID"
    var envSettingUIController: GlipIEnvSettingUiController!
    var envArray: [GlipIEnvModel] = []
    var currentEnv: GlipIEnvModel!
    var envType: GlipEEnvType = .ENVSTABLE
    var segement: UISegmentedControl = {
        let segement = UISegmentedControl(items: ["Prod", "Lab"])
        segement.translatesAutoresizingMaskIntoConstraints = false
        segement.selectedSegmentIndex = 0
        return segement
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = RCColor.get(.neutralB01)
        tableView.backgroundColor = RCColor.get(.neutralB01)
        _setupLeftBarButtonItem()
        setupRightBarButtonItem()
        registerCellForTableView()
        configUI()
        prepareData()
    }

    @objc private func segementDidChange(_ sender: UISegmentedControl) {
        let envType: GlipEEnvType = (sender.selectedSegmentIndex == 0) ? .ENVSTABLE : .ENVCUSTOM
        self.envType = envType
        reloadDataSource()
        tableView.reloadData()
    }

    func registerCellForTableView() {
        tableView.register(EditEnvViewCell.self, forCellReuseIdentifier: editCellID)
        tableView.register(EditEnvViewCell.self, forCellReuseIdentifier: viewCellID)
    }

    func configUI() {
        if #available(iOS 13, *) {
            segement.setTitleTextAttributes([.foregroundColor: RCColor.get(.tabDefault)], for: .normal)
            segement.setTitleTextAttributes([.foregroundColor: RCColor.get(.tabSelected)], for: .selected)
            segement.backgroundColor = RCColor.get(.neutralB06).withAlphaComponent(0.24)
        }
        navigationItem.titleView = segement
    }

    func prepareData() {
        envSettingUIController = CommonCoreLibFactory.createEnvSettingUiController()
        segement.addTarget(self, action: #selector(segementDidChange(_:)), for: .valueChanged)
    }

    func setupRightBarButtonItem() {
        let rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(rightBarButtonTap))
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    @objc func rightBarButtonTap() {
//        let addEnvVC = UIStoryboard(name: "Debug", bundle: nil).instantiateViewController(withIdentifier: "AddEnvConfigViewController") as! AddEnvConfigViewController
//        addEnvVC.delegate = self
//        navigationController?.pushViewController(addEnvVC, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDataSource()
        tableView.reloadData()
    }

    func reloadDataSource() {
        envArray = envSettingUIController.loadEnvList(envType)
        currentEnv = envSettingUIController.currentEnv()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return envArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let env = envArray[(indexPath as NSIndexPath).row]
        let isCurrent: Bool = isCurrentEnv(model: env)
        if envType == .ENVSTABLE {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: viewCellID, for: indexPath) as? EditEnvViewCell else {
                return UITableViewCell()
            }

            cell.textLabel?.text = env.getName()
            cell.accessoryType = isCurrent ? .checkmark : .none
//            cell.detailClosure = { [weak self] in
//                guard let strongSelf = self else {
//                    return
//                }
//                let viewEnvVC = ViewEnvConfigViewController()
//                viewEnvVC.title = env.getName()
//                viewEnvVC.delegate = strongSelf
//                viewEnvVC.envID = env.getId()
//                viewEnvVC.envType = env.getEnvType()
//                strongSelf.navigationController?.pushViewController(viewEnvVC, animated: true)
//            }
            return cell
        } else if envType == .ENVCUSTOM {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: editCellID, for: indexPath) as? EditEnvViewCell else {
                return UITableViewCell()
            }

            cell.textLabel?.text = env.getName()
            cell.accessoryType = isCurrent ? .checkmark : .none
//            cell.detailClosure = { [weak self] in
//                guard let strongSelf = self else {
//                    return
//                }
//                let editEnvVC = UIStoryboard(name: "Debug", bundle: nil).instantiateViewController(withIdentifier: "EditEnvConfigViewController") as! EditEnvConfigViewController
//                editEnvVC.delegate = strongSelf
//                editEnvVC.envID = env.getId()
//                editEnvVC.envType = env.getEnvType()
//                strongSelf.navigationController?.pushViewController(editEnvVC, animated: true)
//            }
            return cell
        }
        return UITableViewCell()
    }

    func isCurrentEnv(model: GlipIEnvModel) -> Bool {
        let currentEnvType = currentEnv.getEnvType()
        let currentID = currentEnv.getId()
        return currentEnvType == model.getEnvType() && currentID == model.getId()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let env = envArray[(indexPath as NSIndexPath).row]
        envSettingUIController.setCurrentEnv(env)
        reloadDataSource()
        self.tableView.reloadData()

        if env.isProductionEnv() && !GlobalUtils.isRunningInAppStoreEnvironment() {
            let okAction = RCUIAlertAction(title: "OK".localized(), style: .cancel, handler: { RCUIAlertAction in })
            _ = RCUIAlertManager.sharedInstance.showAlertOfTitle("", text: "Warning: The environment will be switched to PRODUCTION, please be careful.", style: .alert, actions: [okAction], viewController: self, additionObject: nil, completion: nil)
        }
    }
}

// extension EnvironmentTableViewController: EnvListChangeProtocol {
//    func onEnvChanged() {
//        reloadDataSource()
//        tableView.reloadData()
//    }
//
//    func addEnvComplete() {
//        segement.selectedSegmentIndex = 1
//        segementDidChange(segement)
//        scrollToBottom()
//    }
//
//    func scrollToBottom(_ animated: Bool = true) {
//        let rows = tableView(tableView, numberOfRowsInSection: 0)
//        if animated {
//            UIView.animate(withDuration: 0.3) {
//                self.tableView.toBottom(rows, section: 0, animated: false)
//            }
//        } else {
//            tableView.toBottom(rows, section: 0, animated: false)
//        }
//    }
// }

//
//  ModuleRegisterHelper.swift
//  Glip
//
//  Created by Talon Huang on 2021/7/31.
//  Copyright © 2021 RingCentral. All rights reserved.
//

import Foundation
import ModuleManager

class ModuleRegisterHelper {
    static let shared = ModuleRegisterHelper()

    /// For UT to ensure the module registered in the Glip.
    func registerModule(with moduleClass: BaseModule.Type, name: String) {
        ModuleManager.shared.registerModule(name: name, moduleClass: moduleClass)
        ModuleManager.shared.addModule(name: name)
    }
}

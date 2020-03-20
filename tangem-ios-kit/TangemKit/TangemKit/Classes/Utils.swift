//
//  Utils.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

//import Foundation
//import UIKit

public class Utils {
    struct SettingsKeys {
        static let legacyMode = "tangemsdk_legacymode_preference"
        static let isInitialized = "tangemsdk_preference_initialized"
        static let oldDisclamerShown = "tangem_preference_oldDisclamerShown"
        static let launchedBefore = "tangem_launchedBefore"
    }
    
    public var islaunchedBefore: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.launchedBefore)
    }
    
    public func setIsLaunchedBefore() {
        UserDefaults.standard.set(true, forKey: SettingsKeys.launchedBefore)
    }
    
    public var isOldDisclamerShown: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.oldDisclamerShown)
    }
    
    public func setOldDisclamerShown() {
        UserDefaults.standard.set(true, forKey: SettingsKeys.oldDisclamerShown)
    }

    public var needLegacyMode: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.legacyMode)
    }

    public func initialize(legacyMode: Bool) {
        if !UserDefaults.standard.bool(forKey: SettingsKeys.isInitialized) {
            UserDefaults.standard.set(legacyMode, forKey: SettingsKeys.legacyMode)
            UserDefaults.standard.set(true, forKey: SettingsKeys.isInitialized)
        }
    }
    
    public init() {}
}

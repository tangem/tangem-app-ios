//
//  LegcayModeService.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Manage legacy mode, according to iPhone model and app preferences. Initialized once and can be overridden. You can add SettingsBundle to your app with ID = `tangemsdk_legacymode_preference` for easy manage this feature from app settings. This feature fixes NFC issues with long-running commands and security delay for iPhone 7/7+. Tangem card firmware starts from 2.39
class LegacyModeService {
    private struct SettingsKeys {
        static let legacyMode = "tangemsdk_legacymode_preference"
        static let isInitialized = "tangemsdk_preference_initialized"
    }
    
    var useLegacyMode: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.legacyMode)
    }
    
    func initialize() {
        if !UserDefaults.standard.bool(forKey: SettingsKeys.isInitialized) {
            UserDefaults.standard.set(shouldEnableLegacyMode, forKey: SettingsKeys.legacyMode)
            UserDefaults.standard.set(true, forKey: SettingsKeys.isInitialized)
        }
    }
    
    private var shouldEnableLegacyMode: Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier == "iPhone9,1" || identifier == "iPhone9,2" || identifier == "iPhone9,3" || identifier == "iPhone9,4"
    }
}

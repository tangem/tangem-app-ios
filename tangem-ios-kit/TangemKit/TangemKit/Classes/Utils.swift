//
//  Utils.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

//import Foundation
//import UIKit

//public class Utils {
//    struct SettingsKeys {
//        static let legacyMode = "legacymode_preference"
//        static let isInitialized = "preference_initialized"
//    }
//
//    static var needLegacyMode: Bool {
//        UserDefaults.standard.bool(forKey: SettingsKeys.legacyMode)
//    }
//
//    static var shouldEnableLegacyMode: Bool {
//        var systemInfo = utsname()
//        uname(&systemInfo)
//        let machineMirror = Mirror(reflecting: systemInfo.machine)
//        let identifier = machineMirror.children.reduce("") { identifier, element in
//            guard let value = element.value as? Int8, value != 0 else { return identifier }
//            return identifier + String(UnicodeScalar(UInt8(value)))
//        }
//        return identifier == "iPhone9,1" || identifier == "iPhone9,2" || identifier == "iPhone9,3" || identifier == "iPhone9,4"
//    }
//
//    public static func initialize() {
//        if !UserDefaults.standard.bool(forKey: SettingsKeys.isInitialized) {
//            UserDefaults.standard.set(Utils.shouldEnableLegacyMode, forKey: SettingsKeys.legacyMode)
//            UserDefaults.standard.set(true, forKey: SettingsKeys.isInitialized)
//        }
//    }
//}

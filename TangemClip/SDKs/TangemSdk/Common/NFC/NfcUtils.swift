//
//  LegcayModeService.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Manage legacy mode, according to iPhone model and app preferences. This feature fixes NFC issues with long-running commands and security delay for iPhone 7/7+. Tangem card firmware starts from 2.39
public class NfcUtils {
    private static let poorNFCQualityDevices = ["iPhone9,1", "iPhone9,3", "iPhone9,2", "iPhone9,4"]
    
    private static var identifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    
    public static var isPoorNfcQualityDevice: Bool {
        return poorNFCQualityDevices.contains(identifier)
    }
}

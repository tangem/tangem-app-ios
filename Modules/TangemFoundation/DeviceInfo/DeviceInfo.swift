//
//  DeviceInfo.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit.UIDevice

public struct DeviceInfo {
    public let platform: String
    public let version: String
    public let language: String
    public let timezone: String
    public let device: String
    public let systemVersion: String

    // [REDACTED_TODO_COMMENT]
    public var appLanguageCode: String {
        Locale.appLanguageCode
    }

    public init() {
        platform = Constants.platformName
        version = InfoDictionaryUtils.version.value() ?? Constants.commonUnknown
        language = Locale.deviceLanguageCode
        timezone = TimeZone.current.identifier
        device = IPhoneModel()?.name ?? Constants.commonUnknown
        systemVersion = UIDevice.current.systemVersion
    }

    public func asHeaders() -> [String: String] {
        [
            "platform": platform,
            "version": version,
            "language": language,
            "timezone": timezone,
            "device": device,
            "system_version": systemVersion,
        ]
    }
}

// MARK: - Constants

private extension DeviceInfo {
    enum Constants {
        static let platformName = "ios"
        static let commonUnknown = "unknown"
    }
}

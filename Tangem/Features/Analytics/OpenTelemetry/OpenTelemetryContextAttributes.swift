//
//  OpenTelemetryContextAttributes.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation

/// The device dimensions every mirrored metric carries, repeating what
/// `ContextPlugin.staticContextData()` in the Amplitude SDK collects outside `eventProperties`.
enum OpenTelemetryContextAttributes {
    static let all: [String: String] = {
        var attributes = [
            AttributeName.platform: Constants.platform,
            AttributeName.osName: UIDevice.current.systemName.lowercased(),
            AttributeName.osVersion: UIDevice.current.systemVersion,
        ]

        attributes[AttributeName.language] = Locale.preferredLanguages.first

        // Amplitude resolves the country server-side from the request IP; this is the device region
        // instead. Swap it for a collector-side GeoIP lookup once the endpoint offers one.
        attributes[AttributeName.countryCode] = Locale.current.region?.identifier

        let version: String? = InfoDictionaryUtils.version.value()
        attributes[AttributeName.appVersion] = version

        return attributes
    }()
}

// MARK: - Constants

private extension OpenTelemetryContextAttributes {
    enum AttributeName {
        static let platform = "platform"
        static let osName = "os_name"
        static let osVersion = "os_version"
        static let language = "language"
        static let countryCode = "country_code"
        static let appVersion = "app_version"
    }

    enum Constants {
        static let platform = "iOS"
    }
}

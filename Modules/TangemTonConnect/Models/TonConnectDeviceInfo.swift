//
//  TonConnectDeviceInfo.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `DeviceInfo` returned inside every successful `ConnectEvent` (`spec/connect.md`).
public struct TonConnectDeviceInfo: Encodable, Equatable, Sendable {
    public enum Platform: String, Encodable, Sendable {
        case iphone
        case ipad
        case android
        case windows
        case mac
        case linux
        case browser
    }

    public static let supportedProtocolVersion = 2

    public let platform: Platform
    /// Must equal the wallet's `app_name` entry in the public wallets list.
    public let appName: String
    public let appVersion: String
    public let maxProtocolVersion: Int
    public let features: [TonConnectFeature]

    public init(
        platform: Platform,
        appName: String,
        appVersion: String,
        maxProtocolVersion: Int = TonConnectDeviceInfo.supportedProtocolVersion,
        features: [TonConnectFeature]
    ) {
        self.platform = platform
        self.appName = appName
        self.appVersion = appVersion
        self.maxProtocolVersion = maxProtocolVersion
        self.features = features
    }

    public var sendTransactionFeature: TonConnectFeature.SendTransaction? {
        for feature in features {
            if case .sendTransaction(let value) = feature { return value }
        }
        return nil
    }

    public var signDataTypes: Set<TonConnectSignDataType> {
        for feature in features {
            if case .signData(let types) = feature { return Set(types) }
        }
        return []
    }
}

/// Capabilities the wallet advertises. Only advertise what is enforced at runtime.
public enum TonConnectFeature: Encodable, Equatable, Sendable {
    public struct SendTransaction: Encodable, Equatable, Sendable {
        public let maxMessages: Int
        public let extraCurrencySupported: Bool
        /// Structured `items` support; `nil` means only raw `messages` are accepted.
        public let itemTypes: [String]?

        public init(maxMessages: Int, extraCurrencySupported: Bool = false, itemTypes: [String]? = nil) {
            self.maxMessages = maxMessages
            self.extraCurrencySupported = extraCurrencySupported
            self.itemTypes = itemTypes
        }
    }

    case sendTransaction(SendTransaction)
    case signData(types: [TonConnectSignDataType])

    private enum CodingKeys: String, CodingKey {
        case name
        case maxMessages
        case extraCurrencySupported
        case itemTypes
        case types
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sendTransaction(let feature):
            try container.encode("SendTransaction", forKey: .name)
            try container.encode(feature.maxMessages, forKey: .maxMessages)
            try container.encode(feature.extraCurrencySupported, forKey: .extraCurrencySupported)
            try container.encodeIfPresent(feature.itemTypes, forKey: .itemTypes)
        case .signData(let types):
            try container.encode("SignData", forKey: .name)
            try container.encode(types, forKey: .types)
        }
    }
}

public enum TonConnectSignDataType: String, Codable, Hashable, Sendable {
    case text
    case binary
    case cell
}

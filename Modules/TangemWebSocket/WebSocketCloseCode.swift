//
//  WebSocketCloseCode.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct WebSocketCloseCode: RawRepresentable, Hashable, Sendable {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

public extension WebSocketCloseCode {
    static let normalClosure = Self(rawValue: 1000)
    static let goingAway = Self(rawValue: 1001)
    static let protocolError = Self(rawValue: 1002)
    static let unsupportedData = Self(rawValue: 1003)
    static let invalidFramePayloadData = Self(rawValue: 1007)
    static let policyViolation = Self(rawValue: 1008)
    static let messageTooBig = Self(rawValue: 1009)
    static let mandatoryExtensionMissing = Self(rawValue: 1010)
    static let internalServerError = Self(rawValue: 1011)
}

extension WebSocketCloseCode {
    var isSendable: Bool {
        Self.sendableRanges.contains { $0.contains(rawValue) }
    }
}

// MARK: - Private

private extension WebSocketCloseCode {
    static let sendableRanges: [ClosedRange<UInt16>] = [1000 ... 1003, 1007 ... 1014, 3000 ... 4999]
}

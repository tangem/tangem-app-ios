//
//  RTCUtil.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public class RTCUtil {
    public init() {}

    public func checkStatus() -> RTCStatus {
        guard let status: NSObject.Type = NSClassFromString(Constants.rtcStatusClassName) as? NSObject.Type else {
            return RTCStatus(hasRoot: nil)
        }

        let hasRoot: Bool
        let rootSelector = Selector(Constants.rootSelectorName)
        if status.responds(to: rootSelector), let boolValue = status.value(forKey: Constants.rootSelectorName) as? Bool {
            hasRoot = boolValue
        } else {
            hasRoot = false
        }

        return RTCStatus(hasRoot: hasRoot)
    }
}

// MARK: - RTCUtil + isRootedDevice

public extension RTCUtil {
    static var isRootedDevice: Bool {
        RTCUtil().checkStatus().hasIssues
    }
}

// MARK: - RTCUtil + Constants

private extension RTCUtil {
    enum Constants {
        static let rtcStatusClassName = "RtcStatus"
        static let rootSelectorName = "root"
    }
}

// MARK: - RTCStatus

public struct RTCStatus {
    public var hasIssues: Bool {
        hasRoot == true
    }

    let hasRoot: Bool?
}

// MARK: - RTCStatus + CustomStringConvertible

extension RTCStatus: CustomStringConvertible {
    public var description: String {
        let hasRootDescription = hasRoot.map { String($0) } ?? "unknown"
        return "RTCStatus(hasRoot: \(hasRootDescription))"
    }
}

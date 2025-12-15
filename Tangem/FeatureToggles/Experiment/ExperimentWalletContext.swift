//
//  ExperimentWalletContext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct ExperimentWalletContext {
    let userWalletId: UserWalletId

    let region: String
    let language: String
    let appVersion: String
    let environment: String
    let osVersion: String
    let deviceName: String

    /// Custom attributes
    var attributes: [String: Any]

    // MARK: - Private Properties

    private static let deviceInfo = DeviceInfo()

    // MARK: - Static

    static func initial(for userWalletId: UserWalletId) -> ExperimentWalletContext {
        ExperimentWalletContext(
            userWalletId: userWalletId,
            region: Locale.current.region?.identifier ?? "",
            language: deviceInfo.language,
            appVersion: deviceInfo.version,
            environment: AppEnvironment.current.rawValue,
            osVersion: deviceInfo.systemVersion,
            deviceName: deviceInfo.device,
            attributes: [:]
        )
    }
}

extension ExperimentWalletContext {
    enum ParameterKey: String {
        case environment
    }
}

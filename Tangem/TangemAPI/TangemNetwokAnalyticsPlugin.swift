//
//  TangemNetwokAnalyticsPlugin.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

final class TangemNetworkAnalyticsPlugin: PluginType {
    // MARK: - Plugin

    func didReceive(_ result: Result<Response, MoyaError>, target: any TargetType) {
        switch result {
        case .success:
            // Do nothing
            break
        case .failure(let error):
            let exceptionHost = (error as? TargetTypeLogConvertible)?.requestDescription ?? ""
            let errorCode = error.response?.statusCode.description ?? ""
            log(error: error, exceptionHost: exceptionHost, code: errorCode)
        }
    }

    // MARK: - Private Implementation

    private func log(error: Error, exceptionHost: String, code: String) {
        Analytics.log(
            event: .tangemAPIException,
            params: [
                .exceptionHost: exceptionHost,
                .errorCode: code,
                .errorMessage: error.localizedDescription,
            ],
            analyticsSystems: [.firebase, .crashlytics]
        )
    }
}

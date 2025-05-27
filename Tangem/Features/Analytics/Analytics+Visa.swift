//
//  Analytics+Visa.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemVisa

extension Analytics {
    static func logVisaCardScanErrorIfNeeded(_ error: Error, source: Analytics.ScanErrorsSource) {
        let visaError: VisaError
        if let baseVisaError = error as? VisaError {
            visaError = baseVisaError
        } else if let tangemSdkError = error as? TangemSdkError {
            guard
                case .underlying(let underlying) = tangemSdkError,
                let underlyingVisaError = underlying as? VisaError
            else {
                return
            }

            visaError = underlyingVisaError
        } else {
            return
        }

        Analytics.log(event: .visaErrors, params: [
            Analytics.ParameterKey.errorCode: "\(visaError.errorCode)",
            Analytics.ParameterKey.source: source.parameterValue.rawValue,
        ])
    }
}

//
//  Error+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import SwiftUI
import TangemSdk
import TangemFoundation
import TangemVisa
import TangemLocalization
import struct TangemUIUtils.AlertBinder

extension Error {
    var detailedError: Error {
        if case .underlying(let uError, _) = self as? MoyaError,
           case .sessionTaskFailed(let sessionError) = uError.asAFError {
            return sessionError
        }
        return self
    }

    var alertBinder: AlertBinder {
        toBindable().binder
    }

    func alertBinder(okAction: @escaping () -> Void) -> AlertBinder {
        toBindable().alertBinder(okAction: okAction)
    }

    private func toBindable() -> BindableError {
        self as? BindableError ?? BindableErrorWrapper(self)
    }
}

// MARK: - BindableErrorWrapper

private struct BindableErrorWrapper: BindableError {
    var binder: AlertBinder {
        alertBinder(okAction: {})
    }

    private let error: Error

    init(_ error: Error) {
        self.error = error
    }

    func alertBinder(okAction: @escaping () -> Void) -> AlertBinder {
        return AlertBinder(alert: Alert(
            title: Text(Localization.commonError),
            message: Text(error.localizedDescription),
            dismissButton: Alert.Button.default(Text(Localization.commonOk), action: okAction)
        ))
    }
}

extension Error {
    var isCancellationError: Bool {
        switch self {
        case let moyaError as MoyaError:
            switch moyaError {
            case .underlying(let error, _):
                return error.asAFError?.isExplicitlyCancelledError ?? false
            default:
                return false
            }
        case is CancellationError:
            return true
        case let urlError as URLError:
            return urlError.code == URLError.Code.cancelled
        case let tangemSdkError as TangemSdkError:
            return tangemSdkError.isUserCancelled
        case let visaActivationError as VisaActivationError:
            if case .underlyingError(let error) = visaActivationError {
                if error is VisaActivationError {
                    return false
                }

                return error.isCancellationError
            }

            return false
        default:
            return false
        }
    }

    var universalErrorCode: Int {
        let errorCode: Int
        switch self {
        case let tangemSdkError as TangemSdkError:
            errorCode = getTangemSdkErrorCode(from: tangemSdkError)
        case let tangemError as UniversalError:
            errorCode = tangemError.errorCode
        default:
            errorCode = -1
        }

        return errorCode
    }

    var universalErrorMessage: String {
        Localization.universalError(universalErrorCode)
    }

    var universalErrorAlertBinder: AlertBinder {
        universalErrorMessage.alertBinder
    }

    func makeUniversalErrorAlertBinder(okAction: @escaping () -> Void) -> AlertBinder {
        universalErrorMessage.alertBinder(okAction: okAction)
    }

    private func getTangemSdkErrorCode(from error: TangemSdkError) -> Int {
        if case .underlying(let underlyingError) = error,
           let tangemError = underlyingError as? UniversalError {
            return tangemError.errorCode
        }

        let baseErrorCode = 101000000
        return baseErrorCode + error.code
    }
}

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
}

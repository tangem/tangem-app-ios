//
//  InternalLogger.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

public let VisaLogger = Logger(category: OSLogCategory(name: "Visa"))

struct InternalLogger {
    func error(error: Error) {
        VisaLogger.error(error: error)
    }

    func debug<T>(subsystem: Subsystem, _ message: @autoclosure () -> T) {
        VisaLogger.tag(subsystem.rawValue).info(message())
    }
}

extension InternalLogger {
    enum Subsystem: String {
        case paymentAccountInteractorBuilder = "[Visa] [PaymentAccountInteractorBuilder]: "
        case paymentAccountInteractor = "[Visa] [PaymentAccountInteractor]: "
        case apiService = "[Visa] [API Service]: "
        case tokenInfoLoader = "[Visa] [TokenInfoLoader]: "
        case authorizationTokenHandler = "[Visa] [AuthorizationTokenHandler]: "
        case activationManager = "[Visa] [ActivationManager]: "
        case cardSetupHandler = "[Visa] [CardSetupHandler]: "
        case cardActivationOrderProvider = "[Visa] [CommonCardActivationOrderProvider]: "
        case cardAuthorizationProcessor = "[Visa] [CardAuthorizationProcessor]: "
        case cardActivationTask = "[Visa] [CardActivationTask]: "
        case paymentAccountAddressProvider = "[Visa] [PaymentAccountAddressProvider]: "
        case cardAuthorizationScanHandler = "[Visa] [VisaCardAuthorizationScanHandler]: "
    }
}

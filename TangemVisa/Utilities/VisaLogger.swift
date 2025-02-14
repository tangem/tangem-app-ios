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
    enum Subsystem: String, CustomStringConvertible {
        case bridgeInteractorBuilder = "[Visa] [Bridge Interactor Builder]:\n"
        case bridgeInteractor = "[Visa] [Bridge Interactor]:\n"
        case apiService = "[Visa] [API Service]\n"
        case tokenInfoLoader = "[Visa] [TokenInfoLoader]:\n"
        case authorizationTokenHandler = "[Visa] [AuthorizationTokenHandler]: "
        case activationManager = "[Visa] [ActivationManager]: "
        case cardSetupHandler = "[Visa] [CardSetupHandler]: "
        case cardActivationOrderProvider = "[Visa] [CommonCardActivationOrderProvider]: "
        case cardAuthorizationProcessor = "[Visa] [CardAuthorizationProcessor]: "
        case cardActivationTask = "[Visa] [CardActivationTask]: "
    }
}

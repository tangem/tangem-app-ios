//
//  YieldLendingDepositState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum YieldLendingDepositState: Equatable {
    case loading
    case failedToLoad
    case deployModule
    case unsupportedModule
    case activateToken(TokenActivation)
    case depositAvailable(withUpgrade: Bool)

    enum TokenActivation {
        case initialize
        case reactivate
    }

    enum Module {
        case notDeployed
        case deployed(nativeSupport: NativeSupport, token: YieldModuleSmartContractState.InitializationState)
    }

    enum NativeSupport: Equatable {
        case supported
        case afterUpgrade
        case unavailable
    }

    static func make(module: LoadingResult<Module, Error>) -> YieldLendingDepositState {
        switch module {
        case .loading:
            return .loading
        case .failure:
            return .failedToLoad
        case .success(.notDeployed):
            return .deployModule
        case .success(.deployed(.unavailable, _)):
            return .unsupportedModule
        case .success(.deployed(_, .notInitialized)):
            return .activateToken(.initialize)
        case .success(.deployed(_, .initialized(.notActive))):
            return .activateToken(.reactivate)
        case .success(.deployed(let nativeSupport, .initialized(.active))):
            return .depositAvailable(withUpgrade: nativeSupport == .afterUpgrade)
        }
    }
}

//
//  DynamicAddressesManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemMacro

protocol DynamicAddressesManager {
    var state: DynamicAddressesState { get }
    var statePublisher: AnyPublisher<DynamicAddressesState, Never> { get }

    func enableDynamicAddresses() async throws
}

@CaseFlagable
enum DynamicAddressesState {
    case disabled(derivationIsNeeded: Bool)
    case enabled
}

enum DynamicAddressesManagerError: LocalizedError {
    case attemptToEnableDynamicAddressesWhileAlreadyEnabled

    var errorDescription: String? {
        switch self {
        case .attemptToEnableDynamicAddressesWhileAlreadyEnabled: "Attempt to enable dynamic addresses while already enabled"
        }
    }
}

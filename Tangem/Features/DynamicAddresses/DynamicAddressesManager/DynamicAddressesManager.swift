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

    var derivationIsNeededToEnabled: Bool { get }

    func enableDynamicAddresses() async throws
    func disableDynamicAddresses() throws
}

@CaseFlagable
enum DynamicAddressesState {
    case disabled
    case enabled
}

enum DynamicAddressesManagerError: LocalizedError {
    case attemptToEnableDynamicAddressesWhileAlreadyEnabled
    case attemptToDisableDynamicAddressesWhileAlreadyDisabled

    var errorDescription: String? {
        switch self {
        case .attemptToEnableDynamicAddressesWhileAlreadyEnabled: "Attempt to enable dynamic addresses while already enabled"
        case .attemptToDisableDynamicAddressesWhileAlreadyDisabled: "Attempt to disable dynamic addresses while already disabled"
        }
    }
}

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

    var enablingRequirements: DynamicAddressesEnablingRequirements? { get }
    var disablingRequirements: DynamicAddressesDisablingRequirements? { get }

    func configure(walletModelUpdater: WalletModelUpdater)

    func enableDynamicAddresses() async throws
    func disableDynamicAddresses() throws
}

@CaseFlagable
@RawCaseName
enum DynamicAddressesEnablingRequirements: Equatable {
    case xpubDerivationIsNeeded
    case customTokensRemoveIsNeeded
}

@CaseFlagable
@RawCaseName
enum DynamicAddressesDisablingRequirements: Equatable {
    case compoundTransaction(BSDKAmount, destination: String)
}

@CaseFlagable
enum DynamicAddressesState {
    case disabled
    case enabled
}

enum DynamicAddressesManagerError: LocalizedError {
    case enablingRequirementsNotMet
    case disablingRequirementsNotMet
    case attemptToEnableDynamicAddressesWhileAlreadyEnabled
    case attemptToDisableDynamicAddressesWhileAlreadyDisabled

    var errorDescription: String? {
        switch self {
        case .enablingRequirementsNotMet: "Enabling requirements not met"
        case .disablingRequirementsNotMet: "Disabling requirements not met"
        case .attemptToEnableDynamicAddressesWhileAlreadyEnabled: "Attempt to enable dynamic addresses while already enabled"
        case .attemptToDisableDynamicAddressesWhileAlreadyDisabled: "Attempt to disable dynamic addresses while already disabled"
        }
    }
}

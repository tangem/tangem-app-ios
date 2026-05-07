//
//  DynamicAddressesManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol DynamicAddressesManager {
    var enablingRequirements: DynamicAddressesEnablingRequirements? { get }
    var disablingRequirements: DynamicAddressesDisablingRequirements? { get }

    @MainActor
    func hasDynamicAddressesBalancesFlag() async -> Bool

    @MainActor
    func enableDynamicAddresses() async throws -> BlockchainNetwork

    @MainActor
    func disableDynamicAddresses() throws -> BlockchainNetwork
}

enum DynamicAddressesEnablingRequirements: Equatable {
    case xpubDerivationIsNeeded
    case customTokensRemoveIsNeeded
}

enum DynamicAddressesDisablingRequirements: Equatable {
    case compoundTransaction(BSDKAmount, destination: String)
}

enum DynamicAddressesManagerError: LocalizedError {
    case dynamicAddressesNotSupported
    case enablingRequirementsNotMet
    case disablingRequirementsNotMet
    case attemptToEnableDynamicAddressesWhileAlreadyEnabled
    case attemptToDisableDynamicAddressesWhileAlreadyDisabled

    var errorDescription: String? {
        switch self {
        case .dynamicAddressesNotSupported: "Dynamic addresses not supported"
        case .enablingRequirementsNotMet: "Enabling requirements not met"
        case .disablingRequirementsNotMet: "Disabling requirements not met"
        case .attemptToEnableDynamicAddressesWhileAlreadyEnabled: "Attempt to enable dynamic addresses while already enabled"
        case .attemptToDisableDynamicAddressesWhileAlreadyDisabled: "Attempt to disable dynamic addresses while already disabled"
        }
    }
}

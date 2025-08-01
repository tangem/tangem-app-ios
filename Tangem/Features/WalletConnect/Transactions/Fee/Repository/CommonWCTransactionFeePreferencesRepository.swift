//
//  CommonWCTransactionFeePreferencesRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

protocol WCTransactionFeePreferencesRepository: Actor {
    nonisolated var dappName: String { get }

    func getLastSelectedFeeOption(for networkId: String) -> FeeOption
    func saveSelectedFeeOption(_ option: FeeOption, for networkId: String)
    func getLastCustomFeeValues(for networkId: String) -> (feeValue: Decimal, gasPrice: Decimal)?
    func saveCustomFeeValues(_ values: (feeValue: Decimal, gasPrice: Decimal), for networkId: String)

    func getSuggestedFeeFromDApp(for networkId: String) -> (gasLimit: BigUInt, gasPrice: BigUInt)?
    func saveSuggestedFeeFromDApp(gasLimit: BigUInt, gasPrice: BigUInt, for networkId: String)
}

actor CommonWCTransactionFeePreferencesRepository: WCTransactionFeePreferencesRepository {
    let dappName: String

    private var lastSelectedFeeOptions: [String: FeeOption] = [:]
    private var lastCustomFeeValues: [String: (feeValue: Decimal, gasPrice: Decimal)] = [:]
    private var suggestedFeesFromDApp: [String: (gasLimit: BigUInt, gasPrice: BigUInt)] = [:]

    init(dappName: String) {
        self.dappName = dappName
    }

    func getLastSelectedFeeOption(for networkId: String) -> FeeOption {
        let hasSuggestedFee = suggestedFeesFromDApp[networkId] != nil

        if let savedOption = lastSelectedFeeOptions[networkId] {
            return savedOption
        }

        return hasSuggestedFee ? .suggestedByDApp(dappName: dappName) : .market
    }

    func saveSelectedFeeOption(_ option: FeeOption, for networkId: String) {
        lastSelectedFeeOptions[networkId] = option
    }

    func getLastCustomFeeValues(for networkId: String) -> (feeValue: Decimal, gasPrice: Decimal)? {
        lastCustomFeeValues[networkId]
    }

    func saveCustomFeeValues(_ values: (feeValue: Decimal, gasPrice: Decimal), for networkId: String) {
        lastCustomFeeValues[networkId] = values
    }

    func getSuggestedFeeFromDApp(for networkId: String) -> (gasLimit: BigUInt, gasPrice: BigUInt)? {
        suggestedFeesFromDApp[networkId]
    }

    func saveSuggestedFeeFromDApp(gasLimit: BigUInt, gasPrice: BigUInt, for networkId: String) {
        suggestedFeesFromDApp[networkId] = (gasLimit: gasLimit, gasPrice: gasPrice)
    }

    func clearAllSavedOptions() {
        lastSelectedFeeOptions.removeAll()
        lastCustomFeeValues.removeAll()
        suggestedFeesFromDApp.removeAll()
    }
}

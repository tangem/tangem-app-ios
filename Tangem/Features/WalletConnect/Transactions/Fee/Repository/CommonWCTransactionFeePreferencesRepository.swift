//
//  CommonWCTransactionFeePreferencesRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk

protocol WCTransactionFeePreferencesRepository {
    nonisolated var dappName: String { get }

    func getLastSelectedFeeOption(for networkId: String) async -> FeeOption
    func saveSelectedFeeOption(_ option: FeeOption, for networkId: String) async

    func getSuggestedFeeFromDApp(for networkId: String, blockchain: Blockchain) async -> Fee?
    func saveSuggestedFeeFromDApp(gasLimit: BigUInt, gasPrice: BigUInt, for networkId: String) async
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

    func getSuggestedFeeFromDApp(for networkId: String, blockchain: Blockchain) -> Fee? {
        if let suggestedFeeData = suggestedFeesFromDApp[networkId] {
            let legacyFeeParameters = EthereumLegacyFeeParameters(gasLimit: suggestedFeeData.gasLimit, gasPrice: suggestedFeeData.gasPrice)
            let feeValue = legacyFeeParameters.calculateFee(decimalValue: blockchain.decimalValue)
            let amount = Amount(with: blockchain, value: feeValue)

            return Fee(amount, parameters: legacyFeeParameters)
        }

        return nil
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

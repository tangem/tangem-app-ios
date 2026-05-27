//
//  DynamicAddressesCompoundFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol DynamicAddressesCompoundFlowBaseDependenciesFactory: SendFlowBaseDependenciesFactory {
    typealias Dependencies = (transferModel: TransferModel, notificationManager: SendNotificationManager)

    func makeDependencies(amount: BSDKAmount, destination: String) -> Dependencies
}

struct CommonDynamicAddressesCompoundFlowBaseDependenciesFactory: DynamicAddressesCompoundFlowBaseDependenciesFactory {
    let transferableToken: SendTransferableToken

    func makeDependencies(amount: BSDKAmount, destination: String) -> Dependencies {
        let analyticsLogger = makeSendAnalyticsLogger(sendType: .send, coordinatorSource: .tokenDetails)

        let predefinedValues = TransferModel.PredefinedValues(
            destination: SendDestination(value: .plain(destination), source: .textField),
            tag: .notSupported,
            amount: SendAmount(type: .typical(crypto: amount.value, fiat: .none))
        )

        let transferModel = makeTransferModel(
            analyticsLogger: analyticsLogger,
            predefinedValues: predefinedValues
        )

        transferModel.informationRelevanceService = CommonInformationRelevanceService(
            input: transferModel,
            provider: transferModel
        )

        let notificationManager = makeSendNotificationManager()
        notificationManager.setup(input: transferModel)

        return (transferModel, notificationManager)
    }
}

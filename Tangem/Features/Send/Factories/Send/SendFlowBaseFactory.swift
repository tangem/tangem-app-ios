//
//  SendFlowBaseFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

class SendFlowBaseFactory {
    let dependencies: SendFlowDependenciesFactory

    lazy var sendQRCodeService = dependencies.makeSendQRCodeService()
    lazy var swapManager = dependencies.makeSwapManager()
    lazy var analyticsLogger = dependencies.makeSendAnalyticsLogger(sendType: .send)
    lazy var sendModel = dependencies.makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = dependencies.makeSendNewNotificationManager(receiveTokenInput: sendModel)
    lazy var customFeeService = dependencies.makeCustomFeeService(input: sendModel)
    lazy var sendFeeProvider = dependencies.makeSendWithSwapFeeProvider(
        receiveTokenInput: sendModel,
        sendFeeProvider: dependencies.makeSendFeeProvider(input: sendModel),
        swapFeeProvider: dependencies.makeSwapFeeProvider(swapManager: swapManager)
    )

    init(dependencies: SendFlowDependenciesFactory) {
        self.dependencies = dependencies
    }
}

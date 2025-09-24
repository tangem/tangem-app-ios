//
//  SendViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum SendViewModelBuilder {
    struct IO {
        let input: SendBaseInput
        let output: SendBaseOutput
    }

    struct Types {
        let tokenItem: TokenItem
    }

    struct Dependencies {
        let stepsManager: any SendStepsManager
        let alertBuilder: any SendAlertBuilder
        let dataBuilder: any SendGenericBaseDataBuilder
        let analyticsLogger: any SendBaseViewAnalyticsLogger
        let blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper
    }

    typealias ReturnValue = SendViewModel

    static func make(io: IO, types: Types, dependencies: Dependencies, router: SendRoutable) -> ReturnValue {
        let interactor = CommonSendBaseInteractor(input: io.input, output: io.output)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: dependencies.stepsManager,
            alertBuilder: dependencies.alertBuilder,
            dataBuilder: dependencies.dataBuilder,
            analyticsLogger: dependencies.analyticsLogger,
            blockchainSDKNotificationMapper: dependencies.blockchainSDKNotificationMapper,
            tokenItem: types.tokenItem,
            source: .main,
            coordinator: router
        )

        return viewModel
    }
}

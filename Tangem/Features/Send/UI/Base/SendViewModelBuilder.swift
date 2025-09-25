//
//  SendViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO { get }
    var baseTypes: SendViewModelBuilder.Types { get }
    var baseDependencies: SendViewModelBuilder.Dependencies { get }
}

extension SendBaseBuildable {
    func makeSendBase(stepsManager: any SendStepsManager, router: any SendRoutable) -> SendViewModelBuilder.ReturnValue {
        SendViewModelBuilder.make(
            io: baseIO,
            types: baseTypes,
            dependencies: baseDependencies,
            stepsManager: stepsManager,
            router: router
        )
    }
}

enum SendViewModelBuilder {
    struct IO {
        let input: SendBaseInput
        let output: SendBaseOutput
    }

    struct Types {
        let tokenItem: TokenItem
    }

    struct Dependencies {
        let alertBuilder: any SendAlertBuilder
        let dataBuilder: any SendGenericBaseDataBuilder
        let analyticsLogger: any SendBaseViewAnalyticsLogger
        let blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper
    }

    typealias ReturnValue = SendViewModel

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
        stepsManager: any SendStepsManager,
        router: any SendRoutable
    ) -> ReturnValue {
        let interactor = CommonSendBaseInteractor(input: io.input, output: io.output)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
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

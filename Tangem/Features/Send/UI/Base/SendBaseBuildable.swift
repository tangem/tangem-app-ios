//
//  SendBaseBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO { get }
    var baseDependencies: SendViewModelBuilder.Dependencies { get }
}

extension SendBaseBuildable {
    func makeSendBase(stepsManager: any SendStepsManager, router: any SendRoutable) -> SendViewModelBuilder.ReturnValue {
        SendViewModelBuilder.make(
            io: baseIO, dependencies: baseDependencies, stepsManager: stepsManager, router: router
        )
    }
}

enum SendViewModelBuilder {
    struct IO {
        let input: SendBaseInput
        let output: SendBaseOutput
    }

    struct Dependencies {
        let alertBuilder: any SendAlertBuilder
        let mailDataBuilder: any SendMailDataBuilder
        let approveViewModelInputDataBuilder: any SendApproveViewModelInputDataBuilder
        let feeCurrencyProviderDataBuilder: any SendFeeCurrencyProviderDataBuilder
        let analyticsLogger: any SendBaseViewAnalyticsLogger
        let blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper
        let tangemIconProvider: TangemIconProvider
    }

    typealias ReturnValue = SendViewModel

    static func make(
        io: IO,
        dependencies: Dependencies,
        stepsManager: any SendStepsManager,
        router: any SendRoutable
    ) -> ReturnValue {
        let interactor = CommonSendBaseInteractor(input: io.input, output: io.output)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            alertBuilder: dependencies.alertBuilder,
            mailDataBuilder: dependencies.mailDataBuilder,
            approveViewModelInputDataBuilder: dependencies.approveViewModelInputDataBuilder,
            feeCurrencyProviderDataBuilder: dependencies.feeCurrencyProviderDataBuilder,
            analyticsLogger: dependencies.analyticsLogger,
            blockchainSDKNotificationMapper: dependencies.blockchainSDKNotificationMapper,
            tangemIconProvider: dependencies.tangemIconProvider,
            coordinator: router
        )

        return viewModel
    }
}

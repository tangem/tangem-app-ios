//
//  SendFinishStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO { get }
    var finishDependencies: SendFinishStepBuilder.Dependencies { get }
}

extension SendFinishStepBuildable {
    func makeSendFinishStep(
        sendAmountFinishViewModel: SendAmountFinishViewModel? = nil,
        nftAssetCompactViewModel: NFTAssetCompactViewModel? = nil,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel? = nil,
        addContactViewModel: SendAddContactFinishViewModel? = nil,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel? = nil,
        sendFeeFinishViewModel: SendFeeFinishViewModel? = nil,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel? = nil,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel? = nil,
        jointAccountSignaturesCompactViewModel: JointAccountSignaturesCompactViewModel? = nil,
        router: SendRoutable,
    ) -> SendFinishStepBuilder.ReturnValue {
        SendFinishStepBuilder.make(
            io: finishIO,
            dependencies: finishDependencies,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            addContactViewModel: addContactViewModel,
            stakingTargetsCompactViewModel: stakingTargetsCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel,
            jointAccountSignaturesCompactViewModel: jointAccountSignaturesCompactViewModel,
            router: router,
        )
    }
}

enum SendFinishStepBuilder {
    struct IO {
        let input: SendFinishInput
    }

    struct Dependencies {
        let analyticsLogger: any SendFinishAnalyticsLogger
        let headerTitleProvider: any SendFinishHeaderTitleProvider
    }

    typealias ReturnValue = SendFinishStep

    static func make(
        io: IO,
        dependencies: Dependencies,
        sendAmountFinishViewModel: SendAmountFinishViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        addContactViewModel: SendAddContactFinishViewModel?,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?,
        jointAccountSignaturesCompactViewModel: JointAccountSignaturesCompactViewModel?,
        router: SendRoutable,
    ) -> ReturnValue {
        let viewModel = SendFinishViewModel(
            input: io.input,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            addContactViewModel: addContactViewModel,
            stakingTargetsCompactViewModel: stakingTargetsCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel,
            jointAccountSignaturesCompactViewModel: jointAccountSignaturesCompactViewModel,
            headerTitleProvider: dependencies.headerTitleProvider,
            analyticsLogger: dependencies.analyticsLogger,
            coordinator: router
        )

        let step = SendFinishStep(viewModel: viewModel)
        return step
    }
}

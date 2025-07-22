//
//  NFTSendAmountStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

struct NFTSendAmountStepBuilder {
    typealias IO = (input: SendAmountInput, output: SendAmountOutput)
    typealias ReturnValue = (interactor: SendAmountInteractor, compact: SendAmountCompactViewModel)

    let walletModel: any WalletModel
    let builder: SendDependenciesBuilder
    let asset: NFTAsset
    let collection: NFTCollection

    func makeSendAmountStep(
        io: IO,
        actionType: SendFlowActionType,
        sendQRCodeService: SendQRCodeService?,
        sendAmountValidator: SendAmountValidator,
        analyticsLogger: any SendAmountAnalyticsLogger,
        amountModifier: SendAmountModifier
    ) -> ReturnValue {
        let interactor = makeSendAmountInteractor(
            io: io,
            sendAmountValidator: sendAmountValidator,
            amountModifier: amountModifier,
            type: .crypto,
            actionType: actionType
        )

        let compact = makeSendAmountCompactViewModel(input: io.input)
        return (interactor: interactor, compact: compact)
    }

    func makeSendAmountCompactViewModel(input: SendAmountInput) -> SendAmountCompactViewModel {
        let conventViewModel = NFTSendAmountCompactContentViewModel(
            asset: asset,
            collection: collection,
            nftChainIconProvider: NetworkImageProvider()
        )

        return SendAmountCompactViewModel(conventViewModel: .nft(viewModel: conventViewModel))
    }
}

// MARK: - Private

private extension NFTSendAmountStepBuilder {
    private func makeSendAmountInteractor(
        io: IO,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        type: SendAmountCalculationType,
        actionType: SendFlowActionType
    ) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            input: io.input,
            output: io.output,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            maxAmount: builder.maxAmount(for: io.input.amount, actionType: actionType),
            validator: sendAmountValidator,
            amountModifier: amountModifier,
            type: type
        )
    }
}

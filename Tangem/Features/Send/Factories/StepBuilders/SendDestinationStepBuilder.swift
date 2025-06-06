//
//  SendDestinationStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendDestinationStepBuilder {
    typealias IO = (input: SendDestinationInput, output: SendDestinationOutput)
    typealias ReturnValue = (step: SendDestinationStep, interactor: SendDestinationInteractor, compact: SendDestinationCompactViewModel)

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let walletModel: any WalletModel
    let builder: SendDependenciesBuilder

    func makeSendDestinationStep(
        io: IO,
        sendFeeInteractor: any SendFeeInteractor,
        sendQRCodeService: SendQRCodeService,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let addressTextViewHeightModel = AddressTextViewHeightModel()
        let interactor = makeSendDestinationInteractor(io: io)

        let viewModel = makeSendDestinationViewModel(
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        let step = SendDestinationStep(
            viewModel: viewModel,
            interactor: interactor,
            sendFeeInteractor: sendFeeInteractor,
            tokenItem: walletModel.tokenItem
        )

        let compact = makeSendDestinationCompactViewModel(
            input: io.input,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        return (step: step, interactor: interactor, compact: compact)
    }

    func makeSendDestinationCompactViewModel(
        input: SendDestinationInput,
        addressTextViewHeightModel: AddressTextViewHeightModel = .init()
    ) -> SendDestinationCompactViewModel {
        .init(input: input, addressTextViewHeightModel: addressTextViewHeightModel)
    }
}

private extension SendDestinationStepBuilder {
    func makeSendDestinationViewModel(
        interactor: SendDestinationInteractor,
        sendQRCodeService: SendQRCodeService,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        router: SendDestinationRoutable
    ) -> SendDestinationViewModel {
        let tokenItem = walletModel.tokenItem
        let suggestedWallets = makeSuggestedWallets()
        let additionalFieldType = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain)

        let settings = SendDestinationViewModel.Settings(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets
        )

        let viewModel = SendDestinationViewModel(
            settings: settings,
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        return viewModel
    }

    func makeSendDestinationInteractor(io: IO) -> SendDestinationInteractor {
        CommonSendDestinationInteractor(
            input: io.input,
            output: io.output,
            validator: builder.makeSendDestinationValidator(),
            transactionHistoryProvider: builder.makeSendDestinationTransactionHistoryProvider(),
            transactionHistoryMapper: builder.makeTransactionHistoryMapper(),
            addressResolver: walletModel.addressResolver,
            additionalFieldType: .type(for: walletModel.tokenItem.blockchain),
            parametersBuilder: builder.makeSendTransactionParametersBuilder(),
            analyticsLogger: builder.makeDestinationAnalyticsLogger()
        )
    }

    func makeSuggestedWallets() -> [SendDestinationViewModel.Settings.SuggestedWallet] {
        let ignoredAddresses = walletModel
            .addresses
            .map(\.value)
            .toSet()

        let targetNetworkId = walletModel
            .tokenItem
            .blockchain
            .networkId

        return userWalletRepository
            .models
            .reduce(into: []) { partialResult, userWalletModel in
                let walletModels = userWalletModel
                    .walletModelsManager
                    .walletModels

                partialResult += walletModels
                    .filter { walletModel in
                        let blockchain = walletModel.tokenItem.blockchain
                        let shouldBeIncluded = { blockchain.supportsCompound || !ignoredAddresses.contains(walletModel.defaultAddressString) }

                        return blockchain.networkId == targetNetworkId && walletModel.isMainToken && shouldBeIncluded()
                    }
                    .map { walletModel in
                        (name: userWalletModel.name, address: walletModel.defaultAddressString)
                    }
            }
    }
}

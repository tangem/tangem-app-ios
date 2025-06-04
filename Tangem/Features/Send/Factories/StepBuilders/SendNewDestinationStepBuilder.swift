//
//  SendNewDestinationStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendNewDestinationStepBuilder {
    typealias IO = (input: SendDestinationInput, output: SendDestinationOutput)
    typealias ReturnValue = (step: SendNewDestinationStep, interactor: SendDestinationInteractor, compact: SendNewDestinationCompactViewModel, finish: SendDestinationCompactViewModel)

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let tokenItem: TokenItem
    let ignoredAddresses: [String]
    let addressResolver: AddressResolver?
    let builder: SendDependenciesBuilder

    func makeSendDestinationStep(
        io: IO,
        sendQRCodeService: SendQRCodeService,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let suiTextViewModel = SUITextViewModel()
        let interactor = makeSendDestinationInteractor(io: io)

        let viewModel = makeSendNewDestinationViewModel(
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            addressTextViewHeightModel: suiTextViewModel,
            router: router
        )

        let step = SendNewDestinationStep(viewModel: viewModel, interactor: interactor)

        let compact = makeSendNewDestinationCompactViewModel(
            input: io.input,
            suiTextViewModel: suiTextViewModel
        )

        let finish = makeSendDestinationCompactViewModel(
            input: io.input,
            addressTextViewHeightModel: suiTextViewModel
        )

        return (step: step, interactor: interactor, compact: compact, finish: finish)
    }

    func makeSendNewDestinationCompactViewModel(
        input: SendDestinationInput,
        suiTextViewModel: AddressTextViewHeightModel
    ) -> SendNewDestinationCompactViewModel {
        .init(input: input, suiTextViewModel: suiTextViewModel)
    }

    func makeSendDestinationCompactViewModel(
        input: SendDestinationInput,
        addressTextViewHeightModel: AddressTextViewHeightModel = .init()
    ) -> SendDestinationCompactViewModel {
        .init(input: input, addressTextViewHeightModel: addressTextViewHeightModel)
    }
}

private extension SendNewDestinationStepBuilder {
    func makeSendNewDestinationViewModel(
        interactor: SendDestinationInteractor,
        sendQRCodeService: SendQRCodeService,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        router: SendDestinationRoutable
    ) -> SendNewDestinationViewModel {
        let suggestedWallets = makeSuggestedWallets()
        let additionalFieldType = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain)

        let settings = SendNewDestinationViewModel.Settings(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets
        )

        let viewModel = SendNewDestinationViewModel(
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
            addressResolver: addressResolver,
            additionalFieldType: .type(for: tokenItem.blockchain),
            parametersBuilder: builder.makeSendTransactionParametersBuilder(),
            analyticsLogger: builder.makeDestinationAnalyticsLogger()
        )
    }

    func makeSuggestedWallets() -> [SendDestinationViewModel.Settings.SuggestedWallet] {
        userWalletRepository.models.reduce([]) { result, userWalletModel in
            let walletModels = userWalletModel.walletModelsManager.walletModels
            return result + walletModels
                .filter { walletModel in
                    let shouldBeIncluded = tokenItem.blockchain.supportsCompound || !ignoredAddresses.contains(walletModel.defaultAddressString)
                    let sameNetwork = walletModel.tokenItem.blockchain.networkId == tokenItem.blockchain.networkId

                    return sameNetwork && walletModel.isMainToken && shouldBeIncluded
                }
                .map { walletModel in
                    (name: userWalletModel.name, address: walletModel.defaultAddressString)
                }
        }
    }
}

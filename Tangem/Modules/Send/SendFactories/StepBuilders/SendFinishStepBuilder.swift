//
//  SendFinishStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFinishStepBuilder {
    typealias ReturnValue = (step: SendFinishStep, interactor: SendFinishInteractor)

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let builder: SendModulesStepsBuilder

    func makeSendFinishStep(
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sendType: SendType
    ) -> ReturnValue {
        let interactor = makeSendFinishInteractor()

        let viewModel = makeSendSummaryViewModel(
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            editableType: .notEditable
        )

        let step = SendFinishStep(
            viewModel: viewModel,
            tokenItem: walletModel.tokenItem,
            sendFeeInteractor: sendFeeInteractor,
            feeAnalyticsParameterBuilder: builder.makeFeeAnalyticsParameterBuilder()
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension SendFinishStepBuilder {
    func makeSendSummaryViewModel(
        interactor: SendSummaryInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        editableType: SendSummaryViewModel.EditableType
    ) -> SendSummaryViewModel {
        let settings = SendSummaryViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            editableType: editableType
        )

        return SendSummaryViewModel(
            settings: settings,
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory()
        )
    }

    func makeSendFinishInteractor() -> SendFinishInteractor {
        CommonSendFinishInteractor()
    }

    func makeSendSummarySectionViewModelFactory() -> SendSummarySectionViewModelFactory {
        SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: builder.isFeeApproximate(),
            currencyId: walletModel.tokenItem.currencyId,
            tokenIconInfo: builder.makeTokenIconInfo()
        )
    }
}

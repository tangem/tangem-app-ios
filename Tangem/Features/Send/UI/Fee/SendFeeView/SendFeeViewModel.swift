//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import SwiftUI
import Combine
import BlockchainSdk
import TangemFoundation

class SendFeeViewModel: ObservableObject, Identifiable {
    @Published private(set) var selectedFeeOption: FeeOption?
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var customFeeModels: [SendCustomFeeInputFieldModel] = []

    @Published private(set) var networkFeeUnreachableNotificationViewInput: NotificationViewInput?

    var feeSelectorFooterText: String {
        Localization.commonFeeSelectorFooter(
            "[\(Localization.commonReadMore)](\(feeExplanationUrl.absoluteString))"
        )
    }

    private let feeTokenItem: TokenItem
    private let interactor: SendFeeInteractor
    private let notificationManager: NotificationManager

    private weak var router: SendFeeRoutable?

    private let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()
    private let tokenItem: TokenItem
    private let analyticsLogger: SendFeeAnalyticsLogger

    private var bag: Set<AnyCancellable> = []

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(
        settings: Settings,
        interactor: SendFeeInteractor,
        notificationManager: NotificationManager,
        router: SendFeeRoutable,
        analyticsLogger: SendFeeAnalyticsLogger
    ) {
        feeTokenItem = settings.feeTokenItem
        tokenItem = settings.tokenItem

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.router = router
        self.analyticsLogger = analyticsLogger

        bind()
    }

    func onAppear() {}

    func openFeeExplanation() {
        router?.openFeeExplanation(url: feeExplanationUrl)
    }

    private func bind() {
        interactor.feesPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, values in
                viewModel.updateViewModels(values: values)
            }
            .store(in: &bag)

        interactor.selectedFeePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedFee in
                viewModel.updateSelectedOption(selectedFee: selectedFee)
            }
            .store(in: &bag)

        notificationManager
            .notificationPublisher
            .map { notifications in
                notifications.first { input in
                    guard case .networkFeeUnreachable = input.settings.event as? SendNotificationEvent else {
                        return false
                    }

                    return true
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.networkFeeUnreachableNotificationViewInput, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateSelectedOption(selectedFee: SendFee?) {
        selectedFeeOption = selectedFee?.option

        let showCustomFeeFields = selectedFee?.option == .custom
        let models = showCustomFeeFields ? interactor.customFeeInputFieldModels : []
        if customFeeModels.count != models.count {
            customFeeModels = models
        }
    }

    private func updateViewModels(values: [SendFee]) {
        feeRowViewModels = values.map { fee in
            mapToFeeRowViewModel(fee: fee)
        }
    }

    private func mapToFeeRowViewModel(fee: SendFee) -> FeeRowViewModel {
        let feeComponents = mapToFormattedFeeComponents(fee: fee.value)

        return FeeRowViewModel(
            option: fee.option,
            components: feeComponents,
            style: .selectable(
                isSelected: .init(root: self, default: false, get: { root in
                    root.selectedFeeOption == fee.option
                }, set: { root, newValue in
                    if newValue {
                        root.userDidSelected(fee: fee)
                    }
                })
            )
        )
    }

    private func mapToFormattedFeeComponents(fee: LoadingValue<Fee>) -> LoadingValue<FormattedFeeComponents> {
        switch fee {
        case .loading:
            return .loading
        case .loaded(let value):
            let feeComponents = feeFormatter.formattedFeeComponents(
                fee: value.amount.value,
                tokenItem: feeTokenItem,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
            return .loaded(feeComponents)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }

    private func userDidSelected(fee: SendFee) {
        analyticsLogger.logSendFeeSelected(fee.option)

        selectedFeeOption = fee.option
        interactor.update(selectedFee: fee)
    }
}

// MARK: - SendStepViewAnimatable

extension SendFeeViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

extension SendFeeViewModel {
    struct Settings {
        let feeTokenItem: TokenItem
        let tokenItem: TokenItem
    }
}

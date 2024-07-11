//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import struct BlockchainSdk.Fee

class SendFeeViewModel: ObservableObject, Identifiable {
    @Published private(set) var selectedFeeOption: FeeOption?
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var customFeeModels: [SendCustomFeeInputFieldModel] = []

    @Published private(set) var deselectedFeeViewsVisible: Bool = false
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false
    @Published var alert: AlertBinder?

    @Published private(set) var feeLevelsNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var customFeeNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var feeCoverageNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    var feeSelectorFooterText: String {
        Localization.commonFeeSelectorFooter("[\(Localization.commonReadMore)](\(feeExplanationUrl.absoluteString))")
    }

    var didProperlyDisappear = true

    private let tokenItem: TokenItem
    private let interactor: SendFeeInteractor
    private let notificationManager: SendNotificationManager

    private weak var router: SendFeeRoutable?

    private let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

    private var bag: Set<AnyCancellable> = []

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(
        settings: Settings,
        interactor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        router: SendFeeRoutable
    ) {
        tokenItem = settings.tokenItem

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.router = router

        bind()
    }

    func onAppear() {
        let deselectedFeeViewAppearanceDelay = SendView.Constants.animationDuration / 3
        DispatchQueue.main.asyncAfter(deadline: .now() + deselectedFeeViewAppearanceDelay) {
            withAnimation(SendView.Constants.defaultAnimation) {
                self.deselectedFeeViewsVisible = true
            }
        }

        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .fee])
        } else {
            Analytics.log(.sendFeeScreenOpened)
        }
    }

    func onDisappear() {
        deselectedFeeViewsVisible = false
    }

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
            .notificationPublisher(for: .feeLevels)
            .assign(to: \.feeLevelsNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .customFee)
            .assign(to: \.customFeeNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeIncluded)
            .assign(to: \.feeCoverageNotificationInputs, on: self, ownership: .weak)
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

    private func updateCustomFee(fee: SendFee) {
        guard let customIndex = feeRowViewModels.firstIndex(where: { $0.option == .custom }) else {
            return
        }

        feeRowViewModels[customIndex] = mapToFeeRowViewModel(fee: fee)
        interactor.update(selectedFee: fee)
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
            formattedFeeComponents: feeComponents,
            isSelected: .init(root: self, default: false, get: { root in
                root.selectedFeeOption == fee.option
            }, set: { root, newValue in
                if newValue {
                    root.userDidSelected(fee: fee)
                }
            })
        )
    }

    private func mapToFormattedFeeComponents(fee: LoadingValue<Fee>) -> LoadingValue<FormattedFeeComponents> {
        switch fee {
        case .loading:
            return .loading
        case .loaded(let value):
            let feeComponents = feeFormatter.formattedFeeComponents(fee: value.amount.value, tokenItem: tokenItem)
            return .loaded(feeComponents)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }

    private func userDidSelected(fee: SendFee) {
        if fee.option == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }

        selectedFeeOption = fee.option
        interactor.update(selectedFee: fee)
    }
}

extension SendFeeViewModel: AuxiliaryViewAnimatable {}

extension SendFeeViewModel {
    struct Settings {
        let tokenItem: TokenItem
    }
}

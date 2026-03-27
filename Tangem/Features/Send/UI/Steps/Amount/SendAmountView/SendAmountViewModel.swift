//
//  SendAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers
import struct TangemUI.TokenIconInfo

class SendAmountViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var tokenHeader: SendTokenHeader?

    @Published var fiatIconURL: URL?

    let sourceAmountField: AmountInputFieldModel
    @Published var destinationAmountField: AmountInputFieldModel?

    @Published var sourceAmountTokenViewData: SendAmountTokenViewData?

    @Published var destinationTokenViewType: DestinationTokenViewType?
    @Published var activeField: ActiveAmountField = .send
    @Published var compactSourceSubtitle: SendAmountTokenViewData.SubtitleType?
    @Published var compactDestinationSubtitle: SendAmountTokenViewData.SubtitleType?
    @Published var isInputFieldSwitchingLocked: Bool = false

    /// Gates the `.animation(_, value: activeField)` modifier.
    /// Temporarily set to `false` on first destination entry to prevent animation.
    var animateActiveFieldChange = true

    /// When `true`, the FROM section's token row shows compact data even while expanded.
    /// Used for two-phase animation: Phase 1 swaps data instantly, Phase 2 animates collapse.
    @Published var forceCompactSourceTokenRow = false

    /// Gates the `.animation(_, value: isAmountEditable)` modifier.
    /// Set to `true` in `removeReceivedToken` so the removal animates. Entry never animates.
    var animateDestinationRemoval = false

    /// The single mechanism for driving `@FocusState` from the ViewModel.
    /// The view observes this via `.onChange` and transfers focus accordingly.
    @Published var pendingFocusField: ActiveAmountField?

    var useFiatCalculation: Bool {
        get { sourceAmountField.amountType == .fiat }
        set { sourceAmountField.amountType = newValue ? .fiat : .crypto }
    }

    var useDestinationFiatCalculation: Bool {
        get { destinationAmountField?.amountType == .fiat }
        set { destinationAmountField?.amountType = newValue ? .fiat : .crypto }
    }

    // MARK: - Router

    weak var router: SendAmountStepRoutable?

    // MARK: - Swap Handler

    private let swapHandler: SendAmountSwapHandler?

    // MARK: - Swap-forwarded properties

    var sourceRateBadge: RateBadgeConfig? { swapHandler?.sourceRateBadge }
    var destinationRateBadge: RateBadgeConfig? { swapHandler?.destinationRateBadge }

    var isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never> {
        swapHandler?.isReceiveAmountApproximatePublisher ?? Just(false).eraseToAnyPublisher()
    }

    var compactSourceTokenViewData: SendAmountTokenViewData? {
        sourceAmountTokenViewData.map {
            SendAmountTokenViewData(
                tokenIconInfo: $0.tokenIconInfo,
                title: $0.title,
                subtitle: compactSourceSubtitle ?? $0.subtitle,
                detailsType: .none
            )
        }
    }

    var compactDestinationTokenViewData: SendAmountTokenViewData? {
        guard case .selectedEditableAmount(_, let baseCompactData) = destinationTokenViewType else { return nil }
        return SendAmountTokenViewData(
            tokenIconInfo: baseCompactData.tokenIconInfo,
            title: baseCompactData.title,
            subtitle: compactDestinationSubtitle ?? baseCompactData.subtitle,
            detailsType: baseCompactData.detailsType,
            action: baseCompactData.action
        )
    }

    // MARK: - Dependencies

    private let flowActionType: SendFlowActionType
    let interactor: SendAmountInteractor
    private let analyticsLogger: SendAmountAnalyticsLogger

    private let tokenIconInfoBuilder = TokenIconInfoBuilder()

    private(set) var sourceCurrencySymbol: String = ""
    private(set) var sourceCryptoBalance: String?
    private var bag: Set<AnyCancellable> = []
    private var sourceFieldBag: AnyCancellable?

    init(
        sourceToken: SendSourceToken,
        flowActionType: SendFlowActionType,
        interactor: SendAmountInteractor,
        analyticsLogger: SendAmountAnalyticsLogger,
        swapHandler: SendAmountSwapHandler? = nil
    ) {
        sourceAmountField = AmountInputFieldModel(
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem,
            possibleToConvertToFiat: sourceToken.possibleToConvertToFiat
        )

        self.flowActionType = flowActionType
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.swapHandler = swapHandler
        sourceCurrencySymbol = sourceToken.tokenItem.currencySymbol

        sourceFieldBag = sourceAmountField.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }

        bind()
        swapHandler?.bind(to: self)
    }

    func onAppear() {}

    func userDidTapMaxAmount() {
        analyticsLogger.logTapMaxAmount()

        let amount = try? interactor.updateToMaxAmount()
        FeedbackGenerator.heavy()
        sourceAmountField.updateAmountsUI(amount: amount)
    }

    func userDidTapReceivedTokenSelection() {
        analyticsLogger.logTapConvertToAnotherToken()
        swapHandler?.userDidTapReceivedTokenSelection()
    }

    func removeReceivedToken() {
        swapHandler?.removeReceivedToken()
    }

    func userDidTapCompactField(_ tappedField: ActiveAmountField) {
        guard let swapHandler else {
            activeField = tappedField
            pendingFocusField = tappedField
            return
        }

        swapHandler.userDidTapCompactField(tappedField)
    }

    func amountField(for field: ActiveAmountField) -> AmountInputFieldModel {
        swapHandler?.amountField(for: field) ?? sourceAmountField
    }

    func isFiatMode(for field: ActiveAmountField) -> Bool {
        swapHandler?.isFiatMode(for: field) ?? useFiatCalculation
    }
}

// MARK: - Private

private extension SendAmountViewModel {
    func bind() {
        sourceAmountField.onValueChanged = { [weak self] value in
            self?.textFieldValueDidChanged(amount: value)
        }

        sourceAmountField.$amountType
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amountType in
                viewModel.update(amountType: amountType)
            }
            .store(in: &bag)

        interactor
            .sourceFieldInfoPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, infoText in
                viewModel.sourceAmountField.bottomInfoText = infoText
            }
            .store(in: &bag)

        interactor
            .sourceTokenPublisher
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateSourceToken(sourceToken: $1) }
            .store(in: &bag)

        interactor
            .sourceAmountPublisher
            .compactMap(\.value)
            .removeDuplicates { $0.crypto == $1.crypto }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, amount in
                guard viewModel.swapHandler?.lastUpdateSource != .send else { return }
                viewModel.sourceAmountField.updateAmountsUI(amount: amount)
                viewModel.interactor.validateExternalSourceAmount(amount)
            }
            .store(in: &bag)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        swapHandler?.sourceTextFieldValueDidChange(amount: amount)
        let amount = try? interactor.update(sourceAmount: amount)
        sourceAmountField.updateAlternativeUI(amount: amount)

        if amount == nil {
            destinationAmountField?.updateAmountsUI(amount: nil)
        }
    }

    func update(amountType: SendAmountCalculationType) {
        let amount = try? interactor.update(sourceType: amountType)
        sourceAmountField.updateAmountsUI(amount: amount)
    }
}

// MARK: - Tokens

extension SendAmountViewModel {
    func updateSourceToken(sourceToken: SendSourceToken) {
        tokenHeader = sourceToken.header.asSendTokenHeader(actionType: flowActionType)
        sourceCurrencySymbol = sourceToken.tokenItem.currencySymbol

        let cryptoBalance = sourceToken.availableBalanceProvider.formattedBalanceType.value
        sourceCryptoBalance = cryptoBalance

        var balanceFormatted = cryptoBalance
        if sourceToken.fiatAvailableBalanceProvider.balanceType.value != nil {
            balanceFormatted += " \(AppConstants.dotSign) \(sourceToken.fiatAvailableBalanceProvider.formattedBalanceType.value)"
        }

        let tokenIconInfo = tokenIconInfoBuilder.build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom)
        sourceAmountTokenViewData = .init(
            tokenIconInfo: tokenIconInfo,
            title: sourceToken.tokenItem.name,
            subtitle: .balance(state: .loaded(text: .builder(builder: { $0 }, sensitive: balanceFormatted))),
            detailsType: .max { [weak self] in
                self?.userDidTapMaxAmount()
            }
        )

        sourceAmountField.cryptoIconURL = tokenIconInfo.imageURL
        fiatIconURL = sourceToken.fiatItem.iconURL

        sourceAmountField.reconfigure(
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem,
            possibleToConvertToFiat: sourceToken.possibleToConvertToFiat
        )
    }
}

// MARK: - SendAmountExternalUpdatableViewModel

extension SendAmountViewModel: SendAmountExternalUpdatableViewModel {
    func externalUpdate(amount: SendAmount?) {
        sourceAmountField.updateAmountsUI(amount: amount)
        textFieldValueDidChanged(amount: amount?.main)
    }
}

// MARK: - Types

extension SendAmountViewModel {
    typealias BottomInfoTextType = SendAmountBottomInfoTextType

    enum DestinationTokenViewType {
        case selectButton
        case selected(SendAmountTokenViewData)
        case selectedEditableAmount(
            expandedDestinationData: SendAmountTokenViewData,
            compactDestinationData: SendAmountTokenViewData
        )

        var isAmountEditable: Bool {
            if case .selectedEditableAmount = self { return true }
            return false
        }

        var hasDestinationToken: Bool {
            switch self {
            case .selected, .selectedEditableAmount: true
            case .selectButton: false
            }
        }
    }
}

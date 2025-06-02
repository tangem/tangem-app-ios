//
//  SendNewAmountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import struct TangemUI.TokenIconInfo

class SendNewAmountViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var id: UUID = .init()
    @Published var isEditMode: Bool = false

    @Published var cryptoTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var cryptoTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var fiatTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var fiatTextFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var alternativeAmount: String

    @Published var bottomInfoText: BottomInfoTextType?
    @Published var amountType: SendAmountCalculationType = .crypto

    lazy var tokenWithAmountViewData: TokenWithAmountViewData = .init(
        tokenIconInfo: tokenIconInfo,
        title: tokenItem.name,
        subtitle: balanceFormatted,
        detailsType: .max { [weak self] in
            self?.userDidTapMaxAmount()
        }
    )

    var useFiatCalculation: Bool {
        get { amountType == .fiat }
        set { amountType = newValue ? .fiat : .crypto }
    }

    var tokenCurrencySymbol: String {
        tokenItem.currencySymbol
    }

    var cryptoIconURL: URL? {
        tokenIconInfo.imageURL
    }

    let walletHeaderText: String
    let fiatIconURL: URL
    let possibleToChangeAmountType: Bool

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let tokenIconInfo: TokenIconInfo
    private let balanceFormatted: String
    private let fiatCurrencyCode: String
    private let interactor: SendAmountInteractor
    private let actionType: SendFlowActionType
    private let sendAmountFormatter: SendAmountFormatter
    private var bag: Set<AnyCancellable> = []

    init(initial: Settings, interactor: SendAmountInteractor) {
        walletHeaderText = initial.walletHeaderText
        tokenItem = initial.tokenItem
        balanceFormatted = initial.balanceFormatted
        tokenIconInfo = initial.tokenIconInfo
        fiatIconURL = initial.fiatIconURL
        fiatCurrencyCode = initial.fiatItem.currencyCode
        possibleToChangeAmountType = initial.possibleToChangeAmountType
        actionType = initial.actionType

        cryptoTextFieldViewModel = .init(maximumFractionDigits: initial.tokenItem.decimalCount)
        fiatTextFieldViewModel = .init(maximumFractionDigits: SendAmountStep.Constants.fiatMaximumFractionDigits)

        let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()
        cryptoTextFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: initial.tokenItem.currencySymbol)
        fiatTextFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: initial.fiatItem.currencyCode)

        sendAmountFormatter = .init(tokenItem: initial.tokenItem, fiatItem: initial.fiatItem)
        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: .none, type: .crypto)

        self.interactor = interactor

        bind()
    }

    func onAppear() {}

    func userDidTapMaxAmount() {
        switch actionType {
        case .send:
            Analytics.log(.sendMaxAmountTapped)
        case .stake:
            Analytics.log(event: .stakingButtonMax, params: [.token: tokenItem.currencySymbol])
        default: break
        }

        let amount = interactor.updateToMaxAmount()
        FeedbackGenerator.success()
        updateAmountsUI(amount: amount)
    }
}

// MARK: - Private

private extension SendNewAmountViewModel {
    func bind() {
        $amountType
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amountType in
                viewModel.update(amountType: amountType)
            }
            .store(in: &bag)

        Publishers.Merge(
            cryptoTextFieldViewModel.valuePublisher,
            fiatTextFieldViewModel.valuePublisher
        )
        .withWeakCaptureOf(self)
        .receive(on: DispatchQueue.main)
        .sink { viewModel, value in
            viewModel.textFieldValueDidChanged(amount: value)
        }
        .store(in: &bag)

        interactor
            .infoTextPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.bottomInfoText, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .externalAmountPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.setExternalAmount(amount)
            }
            .store(in: &bag)
    }

    func setExternalAmount(_ amount: SendAmount?) {
        updateAmountsUI(amount: amount)
        textFieldValueDidChanged(amount: amount?.main)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        let amount = interactor.update(amount: amount)
        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: amountType)

        // Update another text field value
        switch amount?.type {
        case .typical(_, let fiat):
            fiatTextFieldViewModel.update(value: fiat)
        case .alternative(_, let crypto):
            cryptoTextFieldViewModel.update(value: crypto)
        case .none:
            cryptoTextFieldViewModel.update(value: nil)
            fiatTextFieldViewModel.update(value: nil)
        }
    }

    func update(amountType: SendAmountCalculationType) {
        let amount = interactor.update(type: amountType)
        updateAmountsUI(amount: amount)
    }

    func updateAmountsUI(amount: SendAmount?) {
        cryptoTextFieldViewModel.update(value: amount?.crypto)
        fiatTextFieldViewModel.update(value: amount?.fiat)

        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: amountType)
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewAmountViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {
        switch state {
        case .appearing(.destination(_)):
            // Have to be always visible
            isEditMode = false
        case .appearing(.newSummary(_)):
            // Will be shown with animation
            isEditMode = true
        case .disappearing(.newSummary(_)):
            // Have to use this HACK to force re-render view with the new transition
            // Will look at it "if" later
            if !isEditMode {
                isEditMode = true
                id = UUID()
            }
        default:
            break
        }
    }
}

// MARK: - Types

extension SendNewAmountViewModel {
    struct Settings {
        let walletHeaderText: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let balanceFormatted: String
        let fiatIconURL: URL
        let fiatItem: FiatItem
        let possibleToChangeAmountType: Bool
        let actionType: SendFlowActionType
    }

    typealias BottomInfoTextType = SendAmountViewModel.BottomInfoTextType
}

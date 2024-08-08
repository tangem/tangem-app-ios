//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendAmountViewModel: ObservableObject {
    // MARK: - ViewState

    let userWalletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let currencyPickerData: SendCurrencyPickerData

    @Published var id: UUID = .init()
    @Published var text: String = ""

    @Published var auxiliaryViewsVisible: Bool = true
    @Published var isEditMode: Bool = false

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?

    @Published var error: String?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var amountType: SendAmountCalculationType = .crypto

    var isFiatCalculation: BindingValue<Bool> {
        .init(
            root: self,
            default: false,
            get: { $0.amountType == .fiat },
            set: { $0.amountType = $1 ? .fiat : .crypto }
        )
    }

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: SendAmountInteractor
    private let sendQRCodeService: SendQRCodeService?
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private var bag: Set<AnyCancellable> = []

    init(
        initial: SendAmountViewModel.Settings,
        interactor: SendAmountInteractor,
        sendQRCodeService: SendQRCodeService?
    ) {
        userWalletName = initial.userWalletName
        balance = initial.balanceFormatted
        tokenIconInfo = initial.tokenIconInfo
        currencyPickerData = initial.currencyPickerData

        prefixSuffixOptionsFactory = .init(
            cryptoCurrencyCode: initial.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: initial.tokenItem.decimalCount)

        tokenItem = initial.tokenItem

        self.interactor = interactor
        self.sendQRCodeService = sendQRCodeService

        bind()
    }

    func onAppear() {
        auxiliaryViewsVisible = true
    }

    func userDidTapMaxAmount() {
        let amount = interactor.updateToMaxAmount()
        decimalNumberTextFieldViewModel.update(value: amount?.main)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol, decimalCount: tokenItem.decimalCount)
    }
}

// MARK: - Private

private extension SendAmountViewModel {
    func bind() {
        $amountType
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amountType in
                viewModel.update(amountType: amountType)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)

        interactor
            .errorPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, error in
                viewModel.error = error?.localizedDescription
            }
            .store(in: &bag)

        interactor
            .externalAmountPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.setExternalAmount(amount?.main)
                viewModel.alternativeAmount = amount?.formatAlternative(
                    currencySymbol: viewModel.tokenItem.currencySymbol,
                    decimalCount: viewModel.tokenItem.decimalCount
                )
            }
            .store(in: &bag)

        sendQRCodeService?
            .qrCodeAmount
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.setExternalAmount(amount)
            }
            .store(in: &bag)
    }

    func setExternalAmount(_ amount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: amount)
        textFieldValueDidChanged(amount: amount)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        let amount = interactor.update(amount: amount)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol, decimalCount: tokenItem.decimalCount)
    }

    func update(amountType: SendAmountCalculationType) {
        let amount = interactor.update(type: amountType)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol, decimalCount: tokenItem.decimalCount)

        switch amountType {
        case .crypto:
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
            decimalNumberTextFieldViewModel.update(value: amount?.crypto)
        case .fiat:
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: 2)
            decimalNumberTextFieldViewModel.update(value: amount?.fiat)
        }
    }
}

// MARK: - SendStepViewAnimatable

extension SendAmountViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {
        switch state {
        case .appearing(.destination(_)):
            // Have to be always visible
            auxiliaryViewsVisible = true
            isEditMode = false

        case .disappearing(.destination(_)):
            UIApplication.shared.endEditing()

        case .appearing(.summary(_)):
            // Will be shown with animation
            auxiliaryViewsVisible = false
            isEditMode = true
        case .disappearing(.summary(_)):
            // Have to use this HACK to force re-render view with the new transition
            // Will look at it "if" later
            if !isEditMode {
                isEditMode = true
                id = UUID()
            } else {
                auxiliaryViewsVisible = false
            }
            UIApplication.shared.endEditing()

        default:
            assertionFailure("Not implemented")
        }
    }
}

extension SendAmountViewModel {
    struct Settings {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let balanceValue: Decimal
        let balanceFormatted: String
        let currencyPickerData: SendCurrencyPickerData
    }
}

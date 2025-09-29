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
import struct TangemUI.TokenIconInfo

class SendAmountViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    let walletHeaderText: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let currencyPickerData: SendCurrencyPickerData

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?

    @Published var bottomInfoText: BottomInfoTextType?
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

    var tokenCurrencySymbol: String {
        tokenItem.currencySymbol
    }

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: SendAmountInteractor
    private let sendQRCodeService: SendQRCodeService?
    private let analyticsLogger: SendAmountAnalyticsLogger
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private var bag: Set<AnyCancellable> = []

    init(
        initial: SendAmountViewModel.Settings,
        interactor: SendAmountInteractor,
        analyticsLogger: SendAmountAnalyticsLogger,
        sendQRCodeService: SendQRCodeService?
    ) {
        tokenItem = initial.tokenItem
        walletHeaderText = initial.walletHeaderText
        balance = initial.balanceFormatted
        tokenIconInfo = initial.tokenIconInfo
        currencyPickerData = initial.currencyPickerData

        prefixSuffixOptionsFactory = .init()
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: initial.tokenItem.currencySymbol)
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: initial.tokenItem.decimalCount)

        self.interactor = interactor
        self.sendQRCodeService = sendQRCodeService
        self.analyticsLogger = analyticsLogger

        bind()
    }

    func onAppear() {}

    func userDidTapMaxAmount() {
        analyticsLogger.logTapMaxAmount()

        let amount = interactor.updateToMaxAmount()
        decimalNumberTextFieldViewModel.update(value: amount.main)
        alternativeAmount = amount.formatAlternative(currencySymbol: tokenItem.currencySymbol, decimalCount: tokenItem.decimalCount)
    }
}

// MARK: - Private

private extension SendAmountViewModel {
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

        decimalNumberTextFieldViewModel
            .valuePublisher
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
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: tokenItem.currencySymbol)
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
            decimalNumberTextFieldViewModel.update(value: amount?.crypto)
        case .fiat:
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode)
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: SendAmountStep.Constants.fiatMaximumFractionDigits)
            decimalNumberTextFieldViewModel.update(value: amount?.fiat)
        }
    }
}

// MARK: - SendStepViewAnimatable

extension SendAmountViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

extension SendAmountViewModel {
    struct Settings {
        let walletHeaderText: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let balanceFormatted: String
        let currencyPickerData: SendCurrencyPickerData
    }

    enum BottomInfoTextType: Hashable {
        case info(String)
        case error(String)
    }
}

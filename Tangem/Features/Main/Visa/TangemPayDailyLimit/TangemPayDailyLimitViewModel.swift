//
//  TangemPayDailyLimitViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

protocol TangemPayDailyLimitRoutable: AnyObject {
    func closeTangemPayDailyLimit()
}

final class TangemPayDailyLimitViewModel: ObservableObject, Identifiable {
    enum State {
        case editLimit
        case success
    }

    let id = UUID()
    let amountFieldViewModel = DecimalNumberTextFieldViewModel(maximumFractionDigits: 0, locale: .init(identifier: "en_US"))

    @Published private(set) var state: State = .editLimit
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSubmitEnabled: Bool = false
    @Published var alert: AlertBinder?

    let maxLimit: Int
    let currency: String = AppConstants.usdCurrencyCode

    var hintText: String {
        guard let minFormatted = formatter.string(from: .init(value: minLimit)),
              let maxFormatted = formatter.string(from: .init(value: maxLimit)) else {
            return ""
        }

        return Localization.tangempayDailyLimitHint(minFormatted, maxFormatted)
    }

    lazy var presets: [String] = [minLimit, 5000, 10_000, 25_000]
        .filter { $0 <= maxLimit }
        .map { formatter.string(from: .init(value: $0)) ?? "" }

    private let formatter = BalanceFormatter().makeDefaultFiatFormatter(
        forCurrencyCode: AppConstants.usdCurrencyCode,
        locale: .posixEnUS,
        formattingOptions: .init(minFractionDigits: 0, maxFractionDigits: 0, formatEpsilonAsLowestRepresentableValue: false)
    )

    private let minLimit = 1

    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayDailyLimitRoutable?

    private var bag = Set<AnyCancellable>()

    init(
        tangemPayAccount: TangemPayAccount,
        coordinator: TangemPayDailyLimitRoutable
    ) {
        self.tangemPayAccount = tangemPayAccount
        maxLimit = tangemPayAccount.adminCardLimit
        self.coordinator = coordinator

        let currentLimit = tangemPayAccount.cardLimit

        amountFieldViewModel.update(value: Decimal(currentLimit))

        isSubmitEnabled = currentLimit > 0 && currentLimit <= maxLimit

        bind()
    }

    func onAppear() {
        Analytics.log(.visaScreenLimitManagementScreenOpened, contextParams: .userWallet(tangemPayAccount.userWalletId))
    }

    func selectPreset(_ value: String) {
        guard let intValue = formatter.number(from: value)?.intValue else { return }

        amountFieldViewModel.update(value: .init(intValue))

        isSubmitEnabled = intValue > 0 && intValue <= maxLimit
    }

    func submit() {
        guard let value = amountFieldViewModel.value, isSubmitEnabled else { return }

        let intValue = NSDecimalNumber(decimal: value).intValue

        Analytics.log(
            event: .visaScreenSetLimitsConfirmed,
            params: [.amount: "\(intValue)"],
            contextParams: .userWallet(tangemPayAccount.userWalletId)
        )

        isLoading = true

        runTask(in: self) { viewModel in
            do {
                try await viewModel.tangemPayAccount.customerService.setCardLimit(amount: intValue)
                await viewModel.tangemPayAccount.loadCustomerInfo()

                await MainActor.run {
                    viewModel.isLoading = false
                    viewModel.state = .success
                }
            } catch {
                await MainActor.run {
                    viewModel.isLoading = false
                    viewModel.alert = AlertBinder(
                        title: Localization.commonSomethingWentWrong,
                        message: Localization.tangempayCardPageDailyLimitErrorDescription
                    )
                }
            }
        }
    }

    func close() {
        coordinator?.closeTangemPayDailyLimit()
    }

    private func bind() {
        amountFieldViewModel.valuePublisher
            .map { [maxLimit] value in
                guard let value else { return false }
                let intValue = NSDecimalNumber(decimal: value).intValue
                return intValue > 0 && intValue <= maxLimit
            }
            .receiveOnMain()
            .assign(to: \.isSubmitEnabled, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

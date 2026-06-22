//
//  TangemPayIssueAdditionalCardCostPopupViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemVisa

protocol TangemPayIssueAdditionalCardCostPopupRoutable: AnyObject {
    func issueCostPopupDidConfirm()
    func issueCostPopupDidRequestAddFunds()
    func issueCostPopupDidFail(error: Error)
    func issueCostPopupDidCancel()
}

final class TangemPayIssueAdditionalCardCostPopupViewModel: ObservableObject, FloatingSheetContentViewModel, TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.CardPlus.regular32.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .info
    }

    var title: AttributedString {
        .init(Localization.tangempayIssueAdditionalCardTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayIssueAdditionalCardDescription)
    }

    var feeLabel: String {
        Localization.tangempayIssueAdditionalCardFeeLabel
    }

    var feeText: String {
        Self.formatCurrency(fee.amount, currencyCode: fee.currency)
    }

    var insufficientFundsBannerTitle: String {
        Localization.tangempayIssueAdditionalCardInsufficientFundsTitle
    }

    var insufficientFundsBannerMessage: String {
        Localization.tangempayIssueAdditionalCardInsufficientFundsSubtitle
    }

    var addFundsButtonTitle: String {
        Localization.tangempayCardDetailsAddFunds
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangempayIssueCard,
            style: .primary,
            size: .default,
            isLoading: isIssuing,
            action: { [weak self] in self?.confirm() }
        )
    }

    @Published private(set) var isInsufficientFunds: Bool = false
    @Published private(set) var isIssuing: Bool = false

    private let offer: TangemPayCustomerOffer
    private let fee: TangemPayCustomerOffer.Fee
    private let userWalletId: UserWalletId
    private let tangemPayAccount: TangemPayAccount
    private let issueCard: () async throws -> Void
    private weak var coordinator: TangemPayIssueAdditionalCardCostPopupRoutable?

    private let bffInsufficientBalanceSubject = CurrentValueSubject<Bool, Never>(false)

    init(
        offer: TangemPayCustomerOffer,
        fee: TangemPayCustomerOffer.Fee,
        userWalletId: UserWalletId,
        tangemPayAccount: TangemPayAccount,
        issueCard: @escaping () async throws -> Void,
        coordinator: TangemPayIssueAdditionalCardCostPopupRoutable
    ) {
        self.offer = offer
        self.fee = fee
        self.userWalletId = userWalletId
        self.tangemPayAccount = tangemPayAccount
        self.issueCard = issueCard
        self.coordinator = coordinator

        let balanceProvider = tangemPayAccount.balancesProvider.totalTokenBalanceProvider
        isInsufficientFunds = (balanceProvider.balanceType.value ?? 0) < fee.amount

        Publishers.CombineLatest(
            balanceProvider.balanceTypePublisher
                .compactMap(\.value)
                .map { [fee] balance in balance < fee.amount },
            bffInsufficientBalanceSubject
        )
        .map { localInsufficient, bffInsufficient in localInsufficient || bffInsufficient }
        .receiveOnMain()
        .assign(to: &$isInsufficientFunds)

        Analytics.log(.visaScreenExtraCardIssuancePopupDisplayed, contextParams: .userWallet(userWalletId))
    }

    func dismiss() {
        guard !isIssuing else { return }
        coordinator?.issueCostPopupDidCancel()
    }

    func openAddFunds() {
        coordinator?.issueCostPopupDidRequestAddFunds()
    }
}

private extension TangemPayIssueAdditionalCardCostPopupViewModel {
    static func formatCurrency(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currencyCode)"
    }

    func confirm() {
        guard !isIssuing else { return }

        Analytics.log(.visaScreenExtraCardIssuanceConfirmed, contextParams: .userWallet(userWalletId))

        isIssuing = true

        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.issueCard()
                viewModel.isIssuing = false
                viewModel.coordinator?.issueCostPopupDidConfirm()
            } catch TangemPayOrderResolverError.insufficientBalance {
                viewModel.isIssuing = false
                viewModel.bffInsufficientBalanceSubject.send(true)
            } catch {
                VisaLogger.error("Failed to issue additional card", error: error)
                viewModel.isIssuing = false
                viewModel.coordinator?.issueCostPopupDidFail(error: error)
            }
        }
    }
}

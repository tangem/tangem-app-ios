//
//  TangemPayIssueAdditionalCardCostPopupViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
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

final class TangemPayIssueAdditionalCardCostPopupViewModel: ObservableObject, FloatingSheetContentViewModel {
    var icon: Image {
        Image(systemName: "creditcard.fill")
    }

    var title: AttributedString {
        .init(Localization.tangempayIssueAdditionalCardTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayIssueAdditionalCardDescription)
    }

    var feeText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = fee.currency
        return formatter.string(from: fee.amount as NSDecimalNumber) ?? "\(fee.amount) \(fee.currency)"
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonContinue,
            style: .primary,
            size: .default,
            isLoading: isLoading || isIssuing,
            isDisabled: isInsufficientFunds,
            action: { [weak self] in self?.confirm() }
        )
    }

    @Published private(set) var isInsufficientFunds: Bool = false
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var isIssuing: Bool = false

    private let offer: TangemPayCustomerOffer
    private let fee: TangemPayCustomerOffer.Fee
    private let userWalletId: UserWalletId
    private let tangemPayAccount: TangemPayAccount
    private let issueCard: () async throws -> Void
    private weak var coordinator: TangemPayIssueAdditionalCardCostPopupRoutable?

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

        runTask(in: self) { viewModel in
            await viewModel.loadBalance()
        }
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
    func loadBalance() async {
        do {
            let balance = try await tangemPayAccount.customerService.getBalance()
            await MainActor.run {
                self.isInsufficientFunds = balance.fiat.availableBalance < self.fee.amount
                self.isLoading = false
            }
        } catch {
            VisaLogger.error("Failed to load balance for additional card issue popup", error: error)
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func confirm() {
        guard !isIssuing, !isInsufficientFunds else { return }

        isIssuing = true

        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.issueCard()
                viewModel.isIssuing = false
                viewModel.coordinator?.issueCostPopupDidConfirm()
            } catch {
                VisaLogger.error("Failed to issue additional card", error: error)
                viewModel.isIssuing = false
                viewModel.coordinator?.issueCostPopupDidFail(error: error)
            }
        }
    }
}

//
//  TangemPayVirtualAccountDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemVisa

@MainActor
final class TangemPayVirtualAccountDetailsViewModel: ObservableObject, Identifiable {
    @Published private(set) var contentState: TangemPayVirtualAccountDetailsContentView.State

    @Injected(\.overlayShareActivitiesPresenter) private var shareActivitiesPresenter: any ShareActivitiesPresenter

    private let tangemPayAccount: TangemPayAccount
    private let onClose: () -> Void

    init(
        credentials: TangemPayBankCredentialsResponse,
        tangemPayAccount: TangemPayAccount,
        onClose: @escaping () -> Void
    ) {
        self.tangemPayAccount = tangemPayAccount
        self.onClose = onClose

        let rows: [TangemPayVirtualAccountDetailsContentView.Row] = [
            .init(key: "account_number", title: Localization.virtualAccountRequisitesAccountNumber, value: credentials.accountNumber),
            .init(key: "routing_number", title: Localization.virtualAccountRequisitesRoutingNumber, value: credentials.routingNumber),
            .init(key: "beneficiary_name", title: Localization.virtualAccountRequisitesBeneficiaryName, value: credentials.beneficiaryName),
            .init(key: "beneficiary_address", title: Localization.virtualAccountRequisitesBeneficiaryAddress, value: credentials.beneficiaryAddress),
            .init(key: "bank_name", title: Localization.virtualAccountRequisitesBankName, value: credentials.beneficiaryBankName),
            .init(key: "bank_address", title: Localization.virtualAccountRequisitesBankAddress, value: credentials.beneficiaryBankAddress),
        ]
        .filter { !$0.value.isEmpty }

        contentState = .init(rows: rows, fees: .loading, dailyDepositLimit: TangemPayDepositLimitFormatter.format(credentials.depositLimit))

        Analytics.log(.visaVATopupBankingDetailsShowed)

        loadFees()
    }

    func reloadFees() {
        guard case .failed = contentState.fees else { return }

        contentState.fees = .loading

        loadFees()
    }

    func copy(_ row: TangemPayVirtualAccountDetailsContentView.Row) {
        Analytics.log(event: .visaVATopupCopyFieldClicked, params: [.field: row.key])

        UIPasteboard.general.string = row.value

        Toast(
            view: TangemSnackbar(title: Localization.commonValueCopied)
                .icon(DesignSystem.Icons.Checkmark.regular20)
                .iconColor(DesignSystem.Color.iconAccentBlue)
        )
        .present(layout: .top(padding: 12), type: .temporary())
    }

    func share() {
        Analytics.log(.visaVATopupShareDetailsButtonClicked)

        let text = contentState.rows.map { "\($0.title): \($0.value)" }.joined(separator: "\n")
        shareActivitiesPresenter.share(activityItems: [text])
    }

    func close() {
        onClose()
    }

    private func loadFees() {
        runTask(in: self) { @MainActor viewModel in
            do {
                let fees = try await viewModel.tangemPayAccount
                    .loadOnrampFees()
                    .compactMap(TangemPayVirtualAccountFee.init(response:))

                viewModel.contentState.fees = fees.isEmpty ? .empty : .loaded(fees)
            } catch {
                VisaLogger.error("Failed to load virtual account onramp fees", error: error)
                viewModel.contentState.fees = .failed
            }
        }
    }
}

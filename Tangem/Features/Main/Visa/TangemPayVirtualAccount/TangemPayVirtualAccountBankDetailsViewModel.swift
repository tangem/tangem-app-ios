//
//  TangemPayVirtualAccountBankDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import TangemUI
import TangemAssets
import TangemLocalization
import TangemPay

@MainActor
final class TangemPayVirtualAccountBankDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    let rows: [Row]

    @Injected(\.overlayShareActivitiesPresenter) private var shareActivitiesPresenter: any ShareActivitiesPresenter

    private let onClose: () -> Void

    init(credentials: TangemPayBankCredentialsResponse, onClose: @escaping () -> Void) {
        self.onClose = onClose

        rows = [
            Row(key: "beneficiary_name", title: Localization.virtualAccountRequisitesBeneficiaryName, value: credentials.beneficiaryName),
            Row(key: "beneficiary_address", title: Localization.virtualAccountRequisitesBeneficiaryAddress, value: credentials.beneficiaryAddress),
            Row(key: "bank_name", title: Localization.virtualAccountRequisitesBankName, value: credentials.beneficiaryBankName),
            Row(key: "bank_address", title: Localization.virtualAccountRequisitesBankAddress, value: credentials.beneficiaryBankAddress),
            Row(key: "account_number", title: Localization.virtualAccountRequisitesAccountNumber, value: credentials.accountNumber),
            Row(key: "routing_number", title: Localization.virtualAccountRequisitesRoutingNumber, value: credentials.routingNumber),
        ]
        .filter { !$0.value.isEmpty }
    }

    func copy(_ value: String) {
        UIPasteboard.general.string = value

        Toast(
            // [REDACTED_TODO_COMMENT]
            view: TangemSnackbar(title: "Copied")
                .icon(DesignSystem.Icons.Checkmark.regular20)
                .iconColor(Color.Tangem.Graphic.Status.accent)
        )
        .present(layout: .top(padding: 12), type: .temporary())
    }

    func share() {
        let text = rows.map { "\($0.title): \($0.value)" }.joined(separator: "\n")
        shareActivitiesPresenter.share(activityItems: [text])
    }

    func close() {
        onClose()
    }
}

extension TangemPayVirtualAccountBankDetailsViewModel {
    struct Row: Identifiable {
        var id: String { key }
        let key: String
        let title: String
        let value: String
    }
}

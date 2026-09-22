//
//  JointAccountOperationPlateViewDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

/// Words an unfinished operation the way the main screen's plate shows it.
struct JointAccountOperationPlateViewDataBuilder {
    private let balanceFormatter = BalanceFormatter()

    /// - Note: An amount this version cannot state is shown the way an unknown balance is, rather than costing the
    /// operation its plate.
    func build(pendingOperation: JointAccountPendingOperation, onTap: @escaping () -> Void) -> JointAccountOperationPlate.ViewData {
        let operation = pendingOperation.operation
        let account = pendingOperation.wallet.account
        let amount = pendingOperation.amount?.value

        // The initiator is one of the members; a member the account no longer lists is named by their address
        let initiatorName = account?.jointAccountMembersService.slots.members
            .first { $0.address.caseInsensitiveEquals(to: operation.initiator) }?
            .name ?? AddressFormatter(address: operation.initiator).truncated()

        let formattedAmount = balanceFormatter.formatCryptoBalance(amount, tokenItem: pendingOperation.tokenItem)
        let destination = AddressFormatter(address: pendingOperation.destination).truncated()

        return JointAccountOperationPlate.ViewData(
            id: operation.id,
            title: Localization.jointOperationBannerTitle(initiatorName, pendingOperation.tokenItem.name),
            subtitle: Localization.jointOperationBannerSubtitle(formattedAmount, destination),
            collectedSignaturesCount: operation.signatures.filter { $0.state == .signed }.count,
            requiredSignaturesCount: account?.policy.signersCount ?? 0,
            isActionable: true,
            onTap: onTap
        )
    }
}

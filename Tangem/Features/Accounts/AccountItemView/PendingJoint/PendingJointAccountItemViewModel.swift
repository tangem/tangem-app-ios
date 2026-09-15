//
//  PendingJointAccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAccounts
import TangemFoundation
import TangemLocalization
import TangemUI

final class PendingJointAccountItemViewModel: Identifiable, ObservableObject {
    /// Keyed by the account rather than by the object, so that a plate rebuilt from a fresh model reads as the same
    /// row to SwiftUI instead of one row replacing another.
    var id: CryptoAccountModelId { jointAccount.id }

    // MARK: - View State

    @Published private(set) var name: String
    @Published private(set) var iconData: AccountIconView.ViewData
    /// Stated outright rather than awaited from the balance provider, which would leave the plate shimmering over a
    /// balance that cannot exist yet.
    @Published private(set) var balance: String
    @Published private(set) var status: String
    @Published private(set) var isInviteActionVisible: Bool

    let priceChange: PriceChangeView.State

    // MARK: - Private properties

    private let jointAccount: any JointAccountModel
    private let onTap: () -> Void

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(jointAccount: any JointAccountModel, onTap: @escaping () -> Void) {
        self.jointAccount = jointAccount
        self.onTap = onTap

        let slots = jointAccount.jointAccountMembersService.slots

        name = jointAccount.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: jointAccount)
        status = Self.status(of: jointAccount.status, slots: slots)
        balance = BalanceFormatter().formatFiatBalance(.zero, currencyCode: AppSettings.shared.selectedCurrencyCode)
        priceChange = PriceChangeUtility().convertToPriceChangeState(changePercent: .zero)
        // Inviting takes both a slot to fill and an invite to fill it with
        isInviteActionVisible = slots.contains { $0.invite != nil }

        bind()
    }

    // MARK: - Public

    func onSelect() {
        onTap()
    }

    // MARK: - Private methods

    private func bind() {
        // The composition is followed apart from the account, whose own changes say nothing of who joined, and the
        // rows are counted off what it hands out rather than read back off the service
        Publishers.CombineLatest(
            // Prepended because the account reports changes rather than state: without a value of its own the
            // combination would wait for one, and the plate would not be counted until the account moved
            jointAccount.didChangePublisher.prepend(()),
            jointAccount.jointAccountMembersService.slotsPublisher
        )
        .map { $1 }
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { viewModel, slots in
            viewModel.onAccountModelDidChange(slots: slots)
        }
        .store(in: &bag)

        AppSettings.shared.$selectedCurrencyCode
            .removeDuplicates()
            .receiveOnMain()
            .map { BalanceFormatter().formatFiatBalance(.zero, currencyCode: $0) }
            .assign(to: &$balance)
    }

    private func onAccountModelDidChange(slots: [JointAccountSlot]) {
        name = jointAccount.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: jointAccount)
        status = Self.status(of: jointAccount.status, slots: slots)
        isInviteActionVisible = slots.contains { $0.invite != nil }
    }

    private static func status(of status: JointAccountStatus, slots: [JointAccountSlot]) -> String {
        switch status {
        case .confirming:
            return Localization.jointAccountWaitingActivation
        case .pending:
            return Localization.jointAccountMembersProgress(slots.members.count, slots.count)
        case .active, .cancelled, .unknown:
            assertionFailure("The plate is only shown for a joint account that is still being put together")

            return Localization.jointAccountMembersProgress(slots.members.count, slots.count)
        }
    }
}

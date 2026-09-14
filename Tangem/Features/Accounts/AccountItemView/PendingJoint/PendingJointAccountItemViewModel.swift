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

    /// Fixed for the plate's lifetime: unlike the name and the icon, which the account model edits in place, the joint
    /// config is immutable — a status moving on or a member joining arrives as a new model, and so as a new plate.
    let status: String
    let isInviteActionVisible: Bool
    let priceChange: PriceChangeView.State

    // MARK: - Private properties

    private let jointAccount: any JointAccountModel
    private let onTap: () -> Void

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(jointAccount: any JointAccountModel, onTap: @escaping () -> Void) {
        self.jointAccount = jointAccount
        self.onTap = onTap

        name = jointAccount.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: jointAccount)
        status = Self.status(for: jointAccount)
        balance = BalanceFormatter().formatFiatBalance(.zero, currencyCode: AppSettings.shared.selectedCurrencyCode)
        priceChange = PriceChangeUtility().convertToPriceChangeState(changePercent: .zero)
        isInviteActionVisible = jointAccount.canInviteMembers

        bind()
    }

    // MARK: - Public

    func onSelect() {
        onTap()
    }

    // MARK: - Private methods

    private func bind() {
        jointAccount
            .didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.onAccountModelDidChange()
            }
            .store(in: &bag)

        AppSettings.shared.$selectedCurrencyCode
            .removeDuplicates()
            .receiveOnMain()
            .map { BalanceFormatter().formatFiatBalance(.zero, currencyCode: $0) }
            .assign(to: &$balance)
    }

    private func onAccountModelDidChange() {
        name = jointAccount.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: jointAccount)
    }

    private static func status(for jointAccount: any JointAccountModel) -> String {
        switch jointAccount.status {
        case .confirming:
            return Localization.jointAccountWaitingActivation
        case .pending:
            return Localization.jointAccountMembersProgress(
                jointAccount.members.count,
                jointAccount.policy.membersCount
            )
        case .active, .cancelled, .unknown:
            assertionFailure("The plate is only shown for a joint account that is still being put together")

            return Localization.jointAccountMembersProgress(
                jointAccount.members.count,
                jointAccount.policy.membersCount
            )
        }
    }
}

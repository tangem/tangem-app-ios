//
//  PausedJointAccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAccounts
import TangemFoundation

final class PausedJointAccountItemViewModel: Identifiable, ObservableObject {
    var id: CryptoAccountModelId { jointAccount.id }

    @Published private(set) var name: String
    @Published private(set) var iconData: AccountIconView.ViewData

    private let jointAccount: any JointAccountModel
    private let onTap: () -> Void

    init(jointAccount: any JointAccountModel, onTap: @escaping () -> Void) {
        self.jointAccount = jointAccount
        self.onTap = onTap

        name = jointAccount.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: jointAccount)

        bind()
    }

    func onSelect() {
        onTap()
    }
}

// MARK: - Private

private extension PausedJointAccountItemViewModel {
    func bind() {
        let jointAccountPublisher = jointAccount.didChangePublisher
            .withWeakCaptureOf(self)
            .map { viewModel, _ in viewModel.jointAccount }
            .receiveOnMain()
            .share()

        jointAccountPublisher
            .map(\.name)
            .assign(to: &$name)

        jointAccountPublisher
            .map { AccountModelUtils.UI.iconViewData(accountModel: $0) }
            .assign(to: &$iconData)
    }
}

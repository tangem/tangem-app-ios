//
//  CommonUserWalletLinkRequester.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

@MainActor
final class CommonUserWalletLinkRequester: UserWalletLinkRequester {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    nonisolated init() {}

    func requestLink(for userWalletModel: any UserWalletModel, completion: @escaping (UserWalletLinkResult) -> Void) {
        let viewModel = UserWalletLinkSheetViewModel(userWalletModel: userWalletModel, onFinish: completion)
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }
}

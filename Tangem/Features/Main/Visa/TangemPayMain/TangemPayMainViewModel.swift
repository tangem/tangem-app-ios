//
//  TangemPayMainViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class TangemPayMainViewModel: ObservableObject {
    let mainHeaderViewModel: MainHeaderViewModel
    lazy var refreshScrollViewStateObject = RefreshScrollViewStateObject { [weak self] in
        guard let self else { return }
        await tangemPayAccount.loadBalance().value
    }

    @Published private(set) var tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel?

    private let tangemPayAccount: TangemPayAccount

    init(tangemPayAccount: TangemPayAccount) {
        self.tangemPayAccount = tangemPayAccount

        mainHeaderViewModel = MainHeaderViewModel(
            isUserWalletLocked: false,
            supplementInfoProvider: tangemPayAccount,
            subtitleProvider: tangemPayAccount,
            balanceProvider: tangemPayAccount,
            updatePublisher: .empty
        )

        tangemPayAccount.tangemPayCardDetailsPublisher
            .map { cardDetails -> TangemPayCardDetailsViewModel? in
                guard let (card, _) = cardDetails else {
                    return nil
                }
                return TangemPayCardDetailsViewModel(
                    lastFourDigits: card.cardNumberEnd,
                    customerInfoManagementService: tangemPayAccount.customerInfoManagementService
                )
            }
            .receiveOnMain()
            .assign(to: &$tangemPayCardDetailsViewModel)
    }
}

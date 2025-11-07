//
//  TangemPayCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class TangemPayCoordinator: CoordinatorObject {
    // MARK: - Properties

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: TangemPayMainViewModel?

    @Published var addToApplePayGuideViewModel: TangemPayAddToAppPayGuideViewModel?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = TangemPayMainViewModel(
            tangemPayAccount: options.tangemPayAccount,
            coordinator: self
        )
    }
}

extension TangemPayCoordinator: TangemPayRoutable {
    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel) {
        addToApplePayGuideViewModel = TangemPayAddToAppPayGuideViewModel(
            tangemPayCardDetailsViewModel: viewModel
        )
    }
}

extension TangemPayCoordinator {
    struct Options {
        let tangemPayAccount: TangemPayAccount
    }
}

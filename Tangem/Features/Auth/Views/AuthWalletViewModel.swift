//
//  AuthWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class AuthWalletViewModel: ObservableObject {
    @Published var icon: LoadingResult<ImageValue, Never> = .loading

    var title: String {
        item.title
    }

    var description: String {
        item.description
    }

    var isProtected: Bool {
        item.isProtected
    }

    private let item: AuthViewState.WalletItem

    init(item: AuthViewState.WalletItem) {
        self.item = item
        loadImage()
    }
}

// MARK: - Internal methods

extension AuthWalletViewModel {
    func onTap() {
        item.action()
    }

    func isUnlocking(with userWalletId: UserWalletId?) -> Bool {
        item.isUnlocking(userWalletId)
    }
}

// MARK: - Private methods

private extension AuthWalletViewModel {
    func loadImage() {
        guard icon.value == nil else {
            return
        }

        runTask(in: self) { viewModel in
            let image = await viewModel.item.imageProvider.loadSmallImage()

            await runOnMain {
                viewModel.icon = .success(image)
            }
        }
    }
}

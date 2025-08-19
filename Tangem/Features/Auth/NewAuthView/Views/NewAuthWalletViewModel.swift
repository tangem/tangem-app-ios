//
//  NewAuthWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class NewAuthWalletViewModel: ObservableObject {
    @Published var icon: LoadingValue<ImageValue> = .loading

    var title: String {
        item.title
    }

    var description: String {
        item.description
    }

    var isProtected: Bool {
        item.isProtected
    }

    private let item: NewAuthViewModel.WalletItem

    init(item: NewAuthViewModel.WalletItem) {
        self.item = item
        loadImage()
    }
}

// MARK: - Internal methods

extension NewAuthWalletViewModel {
    func onTap() {
        item.action()
    }
}

// MARK: - Private methods

private extension NewAuthWalletViewModel {
    func loadImage() {
        guard icon.value == nil else {
            return
        }

        runTask(in: self) { viewModel in
            let image = await viewModel.item.imageProvider.loadSmallImage()

            await runOnMain {
                viewModel.icon = .loaded(image)
            }
        }
    }
}

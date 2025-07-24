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

    var isSecured: Bool {
        item.isSecured
    }

    private let item: NewAuthViewModel.WalletItem

    init(item: NewAuthViewModel.WalletItem) {
        self.item = item
    }
}

// MARK: - Internal methods

extension NewAuthWalletViewModel {
    func onTap() {
        item.action()
    }

    func onLoad() {
        loadImage()
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

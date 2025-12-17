//
//  MarketsWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import TangemFoundation

final class MarketsWalletSelectorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var icon: LoadingResult<ImageValue, Never> = .loading

    private weak var infoProvider: WalletSelectorInfoProvider?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        infoProvider: WalletSelectorInfoProvider
    ) {
        self.infoProvider = infoProvider
        name = infoProvider.name
        bind()
        loadImage()
    }

    func loadImage() {
        runTask(in: self) { viewModel in
            guard let image = await viewModel.infoProvider?.walletImageProvider.loadSmallImage() else {
                return
            }

            await runOnMain {
                viewModel.icon = .success(image)
            }
        }
    }

    func bind() {
        infoProvider?
            .updatePublisher
            .compactMap(\.newName)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, name in
                viewModel.name = name
            }
            .store(in: &bag)
    }
}

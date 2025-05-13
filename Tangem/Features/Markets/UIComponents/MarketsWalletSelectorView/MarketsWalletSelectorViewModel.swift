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

class MarketsWalletSelectorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var icon: LoadingValue<ImageValue> = .loading

    private let userWalletNamePublisher: AnyPublisher<String, Never>
    private let cardImageProvider: CardImageProviding

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        userWalletNamePublisher: AnyPublisher<String, Never>,
        cardImageProvider: CardImageProviding
    ) {
        self.userWalletNamePublisher = userWalletNamePublisher
        self.cardImageProvider = cardImageProvider

        bind()
        loadImage()
    }

    func loadImage() {
        TangemFoundation.runTask(in: self) { viewModel in
            let image = await viewModel.cardImageProvider.loadSmallImage()

            await runOnMain {
                viewModel.icon = .loaded(image)
            }
        }
    }

    func bind() {
        userWalletNamePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, name in
                viewModel.name = name
            }
            .store(in: &bag)
    }
}

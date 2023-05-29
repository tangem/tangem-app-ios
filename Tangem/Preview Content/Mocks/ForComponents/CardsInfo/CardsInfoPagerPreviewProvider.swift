//
// Copyright © 2023 m3g0byt3
//

import Foundation

final class CardsInfoPagerPreviewProvider: ObservableObject {
    @Published var models: [CardInfoPagePreviewViewModel] = []

    init() {
        initializeModels()
    }

    private func initializeModels() {
        // Must match the amount of `CardInfoProvider` entities in `FakeCardHeaderPreviewProvider`
        let upperBound = 6
        models = (0 ..< upperBound).map { _ in
            CardInfoPagePreviewViewModel()
        }
    }
}

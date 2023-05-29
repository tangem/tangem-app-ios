//
// Copyright © 2023 m3g0byt3
//

import Foundation

final class CardInfoPageCellPreviewViewModel: ObservableObject {
    let id = UUID()

    @Published var tapCount = 0

    var title: String {
        id.uuidString + " (\(tapCount))"
    }
}

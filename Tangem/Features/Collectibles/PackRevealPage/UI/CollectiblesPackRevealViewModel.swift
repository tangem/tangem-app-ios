//
//  CollectiblesPackRevealViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class CollectiblesPackRevealViewModel: ObservableObject {
    // MARK: - Properties

    let videoURL: URL?
    let prize: CollectiblesPackRevealView.Prize

    // MARK: - Init

    init(videoURL: URL?, prize: CollectiblesPackRevealView.Prize) {
        self.videoURL = videoURL
        self.prize = prize
    }

    // MARK: - Methods

    func sellBack() {
        // [REDACTED_TODO_COMMENT]
    }
}

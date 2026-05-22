//
//  ShareActivitiesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

final class ShareActivitiesViewModel: ObservableObject {
    // MARK: - Published Properties

    @MainActor
    @Published var activityItems: [Any]?
}

// MARK: - ShareActivitiesPresenter

extension ShareActivitiesViewModel: ShareActivitiesPresenter {
    func share(activityItems: [Any]) {
        Task { @MainActor in
            self.activityItems = activityItems
        }
    }
}

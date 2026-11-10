//
//  StoriesCloseButton.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccessibilityIdentifiers

struct StoriesCloseButton: View {
    let action: () -> Void

    var body: some View {
        NavigationBarButton.close(action: action)
            .accessibilityIdentifier(StoriesAccessibilityIdentifiers.closeButton)
    }
}

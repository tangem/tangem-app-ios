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
        // `redesigned()` makes the DS button use its 44pt system/glass rendering on every iOS version
        // instead of the legacy 28pt circle.
        NavigationBarButton.close(action: action)
            .redesigned()
            .accessibilityIdentifier(StoriesAccessibilityIdentifiers.closeButton)
    }
}

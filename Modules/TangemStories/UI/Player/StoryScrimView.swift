//
//  StoryScrimView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct StoryScrimView: View {
    var body: some View {
        LinearGradient(
            colors: [.black.opacity(0.0), .black.opacity(0.15), .black.opacity(0.75)],
            startPoint: .center,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

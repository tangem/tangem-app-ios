//
//  StoryPageContainerView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct StoryPageContainerView: View {
    private let content: AnyView
    private let screenBounds = UIScreen.main.bounds

    private let ignoresBottomSafeArea: Bool

    public init(content: any View, ignoresBottomSafeArea: Bool = false) {
        self.content = AnyView(content)
        self.ignoresBottomSafeArea = ignoresBottomSafeArea
    }

    public var body: some View {
        content
            .frame(maxWidth: screenBounds.width, maxHeight: screenBounds.height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
            .ignoresSafeArea(edges: ignoresBottomSafeArea ? .bottom : [])
    }
}

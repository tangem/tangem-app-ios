//
//  StoryPageView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct StoryPageView: View {
    private let content: AnyView
    private let screenBounds = UIScreen.main.bounds

    public init(content: any View) {
        self.content = AnyView(content)
    }

    public var body: some View {
        content
            .frame(maxWidth: screenBounds.width, maxHeight: screenBounds.height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
    }
}

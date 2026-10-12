//
//  FeedTopFade.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Apply through `reverseMask` to fade content without painting over the sheet's glass background.
public struct FeedTopFade: View {
    let height: CGFloat
    let visibleHeight: CGFloat

    /// Keep the default 32 pt gradient below the hard fade's 56 pt solid header.
    public init(height: CGFloat = 88, visibleHeight: CGFloat = 32) {
        self.height = height
        self.visibleHeight = visibleHeight
    }

    public var body: some View {
        Fade(position: .top)
            .variant(.hard)
            .backgroundColor(.black)
            .frame(height: height)
            .frame(height: visibleHeight, alignment: .bottom)
            .clipped()
    }
}

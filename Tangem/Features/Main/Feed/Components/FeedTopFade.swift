//
//  FeedTopFade.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

/// Apply through `reverseMask` to fade content without painting over the sheet's glass background.
struct FeedTopFade: View {
    let height: CGFloat
    let visibleHeight: CGFloat

    var body: some View {
        Fade(position: .top)
            .variant(.hard)
            .backgroundColor(.black)
            .frame(height: height)
            .frame(height: visibleHeight, alignment: .bottom)
            .clipped()
    }
}

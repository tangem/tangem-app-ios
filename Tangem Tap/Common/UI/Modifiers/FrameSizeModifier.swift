//
//  FrameSizeModifier.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct FrameSizeModifier: ViewModifier {
    var frameSize: CGSize
    var alignment: SwiftUI.Alignment

    func body(content: Content) -> some View {
        content.frame(width: frameSize.width, height: frameSize.height, alignment: alignment)
    }
}

extension View {
    @ViewBuilder
    func frame(size: CGSize, alignment: SwiftUI.Alignment = .center) -> some View {
        modifier(FrameSizeModifier(frameSize: size, alignment: alignment))
    }
}

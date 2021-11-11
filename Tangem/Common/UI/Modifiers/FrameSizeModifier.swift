//
//  FrameSizeModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct FrameSizeModifier: ViewModifier {
    var frameSize: CGSize
    var alignment: SwiftUI.Alignment

    func body(content: Content) -> some View {
        content.frame(width: max(frameSize.width,0), height: max(frameSize.height,0), alignment: alignment)
    }
}

extension View {
    @ViewBuilder
    func frame(size: CGSize, alignment: SwiftUI.Alignment = .center) -> some View {
        modifier(FrameSizeModifier(frameSize: size, alignment: alignment))
    }
}

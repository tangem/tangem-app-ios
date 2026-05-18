//
//  BottomFadeWithBlur.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlurSwiftUI

public struct BottomFadeWithBlur: View {
    private let backgroundColor: Color

    public init(backgroundColor: Color) {
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        VariableBlur(direction: .up)
            .maximumBlurRadius(Constants.blurRadius)
            .dimmingTintColor(backgroundColor)
            .dimmingAlpha(.constant(alpha: 1.0))
            .dimmingOvershoot(nil)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.height)
            .ignoresSafeArea(.container, edges: .bottom)
            .allowsHitTesting(false)
    }

    private enum Constants {
        static let blurRadius: CGFloat = 10
        static let height: CGFloat = 140
    }
}

// MARK: - Previews

#if DEBUG
#Preview("BottomFadeWithBlur") {
    ZStack(alignment: .bottom) {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0 ..< 20, id: \.self) { index in
                    Text("Paragraph \(index + 1)")
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                }
            }
        }

        BottomFadeWithBlur(backgroundColor: .black)
    }
    .background(Color.black)
}
#endif

//
//  AttributedStringBlinkAnimationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct AttributedStringBlinkAnimationView: View {
    typealias ChangePublisher = Published<ForegroundBlinkAnimationChange>.Publisher

    private let originalString: AttributedString
    private let publisher: ChangePublisher
    private let positiveColor: Color
    private let negativeColor: Color
    private let duration: Double

    @State private var targetString: AttributedString

    init(
        originalString: AttributedString,
        publisher: ChangePublisher,
        positiveColor: Color,
        negativeColor: Color,
        duration: Double = 0.5
    ) {
        self.originalString = originalString
        self.publisher = publisher
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        self.duration = duration
        targetString = originalString
    }

    var body: some View {
        Text(targetString)
            .animation(.none, value: originalString)
            .onChange(of: originalString) {
                targetString = $0
            }
            .onReceive(publisher, perform: { newValue in
                switch newValue {
                case .neutral:
                    return
                case .negative:
                    targetString = targetString(with: negativeColor)
                case .positive:
                    targetString = targetString(with: positiveColor)
                }

                withAnimation(.easeInOut(duration: duration)) {
                    targetString = originalString
                }
            })
    }

    private func targetString(with color: Color) -> AttributedString {
        var string = originalString
        string.foregroundColor = color
        return string
    }
}

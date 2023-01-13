//
//  AsyncButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AsyncButton<Label: View>: View {
    var action: () async -> Void
    var color: UIColor
    @ViewBuilder var label: () -> Label

    @State private var isWaiting = false

    var body: some View {
        Button {
            isWaiting = true

            Task {
                await action()

                isWaiting = false
            }
        } label: {
            if isWaiting {
                ActivityIndicatorView(isAnimating: isWaiting, style: .medium, color: color)
            } else {
                label()
            }
        }
        .disabled(isWaiting)
    }
}

struct AsyncImageButton: View {
    var action: () async -> Void
    var color: UIColor
    var image: Image

    var body: some View {
        AsyncButton(action: action,
                    color: color) {
            image
                .foregroundColor(Color(color))
                .frame(width: 44, height: 44)
        }
    }
}

struct AsyncButton_Previews: PreviewProvider {
    static var previews: some View {
        AsyncImageButton(action: { try? await Task.sleep(seconds: 3) },
                         color: .tangemBlue,
                         image: Assets.plusMini)
    }
}

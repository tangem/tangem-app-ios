//
//  ProgressBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
    let height: CGFloat
    /// Must be in 0...1 range. Values smaller than 0 displays no progress, and > 1 displays max progress
    let currentProgress: CGFloat
    var backgroundColor: Color = .tangemGrayDark1
    var progressColor: Color = .tangemGrayDark6

    var body: some View {
        Rectangle()
            .modifier(
                AnimatableGradient(backgroundColor: backgroundColor,
                                   progressColor: progressColor,
                                   gradientStop: max(0, min(1, currentProgress)))
            )
            .cornerRadius(height / 2)
            .frame(height: height)
    }
}

struct ProgressBarPreviewView: View {

    @State var progress: CGFloat = 0.4

    var body: some View {
        VStack {
            ProgressBar(height: 5, currentProgress: progress, backgroundColor: .tangemGrayDark.opacity(0.12), progressColor: .blue)
                .padding()
            Spacer()
                .frame(height: 50)
            Button(action: {
                var newProgress = progress + 0.3
                if newProgress > 2 {
                    newProgress = -2
                }
                withAnimation {
                    progress = newProgress
                }
            }, label: {
                Text("Animate progress")
                    .padding()
            })
            Spacer()
        }

    }


}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarPreviewView()
    }
}

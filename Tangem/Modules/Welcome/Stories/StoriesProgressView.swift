//
//  StoriesProgressView.swift
//  StoriesDemo
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct StoriesProgressView: View {
    let pages: [WelcomeStoryPage]
    @Binding var currentPage: WelcomeStoryPage
    @Binding var progress: Double

    private let barHeight: Double = 2
    private let barSpacing: Double = 5
    private let barBackgroundOpacity: Double = 0.2

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0 ..< pages.count) { index in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.primary.opacity(barBackgroundOpacity))
                        .overlay(overlay(index, width: geo.size.width), alignment: .leading)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxHeight: barHeight)
    }

    @ViewBuilder
    func overlay(_ index: Int, width: CGFloat) -> some View {
        if index < currentPage.rawValue {
            Color.primary
        } else if index > currentPage.rawValue {
            EmptyView()
        } else {
            Color.primary.frame(width: progress * width)
        }
    }
}

struct StoriesProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .center) {
            Color.purple
            StoriesProgressView(pages: WelcomeStoryPage.allCases, currentPage: .constant(.meetTangem), progress: .constant(0.3))
                .padding()
                .preferredColorScheme(.dark)
        }
        .previewLayout(.fixed(width: 400, height: 100))
    }
}

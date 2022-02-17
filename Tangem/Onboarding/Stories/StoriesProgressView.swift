//
//  StoriesProgressView.swift
//  StoriesDemo
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct StoriesProgressView: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    @Binding var progress: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<numberOfPages) { index in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.primary.opacity(0.2))
                        .overlay(overlay(index, width: geo.size.width), alignment: .leading)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxHeight: 3)
    }
    
    @ViewBuilder
    func overlay(_ index: Int, width: CGFloat) -> some View {
        if index < currentPage {
            Color.primary
        } else if index > currentPage {
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
            StoriesProgressView(numberOfPages: 4, currentPage: .constant(2), progress: .constant(0.3))
                .padding()
                .preferredColorScheme(.dark)
        }
        .previewLayout(.fixed(width: 400, height: 100))
    }
}

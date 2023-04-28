//
//  LoadableTextView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct LoadableTextView: View {
    let state: State
    let font: Font
    let textColor: Color
    let loaderSize: CGSize
    /// Use this to adjust loader position in vertical direction to prevent jumping behaviour
    /// when view changes state from `loading` to `loaded`
    let loaderTopPadding: CGFloat

    var lineLimit: Int = 1

    var body: some View {
        switch state {
        case .initialized:
            Text(" ")
                .frame(size: loaderSize)
        case .noData:
            Text("–")
                .style(font, color: textColor)
                .frame(minHeight: loaderSize.height)
        case .loading:
            SkeletonView()
                .frame(size: loaderSize)
                .padding(.top, loaderTopPadding)
        case .loaded(let text):
            Text(text)
                .style(font, color: textColor)
                .lineLimit(lineLimit)
                .frame(minHeight: loaderSize.height)
        }
    }
}

extension LoadableTextView {
    enum State: Hashable, Identifiable {
        var id: Int { hashValue }

        case initialized
        case noData
        case loading
        case loaded(text: String)
    }
}

struct LoadableTextView_Preview: PreviewProvider {
    static let states: [LoadableTextView.State] = [
        .initialized, .noData, .loading, .loaded(text: "Some random text"),
    ]

    static var previews: some View {
        VStack {
            ForEach(states) { state in
                LoadableTextView(
                    state: .initialized,
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 100, height: 20),
                    loaderTopPadding: 4
                )
            }
        }
    }
}

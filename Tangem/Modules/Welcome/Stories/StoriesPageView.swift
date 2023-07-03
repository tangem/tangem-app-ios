//
//  StoriesPageView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct StoriesPageView<Content: View>: View {
    @ObservedObject var storiesViewModel: StoriesViewModel
    private let content: () -> Content

    init(storiesViewModel: StoriesViewModel, @ViewBuilder content: @escaping () -> Content) {
        self.storiesViewModel = storiesViewModel
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            content()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged {
                            storiesViewModel.didDrag($0.location)
                        }
                        .onEnded {
                            storiesViewModel.didEndDrag($0.location, destination: $0.predictedEndLocation, viewWidth: geo.size.width)
                        }
                )
        }
    }
}

struct StoriesPageView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesPageView(storiesViewModel: StoriesViewModel()) {
            Group {
                Color.red.tag(0)
                Color.blue.tag(1)
                Color.yellow.tag(2)
                Color.purple.tag(3)
            }
        }
    }
}

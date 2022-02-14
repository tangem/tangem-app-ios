//
//  StoriesView.swift
//  StoriesDemo
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct StoriesView<Content: View>: View {
    @ObservedObject var viewModel: StoriesViewModel
    @ViewBuilder private let content: () -> Content
    
    init(viewModel: StoriesViewModel, @ViewBuilder content: @escaping () -> Content) {
        self.viewModel = viewModel
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                TabView(selection: $viewModel.selection, content: content)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0).onEnded { v in
                            let width = geo.size.width
                            let moveForward = v.location.x > (width / 2)
                            viewModel.move(forward: moveForward)
                        }
                    )
                
                StoriesProgressView(numberOfPages: viewModel.numberOfViews, currentPage: $viewModel.selection, progress: $viewModel.currentProgress)
                    .padding(.horizontal)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(viewModel: StoriesViewModel(numberOfViews: 4, storyDuration: 2)) {
            Group {
                Color.red.tag(0)
                Color.blue.tag(1)
                Color.yellow.tag(2)
                Color.purple.tag(3)
            }
        }
    }
}

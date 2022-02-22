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
                content()
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged {
                                viewModel.didDrag($0.location)
                            }
                            .onEnded {
                                viewModel.didEndDrag($0.location, destination: $0.predictedEndLocation, viewWidth: geo.size.width)
                            }
                    )
                
                StoriesProgressView(pages: WelcomeStoryPage.allCases, currentPage: $viewModel.currentPage, progress: $viewModel.currentProgress)
                    .padding(.horizontal)
                    .padding(.top)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
}

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(viewModel: StoriesViewModel()) {
            Group {
                Color.red.tag(0)
                Color.blue.tag(1)
                Color.yellow.tag(2)
                Color.purple.tag(3)
            }
        }
    }
}

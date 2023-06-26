//
//  StoriesView.swift
//  StoriesDemo
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct StoriesView: View {
    @ObservedObject var viewModel: StoriesViewModel

    private var isScanning: Binding<Bool>
    private let scanCard: () -> Void
    private let orderCard: () -> Void
    private let openPromotion: () -> Void
    private let searchTokens: () -> Void

    init(
        viewModel: StoriesViewModel,
        isScanning: Binding<Bool>,
        scanCard: @escaping () -> Void,
        orderCard: @escaping () -> Void,
        openPromotion: @escaping () -> Void,
        searchTokens: @escaping () -> Void

    ) {
        self.viewModel = viewModel
        self.isScanning = isScanning
        self.scanCard = scanCard
        self.orderCard = orderCard
        self.openPromotion = openPromotion
        self.searchTokens = searchTokens
    }

    var body: some View {
        if viewModel.checkingPromotionAvailability {
            Color.black
                .ignoresSafeArea()
        } else {
            ZStack(alignment: .top) {
                StoriesPageView(storiesViewModel: viewModel) {
                    viewModel.currentStoryPage(
                        isScanning: isScanning,
                        scanCard: scanCard,
                        orderCard: orderCard,
                        openPromotion: openPromotion,
                        searchTokens: searchTokens
                    )
                }

                StoriesProgressView(pages: viewModel.pages, currentPageIndex: viewModel.currentPageIndex, progress: $viewModel.currentProgress)
                    .padding(.horizontal)
                    .padding(.top)
            }
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
        }
    }
}

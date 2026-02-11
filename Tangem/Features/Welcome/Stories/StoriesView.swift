//
//  StoriesView.swift
//  StoriesDemo
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI
import TangemUIUtils

struct StoriesView: View {
    @ObservedObject var viewModel: StoriesViewModel
    let scanTroubleshootingDialog: Binding<ConfirmationDialogViewModel?>

    var body: some View {
        ZStack {
            if viewModel.checkingPromotionAvailability {
                Color.black
                    .ignoresSafeArea()
                    .task {
                        await viewModel.checkPromotion()
                    }
            } else {
                contentView
            }
        }
        .animation(.default, value: viewModel.checkingPromotionAvailability)
    }

    @ViewBuilder
    var contentView: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                currentStoryPage()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged {
                                viewModel.didDrag($0.location)
                            }
                            .onEnded {
                                viewModel.didEndDrag($0.location, destination: $0.predictedEndLocation, viewWidth: geo.size.width)
                            }
                    )

                StoriesProgressView(pages: viewModel.pages, currentPageIndex: viewModel.currentPageIndex, progress: $viewModel.currentProgress)
                    .padding(.horizontal)
                    .padding(.top)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    @ViewBuilder
    func currentStoryPage() -> some View {
        switch viewModel.currentPage {
        case WelcomeStoryPage.learn:
            LearnAndEarnStoryPage(
                learn: { viewModel.delegate?.openPromotion() }
            )
        case WelcomeStoryPage.meetTangem:
            MeetTangemStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                createWallet: viewModel.onCreateWallet,
                scanCard: viewModel.onScanCard,
                orderCard: viewModel.onOrderCard,
                scanTroubleshootingDialog: scanTroubleshootingDialog
            )
        case WelcomeStoryPage.awe:
            AweStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                createWallet: viewModel.onCreateWallet,
                scanCard: viewModel.onScanCard,
                orderCard: viewModel.onOrderCard,
                scanTroubleshootingDialog: scanTroubleshootingDialog
            )
        case WelcomeStoryPage.backup:
            BackupStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                createWallet: viewModel.onCreateWallet,
                scanCard: viewModel.onScanCard,
                orderCard: viewModel.onOrderCard,
                scanTroubleshootingDialog: scanTroubleshootingDialog
            )
        case WelcomeStoryPage.currencies:
            CurrenciesStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                createWallet: viewModel.onCreateWallet,
                scanCard: viewModel.onScanCard,
                orderCard: viewModel.onOrderCard,
                searchTokens: viewModel.onSearchTokens,
                scanTroubleshootingDialog: scanTroubleshootingDialog
            )
        case WelcomeStoryPage.finish:
            FinishStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                createWallet: viewModel.onCreateWallet,
                scanCard: viewModel.onScanCard,
                orderCard: viewModel.onOrderCard,
                scanTroubleshootingDialog: scanTroubleshootingDialog
            )
        }
    }
}

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(viewModel: StoriesViewModel(), scanTroubleshootingDialog: .constant(nil))
    }
}

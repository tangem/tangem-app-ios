//
//  CardOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct NoOpTransition: AnimatableModifier {
    var animatableData: CGFloat = 0
    init(_ x: CGFloat) {
        animatableData = x
    }
    func body(content: Content) -> some View {
        return content
    }
}
extension AnyTransition {
    static let noOp: AnyTransition = .modifier(active: NoOpTransition(1), identity: NoOpTransition(0))
}

struct CardOnboardingView: View {
    
    @ObservedObject var viewModel: CardOnboardingViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @ViewBuilder
    var navigationLinks: some View {
        if !viewModel.isFromMainScreen {
            NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
                           isActive: $viewModel.toMain)
//                           isActive: $navigation.readToMain)
        }
        
        NavigationLink(destination: EmptyView(), isActive: .constant(false))
    }
    
    @ViewBuilder
    var notScannedContent: some View {
        Text("Not scanned view")
    }
    
    @ViewBuilder
    var defaultLaunchView: some View {
        SingleCardOnboardingView(viewModel: viewModel.assembly.getOnboardingViewModel())
    }
    
    @ViewBuilder
    var content: some View {
        switch viewModel.content {
        case .notScanned:
            if viewModel.isFromMainScreen {
                defaultLaunchView
                    .transition(.noOp)
            } else {
                LetsStartOnboardingView(viewModel: viewModel.assembly.getLetsStartOnboardingViewModel(with: viewModel.processScannedCard(with:)))
                    .transition(.noOp)
            }
        case .singleCard:
            defaultLaunchView
                .transition(.noOp)
        case .twin:
            TwinsOnboardingView(viewModel: viewModel.assembly.getTwinsOnboardingViewModel())
                .transition(.noOp)
        default:
            Text("Default case")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                navigationLinks
                
                content
            }
            .navigationBarTitle(viewModel.content.navbarTitle, displayMode: .inline)
//            .navigationBarHidden(
//                !navigation.onboardingToBuyCrypto &&
//                    !navigation.readToShop
//            )
        }
        .onAppear(perform: {
            viewModel.bind()
        })
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
    }
}

struct CardOnboardingView_Previews: PreviewProvider {
    
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        CardOnboardingView(
//            viewModel: assembly.makeCardOnboardingViewModel(with: assembly.previewTwinOnboardingInput)
            viewModel: assembly.getLaunchOnboardingViewModel()
        )
        .environmentObject(assembly.services.navigationCoordinator)
    }
}

struct CardOnboardingMessagesView: View {
    
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let onTitleTapCallback: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .frame(maxWidth: .infinity)
//                .background(Color.red)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(.tangemTapGrayDark6)
                .padding(.bottom, 14)
                .onTapGesture {
                    // [REDACTED_TODO_COMMENT]
                    onTitleTapCallback?()
                }
                .animation(nil)
            Text(subtitle)
                .frame(maxWidth: .infinity)
//                .background(Color.yellow)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.tangemTapGrayDark6)
                .frame(maxWidth: .infinity)
                .animation(nil)
        }
    }
    
}

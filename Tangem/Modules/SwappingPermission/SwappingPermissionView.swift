//
//  SwappingPermissionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BottomSheetContainerView<Content: View>: View {
    private let content: () -> Content
    
    @Binding private var isPresented: Bool
    
    @State private var contentSize: CGSize = .zero
    @State private var opacity: CGFloat = 0
    @State private var offset: CGFloat = UIScreen.main.bounds.height
    
    init(isPresented: Binding<Bool>, content: @escaping () -> Content) {
        _isPresented = isPresented
        self.content = content
    }

    var body: some View {
        Group {
            if isPresented {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Color.black.opacity(opacity)
                        
                        VStack {
                            Assets.bottomSheetHandIndicator
                                .padding(.vertical, 8)
                            
                            content()
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                        .readSize(onChange: { contentSize = $0 })
                        .background(Colors.Background.secondary)
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .offset(y: offset)
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3)) {
                offset = .zero // contentSize.height
                opacity = 0.3
            }
        }
    }
}

struct SwappingPermissionView: View {
    @ObservedObject private var viewModel: SwappingPermissionViewModel

    init(viewModel: SwappingPermissionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            headerView

            content
            
            buttons
        }
        .padding(.bottom, 10)
        .background(Colors.Background.secondary)
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Give Permission")
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)

            Text("To continue you need to allow 1inch smart contracts to use your Dai")
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .padding(.horizontal, 50)
                .multilineTextAlignment(.center)
        }
    }

    private var content: some View {
        GroupedSection([
            DefaultRowViewModel(title: "Amount DAI", detailsType: .text("􀯠")),
            DefaultRowViewModel(title: "Your Wallet", detailsType: .text("0x19388...097d")),
            DefaultRowViewModel(title: "Spender", detailsType: .text("0x19388...097d")),
            DefaultRowViewModel(title: "Fee", detailsType: .text("2,14 $")),
        ]) {
            DefaultRowView(viewModel: $0)
        }
        .padding(.horizontal, 16)
    }
    
    private var buttons: some View {
        VStack(spacing: 10) {
            MainButton(text: "Approve", icon: .trailing(Assets.tangemIcon), action: {})
            
            MainButton(text: "Cancel", style: .secondary, action: {})
        }
        .padding(.horizontal, 16)
    }
}

struct SwappingPermissionView_Preview: PreviewProvider {
    static let viewModel = SwappingPermissionViewModel(coordinator: nil)

    static var previews: some View {
            SwappingPermissionView(viewModel: viewModel)
    }
}

//
//  MainView.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import StoreKit

struct MainView: View {

    @ObservedObject var viewModel: MainViewModel

    @State private var isDisplayingAppStoreOverlay = false

    var body: some View {
        VStack {
            Text("main_title")
                .font(.system(size: 17, weight: .medium))
                .frame(height: 44, alignment: .center)
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 8) {
                        CardView(image: viewModel.image,
                                 width: geometry.size.width - 32)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        Text("main_warning")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)

                        Spacer()
                    }
                }
                .frame(width: geometry.size.width)
            }
            .appStoreOverlay(isPresented: $viewModel.shouldShowGetFullApp) { () -> SKOverlay.Configuration in
                SKOverlay.AppClipConfiguration(position: .bottom)
            }
            .onAppear(perform: viewModel.onAppear)
        }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: MainViewModel())
    }
}

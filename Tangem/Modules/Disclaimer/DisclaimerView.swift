//
//  DisclaimerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct DisclaimerView: View {
    let viewModel: DisclaimerViewModel

    private let bottomViewHeight: CGFloat = 150

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.style.isVisibleHeader {
                    Text(viewModel.style.title)
                        .font(.system(size: 30, weight: .bold, design: .default))
                        .foregroundColor(.tangemGrayDark6)
                        .padding([.top, .horizontal], 16)
                }

                ScrollView {
                    Text("disclaimer_text")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.tangemGrayDark5)
                        .padding(.horizontal, 16)
                        .padding(.bottom, viewModel.showAccept ? bottomViewHeight : 0)
                }
            }

            if viewModel.showAccept {
                bottomView
            }
        }
        .modifier(if: viewModel.showAccept, then: {
            $0.edgesIgnoringSafeArea(.bottom)
        })
        .navigationBarTitle(viewModel.style.title)
        .navigationBarBackButtonHidden(viewModel.style.isNavigationBarHidden)
        .navigationBarHidden(viewModel.style.isNavigationBarHidden)
    }

    private var bottomView: some View {
        ZStack(alignment: .center) {
            LinearGradient(
                gradient: Gradient(stops: [
                    Gradient.Stop(color: .white.opacity(0.2), location: 0.0),
                    Gradient.Stop(color: .white, location: 0.5),
                    Gradient.Stop(color: .white, location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(
                width: UIScreen.main.bounds.width,
                height: bottomViewHeight
            )

            TangemButton(title: "common_accept", action: viewModel.onAccept)
                .buttonStyle(TangemButtonStyle())
        }
    }
}

extension DisclaimerView {
    enum Style {
        case sheet
        case navbar

        var title: LocalizedStringKey { "disclaimer_title" }
        var isVisibleHeader: Bool { self == .sheet }
        var isNavigationBarHidden: Bool { self == .sheet }
    }
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerView(viewModel: .init(style: .sheet, showAccept: true, coordinator: nil))
            .previewGroup(devices: [.iPhone12Pro, .iPhone8Plus], withZoomed: false)

        NavigationView(content: {
            DisclaimerView(viewModel: .init(style: .navbar, showAccept: true, coordinator: nil))
        })
    }
}

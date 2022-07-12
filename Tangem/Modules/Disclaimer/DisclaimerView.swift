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

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if viewModel.style.withHeaderStack {
                    HStack {
                        Text("disclaimer_title")
                            .font(.system(size: 30, weight: .bold, design: .default))
                            .foregroundColor(.tangemGrayDark6)
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16))
                }

                ScrollView {
                    Text("disclaimer_text")
                        .font(Font.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.tangemGrayDark5)
                        .padding(.horizontal, 16)
                        .padding(.bottom, viewModel.showAccept ? 150 : 0)
                        .padding(.top, viewModel.style.disclaimerTextTopPadding)
                }
            }

            if viewModel.showAccept {
                TangemButton(title: "common_accept", action: viewModel.onAccept)
                    .buttonStyle(TangemButtonStyle())
                    .background(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white.opacity(0.2), location: 0.0),
                                .init(color: .white, location: 0.5),
                                .init(color: .white, location: 1.0),
                            ]),
                            startPoint: .top,
                            endPoint: .bottom)
                            .frame(size: CGSize(width: UIScreen.main.bounds.width, height: 135))
                            .offset(y: -20)
                    )
                    .alignmentGuide(.bottom, computeValue: { dimension in
                        dimension[.bottom] + 16
                    })
            }
        }
        .navigationBarTitle(viewModel.style.navbarTitle)
        .navigationBarBackButtonHidden(viewModel.style.navbarItemsHidden)
        .navigationBarHidden(viewModel.style.navbarItemsHidden)
    }
}

extension DisclaimerView {
    enum Style {
        case sheet
        case navbar

        var navbarTitle: LocalizedStringKey {
            switch self {
            case .sheet: return ""
            case .navbar: return "disclaimer_title"
            }
        }

        var withHeaderStack: Bool {
            switch self {
            case .sheet: return true
            case .navbar: return false
            }
        }

        var disclaimerTextTopPadding: CGFloat {
            switch self {
            case .sheet: return 0
            case .navbar: return 16
            }
        }

        var navbarItemsHidden: Bool {
            switch self {
            case .navbar: return false
            default: return true
            }
        }

    }
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerView(viewModel: .init(style: .sheet, showAccept: true, coordinator: nil))
            .previewGroup(devices: [.iPhoneX, .iPhone8Plus], withZoomed: false)
        NavigationView(content: {
            DisclaimerView(viewModel: .init(style: .navbar, showAccept: true, coordinator: nil))
        })
    }
}

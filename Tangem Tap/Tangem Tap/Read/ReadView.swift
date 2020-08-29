//
//  ReadView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ReadView: View {
    @ObservedObject var viewModel: ReadViewModel
    
    var cardScale: CGFloat {
        switch viewModel.state {
        case .read: return 0.4
        case .ready: return 0.25
        case .welcome: return 1.0
        }
    }
    
    var cardOffsetX: CGFloat {
        switch viewModel.state {
        case .read: return 0
        case .ready: return -UIScreen.main.bounds.width*1.8
        case .welcome: return -UIScreen.main.bounds.width/4.0
        }
    }
    
    var cardOffsetY: CGFloat {
        switch viewModel.state {
        case .read: return -240.0
        case .ready: return -300.0
        case .welcome: return 0.0
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                ZStack {
                    CircleView().offset(x: UIScreen.main.bounds.width/8.0, y: -UIScreen.main.bounds.height/8.0)
                    CardRectView(withShadow: viewModel.state != .read)
                        .animation(.easeInOut)
                        .offset(x: cardOffsetX, y: cardOffsetY)
                        .scaleEffect(cardScale)
                    if viewModel.state != .welcome {
                        Image("iphone")
                            .transition(.offset(x: 400.0, y: 0.0))
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8.0) {
                    if viewModel.state == .welcome {
                        Text("read_welcome_title")
                            .font(Font.system(size: 29.0, weight: .light, design: .default))
                            .foregroundColor(Color.tangemTapGrayDark6)
                    }
                    Text(viewModel.state == .welcome  ? "read_welcome_subtitle" : "read_ready_title" )
                        .font(Font.system(size: 29.0, weight: .light, design: .default))
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8.0) {
                        Button(action: {
                            withAnimation {
                                self.viewModel.nextState()
                            }
                            if self.viewModel.state == .read {
                                self.viewModel.scan()
                            }
                        }) {
                            if viewModel.state == .welcome {
                                Text("read_button_yes")
                            } else {
                                HStack(alignment: .center) {
                                    Text("read_button_tapin")
                                    Spacer()
                                    Image("arrow.right")
                                }
                                .padding(.horizontal)
                            }
                        }
                        .buttonStyle(TangemButtonStyle(size: viewModel.state != ReadViewModel.State.welcome ? .big : .small, colorStyle: .green))
                        if viewModel.state == ReadViewModel.State.welcome {
                            Button(action: {
                                self.viewModel.openShop()
                            }) { HStack(alignment: .center, spacing: 16.0) {
                                Text("read_button_shop")
                                Spacer()
                                Image("shopBag")
                            }
                            .padding(.horizontal)
                            }
                            .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .black))
                            .animation(.easeIn)
                            .transition(.offset(x: 400.0, y: 0.0))
                        }
                        Spacer()
                    }
                    .padding(.top, 16.0)
                }
                if viewModel.openDetails {
                    NavigationLink(destination:
                        DetailsView(viewModel: DetailsViewModel(cid: viewModel.sdkService.cards.first!.key,
                                                                sdkService: viewModel.$sdkService)),
                                   isActive: $viewModel.openDetails) {
                                    EmptyView()
                    }
                }
            }
            .padding([.leading, .bottom, .trailing], 16.0)
            .background(Color.tangemTapBg.edgesIgnoringSafeArea(.all))
            .background(NavigationConfigurator() { nc in
                nc.navigationBar.barTintColor = UIColor.tangemTapBgGray
                nc.navigationBar.shadowImage = UIImage()
            })
            
            
        }
    }
}
struct ReadView_Previews: PreviewProvider {
    @State static var sdkService = TangemSdkService()
    static var previews: some View {
        Group {
            ReadView(viewModel: ReadViewModel(sdkService: $sdkService))
                .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
                .previewDisplayName("iPhone 7")
            ReadView(viewModel: ReadViewModel(sdkService: $sdkService))
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max")
            
            ReadView(viewModel: ReadViewModel(sdkService: $sdkService))
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max Dark")
                .environment(\.colorScheme, .dark)
            
        }
    }
}

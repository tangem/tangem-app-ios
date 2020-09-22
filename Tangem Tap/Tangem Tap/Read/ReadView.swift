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
        case .welcome, .welcomeBack: return 1.0
        }
    }
    
    var cardOffsetX: CGFloat {
        switch viewModel.state {
        case .read: return 0
        case .ready: return -UIScreen.main.bounds.width*1.8
        case .welcome, .welcomeBack: return -UIScreen.main.bounds.width/4.0
        }
    }
    
    var cardOffsetY: CGFloat {
        switch viewModel.state {
        case .read: return -240.0
        case .ready: return -300.0
        case .welcome, .welcomeBack: return 0.0
        }
    }
    
    var greenButtonTitleKey: String {
        switch viewModel.state {
        case .read, .ready:
            return "read_button_tapin"
        case .welcome:
            return "read_button_yes"
        case .welcomeBack:
            return "read_button_scan"
        }
    }
    
    var blackButtonTitleKey: String {
        switch viewModel.state {
        case .welcomeBack:
            return "read_button_shop"
        default:
            return "common_no"
        }
    }
    
    var titleKey: String {
        switch viewModel.state {
        case .welcomeBack:
            return "read_welcome_back_title"
        default:
            return "read_welcome_title"
        }
    }
    
    var subTitleKey: String {
        switch viewModel.state {
        case .welcome:
            return "read_welcome_subtitle"
        case .welcomeBack:
            return "read_welcome_back_subtitle"
        case .read, .ready:
            return "read_ready_title"
            
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
                    if viewModel.state == .read || viewModel.state == .ready  {
                        Image("iphone")
                            .transition(.offset(x: 400.0, y: 0.0))
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8.0) {
                    if viewModel.state == .welcome || viewModel.state == .welcomeBack {
                        Text(titleKey.localized)
                            .font(Font.system(size: 29.0, weight: .light, design: .default))
                            .foregroundColor(Color.tangemTapGrayDark6)
                    }
                    Text(subTitleKey.localized)
                        .font(Font.system(size: 29.0, weight: .light, design: .default))
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8.0) {
                        if viewModel.state == .welcome ||
                            viewModel.state == .welcomeBack {
                            Button(action: {
                                self.viewModel.openShop()
                            }) { HStack(alignment: .center) {
                                Text(blackButtonTitleKey.localized)
                                Spacer()
                                Image("shopBag")
                            }
                            .padding(.horizontal)
                            }
                            .buttonStyle(TangemButtonStyle(size: .small, colorStyle: .black))
                            .transition(.offset(x: -200.0, y: 0.0))
                        }
                        Button(action: {
                            withAnimation {
                                self.viewModel.nextState()
                            }
                            switch self.viewModel.state {
                            case .read, .welcomeBack:
                                self.viewModel.scan()
                            default:
                                break
                            }
                        }) {
                            HStack(alignment: .center) {
                                Text(greenButtonTitleKey.localized)
                                Spacer()
                                Image("arrow.right")
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .green))
                        Spacer()
                    }
                    .padding(.top, 16.0)
                }
                if viewModel.openDetails {
                    NavigationLink(destination:
                        DetailsView(viewModel: DetailsViewModel(cid: viewModel.sdkService.cards.first!.key,
                                                                sdkService: viewModel.sdkService)),
                                   isActive: $viewModel.openDetails) {
                                    EmptyView()
                    }
                }
            }
            .padding([.leading, .bottom, .trailing], 16.0)
            .background(Color.tangemTapBg.edgesIgnoringSafeArea(.all))
            .background(NavigationConfigurator() { nc in
                nc.navigationBar.barTintColor = UIColor.tangemTapBgGray
                nc.navigationBar.tintColor = UIColor.tangemTapGrayDark6
                nc.navigationBar.shadowImage = UIImage()
            })
            
            
        }
    }
}
struct ReadView_Previews: PreviewProvider {
    static var sdkService = TangemSdkService()
    static var previews: some View {
        Group {
            ReadView(viewModel: ReadViewModel(sdkService: sdkService))
                .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
                .previewDisplayName("iPhone 7")
            ReadView(viewModel: ReadViewModel(sdkService: sdkService))
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max")
            
            ReadView(viewModel: ReadViewModel(sdkService: sdkService))
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max Dark")
                .environment(\.colorScheme, .dark)
            
        }
    }
}

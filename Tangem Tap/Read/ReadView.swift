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
        case .read: return 0.25*CircleView.diameter
        case .ready: return -UIScreen.main.bounds.width*1.8
        case .welcome, .welcomeBack: return -UIScreen.main.bounds.width/4.0
        }
    }
    
    var cardOffsetY: CGFloat {
        switch viewModel.state {
        case .read: return -80.0
        case .ready: return -200.0
        case .welcome, .welcomeBack: return 0
        }
    }
    
    var greenButtonTitleKey: LocalizedStringKey {
        switch viewModel.state {
        case .read, .ready:
            return "read_button_tapin"
        case .welcome:
            return "read_button_yes"
        case .welcomeBack:
            return "read_button_scan"
        }
    }
    
    var blackButtonTitleKey: LocalizedStringKey {
        switch viewModel.state {
        case .welcomeBack:
            return "read_button_shop"
        default:
            return "common_no"
        }
    }
    
    var titleKey: LocalizedStringKey {
        switch viewModel.state {
        case .welcomeBack:
            return "read_welcome_back_title"
        default:
            return "read_welcome_title"
        }
    }
    
    var subTitleKey: LocalizedStringKey {
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
            ZStack {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    CircleView().offset(x: 0.1*CircleView.diameter, y: -0.1*CircleView.diameter)
                    CardRectView(withShadow: viewModel.state != .read)
                        .animation(.easeInOut)
                        .offset(x: cardOffsetX, y: cardOffsetY)
                        .scaleEffect(cardScale)
                    if viewModel.state == .read || viewModel.state == .ready  {
                        Image("iphone")
                            .offset(x: 0.1*CircleView.diameter, y: 0.15*CircleView.diameter)
                            .transition(.offset(x: 400.0, y: 0.0))
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: 390)
                Spacer()
                
                if viewModel.state == .welcome || viewModel.state == .welcomeBack {
                    Text(titleKey)
                        .font(Font.system(size: 29.0, weight: .light, design: .default))
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .padding(.leading, 16)
                }
                Text(subTitleKey)
                    .font(Font.system(size: 29.0, weight: .light, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark6)
                    .padding(.leading, 16)
                // .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                HStack(spacing: 8.0) {
                    if viewModel.state == .welcome ||
                        viewModel.state == .welcomeBack {
                        Button(action: {
                            self.viewModel.openShop()
                        }) { HStack(alignment: .center) {
                            Text(blackButtonTitleKey)
                            Spacer()
                            Image("shopBag")
                        }
                        .padding(.horizontal)
                        }
                        .buttonStyle(TangemButtonStyle(size: .small, colorStyle: .black))
                        // .transition(.offset(x: -200.0, y: 0.0))
                    } else {
                        Color.clear.frame(width: 93, height: 56)
                    }
                    TangemButton(isLoading: self.viewModel.isLoading,
                                 title: greenButtonTitleKey,
                                 image: "arrow.right") {
                                    withAnimation {
                                        self.viewModel.nextState()
                                    }
                                    switch self.viewModel.state {
                                    case .read, .welcomeBack:
                                        self.viewModel.scan()
                                    default:
                                        break
                                    }
                    }.buttonStyle(TangemButtonStyle(size: .big, colorStyle: .green))
                    Spacer()
                }
                .padding([.leading, .bottom, .trailing], 16.0)
            }
            .edgesIgnoringSafeArea(.top)
            .background(Color.tangemTapBg.edgesIgnoringSafeArea(.all))
            .alert(item: $viewModel.scanError) { $0.alert }
            
                if viewModel.openDetails {
                    NavigationLink(destination:
                        MainView(viewModel: MainViewModel(cid: viewModel.sdkService.cards.first!.key,
                                                                sdkService: viewModel.sdkService)),
                                   isActive: $viewModel.openDetails) {
                                    EmptyView()
                    }
                }
            }
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

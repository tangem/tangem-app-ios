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
            return "home_button_tapin"
        case .welcome:
            return "home_button_yes"
        case .welcomeBack:
            return "home_button_scan"
        }
    }
    
    var blackButtonTitleKey: LocalizedStringKey {
        switch viewModel.state {
        case .welcomeBack:
            return "home_button_shop"
        default:
            return "common_no"
        }
    }
    
    var titleKey: LocalizedStringKey {
        switch viewModel.state {
        case .welcome:
            return "home_welcome"
        case .welcomeBack:
            return "home_welcome_back"
        case .read, .ready:
            return "home_ready_title"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
            VStack(alignment: .leading, spacing: 0) {
                GeometryReader { geo in
                ZStack {
                    CircleView().offset(x: 0.1*CircleView.diameter, y: -0.1*CircleView.diameter)
                    CardRectView(withShadow: self.viewModel.state != .read)
                        .animation(.easeInOut)
                        .offset(x: self.cardOffsetX, y: self.cardOffsetY)
                        .scaleEffect(self.cardScale)
                    if self.viewModel.state == .read || self.viewModel.state == .ready  {
                        Image("iphone")
                            .offset(x: 0.1*CircleView.diameter, y: 0.15*CircleView.diameter)
                            .transition(.offset(x: 400.0, y: 0.0))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(minHeight: nil,
                       idealHeight: 390,
                       maxHeight: 390)
                Spacer()
                
                    Text(titleKey)
                        .font(Font.system(size: 29.0, weight: .light, design: .default))
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .padding(.leading, 16)
                        .padding(.trailing, 50)
                Spacer()
                
                HStack(spacing: 8.0) {
                    if viewModel.state == .welcome ||
                        viewModel.state == .welcomeBack {
                        TangemButton(isLoading: false,
                                     title: blackButtonTitleKey,
                                     image: "shopBag" ) {
                            self.viewModel.objectWillChange.send()
                            self.viewModel.navigation.openShop = true
                        }.buttonStyle(TangemButtonStyle(color: .black))
                    } else {
                        Color.clear.frame(width: ButtonSize.small.value.width, height: ButtonSize.small.value.height)
                    }
                    TangemLongButton(isLoading: self.viewModel.isLoading,
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
                    }
                    .buttonStyle(TangemButtonStyle(color: .green))
                    Spacer()
                }
                .padding([.leading, .bottom], 16.0)
            }
            .edgesIgnoringSafeArea(.top)
            .background(Color.tangemTapBg.edgesIgnoringSafeArea(.all))
            .alert(item: $viewModel.scanError) { $0.alert }
            
                if viewModel.navigation.openMain {
                    NavigationLink(destination:
                                    MainView(viewModel: viewModel.assembly.makeMainViewModel()),
                                   isActive: $viewModel.navigation.openMain) {
                                    EmptyView()
                    }
                }
                
                if viewModel.navigation.openDisclaimer {
                    NavigationLink(destination: DisclaimerView(viewModel: viewModel.assembly.makeDisclaimerViewModel(with: .accept)),
                                   isActive: $viewModel.navigation.openDisclaimer) {
                                      EmptyView()
                    }
                }
                
                NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                               isActive: $viewModel.navigation.openShop) {
                    EmptyView()
                }
            }
        }
    }
}


struct ReadView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReadView(viewModel: Assembly.previewAssembly.makeReadViewModel())
                .previewLayout(.fixed(width: 320.0, height: 568))
                .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
                .previewDisplayName("iPhone 7")
            ReadView(viewModel: Assembly.previewAssembly.makeReadViewModel())
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max")
            ReadView(viewModel: Assembly.previewAssembly.makeReadViewModel())
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max Dark")
                .environment(\.colorScheme, .dark)
            
        }
    }
}

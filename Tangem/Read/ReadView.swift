////
////  ReadView.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2020 Tangem AG. All rights reserved.
////
//
//import Foundation
//import SwiftUI
//
//struct ReadView: View {
//    [REDACTED_USERNAME] var viewModel: ReadViewModel
//    [REDACTED_USERNAME] var navigation: NavigationCoordinator
//    
//    var cardScale: CGFloat {
//        switch viewModel.state {
//        case .read: return 0.4
//        case .ready: return 0.25
//        case .welcome, .welcomeBack: return 1.0
//        }
//    }
//    
//    var cardOffsetX: CGFloat {
//        switch viewModel.state {
//        case .read: return 0.25 * CircleView.diameter
//        case .ready: return -UIScreen.main.bounds.width*1.8
//        case .welcome, .welcomeBack: return -UIScreen.main.bounds.width/4.0
//        }
//    }
//    
//    var cardOffsetY: CGFloat {
//        switch viewModel.state {
//        case .read: return -80.0
//        case .ready: return -200.0
//        case .welcome, .welcomeBack: return 0
//        }
//    }
//    
//    var greenButtonTitleKey: LocalizedStringKey {
//        switch viewModel.state {
//        case .read, .ready:
//            return "home_button_tapin"
//        case .welcome:
//            return "home_button_yes"
//        case .welcomeBack:
//            return "home_button_scan"
//        }
//    }
//    
//    var blackButtonTitleKey: LocalizedStringKey {
//        switch viewModel.state {
//        case .welcomeBack:
//            return "home_button_shop"
//        default:
//            return "common_no"
//        }
//    }
//    
//    var titleKey: LocalizedStringKey {
//        switch viewModel.state {
//        case .welcome:
//            return "home_welcome"
//        case .welcomeBack:
//            return "home_welcome_back"
//        case .read, .ready:
//            return "home_ready_title"
//        }
//    }
//    
//    var navigationLinks: some View {
//        Group {
//            // MARK: - Navigation links
//            NavigationLink(destination:
//                            MainView(viewModel: viewModel.assembly.makeMainViewModel()),
//                           isActive: $navigation.readToMain)
//            
//            NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
//                           isActive: $navigation.readToShop)
//        }
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            navigationLinks
//            
//            GeometryReader { geo in
//                ZStack {
//                    CircleView().offset(x: 0.1 * CircleView.diameter, y: -0.1 * CircleView.diameter)
//                    CardRectView(withShadow: self.viewModel.state != .read)
//                        .animation(.easeInOut)
//                        .offset(x: self.cardOffsetX, y: self.cardOffsetY)
//                        .scaleEffect(self.cardScale)
//                    if self.viewModel.state == .read || self.viewModel.state == .ready  {
//                        Image("iphone")
//                            .offset(x: 0.1 * CircleView.diameter, y: 0.15 * CircleView.diameter)
//                            .transition(.offset(x: 400.0, y: 0.0))
//                    }
//                }
//                .frame(width: geo.size.width, height: geo.size.height)
//            }
//            .frame(minHeight: nil,
//                   idealHeight: 390,
//                   maxHeight: 390)
//            Spacer()
//            
//            Text(titleKey)
//                .font(Font.system(size: 29.0, weight: .light, design: .default))
//                .foregroundColor(Color.tangemGrayDark6)
//                .padding(.leading, 16)
//                .padding(.trailing, 50)
//            Spacer()
//            
//            HStack(spacing: 8.0) {
//                if viewModel.state == .welcome ||
//                    viewModel.state == .welcomeBack {
//                    TangemButton(title: blackButtonTitleKey,
//                                 image: "shopBag" ) {
//                        navigation.readToShop = true
//                    }.buttonStyle(TangemButtonStyle(colorStyle: .black))
//                } else {
//                    //todo: remove it
//                    Color.clear.frame(width: ButtonLayout.small.size!.width, height: ButtonLayout.small.size!.height)
//                }
//                TangemButton(title: greenButtonTitleKey,
//                             systemImage: "arrow.right") {
//                    withAnimation {
//                        self.viewModel.nextState()
//                    }
//                    switch self.viewModel.state {
//                    case .read, .welcomeBack:
//                        self.viewModel.scan()
//                    default:
//                        break
//                    }
//                }
//                .buttonStyle(TangemButtonStyle(layout: .big,
//                                               isLoading: self.viewModel.isLoading))
//                .sheet(isPresented: $navigation.readToSendEmail, content: {
//                    MailView(dataCollector: viewModel.failedCardScanTracker, support: .tangem, emailType: .failedToScanCard)
//                })
//                ScanTroubleshootingView(isPresented: $navigation.readToTroubleshootingScan) {
//                    self.viewModel.scan()
//                } requestSupportAction: {
//                    self.viewModel.failedCardScanTracker.resetCounter()
//                    self.navigation.readToSendEmail = true
//                }
//                Spacer()
//            }
//            .padding([.leading, .bottom], 16.0)
//        }
//        .edgesIgnoringSafeArea(.top)
//        .background(Color.tangemBg.edgesIgnoringSafeArea(.all))
//        .alert(item: $viewModel.scanError) { $0.alert }
//    }
//}
//
//
//struct ReadView_Previews: PreviewProvider {
//    static let assembly = Assembly.previewAssembly
//    
//    static var previews: some View {
//        Group {
//            ReadView(viewModel: assembly.makeReadViewModel())
//                .environmentObject(assembly.services.navigationCoordinator)
//            
//        }
//        .previewGroup(devices: [.iPhone7, .iPhone12ProMax])
//    }
//}

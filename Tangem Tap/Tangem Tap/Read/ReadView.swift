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
    @EnvironmentObject var tangemSdkModel: TangemSdkModel
    
    @ObservedObject var model = ReadViewModel()
    
    var cardScale: CGFloat {
        switch model.state {
        case .read: return 0.4
        case .ready: return 0.25
        case .welcome: return 1.0
        }
    }
    
    var cardOffsetX: CGFloat {
        switch model.state {
        case .read: return 0
        case .ready: return -UIScreen.main.bounds.width*1.8
        case .welcome: return -UIScreen.main.bounds.width/4.0
        }
    }
    
    var cardOffsetY: CGFloat {
        switch model.state {
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
                    CardRectView(withShadow: model.state != .read)
                        .animation(.easeInOut)
                        .offset(x: cardOffsetX, y: cardOffsetY)
                        .scaleEffect(cardScale)
                    if model.state != .welcome {
                        Image("iphone")
                            .transition(.offset(x: 400.0, y: 0.0))
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8.0) {
                    if model.state == .welcome {
                        Text("read_welcome_title")
                            .font(Font.custom("SairaSemiCondensed-Medium", size: 29.0))
                    }
                    Text(model.state == .welcome  ? "read_welcome_subtitle" : "read_ready_title" )
                        .font(Font.custom("SairaSemiCondensed-Light", size: 29.0))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8.0) {
                        Button(action: {
                            withAnimation {
                                self.model.nextState()
                            }
                            if self.model.state == .read {
                                self.tangemSdkModel.scan()
                            }
                        }) {
                            if model.state == .welcome {
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
                        .buttonStyle(TangemButtonStyle(size: model.state != ReadViewModel.State.welcome ? .big : .small, colorStyle: .green))
                        if model.state == ReadViewModel.State.welcome {
                            Button(action: {
                                self.model.openShop()
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
                
                NavigationLink(destination: DetailsView()
                    .environmentObject(tangemSdkModel),
                               isActive: $tangemSdkModel.openDetails) {
                                EmptyView()
                }
                
            }
            .padding([.leading, .bottom, .trailing], 16.0)
            .background(Color.tangemBg.edgesIgnoringSafeArea(.all))
            .background(NavigationConfigurator() { nc in
                nc.navigationBar.barTintColor = UIColor.tangemTapBgGray
                nc.navigationBar.shadowImage = UIImage()
            })
        }
        
    }
}

struct ReadView_Previews: PreviewProvider {
    static var model = TangemSdkModel()
    static var previews: some View {
        Group {
            ReadView()
                .environmentObject(model)
                .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
                .previewDisplayName("iPhone 7")
            ReadView()
                .environmentObject(model)
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max")
            
            ReadView()
                .environmentObject(model)
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max Dark")
                .environment(\.colorScheme, .dark)
            
        }
    }
}

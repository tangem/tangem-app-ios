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
    
    let model = ReadViewModel()
    
    var body: some View {
        ZStack {
            Color.tangemBg
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center) {
                ZStack {
                    CircleView()
                    VStack {
                        CardRectView().offset(x: 0.0, y: 10.0)
                        Spacer()
                    }
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("read_welcome_title")
                        .font(Font.custom("SairaSemiCondensed-Medium", size: 29.0))
                    Text("read_welcome_subtitle")
                        .font(Font.custom("SairaSemiCondensed-Light", size: 29.0))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8.0) {
                        Button(action: {
                            
                        }) { Text("read_button_yes")
                        }
                        .buttonStyle(TangemButtonStyle(size: .small, colorStyle: .green))
                        
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
                    }
                }
            }
            .padding(.bottom, 16.0)
        }
    }
}

struct ReadView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReadView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
                .previewDisplayName("iPhone 7")
            
            ReadView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max")
            
            ReadView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}

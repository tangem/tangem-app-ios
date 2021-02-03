//
//  TangemButton.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TangemButton: View {
    let isLoading: Bool    
    let title: LocalizedStringKey
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !self.isLoading {
                self.action()
            }
        }, label:  {
            HStack(alignment: .center, spacing: 8) {
                if isLoading {
                    ActivityIndicatorView()
                } else {
                    Text(title)
                        .fontWeight(.bold)
                        .font(.system(size: 15))
					if !image.isEmpty {
						Image(image)
					}
                }
            }
            .padding(.horizontal, 16)
            .frame(minWidth: ButtonSize.small.value.width,
                   maxWidth: .infinity,
                   minHeight: ButtonSize.small.value.height,
                   maxHeight: ButtonSize.small.value.height,
                   alignment: .center)
            .fixedSize()
        })
    }
}

struct TangemVerticalButton: View {
    let isLoading: Bool
    let title: LocalizedStringKey
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !self.isLoading {
                self.action()
            }
        }, label:  {
            
            VStack(alignment: .center, spacing:0) {
                if isLoading {
                    ActivityIndicatorView()
                } else {
                    Image(image)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    Text(title)
                        .fontWeight(.bold)
                        .font(.system(size: 15))
                }
            }
            .padding(.all, 8)
            .frame(minWidth: ButtonSize.smallVertical.value.width,
                   maxWidth: ButtonSize.smallVertical.value.width,
                   minHeight: ButtonSize.smallVertical.value.height,
                   idealHeight: ButtonSize.smallVertical.value.height,
                   maxHeight: ButtonSize.smallVertical.value.height,
                   alignment: .center)
            .fixedSize()
        })
    }
}

struct TangemLongButton: View {
    let isLoading: Bool
    let title: LocalizedStringKey
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !self.isLoading {
                self.action()
            }
        }, label: {
            HStack(alignment: .center, spacing: 8) {
                if isLoading {
                    ActivityIndicatorView()
                } else {
                    Text(title)
                        .fontWeight(.bold)
                        .font(.system(size: 15))
                    Spacer()
                    Image(image)
                }
            }
            .padding(.horizontal, 16)
            .frame(minWidth: ButtonSize.big.value.width,
                   maxWidth: ButtonSize.big.value.width,
                   minHeight: ButtonSize.big.value.height,
                   maxHeight: ButtonSize.big.value.height,
                   alignment: .center)
            .fixedSize()
        })
    }
}

struct TangemButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TangemButton(isLoading: false,
                         title: "Recharge de portefeuille",
                         image: "scan") {}
                .buttonStyle(TangemButtonStyle(color: .black))
            
            TangemLongButton(isLoading: false,
                             title: "wallet_button_scan",
                             image: "scan") {}
                .buttonStyle(TangemButtonStyle(color: .black))
            
                HStack {
                    TangemVerticalButton(isLoading: true,
                                         title: "wallet_button_send",
                                         image: "scan") {}
                        .buttonStyle(TangemButtonStyle(color: .green))
                        .layoutPriority(0)
                    
                    TangemVerticalButton(isLoading: false,
                                         title: "wallet_button_topup",
                                         image: "arrow.up") {}
                        .buttonStyle(TangemButtonStyle(color: .green))
                        .layoutPriority(1)
                    TangemVerticalButton(isLoading: false,
                                         title: "wallet_button_scan",
                                         image: "arrow.right") {}
                        .buttonStyle(TangemButtonStyle(color: .green))
                        .layoutPriority(0)
                }
                .padding(.horizontal, 8)
            
            
            
        }
        .environment(\.locale, .init(identifier: "fr"))
        .previewGroup()
    }
}

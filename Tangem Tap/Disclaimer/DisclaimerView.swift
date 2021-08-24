//
//  DisclaimerView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct DisclaimerView: View {
    
    enum Style {
        case sheet, navbar
        
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
        
        var isWithCloseButton: Bool {
            switch self {
            case .sheet: return true
            case .navbar: return false
            }
        }
    }
    
    var style: Style
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            if style.withHeaderStack {
                HStack {
                    Text("disclaimer_title")
                        .font(.system(size: 30, weight: .bold, design: .default))
                        .foregroundColor(.tangemTapGrayDark6)
                    Spacer()
                    if style.isWithCloseButton {
                        Button(action: { presentationMode.wrappedValue.dismiss() }, label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .foregroundColor(.tangemTapGrayDark4.opacity(0.6))
                                .frame(width: 11, height: 11)
                        })
                        .frame(width: 30, height: 30)
                        .background(Color.tangemTapBgGray)
                        .cornerRadius(15)
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16))
            }
            ScrollView {
                Text("disclaimer_text")
                    .font(Font.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.tangemTapGrayDark5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                    .padding(.top, style.disclaimerTextTopPadding)
            }
        }
        .navigationBarTitle(style.navbarTitle)
        .navigationBarBackButtonHidden(style.navbarItemsHidden)
        .navigationBarHidden(style.navbarItemsHidden)
    }
    
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerView(style: .sheet)
        NavigationView(content: {
            DisclaimerView(style: .navbar)
        })
    }
}

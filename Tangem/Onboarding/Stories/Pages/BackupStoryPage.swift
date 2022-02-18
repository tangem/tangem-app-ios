//
//  BackupStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BackupStoryPage: View {
    var scanCard: (() -> Void)
    var orderCard: (() -> Void)
    
    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            Text("story_backup_title")
                .font(.system(size: 36, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding()
                .padding(.top, StoriesConstants.titleExtraTopPadding)
            
            Text("story_backup_description")
                .font(.system(size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            Spacer()
            

            Image("cards_flying")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Spacer()
            
            HStack {
                Button {
                    scanCard()
                } label: {
                    Text("home_button_scan")
                }
                .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt, layout: .flexibleWidth))
                
                Button {
                    orderCard()
                } label: {
                    Text("home_button_order")
                }
                .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BackupStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        BackupStoryPage { } orderCard: { }
    }
}

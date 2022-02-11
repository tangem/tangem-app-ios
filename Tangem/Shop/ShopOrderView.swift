//
//  ShopOrderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ShopOrderView: View {
    let order: Order
    
    var body: some View {
        VStack {
            SheetDragHandler()
            WebViewContainer(url: order.statusUrl, title: "")
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
    }
}

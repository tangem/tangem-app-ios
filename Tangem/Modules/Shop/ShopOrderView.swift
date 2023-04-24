//
//  ShopOrderView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 10.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ShopOrderView: View {
    let order: Order

    var body: some View {
        VStack {
            SheetDragHandler()
            WebViewContainer(viewModel: .init(url: order.statusUrl, title: "", addLoadingIndicator: true))
        }
        // .navigationBarTitle("", displayMode: .inline) // Don't remove it, otherwise navigation title will NOT hide on iOS 13
        .edgesIgnoringSafeArea(.all)
    }
}

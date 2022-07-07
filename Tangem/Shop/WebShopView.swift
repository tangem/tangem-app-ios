//
//  WebShopView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct WebShopView: View {
    let url = URL(string: "https://tangem.com/ru/resellers/")!
    
    var body: some View {
        SafariView(url: url)
    }
}

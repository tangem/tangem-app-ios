//
//  ExtractView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ExtractView: View {
    @EnvironmentObject var tangemSdkModel: TangemSdkService
    
    let model = ExtractViewModel()
    
    var body: some View {
        Text("Extract")
    }
}

struct ExtractView_Previews: PreviewProvider {
    static var previews: some View {
        ExtractView()
    }
}

//
//  DetailsView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct DetailsView: View {
    @EnvironmentObject var tangemSdkModel: TangemSdkModel
    
    let model = DetailsViewModel()
    
    var body: some View {
            Text("Details")
    }
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsView()
    }
}

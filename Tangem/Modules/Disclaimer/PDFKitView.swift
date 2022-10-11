//
//  PDFKitView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import PDFKit

struct PDFKitView: View {
    var url: URL

    var body: some View {
        PDFRepresentedView(url)
    }
}

fileprivate struct PDFRepresentedView: UIViewRepresentable {
    let url: URL

    init(_ url: URL) {
        self.url = url
    }

    func makeUIView(context: UIViewRepresentableContext<PDFRepresentedView>) -> PDFRepresentedView.UIViewType {
        let pdfView = PDFView()
        
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: self.url)
        pdfView.minScaleFactor = UIScreen.main.bounds.height * 0.00074
        pdfView.maxScaleFactor = 5.0

        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PDFRepresentedView>) {
    }
}

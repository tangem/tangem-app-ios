//
//  SafariView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import SafariServices
import WebKit


struct WebViewContainer: View {
    var url: URL?
    //    var closeUrl: String? = nil
    var title: LocalizedStringKey
    var addLoadingIndicator = false
    var withCloseButton = false
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading: Bool = true
    
    var urlActions: [String : ((String) -> Void)] = [:]
    //    {
    //        if let closeUrl = closeUrl {
    //            return [closeUrl: {
    //                self.presentationMode.wrappedValue.dismiss()
    //            }]
    //        } else {
    //            return [:]
    //        }
    //    }
    
    private var content: some View {
        ZStack {
            WebView(url: url, urlActions: urlActions, isLoading: $isLoading)
                .navigationBarTitle(title, displayMode: .inline)
                .background(Color.tangemBg.edgesIgnoringSafeArea(.all))
            if isLoading && addLoadingIndicator {
                ActivityIndicatorView(color: .tangemGrayDark)
            }
        }
    }
    
    var body: some View {
        VStack {
            if withCloseButton {
                NavigationView {
                    content
                        .navigationBarItems(leading:
                            Button("common_close") {
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                }
            } else {
                content
            }
            
        }
    }
}


struct WebView: UIViewRepresentable {
    var url: URL?
    var urlActions: [String : ((String) -> Void)] = [:]
    var isLoading:  Binding<Bool>
    
    func makeUIView(context: Context) -> WKWebView {
        let view =  WKWebView()
        if let url = url {
            print("Loading request with url: \(url)")
            view.load(URLRequest(url: url))
        }
        view.navigationDelegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let urlActions: [String: ((String) -> Void)]
        var isLoading:  Binding<Bool>
        
        init(urlActions: [String : ((String) -> Void)] = [:], isLoading: Binding<Bool>) {
            self.urlActions = urlActions
            self.isLoading = isLoading
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url?.absoluteString.split(separator: "?").first,
               let actionForURL = urlActions[String(url).removeLatestSlash()] {
                decisionHandler(.cancel)
                actionForURL(navigationAction.request.url!.absoluteString)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading.wrappedValue = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading.wrappedValue = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(urlActions: urlActions, isLoading: self.isLoading)
    }
}

//class CustomSafariViewController: UIViewController {
//    var url: URL!
//    //{
//      //  didSet {
//            // when url changes, reset the safari child view controller
//           // configureChildViewController()
//   //     }
//   // }
//
//    private var webView = WKWebView()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.addSubview(webView)
//       // configureChildViewController()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        webView.load(URLRequest(url: url))
//    }
//
////    private func configureChildViewController() {
////        // Remove the previous safari child view controller if not nil
////        if let safariViewController = safariViewController {
////            safariViewController.willMove(toParent: self)
////            safariViewController.view.removeFromSuperview()
////            safariViewController.removeFromParent()
////            self.safariViewController = nil
////        }
////
////        // Create a new safari child view controller with the url
////        let newSafariViewController = SFSafariViewController(url: url)
////        addChild(newSafariViewController)
////        newSafariViewController.view.frame = view.frame
////        view.addSubview(newSafariViewController.view)
////        newSafariViewController.didMove(toParent: self)
////        self.safariViewController = newSafariViewController
////    }
//}

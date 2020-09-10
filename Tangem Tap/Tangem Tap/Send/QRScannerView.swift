//
//  QRScanner.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SwiftUI

struct QRScannerView: UIViewRepresentable {
    @Binding var code: String
    var codeMapper: ((String) -> String)? = nil
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIView(context: Context) -> UIQRScannerView {
        let view = UIQRScannerView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: UIQRScannerView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(code: $code, codeMapper: codeMapper, presentationMode: presentationMode)
    }
    
    class Coordinator: NSObject, QRScannerViewDelegate {
        @Binding var code: String
        var codeMapper: ((String) -> String)? = nil
        @Binding var presentationMode: PresentationMode
        
        init(code: Binding<String>, codeMapper:((String) -> String)?, presentationMode: Binding<PresentationMode>){
            self._code = code
            self.codeMapper = codeMapper
            self._presentationMode = presentationMode
        }
        
        func qrScanningDidFail() {
            presentationMode.dismiss()
        }
        
        func qrScanningSucceededWithCode(_ str: String?) {
            if let str = str {
                if let codeMapper = codeMapper {
                    self.code = codeMapper(str)
                } else {
                    self.code = str
                }
            }
            presentationMode.dismiss()
        }
        
        func qrScanningDidStop() {
            
        }
    }
}


/// Delegate callback for the QRScannerView.
protocol QRScannerViewDelegate: class {
    func qrScanningDidFail()
    func qrScanningSucceededWithCode(_ str: String?)
    func qrScanningDidStop()
}

class UIQRScannerView: UIView {
    
    weak var delegate: QRScannerViewDelegate?
    
    /// capture settion which allows us to start and stop scanning.
    var captureSession: AVCaptureSession?
    private var feedbackGenerator: UINotificationFeedbackGenerator? = nil
    // Init methods..
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        doInitialSetup()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        doInitialSetup()
    }
    
    //MARK: overriding the layerClass to return `AVCaptureVideoPreviewLayer`.
    override class var layerClass: AnyClass  {
        return AVCaptureVideoPreviewLayer.self
    }
    override var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }
}

extension UIQRScannerView {
    var isRunning: Bool {
        return captureSession?.isRunning ?? false
    }
    
    func startScanning() {
        feedbackGenerator?.prepare()
        captureSession?.startRunning()
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
        delegate?.qrScanningDidStop()
    }
    
    /// Does the initial setup for captureSession
    private func doInitialSetup() {
        clipsToBounds = true
        captureSession = AVCaptureSession()
        feedbackGenerator = UINotificationFeedbackGenerator()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch let error {
            print(error)
            return
        }
        
        if (captureSession?.canAddInput(videoInput) ?? false) {
            captureSession?.addInput(videoInput)
        } else {
            scanningDidFail()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession?.canAddOutput(metadataOutput) ?? false) {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            scanningDidFail()
            return
        }
        
        self.layer.session = captureSession
        self.layer.videoGravity = .resizeAspectFill
        
        captureSession?.startRunning()
    }
    func scanningDidFail() {
        feedbackGenerator?.notificationOccurred(.error)
        delegate?.qrScanningDidFail()
        captureSession = nil
        feedbackGenerator = nil
    }
    
    func found(code: String) {
        feedbackGenerator?.notificationOccurred(.success)
        delegate?.qrScanningSucceededWithCode(code)
        feedbackGenerator = nil
    }
    
}

extension UIQRScannerView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        stopScanning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
           // AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
    
}

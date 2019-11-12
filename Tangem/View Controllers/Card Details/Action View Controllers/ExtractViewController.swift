//
//  ExtractViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif
import TangemKit



@available(iOS 13.0, *)
class ExtractViewController: ModalActionViewController {
    var card: Card!
    var onDone: (()-> Void)?
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = Localizations.sendPayment.uppercased()
        }
    }
    @IBOutlet weak var amountText: UITextField! {
        didSet {
            amountText.delegate = self
            amountText.placeholder = Localizations.generalAmount.lowercased()
            
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 34))
            toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                             UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))]
            
            amountText.inputAccessoryView = toolbar
        }
    }
    
    @IBOutlet weak var feeTitleLabel: UILabel! {
        didSet {
            feeTitleLabel.text = Localizations.confirmTransactionFee
        }
    }
    @IBOutlet weak var includeFeeLabel: UILabel! {
        didSet {
            includeFeeLabel.text = Localizations.confirmTransactionBtnIncludingFee
        }
    }
    @IBOutlet weak var amountTitleLabel: UILabel! {
        didSet {
            amountTitleLabel.text = Localizations.generalAmount.uppercased()
        }
    }
    @IBOutlet weak var toWalletLabel: UILabel! {
        didSet {
            toWalletLabel.text = Localizations.toWallet.uppercased()
        }
    }
    @IBOutlet weak var addressTitleLabel: UILabel! {
        didSet {
            addressTitleLabel.text = "\(Localizations.address):"
        }
    }
    @IBOutlet weak var cardTitleLabel: UILabel! {
        didSet {
            cardTitleLabel.text = Localizations.detailsTitleCardId
        }
    }
    @IBOutlet weak var amountStackView: UIStackView!
    @IBOutlet weak var addressSeparator: UIView!
    @IBOutlet weak var amountSeparator: UIView!
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var targetStackView: UIStackView!
    @IBOutlet weak var feeControl: UISegmentedControl!  {
        didSet {
            feeControl.setTitle(Localizations.confirmTransactionBtnFeeMinimal, forSegmentAt: 0)
            
            feeControl.setTitle(Localizations.confirmTransactionBtnFeeNormal, forSegmentAt: 1)
            
            feeControl.setTitle(Localizations.confirmTransactionBtnFeePriority, forSegmentAt: 2)
        }
    }
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var amountUnitsLabel: UILabel!
    @IBOutlet weak var blockchainNameLabel: UILabel!
    @IBOutlet weak var targetAddressText: UITextField! {
        didSet {
            targetAddressText.delegate = self
            targetAddressText.placeholder = Localizations.address.lowercased()
        }
    }
    @IBOutlet weak var includeFeeSwitch: UISwitch!
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var pasteTargetAdressButton: UIButton!
    @IBOutlet weak var btnSend: UIButton! {
        didSet {
            btnSend.setTitle(Localizations.confirmTransactionBtnSend, for: .normal)
        }
    }
    @IBOutlet weak var cardInfoContainer: UIStackView!
    
    private var readerSession: NFCTagReaderSession?
    private var validatedAmount: String?
    private var validatedTarget: String?
    private var validatedFee: String?
    private var bgLayer = CALayer()
    private var pasteLayer = CALayer()
    private var triangleLayer = CAShapeLayer()
    private var feeTimer: Timer?
    private var feeTime = Date(timeIntervalSince1970: TimeInterval(1.0))
    
    private lazy var recognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.numberOfTouchesRequired = 1
        recognizer.addTarget(self, action: #selector(viewDidTap))
        return recognizer
    }()
    
    private lazy var signSession: CardSignSession = {
        let session = CardSignSession(cardId: card.cardID,
                                      supportedSignMethods: card.supportedSignMethods) {[weak self] result in
                                        switch result {
                                        case .cancelled:
                                            self?.btnSend.hideActivityIndicator()
                                            self?.updateSendButtonSubtitle()
                                            self?.removeLoadingView()
                                        case.success(let signature):
                                            self?.handleSuccessSign(with: signature)
                                        case .failure(let signError):
                                            self?.btnSend.hideActivityIndicator()
                                            self?.updateSendButtonSubtitle()
                                            self?.removeLoadingView()
                                            
                                            switch signError {
                                            case .missingIssuerSignature:
                                                self?.handleTXNotSignedByIssuer()
                                            case .nfcError(let nfcError):
                                                self?.handleGenericError(nfcError)
                                            default:
                                                self?.handleGenericError(signError)
                                            }
                                        }
        }
        
        return session
    }()
    
    private var coinProvider: CoinProvider {
        return card.cardEngine as! CoinProvider
    }
    
    @objc func viewDidTap() {
        targetAddressText.resignFirstResponder()
        amountText.resignFirstResponder()
    }
    
    private var fee: (min: String, normal: String, max: String)? {
        didSet {
            feeTime = Date()
        }
    }
    @IBAction func feeIncludeChanged(_ sender: UISwitch, forEvent event: UIEvent) {
        validateInput()
    }
    
    @IBAction func feePresetChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        if fee == nil {
            tryUpdateFeePreset()
            return
        }
        updateFee()
        validateInput()
    }
    @IBAction func pasteTapped(_ sender: Any, forEvent event: UIEvent) {
        if let pasteAddress = getPasteAddress() {
            targetAddressText.text = pasteAddress
            tryUpdateFeePreset()
        } else {
            pasteTargetAdressButton.isEnabled = false
        }
    }
    
    @IBAction func targetChanged(_ sender: UITextField, forEvent event: UIEvent) {
        setError(false, for: sender)
        tryUpdateFeePreset()
    }
    
    @IBAction func amountChanged(_ sender: UITextField, forEvent event: UIEvent) {
        setError(false, for: sender)
        tryUpdateFeePreset()
    }
    
    @IBAction func scanTapped() {
        guard !signSession.isBusy, validateInput() else {
            return
        }
        
        guard feeTime.distance(to: Date()) < TimeInterval(60.0) else {
            tryUpdateFeePreset()
            return
        }
        
        btnSend.setAttributedTitle(NSAttributedString(string: ""), for: .normal)
        btnSend.showActivityIndicator()
        addLoadingView()
        
        if let asyncCoinProvider = coinProvider as? CoinProviderAsync {
            asyncCoinProvider.getHashForSignature(amount: self.validatedAmount!, fee: self.validatedFee!, includeFee: self.includeFeeSwitch.isOn, targetAddress: self.validatedTarget!) { [weak self] hash in
                
                guard let hash = hash else {
                    self?.handleTXBuildError()
                    return
                }
                
                DispatchQueue.main.async {
                    self?.signSession.start(dataToSign: hash)
                }
            }
        }
        else {
            guard let dataToSign = coinProvider.getHashForSignature(amount: self.validatedAmount!, fee: self.validatedFee!, includeFee: self.includeFeeSwitch.isOn, targetAddress: self.validatedTarget!) else {
                self.handleTXBuildError()
                return
            }
            
            signSession.start(dataToSign: dataToSign)
        }
    }
    
    func addLoadingView() {
        if let window = self.view.window {
            let view = UIView(frame: window.bounds)
            view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            view.addSubview(indicator)
            view.tag = 0781
            indicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            indicator.startAnimating()
            window.addSubview(view)
            window.bringSubview(toFront: view)
        }
    }
    
    func removeLoadingView() {
        if let window = self.view.window,
            let view = window.viewWithTag(0781) {
            view.removeFromSuperview()
        }
    }
    
    func updateFee() {
        switch feeControl.selectedSegmentIndex {
        case 0:
            feeLabel.text = fee?.min ?? ""
        case 1:
            feeLabel.text = fee?.normal ?? ""
        case 2:
            feeLabel.text = fee?.max ?? ""
        default:
            feeLabel.text = ""
        }
        
        
        if !feeLabel.text!.isEmpty {
            feeLabel.text! += " \(card.walletUnits)"
        } else {
            feeLabel.text = Localizations.commonFeeStub
        }
        
        
        validatedFee = feeLabel.text
        feeLabel.hideActivityIndicator()
        //  print("min fee: \(fee?.min) normal fee: \(fee?.normal) max fee \(fee?.max)")
    }
    
    @discardableResult
    func validateInput(skipFee: Bool = false) -> Bool {
        validatedAmount = ""
        validatedFee = ""
        validatedTarget = ""
        
        guard let target = targetAddressText.text,
            validate(address: target) else {
                setError(true, for: targetAddressText )
                btnSendSetEnabled(false)
                return false
        }
        
        guard let amount = amountText.text?.replacingOccurrences(of: ",", with: "."),
            !amount.isEmpty,
            let amountValue = Decimal(string: amount),
            amountValue > 0,
            let total = Decimal(string: card.balance),
            amountValue <= total else {
                setError(true, for: amountText )
                btnSendSetEnabled(false)
                return false
        }
        
        if !skipFee {
            guard let fee = feeLabel.text?.remove(" \(card.walletUnits)"),
                let feeValue = Decimal(string: fee),
                !fee.isEmpty else {
                    btnSendSetEnabled(false)
                    return false
            }
            
            let valueToSend = includeFeeSwitch.isOn ? amountValue : amountValue + feeValue
            guard total >= valueToSend else {
                setError(true, for: amountText )
                btnSendSetEnabled(false)
                return false
            }
            
            let valueToReceive = includeFeeSwitch.isOn ? amountValue - feeValue : amountValue + feeValue
            guard valueToReceive > 0 else {
                setError(true, for: amountText )
                btnSendSetEnabled(false)
                return false
            }
            
            
            validatedFee = fee
        }
        
        setError(false, for: targetAddressText )
        setError(false, for: amountText )
        validatedAmount = amount
        validatedTarget = target
        btnSendSetEnabled(true)
        updateSendButtonSubtitle()
        return true
    }
    
    func getPasteAddress() -> String? {
        if let pasteString = UIPasteboard.general.string,
            validate(address: pasteString) {
            return pasteString
        }
        return  nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = getPasteAddress() {
            pasteTargetAdressButton.isEnabled = true
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnSend.layer.cornerRadius = 8.0
        btnSendSetEnabled(false)
        cardLabel.text = card.cardID
        amountLabel.text = "\(card.balance) \(card.units)"
        
        
        includeFeeSwitch.transform = CGAffineTransform.identity.translatedBy(x: -0.1*includeFeeSwitch.frame.width, y: 0).scaledBy(x: 0.8, y: 0.8)
        
        //        let addressText = NSMutableAttributedString(string: "Address: \(card.address)")
        //        addressText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: 8))
        
        addressLabel.text = card.address
        feeLabel.text = Localizations.commonFeeStub
        amountText.text = card.balance
        
        let traits = (self.card.cardEngine as! CoinProvider).coinTraitCollection
        includeFeeSwitch.isHidden = !traits.contains(CoinTrait.allowsFeeInclude)
        feeControl.isHidden = !traits.contains(CoinTrait.allowsFeeSelector)
        
        blockchainNameLabel.text = card.blockchain.rawValue.uppercased()
        amountUnitsLabel.text = card.units.uppercased()
        view.addGestureRecognizer(recognizer)
        
        topStackView.setCustomSpacing(20.0, after: amountStackView)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func validate(address: String) -> Bool {
        guard !address.isEmpty,
            address != card.cardEngine.walletAddress,
            (card.cardEngine as! CoinProvider).validate(address: address)
            else {
                return false
        }
        
        return true
    }
    
    
    func updateSendButtonSubtitle() {
        guard btnSend.isEnabled else {
            return
        }
        
        guard let amount = Decimal(string: validatedAmount ?? ""),
            let fee = Decimal(string: validatedFee ?? "") else {
                if btnSend.titleLabel?.text != Localizations.confirmTransactionBtnSend {
                    UIView.performWithoutAnimation {
                        btnSend.setTitle(Localizations.confirmTransactionBtnSend, for: .normal)
                        btnSend.layoutIfNeeded()
                    }
                }
                return
        }
        
        let valueToSend = (includeFeeSwitch.isOn ? amount : amount + fee).rounded(blockchain: card.blockchain)
        guard valueToSend > 0 else {
            if btnSend.titleLabel?.text != Localizations.confirmTransactionBtnSend {
                btnSend.setTitle(Localizations.confirmTransactionBtnSend, for: .normal)
            }
            return
        }
        
        let titleFont = UIFont(name: "SairaCondensed-ExtraBold", size: 20)!
        let subtitleFont = UIFont(name: "SairaCondensed-Regular", size: 12)!
        
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.alignment = .center
        titleParagraph.maximumLineHeight = 24
        
        
        let subtitleParagraph = NSMutableParagraphStyle()
        subtitleParagraph.alignment = .center
        subtitleParagraph.maximumLineHeight = 12
        
        let titleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.paragraphStyle: titleParagraph,
                                                               NSAttributedString.Key.foregroundColor: UIColor.white,
                                                               NSAttributedString.Key.font: titleFont]
        
        let subtitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.paragraphStyle: subtitleParagraph,
                                                                  NSAttributedString.Key.foregroundColor: UIColor.white,
                                                                  NSAttributedString.Key.font: subtitleFont]
        
        let titleText = NSMutableAttributedString(string: "\(Localizations.confirmTransactionBtnSend)", attributes: titleAttributes)
        let subtitleText = NSMutableAttributedString(string: "\(valueToSend) \(card.units)", attributes: subtitleAttributes)
        titleText.append(NSAttributedString(string: "\n"))
        titleText.append(subtitleText)
        
        UIView.performWithoutAnimation {
            btnSend?.setAttributedTitle(titleText, for: .normal)
            btnSend.layoutIfNeeded()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addBgLayers()
    }
    
    
    private func addBgLayers(){
        
        let color = UIColor.init(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0).cgColor
        let padding = CGFloat(16.0)
        
        
        bgLayer.backgroundColor = color
        let converted = topStackView.convert(cardInfoContainer.frame, to: view)
        bgLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: converted.height + converted.minY + padding)
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: view.center.x-50, y: converted.maxY + padding))
        path.addLine(to: CGPoint(x: view.center.x+50, y: converted.maxY + padding))
        path.addLine(to: CGPoint(x: view.center.x, y: converted.maxY + 16 + padding))
        path.close()
        triangleLayer.fillColor = color
        triangleLayer.path = path.cgPath
        
        //let convertedPasteFrame =  topStackView.convert(targetStackView.convert(pasteTargetAddressContainer.frame, to: topStackView), to: view)
        // pasteLayer.frame = CGRect(x: 0, y: convertedPasteFrame.minY, width: view.frame.width, height: convertedPasteFrame.height)
        // pasteLayer.backgroundColor = color
        
        if bgLayer.superlayer == nil {
            view.layer.insertSublayer(triangleLayer, at: 0)
            view.layer.insertSublayer(bgLayer, at: 0)
            view.layer.insertSublayer(pasteLayer, at: 0)
        }
        
        bgLayer.setNeedsLayout()
        triangleLayer.setNeedsLayout()
        // pasteLayer.setNeedsLayout()
    }
    
    
    func tryUpdateFeePreset() {
        btnSendSetEnabled(false)
        feeTimer?.invalidate()
        feeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { [weak self] _ in
            guard let self = self else {
                return
            }
            
            guard self.validateInput(skipFee: true),
                let targetAddress = self.validatedTarget,
                let amount = self.validatedAmount  else {
                    self.fee = nil
                    self.updateFee()
                    return
            }
            
            self.feeLabel.showActivityIndicator()
            
            let cProvider = self.card.cardEngine as! CoinProvider
            cProvider.getFee(targetAddress: targetAddress, amount: amount) {[weak self] fee in
                self?.fee = fee
                DispatchQueue.main.async {
                    self?.updateFee()
                    self?.validateInput()
                }
            }
        })
    }
    
    private func setError(_ error: Bool, for textField: UITextField) {
        
        let separatorColor = UIColor.init(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
        let textColor = UIColor.init(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
        
        //        textField.layer.borderColor = error ? UIColor.red.cgColor : UIColor.clear.cgColor
        //        textField.layer.borderWidth = error ? 1.0 : 0.0
        //        textField.layer.cornerRadius = error ? 8.0 : 0.0
        textField.textColor = error ? UIColor.red : textColor
        
        if textField == amountText {
            amountSeparator.backgroundColor = error ? UIColor.red : separatorColor
        } else if textField == targetAddressText {
            addressSeparator.backgroundColor = error ? UIColor.red : separatorColor
        }
    }
    
    func btnSendSetEnabled(_ enabled: Bool) {
        btnSend.isEnabled = enabled
        UIView.animate(withDuration: 0.3) {
            self.btnSend.backgroundColor = enabled ? UIColor(red: 27.0/255.0, green: 154.0/255.0, blue: 247.0/255.0, alpha: 1) :  UIColor.init(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
        }
    }
    
    private func handleSuccessSign(with signature: [UInt8]) {
        coinProvider.sendToBlockchain(signFromCard: signature) {[weak self] result in
            DispatchQueue.main.async {
                self?.removeLoadingView()
                self?.btnSend.hideActivityIndicator()
                self?.updateSendButtonSubtitle()
                if result {
                    self?.handleSuccess(completion: {
                        self?.dismiss(animated: true) {
                            self?.onDone?()
                        }
                    })
                } else {
                    self?.handleTXSendError(message:"")
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension ExtractViewController: DefaultErrorAlertsCapable {
    
}

@available(iOS 13.0, *)
extension ExtractViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === amountText else {
            return true
        }
        
        let maxLength = card.blockchain.decimalCount
        let currentString: NSString = textField.text! as NSString
        let newString: String =
            currentString.replacingCharacters(in: range, with: string) as String
        
        
        
        var allowNew = true
        
        if let dotIndex = newString.index(of: ".") {
            let fromIndex = newString.index(after: dotIndex)
            let decimalsString = newString[fromIndex...]
            allowNew = decimalsString.count <= maxLength
        } else {
            allowNew = true
        }
        
        guard allowNew else {
            return false
        }
        
        if string == "," {
            if let text = textField.text {
                textField.text = text + "."
                return false
            }
        }
        
        return true
    }
}

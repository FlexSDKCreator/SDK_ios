//
//  Toast.swift
//  MobileERP
//
//  Created by Sunil Luitel on 4/29/16.
//  Copyright © 2016 Sunil Luitel. All rights reserved.

import UIKit


func /(lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs / CGFloat(rhs)
}

/*
 *  Toast margin and Duration
 */
let HRToastDefaultDuration  =   2.0
let HRToastFadeDuration     =   0.2
let HRToastShortDuration  =   0.8




// label setting
let HRToastMaxWidth       :  CGFloat  = 0.8;      // 80% of parent view width
let HRToastMaxHeight      :  CGFloat  = 0.8;
let HRToastFontSize       :  CGFloat  = 16.0
let HRToastMaxMessageLines            = 0


let HRToastOpacity        : CGFloat   = 0.9
let HRToastCornerRadius   : CGFloat   = 10.0

var HRToastTimer: UnsafePointer<Timer>?          =   nil
var HRToastView: UnsafePointer<UIView>?            =   nil
var prevToastMessage: String?


extension UIView {
    
    
    
    func showToast(message msg: String) {
        let toast = self.viewForMessage(msg)
        self.showToast(toast: toast!, duration: HRToastDefaultDuration)
    }
    func showShortToast(message msg: String) {
        let toast = self.viewForMessage(msg)
        self.showToast(toast: toast!, duration: HRToastShortDuration)
    }
    fileprivate func showToast(toast: UIView, duration: Double) {
        let existToast = objc_getAssociatedObject(self, &HRToastView) as! UIView?
        if existToast != nil {
            if let timer: Timer = objc_getAssociatedObject(existToast as Any, &HRToastTimer) as? Timer {
                timer.invalidate();
            }
            self.hideToast(toast: existToast!, force: false);
        }
        
        toast.center = self.centerPointForPosition(toast)
        toast.alpha = 0.0
        
        
        self.addSubview(toast)
        objc_setAssociatedObject(self, &HRToastView, toast, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        
        UIView.animate(withDuration: HRToastFadeDuration,
                                   delay: 0.0, options: ([.curveEaseOut, .allowUserInteraction]),
                                   animations: {
                                    toast.alpha = 1.0
            },
                                   completion: { (finished: Bool) in
                                    let timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(UIView.toastTimerDidFinish(_:)), userInfo: toast, repeats: false)
                                    objc_setAssociatedObject(toast, &HRToastTimer, timer, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        })
    }
    
    
    
    /*
     *  private methods (helper)
     */
    
    func hideToast(toast: UIView, force: Bool) {
        let completeClosure = { (finish: Bool) -> () in
            toast.removeFromSuperview()
            objc_setAssociatedObject(self, &HRToastTimer, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        if force {
            completeClosure(true)
        } else {
            UIView.animate(withDuration: HRToastFadeDuration,
                                       delay: 0.0,
                                       options: ([.curveEaseIn, .beginFromCurrentState]),
                                       animations: {
                                        toast.alpha = 0.0
                },
                                       completion:completeClosure)
        }
    }
    
    @objc func toastTimerDidFinish(_ timer: Timer) {
        self.hideToast(toast: timer.userInfo as! UIView, force: false)
        prevToastMessage = nil
    }
    
    
    fileprivate func centerPointForPosition(_ toast: UIView) -> CGPoint {
        let toastSize = toast.bounds.size
        let viewSize  = self.bounds.size
        return CGPoint(x: viewSize.width/2, y: viewSize.height - toastSize.height/2 - 5 * DimenConstants.toastVerticalMargin)
    }
    
    fileprivate func viewForMessage(_ msg: String?) -> UIView? {
        if msg == nil { return nil }
        let combinedMessage: String?
        if prevToastMessage != nil {
            combinedMessage = prevToastMessage! + "\n" + msg!
        } else {
            combinedMessage = msg
        }
        prevToastMessage = combinedMessage
        var msgLabel: UILabel?
        let wrapperView = UIView()
        wrapperView.autoresizingMask = ([.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin])
        wrapperView.layer.cornerRadius = HRToastCornerRadius
        wrapperView.backgroundColor = UIColor.black.withAlphaComponent(HRToastOpacity)
        
        
        msgLabel = UILabel();
        msgLabel!.numberOfLines = HRToastMaxMessageLines
        msgLabel!.lineBreakMode = .byCharWrapping
        msgLabel!.textAlignment = .center
        msgLabel!.textColor = UIColor.white
        msgLabel!.backgroundColor = UIColor.clear
        msgLabel!.alpha = 1.0
        msgLabel!.text = combinedMessage
        
        let maxSizeMessage = CGSize(width: (self.bounds.size.width * HRToastMaxWidth) , height: self.bounds.size.height * HRToastMaxHeight)
        let expectedHeight = msg!.stringHeightWithFontSize(HRToastFontSize, width: maxSizeMessage.width)
        msgLabel!.frame = CGRect(x: DimenConstants.toastHorizontalMargin, y: DimenConstants.toastVerticalMargin, width: maxSizeMessage.width, height: expectedHeight)
        msgLabel!.sizeToFit()
        
        
        var msgWidth: CGFloat, msgHeight: CGFloat
        msgWidth = msgLabel!.bounds.size.width
        msgHeight = msgLabel!.bounds.size.height
        
        // set wrapper view's frame
        let wrapperWidth  = max(DimenConstants.toastHorizontalMargin * 2 + msgWidth,DimenConstants.toastHorizontalMargin)
        let wrapperHeight = max(DimenConstants.toastVerticalMargin * 2 + msgHeight, DimenConstants.toastVerticalMargin * 2)
        wrapperView.frame = CGRect(x: 0.0, y: 0.0, width: wrapperWidth, height: wrapperHeight)
        
        
        wrapperView.addSubview(msgLabel!)
        return wrapperView
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

final class Snackbar: UIView {
    private static weak var current: Snackbar?
    private var dismissTimer: Timer?
    private var action: (() -> Void)?

    static func show(message: String, actionTitle: String, duration: TimeInterval = 5.0, action: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first else { return }
            current?.dismiss(animated: false)
            let bar = Snackbar(message: message, actionTitle: actionTitle, action: action)
            current = bar
            bar.present(in: window, duration: duration)
        }
    }

    private init(message: String, actionTitle: String, action: @escaping () -> Void) {
        super.init(frame: .zero)
        self.action = action
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 0.196, green: 0.196, blue: 0.196, alpha: 1.0)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(actionTitle, for: .normal)
        button.setTitleColor(UIColor(red: 0.502, green: 0.796, blue: 0.769, alpha: 1.0), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        addSubview(label)
        addSubview(button)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 17),
            label.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -17),
            button.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            button.centerYAnchor.constraint(equalTo: label.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func present(in window: UIWindow, duration: TimeInterval) {
        window.addSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: window.leadingAnchor),
            trailingAnchor.constraint(equalTo: window.trailingAnchor),
            bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        window.layoutIfNeeded()
        transform = CGAffineTransform(translationX: 0, y: bounds.height)
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
            self.transform = .identity
        }, completion: nil)
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }

    @objc private func actionTapped() {
        let action = self.action
        dismiss(animated: true)
        action?()
    }

    private func dismiss(animated: Bool) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        action = nil
        guard animated else {
            removeFromSuperview()
            return
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
            self.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}

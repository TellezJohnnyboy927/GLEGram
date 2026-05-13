import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData

final class PeerInfoScreenSelectableBackgroundNode: ASDisplayNode {
    private let backgroundNode: ASDisplayNode
    private let button: HighlightTrackingButton
    
    let bringToFrontForHighlight: () -> Void
    
    private var isHighlighted: Bool = false
    
    // MARK: - MQGram
    private var longPressRecognizer: UILongPressGestureRecognizer?
    // MARK: - End MQGram
    
    var pressed: (() -> Void)? {
        didSet {
            self.updateInteractionEnabled()
        }
    }
    
    // MARK: - MQGram
    /// Optional long-press action. When set, a 2-second long-press on the
    /// background fires `longPressed`. Used for the hidden Swiftgram entry.
    var longPressed: (() -> Void)? {
        didSet {
            self.updateInteractionEnabled()
            self.updateLongPressRecognizer()
        }
    }
    // MARK: - End MQGram
    
    init(bringToFrontForHighlight: @escaping () -> Void) {
        self.bringToFrontForHighlight = bringToFrontForHighlight
        
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.alpha = 0.0
        
        self.button = HighlightTrackingButton()
        self.button.isAccessibilityElement = false
        
        super.init()
        
        self.addSubnode(self.backgroundNode)
        self.view.addSubview(self.button)
        
        self.button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        self.button.highligthedChanged = { [weak self] highlighted in
            self?.updateIsHighlighted(highlighted)
        }
    }
    
    @objc private func buttonPressed() {
        self.pressed?()
    }
    
    // MARK: - MQGram
    private func updateInteractionEnabled() {
        self.button.isUserInteractionEnabled = self.pressed != nil || self.longPressed != nil
    }
    
    private func updateLongPressRecognizer() {
        if self.longPressed != nil {
            if self.longPressRecognizer == nil {
                let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
                recognizer.minimumPressDuration = 2.0
                recognizer.cancelsTouchesInView = true
                self.button.addGestureRecognizer(recognizer)
                self.longPressRecognizer = recognizer
            }
        } else if let recognizer = self.longPressRecognizer {
            self.button.removeGestureRecognizer(recognizer)
            self.longPressRecognizer = nil
        }
    }
    
    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            self.longPressed?()
        }
    }
    // MARK: - End MQGram
    
    func updateIsHighlighted(_ isHighlighted: Bool) {
        if self.isHighlighted != isHighlighted {
            self.isHighlighted = isHighlighted
            if isHighlighted {
                self.bringToFrontForHighlight()
                self.backgroundNode.layer.removeAnimation(forKey: "opacity")
                self.backgroundNode.alpha = 1.0
            } else {
                self.backgroundNode.alpha = 0.0
                self.backgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25)
            }
        }
    }
    
    func update(size: CGSize, theme: PresentationTheme, transition: ContainedViewLayoutTransition) {
        self.backgroundNode.backgroundColor = theme.list.itemHighlightedBackgroundColor
        transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(), size: size))
        transition.updateFrame(view: self.button, frame: CGRect(origin: CGPoint(), size: size))
    }
}

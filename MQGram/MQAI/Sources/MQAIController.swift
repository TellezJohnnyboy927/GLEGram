import Foundation
import UIKit
import AsyncDisplayKit
import Display

/// Public entry point used by `TelegramRootController` to register the AI tab.
///
/// Wraps a `MQAIChatViewController` (plain UIKit) inside a `Display.ViewController`
/// so it integrates with Telegram's tab bar and navigation system.
public final class MQAIController: ViewController, MQAIChatPresentationDelegate {

    private let chatViewController: MQAIChatViewController
    private let containerNode = ASDisplayNode()

    public init() {
        self.chatViewController = MQAIChatViewController()

        super.init(navigationBarPresentationData: nil)

        self.chatViewController.presentationDelegate = self

        self.title = "AI"
        self.tabBarItem.title = "AI"
        self.tabBarItem.image = MQAIIcons.tabIcon
        self.tabBarItem.selectedImage = MQAIIcons.tabIconFilled

        self.navigationBar?.isHidden = true
        self.statusBar.statusBarStyle = .White
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }

    public override func loadDisplayNode() {
        self.displayNode = containerNode
        containerNode.backgroundColor = .black
        containerNode.setViewBlock { [weak self] in
            let view = UIView()
            view.backgroundColor = .black
            if let self = self {
                self.embedChatViewController(into: view)
            }
            return view
        }
        self.displayNodeDidLoad()
    }

    private func embedChatViewController(into hostView: UIView) {
        addChild(chatViewController)
        chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(chatViewController.view)
        NSLayoutConstraint.activate([
            chatViewController.view.topAnchor.constraint(equalTo: hostView.topAnchor),
            chatViewController.view.leftAnchor.constraint(equalTo: hostView.leftAnchor),
            chatViewController.view.rightAnchor.constraint(equalTo: hostView.rightAnchor),
            chatViewController.view.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
        ])
        chatViewController.didMove(toParent: self)
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let bounds = CGRect(origin: .zero, size: layout.size)
        containerNode.frame = bounds
    }

    // MARK: - MQAIChatPresentationDelegate

    public func mqaiPresentHistory(_ source: MQAIChatViewController) {
        let history = MQAIHistoryViewController()
        history.onSelectSession = { [weak source] session in
            source?.load(session: session)
        }
        history.onStartNew = { [weak source] in
            source?.startNewSession()
        }
        let nav = UINavigationController(rootViewController: history)
        nav.modalPresentationStyle = .pageSheet
        source.present(nav, animated: true)
    }

    public func mqaiPresentSettings(_ source: MQAIChatViewController) {
        let settings = MQAISettingsViewController()
        let nav = UINavigationController(rootViewController: settings)
        nav.modalPresentationStyle = .pageSheet
        source.present(nav, animated: true)
    }

    public func mqaiPresentModelPicker(_ source: MQAIChatViewController) {
        let storage = MQAIStorage.shared
        let picker = MQAIModelPickerViewController(selectedId: storage.selectedModel.id)
        picker.onSelect = { [weak source] model in
            source?.selectModel(model)
        }
        source.present(picker, animated: true)
    }

    public func mqaiPresentAttachmentPicker(_ source: MQAIChatViewController) {
        // Image / file attachment is not implemented yet — show a hint.
        let alert = UIAlertController(
            title: "Attachments",
            message: "Image and file attachments will be enabled in a future update.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        source.present(alert, animated: true)
    }
}

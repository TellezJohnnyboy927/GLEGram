import Foundation
import UIKit

/// Main UIKit-based chat screen embedded in the AI tab.
///
/// Layout (matches the design reference):
///   - Top bar: history button (left) — title "AI" (center) — profile/settings (right)
///   - Empty state: bubble icon + greeting "Hi, <name>! How can I help you today?"
///   - Bottom input bar: attach button, "Search" toggle, model picker pill, send arrow
public final class MQAIChatViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Public

    public weak var presentationDelegate: MQAIChatPresentationDelegate?

    // MARK: - State

    private let storage: MQAIStorage
    private let dispatcher: MQAIProviderDispatcher
    private var session: MQAIChatSession
    private var isSending = false
    private var isWebSearchEnabled = false

    // MARK: - Views

    private let backgroundView = UIView()
    private let topBar = UIView()
    private let titleLabel = UILabel()
    private let historyButton = UIButton(type: .system)
    private let profileButton = UIButton(type: .system)

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateContainer = UIView()
    private let emptyBubble = UILabel()
    private let emptyTitle = UILabel()
    private let emptySubtitle = UILabel()

    private let inputContainer = UIView()
    private let inputBubble = UIView()
    private let inputTextView = UITextView()
    private let inputPlaceholder = UILabel()
    private let attachButton = UIButton(type: .system)
    private let searchToggleButton = UIButton(type: .system)
    private let modelPillButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)

    private var inputBottomConstraint: NSLayoutConstraint?
    private var inputTextHeightConstraint: NSLayoutConstraint?

    // MARK: - Init

    public init(
        storage: MQAIStorage = .shared,
        dispatcher: MQAIProviderDispatcher = .shared,
        session: MQAIChatSession? = nil
    ) {
        self.storage = storage
        self.dispatcher = dispatcher
        self.session = session ?? MQAIChatSession(modelId: storage.selectedModel.id)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupViews()
        observeKeyboard()
        updateEmptyStateVisibility()
        refreshModelPillTitle()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .black
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leftAnchor.constraint(equalTo: view.leftAnchor),
            backgroundView.rightAnchor.constraint(equalTo: view.rightAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        setupTopBar()
        setupEmptyState()
        setupTable()
        setupInputBar()
    }

    private func setupTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = .black
        view.addSubview(topBar)
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            topBar.rightAnchor.constraint(equalTo: view.rightAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44),
        ])

        historyButton.translatesAutoresizingMaskIntoConstraints = false
        historyButton.tintColor = .white
        historyButton.setImage(MQAIIcons.history, for: .normal)
        historyButton.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
        topBar.addSubview(historyButton)

        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.tintColor = .white
        profileButton.setImage(MQAIIcons.profile, for: .normal)
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        topBar.addSubview(profileButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "AI"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        topBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            historyButton.leftAnchor.constraint(equalTo: topBar.leftAnchor, constant: 16),
            historyButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            historyButton.widthAnchor.constraint(equalToConstant: 32),
            historyButton.heightAnchor.constraint(equalToConstant: 32),

            profileButton.rightAnchor.constraint(equalTo: topBar.rightAnchor, constant: -16),
            profileButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            profileButton.widthAnchor.constraint(equalToConstant: 32),
            profileButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyStateContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateContainer)

        emptyBubble.translatesAutoresizingMaskIntoConstraints = false
        emptyBubble.text = "💬"
        emptyBubble.font = UIFont.systemFont(ofSize: 64)
        emptyBubble.textAlignment = .center
        emptyStateContainer.addSubview(emptyBubble)

        emptyTitle.translatesAutoresizingMaskIntoConstraints = false
        emptyTitle.textColor = .white
        emptyTitle.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        emptyTitle.textAlignment = .center
        emptyTitle.text = "Hi! 👋"
        emptyStateContainer.addSubview(emptyTitle)

        emptySubtitle.translatesAutoresizingMaskIntoConstraints = false
        emptySubtitle.textColor = .white
        emptySubtitle.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        emptySubtitle.textAlignment = .center
        emptySubtitle.text = "How can I help you today?"
        emptyStateContainer.addSubview(emptySubtitle)

        NSLayoutConstraint.activate([
            emptyStateContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            emptyStateContainer.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24),
            emptyStateContainer.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),

            emptyBubble.topAnchor.constraint(equalTo: emptyStateContainer.topAnchor),
            emptyBubble.centerXAnchor.constraint(equalTo: emptyStateContainer.centerXAnchor),

            emptyTitle.topAnchor.constraint(equalTo: emptyBubble.bottomAnchor, constant: 16),
            emptyTitle.leftAnchor.constraint(equalTo: emptyStateContainer.leftAnchor),
            emptyTitle.rightAnchor.constraint(equalTo: emptyStateContainer.rightAnchor),

            emptySubtitle.topAnchor.constraint(equalTo: emptyTitle.bottomAnchor, constant: 8),
            emptySubtitle.leftAnchor.constraint(equalTo: emptyStateContainer.leftAnchor),
            emptySubtitle.rightAnchor.constraint(equalTo: emptyStateContainer.rightAnchor),
            emptySubtitle.bottomAnchor.constraint(equalTo: emptyStateContainer.bottomAnchor),
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.register(MQAIMessageCell.self, forCellReuseIdentifier: MQAIMessageCell.reuseId)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupInputBar() {
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.backgroundColor = .clear
        view.addSubview(inputContainer)

        let bottom = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        inputBottomConstraint = bottom

        NSLayoutConstraint.activate([
            inputContainer.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
            inputContainer.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
            bottom,
        ])

        inputBubble.translatesAutoresizingMaskIntoConstraints = false
        inputBubble.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        inputBubble.layer.cornerRadius = 22
        inputBubble.layer.borderWidth = 1
        inputBubble.layer.borderColor = UIColor(white: 1.0, alpha: 0.08).cgColor
        inputContainer.addSubview(inputBubble)

        NSLayoutConstraint.activate([
            inputBubble.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            inputBubble.leftAnchor.constraint(equalTo: inputContainer.leftAnchor),
            inputBubble.rightAnchor.constraint(equalTo: inputContainer.rightAnchor),
            inputBubble.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),
        ])

        // First row: text input
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.backgroundColor = .clear
        inputTextView.textColor = .white
        inputTextView.font = UIFont.systemFont(ofSize: 17)
        inputTextView.delegate = self
        inputTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 8, right: 12)
        inputTextView.textContainer.lineFragmentPadding = 0
        inputTextView.isScrollEnabled = false
        inputTextView.returnKeyType = .default
        inputTextView.autocorrectionType = .default
        inputBubble.addSubview(inputTextView)

        inputPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        inputPlaceholder.text = "Ask anything…"
        inputPlaceholder.textColor = UIColor(white: 1.0, alpha: 0.4)
        inputPlaceholder.font = UIFont.systemFont(ofSize: 17)
        inputBubble.addSubview(inputPlaceholder)

        let textHeight = inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        inputTextHeightConstraint = textHeight

        // Second row: action buttons
        attachButton.translatesAutoresizingMaskIntoConstraints = false
        attachButton.tintColor = .white
        attachButton.setImage(MQAIIcons.attach, for: .normal)
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
        inputBubble.addSubview(attachButton)

        searchToggleButton.translatesAutoresizingMaskIntoConstraints = false
        configureSearchToggle()
        searchToggleButton.addTarget(self, action: #selector(toggleSearchTapped), for: .touchUpInside)
        inputBubble.addSubview(searchToggleButton)

        modelPillButton.translatesAutoresizingMaskIntoConstraints = false
        configureModelPill()
        modelPillButton.addTarget(self, action: #selector(modelPillTapped), for: .touchUpInside)
        inputBubble.addSubview(modelPillButton)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.tintColor = .white
        sendButton.backgroundColor = UIColor(white: 0.22, alpha: 1)
        sendButton.layer.cornerRadius = 16
        sendButton.setImage(MQAIIcons.send, for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        inputBubble.addSubview(sendButton)

        NSLayoutConstraint.activate([
            inputTextView.topAnchor.constraint(equalTo: inputBubble.topAnchor),
            inputTextView.leftAnchor.constraint(equalTo: inputBubble.leftAnchor),
            inputTextView.rightAnchor.constraint(equalTo: inputBubble.rightAnchor),
            textHeight,

            inputPlaceholder.leftAnchor.constraint(equalTo: inputTextView.leftAnchor, constant: 12),
            inputPlaceholder.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 12),

            attachButton.leftAnchor.constraint(equalTo: inputBubble.leftAnchor, constant: 8),
            attachButton.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 2),
            attachButton.bottomAnchor.constraint(equalTo: inputBubble.bottomAnchor, constant: -10),
            attachButton.widthAnchor.constraint(equalToConstant: 36),
            attachButton.heightAnchor.constraint(equalToConstant: 36),

            searchToggleButton.leftAnchor.constraint(equalTo: attachButton.rightAnchor, constant: 6),
            searchToggleButton.centerYAnchor.constraint(equalTo: attachButton.centerYAnchor),
            searchToggleButton.heightAnchor.constraint(equalToConstant: 32),

            modelPillButton.leftAnchor.constraint(equalTo: searchToggleButton.rightAnchor, constant: 6),
            modelPillButton.centerYAnchor.constraint(equalTo: attachButton.centerYAnchor),
            modelPillButton.heightAnchor.constraint(equalToConstant: 32),

            sendButton.rightAnchor.constraint(equalTo: inputBubble.rightAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: attachButton.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    private func configureSearchToggle() {
        var config = UIButton.Configuration.plain()
        config.image = MQAIIcons.globe
        config.imagePadding = 6
        config.title = "Search"
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 14)
        config.baseForegroundColor = isWebSearchEnabled ? .white : .white
        config.background.backgroundColor = isWebSearchEnabled
            ? UIColor.systemBlue
            : UIColor(white: 0.22, alpha: 1)
        config.background.cornerRadius = 16
        config.attributedTitle = AttributedString("Search", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
        ]))
        searchToggleButton.configuration = config
    }

    private func configureModelPill() {
        var config = UIButton.Configuration.plain()
        config.image = MQAIIcons.modelGlyph
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        config.baseForegroundColor = .white
        config.background.backgroundColor = UIColor(white: 0.22, alpha: 1)
        config.background.cornerRadius = 16
        modelPillButton.configuration = config
    }

    private func refreshModelPillTitle() {
        var config = modelPillButton.configuration ?? UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(
            storage.selectedModel.displayName,
            attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .medium)])
        )
        modelPillButton.configuration = config
    }

    // MARK: - Empty state

    private func updateEmptyStateVisibility() {
        let isEmpty = session.messages.isEmpty
        emptyStateContainer.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    // MARK: - Actions

    @objc private func historyTapped() {
        presentationDelegate?.mqaiPresentHistory(self)
    }

    @objc private func profileTapped() {
        presentationDelegate?.mqaiPresentSettings(self)
    }

    @objc private func attachTapped() {
        presentationDelegate?.mqaiPresentAttachmentPicker(self)
    }

    @objc private func toggleSearchTapped() {
        isWebSearchEnabled.toggle()
        configureSearchToggle()
    }

    @objc private func modelPillTapped() {
        presentationDelegate?.mqaiPresentModelPicker(self)
    }

    @objc private func sendTapped() {
        let text = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        send(userText: text)
    }

    private func send(userText: String) {
        let model = storage.selectedModel
        let userMessage = MQAIChatMessage(role: .user, content: userText)
        session.messages.append(userMessage)
        if session.title == "New chat", !userText.isEmpty {
            session.title = String(userText.prefix(40))
        }
        session.modelId = model.id
        session.updatedAt = Date()
        inputTextView.text = ""
        inputPlaceholder.isHidden = false
        updateEmptyStateVisibility()
        tableView.reloadData()
        scrollToBottom()
        isSending = true
        sendButton.isEnabled = false

        dispatcher.sendChatCompletion(model: model, messages: session.messages) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSending = false
                self.sendButton.isEnabled = true
                switch result {
                case let .success(reply):
                    self.session.messages.append(MQAIChatMessage(role: .assistant, content: reply))
                case let .failure(error):
                    let text = error.errorDescription ?? "Request failed."
                    self.session.messages.append(MQAIChatMessage(role: .assistant, content: "⚠️ \(text)"))
                }
                self.session.updatedAt = Date()
                self.storage.upsertSession(self.session)
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        }
    }

    private func scrollToBottom() {
        let count = session.messages.count
        guard count > 0 else { return }
        let path = IndexPath(row: count - 1, section: 0)
        tableView.scrollToRow(at: path, at: .bottom, animated: true)
    }

    // MARK: - UITextViewDelegate

    public func textViewDidChange(_ textView: UITextView) {
        inputPlaceholder.isHidden = !textView.text.isEmpty
        let target = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let capped = min(max(target.height, 40), 140)
        inputTextHeightConstraint?.constant = capped
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return session.messages.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MQAIMessageCell.reuseId, for: indexPath) as! MQAIMessageCell
        cell.configure(with: session.messages[indexPath.row])
        return cell
    }

    // MARK: - Public reset / load

    public func startNewSession() {
        session = MQAIChatSession(modelId: storage.selectedModel.id)
        updateEmptyStateVisibility()
        tableView.reloadData()
    }

    public func load(session: MQAIChatSession) {
        self.session = session
        updateEmptyStateVisibility()
        tableView.reloadData()
        scrollToBottom()
    }

    public func selectModel(_ model: MQAIModel) {
        storage.selectedModel = model
        refreshModelPillTitle()
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardFrameChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardFrameChange(_ note: Notification) {
        guard
            let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
        let bottomInset = max(0, view.bounds.height - frame.origin.y)
        let safeBottom = view.safeAreaInsets.bottom
        inputBottomConstraint?.constant = -(max(bottomInset - safeBottom, 0) + 8)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_: Notification) {
        inputBottomConstraint?.constant = -8
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
}

/// Delegate used by `MQAIChatViewController` to present modal screens that
/// require navigation context held by the parent (history list, model picker,
/// API key settings, attachment picker).
public protocol MQAIChatPresentationDelegate: AnyObject {
    func mqaiPresentHistory(_ source: MQAIChatViewController)
    func mqaiPresentSettings(_ source: MQAIChatViewController)
    func mqaiPresentModelPicker(_ source: MQAIChatViewController)
    func mqaiPresentAttachmentPicker(_ source: MQAIChatViewController)
}

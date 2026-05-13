import Foundation
import UIKit

/// Lets the user enter an API key for each AI provider. Keys live in
/// `UserDefaults` via `MQAIStorage`.
public final class MQAISettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    private let storage: MQAIStorage
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let providers: [MQAIProviderKind] = MQAIProviderKind.allCases

    public init(storage: MQAIStorage = .shared) {
        self.storage = storage
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI Settings"
        view.backgroundColor = .black

        let close = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem = close

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MQAIKeyCell.self, forCellReuseIdentifier: MQAIKeyCell.reuseId)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    public func numberOfSections(in tableView: UITableView) -> Int { 1 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return providers.count
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "API keys"
    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Keys are stored locally on this device only. They are sent directly to each provider; nothing routes through MQGram servers."
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MQAIKeyCell.reuseId, for: indexPath) as! MQAIKeyCell
        let provider = providers[indexPath.row]
        cell.configure(
            provider: provider,
            currentKey: storage.apiKey(for: provider)
        ) { [weak self] newValue in
            self?.storage.setApiKey(newValue, for: provider)
        }
        return cell
    }
}

private final class MQAIKeyCell: UITableViewCell, UITextFieldDelegate {
    static let reuseId = "MQAIKeyCell"

    private let providerLabel = UILabel()
    private let keyField = UITextField()
    private var onChange: ((String?) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        selectionStyle = .none

        providerLabel.translatesAutoresizingMaskIntoConstraints = false
        providerLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        providerLabel.textColor = .white
        contentView.addSubview(providerLabel)

        keyField.translatesAutoresizingMaskIntoConstraints = false
        keyField.font = UIFont.systemFont(ofSize: 15)
        keyField.textColor = .white
        keyField.placeholder = "sk-…"
        keyField.attributedPlaceholder = NSAttributedString(
            string: "Paste API key",
            attributes: [.foregroundColor: UIColor(white: 1, alpha: 0.4)]
        )
        keyField.autocorrectionType = .no
        keyField.autocapitalizationType = .none
        keyField.isSecureTextEntry = true
        keyField.delegate = self
        keyField.addTarget(self, action: #selector(fieldChanged(_:)), for: .editingChanged)
        contentView.addSubview(keyField)

        NSLayoutConstraint.activate([
            providerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            providerLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            providerLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),

            keyField.topAnchor.constraint(equalTo: providerLabel.bottomAnchor, constant: 4),
            keyField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            keyField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
            keyField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(provider: MQAIProviderKind, currentKey: String?, onChange: @escaping (String?) -> Void) {
        providerLabel.text = provider.displayName
        keyField.text = currentKey
        self.onChange = onChange
    }

    @objc private func fieldChanged(_ field: UITextField) {
        onChange?(field.text)
    }
}

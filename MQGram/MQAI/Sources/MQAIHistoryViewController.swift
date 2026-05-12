import Foundation
import UIKit

/// Lists previous AI chat sessions. Tapping a row loads it; swipe-to-delete
/// removes it. A "New chat" button starts a fresh session.
public final class MQAIHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    public var onSelectSession: ((MQAIChatSession) -> Void)?
    public var onStartNew: (() -> Void)?

    private let storage: MQAIStorage
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var sessions: [MQAIChatSession] = []

    public init(storage: MQAIStorage = .shared) {
        self.storage = storage
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "History"
        view.backgroundColor = .black

        let close = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem = close

        let newBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(newTapped))
        navigationItem.rightBarButtonItem = newBtn

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        sessions = storage.loadSessions()
        tableView.reloadData()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func newTapped() {
        onStartNew?()
        dismiss(animated: true)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        let session = sessions[indexPath.row]
        cell.textLabel?.text = session.title
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        let preview = session.messages.last?.content ?? ""
        cell.detailTextLabel?.text = preview.replacingOccurrences(of: "\n", with: " ")
        cell.detailTextLabel?.textColor = UIColor(white: 1, alpha: 0.5)
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let session = sessions[indexPath.row]
        onSelectSession?(session)
        dismiss(animated: true)
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let session = sessions[indexPath.row]
        storage.deleteSession(id: session.id)
        sessions.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

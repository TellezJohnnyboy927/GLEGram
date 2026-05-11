import Foundation
import UIKit

/// Cell that renders a single message bubble (user-aligned right, assistant-aligned left).
final class MQAIMessageCell: UITableViewCell {
    static let reuseId = "MQAIMessageCell"

    private let bubble = UIView()
    private let messageLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 16
        contentView.addSubview(bubble)

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        bubble.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.82),

            messageLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            messageLabel.leftAnchor.constraint(equalTo: bubble.leftAnchor, constant: 14),
            messageLabel.rightAnchor.constraint(equalTo: bubble.rightAnchor, constant: -14),
        ])

        leadingConstraint = bubble.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12)
        trailingConstraint = bubble.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(with message: MQAIChatMessage) {
        messageLabel.text = message.content
        switch message.role {
        case .user:
            bubble.backgroundColor = UIColor.systemBlue
            messageLabel.textColor = .white
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        case .assistant, .system:
            bubble.backgroundColor = UIColor(white: 0.18, alpha: 1)
            messageLabel.textColor = .white
            trailingConstraint?.isActive = false
            leadingConstraint?.isActive = true
        }
    }
}

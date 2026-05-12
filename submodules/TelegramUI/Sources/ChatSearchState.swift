import Foundation
import Postbox
import TelegramCore

struct ChatSearchState: Equatable {
    let query: String
    let location: SearchMessagesLocation
    // MARK: - MQGram
    let onlyDeleted: Bool
    // MARK: - End MQGram
    let loadMoreState: SearchMessagesState?
}

import Foundation
import SwiftData

@Model
final class CheckIn {
    @Attribute(.unique) var id: String

    init(id: String) {
        self.id = id
    }
}

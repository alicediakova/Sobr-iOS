import Foundation
import SwiftData

@Model
final class DayEntry {
    @Attribute(.unique) var date: String
    var count: Int
    var updatedAt: Date

    init(date: String, count: Int, updatedAt: Date) {
        self.date = date
        self.count = count
        self.updatedAt = updatedAt
    }
}

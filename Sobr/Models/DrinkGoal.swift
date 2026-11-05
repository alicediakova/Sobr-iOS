import Foundation
import SwiftData

@Model
final class DrinkGoal {
    @Attribute(.unique) var period: String
    var maxDrinks: Int
    var createdAt: Date
    var updatedAt: Date

    init(period: String, maxDrinks: Int, createdAt: Date, updatedAt: Date) {
        self.period = period
        self.maxDrinks = maxDrinks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

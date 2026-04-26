import SwiftUI

extension Binding where Value == String {
    func digitsOnly() -> Binding<String> {
        Binding(
            get: { wrappedValue },
            set: { newValue in
                wrappedValue = newValue.filter(\.isNumber)
            }
        )
    }
}

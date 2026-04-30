import Foundation

struct ExampleMetadata: Identifiable {
    let route: AppRoute
    let capability: String

    var id: String { route.id }
    var title: String { route.title }
    var subtitle: String { route.subtitle }
}

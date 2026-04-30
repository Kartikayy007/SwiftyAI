import Foundation

@MainActor
final class TaskCancellation {
    private var task: Task<Void, Never>?

    var isRunning: Bool {
        task != nil
    }

    func run(_ operation: @escaping @Sendable () async -> Void) {
        cancel()
        task = Task {
            await operation()
            await MainActor.run {
                self.task = nil
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

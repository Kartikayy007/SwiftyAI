import Foundation
import Observation

@MainActor
@Observable
public final class AICompletion {
    public var input: String
    public var output: String
    public var isLoading: Bool
    public var error: Error?

    public var prompt: String {
        get { input }
        set { input = newValue }
    }

    public var completion: String {
        get { output }
        set { output = newValue }
    }

    private var model: (any AIModel)?
    private let modelString: String?
    private let options: GenerationOptions
    private var generationTask: Task<Void, Never>?
    private var generationID = 0

    public init(
        model: any AIModel,
        options: GenerationOptions = GenerationOptions()
    ) {
        self.input = ""
        self.output = ""
        self.isLoading = false
        self.error = nil
        self.model = model
        self.modelString = nil
        self.options = options
    }

    public init(
        model modelString: String,
        options: GenerationOptions = GenerationOptions()
    ) {
        self.input = ""
        self.output = ""
        self.isLoading = false
        self.error = nil
        self.model = nil
        self.modelString = modelString
        self.options = options
    }

    public func send() {
        guard !isLoading else { return }

        let prompt = input
        error = nil
        output = ""
        isLoading = true
        generationID += 1
        let currentGenerationID = generationID

        generationTask = Task { [weak self] in
            guard let self else { return }
            await self.generate(prompt, generationID: currentGenerationID)
        }
    }

    public func stop() {
        generationID += 1
        generationTask?.cancel()
        generationTask = nil
        isLoading = false
    }

    public func reset() {
        stop()
        input = ""
        output = ""
        error = nil
    }

    private func resolveModel() async throws -> any AIModel {
        if let model {
            return model
        }

        guard let modelString else {
            throw AIError.unsupportedFeature("AICompletion has no model configured")
        }

        let resolved = try await AIRegistry.shared.resolve(modelString)
        model = resolved
        return resolved
    }

    private func generate(_ prompt: String, generationID: Int) async {
        defer {
            finishGeneration(generationID)
        }

        do {
            let resolvedModel = try await resolveModel()
            let response = try await generateText(model: resolvedModel, prompt: prompt, options: options)
            guard !Task.isCancelled, self.generationID == generationID else { return }
            output = response.text
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, self.generationID == generationID else { return }
            self.error = error
        }
    }

    private func finishGeneration(_ generationID: Int) {
        guard self.generationID == generationID else { return }
        generationTask = nil
        isLoading = false
    }
}

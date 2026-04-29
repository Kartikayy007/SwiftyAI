public struct LanguageModelRequest: Sendable {
    public var prompt: [AIMessageContent]
    public var options: GenerationOptions

    public init(
        prompt: String,
        system: String? = nil,
        options: GenerationOptions = GenerationOptions()
    ) {
        var options = options
        if let system {
            options.system = system
        }
        self.prompt = [.text(prompt)]
        self.options = options
    }

    public init(
        prompt: [AIMessageContent],
        system: String? = nil,
        options: GenerationOptions = GenerationOptions()
    ) {
        var options = options
        if let system {
            options.system = system
        }
        self.prompt = prompt
        self.options = options
    }

    public var system: String? {
        get { options.system }
        set { options.system = newValue }
    }

    public var promptText: String {
        get { prompt.textContent }
        set { prompt = [.text(newValue)] }
    }
}

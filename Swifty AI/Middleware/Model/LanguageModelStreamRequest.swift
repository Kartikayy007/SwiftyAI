public struct LanguageModelStreamRequest: Sendable {
    public var prompt: [AIMessageContent]?
    public var messages: [ChatMessage]?
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
        self.messages = nil
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
        self.messages = nil
        self.options = options
    }

    public init(
        messages: [ChatMessage],
        options: GenerationOptions = GenerationOptions()
    ) {
        self.prompt = nil
        self.messages = messages
        self.options = options
    }

    public var system: String? {
        get { options.system }
        set { options.system = newValue }
    }

    public var promptText: String {
        get {
            if let prompt {
                return prompt.textContent
            }
            return messages?.last(where: { $0.role == .user })?.content ?? ""
        }
        set {
            prompt = [.text(newValue)]
            messages = nil
        }
    }

    var languageRequest: LanguageModelRequest {
        var resolvedOptions = options
        if resolvedOptions.system == nil,
           let systemMessage = messages?.first(where: { $0.role == .system }) {
            resolvedOptions.system = systemMessage.content
        }
        if let prompt {
            return LanguageModelRequest(prompt: prompt, options: resolvedOptions)
        }
        let parts = messages?.last(where: { $0.role == .user })?.parts ?? [.text("")]
        return LanguageModelRequest(prompt: parts, options: resolvedOptions)
    }
}

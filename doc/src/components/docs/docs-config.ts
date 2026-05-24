export const docsNavGroups = [
  {
    title: "Start",
    items: [
      { title: "Overview", href: "/docs" },
      { title: "Installation", href: "/docs/installation" },
      { title: "Provider Setup", href: "/docs/provider-setup" },
      { title: "Quickstart", href: "/docs/quickstart" },
    ],
  },
  {
    title: "Core Generation",
    items: [
      { title: "Generate Text", href: "/docs/generate-text" },
      { title: "Stream Text", href: "/docs/stream-text" },
      { title: "Generation Options", href: "/docs/generation-options" },
      { title: "Generate Object", href: "/docs/generate-object" },
    ],
  },
  {
    title: "Tools and Agents",
    items: [
      { title: "Tools", href: "/docs/tools" },
      { title: "Tool Calling", href: "/docs/tool-calling" },
      { title: "Agent UI Stream", href: "/docs/agent-ui-stream" },
    ],
  },
  {
    title: "Multimodal and Media",
    items: [
      { title: "Multimodal Input", href: "/docs/multimodal" },
      { title: "Image Generation", href: "/docs/image-generation" },
      { title: "Audio", href: "/docs/audio" },
      { title: "Video", href: "/docs/video" },
    ],
  },
  {
    title: "Providers",
    items: [
      { title: "Provider Registry", href: "/docs/provider-registry" },
      { title: "Providers", href: "/docs/providers" },
      { title: "Custom Providers", href: "/docs/custom-providers" },
      { title: "Local Models", href: "/docs/local-models" },
    ],
  },
  {
    title: "Swift App State",
    items: [
      { title: "SwiftUI Hooks", href: "/docs/swiftui-hooks" },
      { title: "AIChat", href: "/docs/ai-chat" },
      { title: "AICompletion", href: "/docs/ai-completion" },
      { title: "SwiftyChat", href: "/docs/swifty-chat" },
    ],
  },
  {
    title: "Utilities",
    items: [
      { title: "Middleware", href: "/docs/middleware" },
      { title: "Utilities", href: "/docs/utilities" },
      { title: "Message Management", href: "/docs/message-management" },
      { title: "Streaming Utilities", href: "/docs/streaming-utilities" },
    ],
  },
] as const;

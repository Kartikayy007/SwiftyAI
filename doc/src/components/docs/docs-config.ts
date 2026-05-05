import {
  AudioLines,
  Boxes,
  Braces,
  Cable,
  Clapperboard,
  Cpu,
  FileText,
  Gauge,
  Image,
  KeyRound,
  Layers,
  ListChecks,
  MessageSquareText,
  PackageCheck,
  Radio,
  Route,
  Rows3,
  Sparkles,
  SquareFunction,
  TextCursorInput,
  Wrench,
} from "lucide-react";

export const docsNavGroups = [
  {
    title: "Start",
    items: [
      { title: "Overview", href: "/docs", icon: Sparkles },
      { title: "Installation", href: "/docs/installation", icon: PackageCheck },
      { title: "Provider Setup", href: "/docs/provider-setup", icon: KeyRound },
      { title: "Quickstart", href: "/docs/quickstart", icon: Route },
    ],
  },
  {
    title: "Core Generation",
    items: [
      { title: "Generate Text", href: "/docs/generate-text", icon: TextCursorInput },
      { title: "Stream Text", href: "/docs/stream-text", icon: Radio },
      { title: "Generation Options", href: "/docs/generation-options", icon: ListChecks },
      { title: "Generate Object", href: "/docs/generate-object", icon: Braces },
    ],
  },
  {
    title: "Tools and Agents",
    items: [
      { title: "Tools", href: "/docs/tools", icon: Wrench },
      { title: "Tool Calling", href: "/docs/tool-calling", icon: Cable },
      { title: "Agent UI Stream", href: "/docs/agent-ui-stream", icon: Rows3 },
    ],
  },
  {
    title: "Multimodal and Media",
    items: [
      { title: "Multimodal Input", href: "/docs/multimodal", icon: FileText },
      { title: "Image Generation", href: "/docs/image-generation", icon: Image },
      { title: "Audio", href: "/docs/audio", icon: AudioLines },
      { title: "Video", href: "/docs/video", icon: Clapperboard },
    ],
  },
  {
    title: "Providers",
    items: [
      { title: "Provider Registry", href: "/docs/provider-registry", icon: Boxes },
      { title: "Providers", href: "/docs/providers", icon: Layers },
      { title: "Custom Providers", href: "/docs/custom-providers", icon: SquareFunction },
      { title: "Local Models", href: "/docs/local-models", icon: Cpu },
    ],
  },
  {
    title: "Swift App State",
    items: [
      { title: "SwiftUI Hooks", href: "/docs/swiftui-hooks", icon: MessageSquareText },
      { title: "AIChat", href: "/docs/ai-chat", icon: MessageSquareText },
      { title: "AICompletion", href: "/docs/ai-completion", icon: TextCursorInput },
    ],
  },
  {
    title: "MCP and Observability",
    items: [
      { title: "MCP", href: "/docs/mcp", icon: Cpu },
      { title: "Telemetry", href: "/docs/telemetry", icon: Gauge },
    ],
  },
  {
    title: "Utilities",
    items: [
      { title: "Utilities", href: "/docs/utilities", icon: Sparkles },
      { title: "Message Management", href: "/docs/message-management", icon: ListChecks },
      { title: "Streaming Utilities", href: "/docs/streaming-utilities", icon: Radio },
    ],
  },
] as const;

import {
  Boxes,
  BrainCircuit,
  Braces,
  Cable,
  Cpu,
  Gauge,
  GitBranch,
  MessageSquareText,
  Radio,
  Sparkles,
  TextCursorInput,
} from "lucide-react";

export const docsNav = [
  {
    title: "Overview",
    href: "/docs",
    icon: Sparkles,
  },
  {
    title: "Generate Text",
    href: "/docs/generate-text",
    icon: TextCursorInput,
  },
  {
    title: "Stream Text",
    href: "/docs/stream-text",
    icon: Radio,
  },
  {
    title: "Tools",
    href: "/docs/tools",
    icon: Cable,
  },
  {
    title: "Generate Object",
    href: "/docs/generate-object",
    icon: Braces,
  },
  {
    title: "Embeddings",
    href: "/docs/embeddings",
    icon: BrainCircuit,
  },
  {
    title: "Reranking",
    href: "/docs/reranking",
    icon: GitBranch,
  },
  {
    title: "Provider Registry",
    href: "/docs/provider-registry",
    icon: Boxes,
  },
  {
    title: "SwiftUI Hooks",
    href: "/docs/swiftui-hooks",
    icon: MessageSquareText,
  },
  {
    title: "MCP",
    href: "/docs/mcp",
    icon: Cpu,
  },
  {
    title: "Telemetry",
    href: "/docs/telemetry",
    icon: Gauge,
  },
] as const;

export const pageSections = ["Overview", "API", "Example", "Notes"] as const;

"use client";
import { useTheme } from "next-themes";
import { useEffect, useState } from "react";
import { AsciiArt } from "@/components/ui/ascii-art";

export default function AsciiArtDemo() {
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  if (!mounted) return <div className="h-full w-full" />;

  const isDark = resolvedTheme === "dark";

  return (
    <AsciiArt
      src="/swiftyAIlogo-removebg-preview.png"
      resolution={440}
      color={isDark ? "white" : "#1a1a1a"}
      charset="dense"
      objectFit="cover"
      transparentBackground
      animated={false}
      animationStyle="none"
      className="h-full w-full origin-center scale-[1.25]"
    />
  );
}

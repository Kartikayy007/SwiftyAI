"use client";

import * as React from "react";
import Link from "next/link";
import Image from "next/image";
import { ThemeToggle } from "@/components/theme/theme-toggle";
import AsciiArtDemo from "@/components/ui/ascii-art-demo";
import { HomeCards } from "@/components/home/home-cards";
import { ArticlePanel } from "@/components/home/article-panel";
import type { HomeCard } from "@/components/home/home-card-data";
import { gridBorder, pagePaddingX, sectionPaddingX } from "@/lib/layout-tokens";
import { cn } from "@/lib/utils";

export function HomePageShell() {
  const [activeCard, setActiveCard] = React.useState<HomeCard | null>(null);
  const panelOpen = activeCard !== null;

  const closePanel = () => setActiveCard(null);

  React.useEffect(() => {
    if (!panelOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") closePanel();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [panelOpen]);

  return (
    <div
      className={cn(
        "flex h-screen flex-col overflow-hidden text-foreground transition-[background] duration-200",
        pagePaddingX,
        panelOpen ? "hatch-bg" : "bg-background"
      )}
      style={{ fontFamily: "var(--font-inter), var(--font-fira-sans), sans-serif" }}
    >
      <div className={cn("flex min-h-0 flex-1 flex-col border-x", gridBorder)}>
        <header className={cn("shrink-0 border-b py-3", gridBorder, sectionPaddingX)}>
          <div className="flex items-center justify-between">
            <Link href="/" className="flex items-center gap-2">
              <Image
                src="/swiftyAIlogo.png"
                alt="SwiftyAI"
                width={24}
                height={24}
                className="rounded"
              />
              <span
                className="text-sm font-semibold tracking-tight"
                style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
              >
                SwiftyAI
              </span>
            </Link>

            <nav className="flex items-center gap-5">
              {[
                ["DOCS", "/docs"],
                ["QUICKSTART", "/docs/quickstart"],
                ["PROVIDERS", "/docs/providers"],
                ["GITHUB", "https://github.com/Kartikayy007/SwiftyAI"],
              ].map(([label, href]) => (
                <Link
                  key={label}
                  href={href}
                  className="text-[11px] font-semibold tracking-widest text-muted-foreground hover:text-foreground transition-colors"
                  style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
                  {...(href.startsWith("http") ? { target: "_blank", rel: "noopener noreferrer" } : {})}
                >
                  {label}
                </Link>
              ))}
              <ThemeToggle />
            </nav>
          </div>
        </header>

        <div className="relative flex min-h-0 flex-1 overflow-hidden">
          {panelOpen ? (
            <button
              type="button"
              aria-label="Close panel"
              className="absolute inset-0 z-10 cursor-default"
              onClick={closePanel}
            />
          ) : null}

          <main
            className={cn(
              "relative z-0 flex min-h-0 flex-1 flex-col justify-between py-8 transition-opacity",
              panelOpen && "opacity-50"
            )}
          >
            <section className={cn("shrink-0 border-b pb-10", gridBorder, sectionPaddingX)}>
              <div className="flex flex-row items-center gap-10 lg:gap-12">
                <div className="flex-1">
                  <h1
                    className="font-black leading-[0.88] tracking-tight text-foreground"
                    style={{
                      fontFamily: "var(--font-fira-sans), sans-serif",
                      fontWeight: 900,
                      fontSize: "clamp(3.5rem,8vw,6.5rem)",
                    }}
                  >
                    <span
                      className="block"
                      style={{
                        background: "linear-gradient(90deg, #FF6B35, #FF9F1C, #FF6B35)",
                        backgroundSize: "300% 100%",
                        WebkitBackgroundClip: "text",
                        WebkitTextFillColor: "transparent",
                        backgroundClip: "text",
                        animation: "gradientShift 6s ease infinite",
                      }}
                    >
                      Swift AI SDK
                    </span>
                    <span className="block">For Apple Devs</span>
                  </h1>
                  <p
                    className="mt-5 max-w-xl leading-snug text-muted-foreground"
                    style={{
                      fontFamily: "var(--font-playfair), Georgia, serif",
                      fontStyle: "italic",
                      fontSize: "clamp(1.05rem,1.9vw,1.35rem)",
                    }}
                  >
                    Build intelligent iOS, macOS, watchOS, and tvOS apps with a&nbsp;native Swift API for
                    streaming, tool calling, and multimodal AI.
                  </p>
                </div>
                <div className="relative aspect-square w-[min(42vw,400px)] shrink-0 overflow-hidden">
                  <AsciiArtDemo />
                </div>
              </div>
            </section>

            <HomeCards onCardSelect={setActiveCard} />

            <div className={cn("shrink-0 border-b py-6", gridBorder)} aria-hidden />
          </main>

          {activeCard ? <ArticlePanel card={activeCard} onClose={closePanel} /> : null}
        </div>
      </div>
    </div>
  );
}

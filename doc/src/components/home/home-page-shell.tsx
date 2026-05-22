"use client";

import * as React from "react";
import Link from "next/link";
import Image from "next/image";
import { Menu } from "lucide-react";
import { ThemeToggle } from "@/components/theme/theme-toggle";
import AsciiArtDemo from "@/components/ui/ascii-art-demo";
import { HomeCards } from "@/components/home/home-cards";
import { ArticlePanel } from "@/components/home/article-panel";
import type { HomeCard } from "@/components/home/home-card-data";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { gridBorder, pagePaddingX, sectionPaddingX } from "@/lib/layout-tokens";
import { cn } from "@/lib/utils";

const navLinks = [
  ["DOCS", "/docs"],
  ["QUICKSTART", "/docs/quickstart"],
  ["PROVIDERS", "/docs/providers"],
  ["GITHUB", "https://github.com/Kartikayy007/SwiftyAI"],
] as const;

const GitHubIcon = () => (
  <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="currentColor" aria-hidden>
    <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
  </svg>
);

export function HomePageShell({ stars }: { stars?: number | null }) {
  const [activeCard, setActiveCard] = React.useState<HomeCard | null>(null);
  const [menuOpen, setMenuOpen] = React.useState(false);
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
        "flex min-h-dvh flex-col overflow-x-hidden text-foreground transition-[background] duration-200",
        pagePaddingX,
        panelOpen ? "hatch-bg" : "bg-background"
      )}
      style={{ fontFamily: "var(--font-inter), var(--font-fira-sans), sans-serif" }}
    >
      <div className={cn("flex min-h-dvh flex-1 flex-col border-x", gridBorder)}>
        <header className={cn("shrink-0 border-b py-3", gridBorder, sectionPaddingX)}>
          <div className="flex items-center justify-between gap-3">
            <Link href="/" className="flex shrink-0 items-center gap-2">
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

            <nav className="hidden items-center gap-4 md:flex md:gap-5">
              {navLinks.map(([label, href]) =>
                label === "GITHUB" ? (
                  <Link
                    key={label}
                    href={href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-[11px] font-semibold tracking-widest text-muted-foreground ring-1 ring-border hover:bg-muted hover:text-foreground transition-colors"
                    style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
                  >
                    <GitHubIcon />
                    {label}
                    {stars != null && (
                      <span className="flex items-center gap-0.5 ml-0.5">
                        <svg viewBox="0 0 16 16" className="h-2.5 w-2.5 fill-current" aria-hidden>
                          <path d="M8 .25a.75.75 0 0 1 .673.418l1.882 3.815 4.21.612a.75.75 0 0 1 .416 1.279l-3.046 2.97.719 4.192a.751.751 0 0 1-1.088.791L8 12.347l-3.766 1.98a.75.75 0 0 1-1.088-.79l.72-4.194L.818 6.374a.75.75 0 0 1 .416-1.28l4.21-.611L7.327.668A.75.75 0 0 1 8 .25Z" />
                        </svg>
                        {stars >= 1000 ? `${(stars / 1000).toFixed(1)}k` : stars}
                      </span>
                    )}
                  </Link>
                ) : (
                  <Link
                    key={label}
                    href={href}
                    className="text-[11px] font-semibold tracking-widest text-muted-foreground hover:text-foreground transition-colors"
                    style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
                    {...(href.startsWith("http") ? { target: "_blank", rel: "noopener noreferrer" } : {})}
                  >
                    {label}
                  </Link>
                )
              )}
              <ThemeToggle />
            </nav>

            <div className="flex items-center gap-1 md:hidden">
              <ThemeToggle />
              <Sheet open={menuOpen} onOpenChange={setMenuOpen}>
                <SheetTrigger
                  render={
                    <Button variant="ghost" size="icon" aria-label="Open menu" />
                  }
                >
                  <Menu className="h-5 w-5" />
                </SheetTrigger>
                <SheetContent side="right" className="w-full max-w-xs p-0">
                  <SheetHeader className="border-b px-4 py-3 text-left">
                    <SheetTitle>Menu</SheetTitle>
                  </SheetHeader>
                  <nav className="flex flex-col p-2">
                    {navLinks.map(([label, href]) => (
                      <Link
                        key={label}
                        href={href}
                        onClick={() => setMenuOpen(false)}
                        className="rounded-md px-3 py-3 text-sm font-semibold tracking-widest text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                        style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
                        {...(href.startsWith("http")
                          ? { target: "_blank", rel: "noopener noreferrer" }
                          : {})}
                      >
                        <span className="flex items-center gap-1.5">
                          {label === "GITHUB" && <GitHubIcon />}
                          {label}
                          {label === "GITHUB" && stars != null && (
                            <span className="flex items-center gap-0.5 ml-0.5 text-xs">
                              <svg viewBox="0 0 16 16" className="h-2.5 w-2.5 fill-current" aria-hidden>
                                <path d="M8 .25a.75.75 0 0 1 .673.418l1.882 3.815 4.21.612a.75.75 0 0 1 .416 1.279l-3.046 2.97.719 4.192a.751.751 0 0 1-1.088.791L8 12.347l-3.766 1.98a.75.75 0 0 1-1.088-.79l.72-4.194L.818 6.374a.75.75 0 0 1 .416-1.28l4.21-.611L7.327.668A.75.75 0 0 1 8 .25Z" />
                              </svg>
                              {stars >= 1000 ? `${(stars / 1000).toFixed(1)}k` : stars}
                            </span>
                          )}
                        </span>
                      </Link>
                    ))}
                  </nav>
                </SheetContent>
              </Sheet>
            </div>
          </div>
        </header>

        <div className="relative flex min-h-0 flex-1 flex-col overflow-hidden lg:overflow-hidden">
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
              "relative z-0 flex min-h-0 flex-1 flex-col overflow-y-auto transition-opacity",
              "py-6 sm:justify-between sm:py-8",
              panelOpen && "opacity-50"
            )}
          >
            <section className={cn("shrink-0 border-b pb-8 sm:pb-10", gridBorder, sectionPaddingX)}>
              <div className="flex flex-col items-center gap-8 lg:flex-row lg:items-center lg:gap-12">
                <div className="w-full flex-1 text-center lg:text-left">
                  <h1
                    className="font-black leading-[0.88] tracking-tight text-foreground"
                    style={{
                      fontFamily: "var(--font-fira-sans), sans-serif",
                      fontWeight: 900,
                      fontSize: "clamp(2.5rem,10vw,6.5rem)",
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
                    className="mx-auto mt-4 max-w-xl leading-snug text-muted-foreground sm:mt-5 lg:mx-0"
                    style={{
                      fontFamily: "var(--font-playfair), Georgia, serif",
                      fontStyle: "italic",
                      fontSize: "clamp(1rem,2.5vw,1.35rem)",
                    }}
                  >
                    Build intelligent iOS, macOS, watchOS, and tvOS apps with a&nbsp;native Swift API for
                    streaming, tool calling, and multimodal AI.
                  </p>
                </div>
                <div className="relative mx-auto aspect-square w-full max-w-[280px] shrink-0 overflow-hidden sm:max-w-[320px] lg:mx-0 lg:w-[min(42vw,400px)] lg:max-w-none">
                  <AsciiArtDemo />
                </div>
              </div>
            </section>

            <HomeCards onCardSelect={setActiveCard} />

            <div className={cn("hidden shrink-0 border-b py-6 sm:block", gridBorder)} aria-hidden />
          </main>

          {activeCard ? <ArticlePanel card={activeCard} onClose={closePanel} /> : null}
        </div>
      </div>
    </div>
  );
}

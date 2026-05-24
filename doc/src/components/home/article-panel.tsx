"use client";

import * as React from "react";
import Link from "next/link";
import { XIcon, ArrowUpRight, BookOpen } from "lucide-react";
import { cn } from "@/lib/utils";
import type { HomeCard } from "@/components/home/home-card-data";

type ArticlePanelProps = {
  card: HomeCard;
  onClose: () => void;
  className?: string;
};

function useShikiHtml(code: string, lang: string) {
  const [html, setHtml] = React.useState<string | null>(null);

  React.useEffect(() => {
    let cancelled = false;
    import("shiki").then(({ codeToHtml }) =>
      codeToHtml(code, {
        lang,
        theme: "github-dark",
      })
    ).then((result) => {
      if (!cancelled) setHtml(result);
    }).catch(() => {
      if (!cancelled) setHtml(null);
    });
    return () => { cancelled = true; };
  }, [code, lang]);

  return html;
}

export function ArticlePanel({ card, onClose, className }: ArticlePanelProps) {
  const highlightedHtml = useShikiHtml(card.snippet, "swift");

  return (
    <aside
      role="dialog"
      aria-modal="true"
      aria-labelledby="article-panel-title"
      className={cn(
        "fixed inset-0 z-30 flex w-full flex-col bg-background",
        "animate-in fade-in slide-in-from-right-4 duration-200",
        "sm:absolute sm:inset-y-0 sm:right-0 sm:left-auto sm:w-[min(44%,30rem)] sm:border-l sm:border-foreground/30",
        className
      )}
    >
      <button
        type="button"
        onClick={onClose}
        aria-label="Close"
        className="absolute top-3 right-3 z-10 flex h-8 w-8 items-center justify-center text-muted-foreground transition-colors hover:text-foreground"
      >
        <XIcon className="h-4 w-4" />
      </button>

      <div className="flex min-h-0 flex-1 flex-col overflow-y-auto">
        <div className="shrink-0 px-5 pt-8 pb-5 pr-12 sm:px-7">
          <h2
            id="article-panel-title"
            className="text-[clamp(1.5rem,3.5vw,2rem)] font-black leading-[0.95] tracking-tight"
            style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
          >
            {card.label}
          </h2>
          <p
            className="mt-3 text-[clamp(0.88rem,1.6vw,1.05rem)] leading-snug text-muted-foreground"
            style={{
              fontFamily: "var(--font-playfair), Georgia, serif",
              fontStyle: "italic",
            }}
          >
            {card.description}
          </p>
          <p
            className="mt-3 text-[10px] font-semibold tracking-widest text-muted-foreground uppercase"
            style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
          >
            {card.tag} · {card.date}
          </p>
          <Link
            href={card.href}
            className="mt-4 inline-flex items-center gap-1.5 text-[11px] font-semibold tracking-widest uppercase text-foreground transition-opacity hover:opacity-70"
            style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
          >
            <BookOpen className="h-3 w-3" />
            View docs
            <ArrowUpRight className="h-3 w-3" />
          </Link>
        </div>

        <div className="mx-5 sm:mx-7 mb-6">
          <div className="rounded-lg overflow-hidden border border-foreground/15 text-[12px]">
            <div className="flex items-center justify-between border-b border-foreground/10 bg-[#0d1117] px-4 py-2">
              <div className="flex items-center gap-1.5">
                <span className="h-2.5 w-2.5 rounded-full bg-red-500/80" />
                <span className="h-2.5 w-2.5 rounded-full bg-yellow-400/80" />
                <span className="h-2.5 w-2.5 rounded-full bg-green-500/80" />
              </div>
              <span
                className="text-[10px] font-medium tracking-widest text-white/30 uppercase"
                style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
              >
                Swift
              </span>
            </div>
            {highlightedHtml ? (
              <div
                className="[&>pre]:!m-0 [&>pre]:!rounded-none [&>pre]:!border-0 [&>pre]:overflow-x-auto [&>pre]:px-4 [&>pre]:py-4 [&>pre]:text-[12px] [&>pre]:leading-relaxed"
                dangerouslySetInnerHTML={{ __html: highlightedHtml }}
              />
            ) : (
              <pre className="overflow-x-auto bg-[#0d1117] px-4 py-4 text-[12px] leading-relaxed text-emerald-300/80 font-mono">
                <code>{card.snippet}</code>
              </pre>
            )}
          </div>
        </div>
      </div>
    </aside>
  );
}

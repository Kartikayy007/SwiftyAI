"use client";

import Image from "next/image";
import Link from "next/link";
import { XIcon } from "lucide-react";
import { cn } from "@/lib/utils";
import type { HomeCard } from "@/components/home/home-card-data";

type ArticlePanelProps = {
  card: HomeCard;
  onClose: () => void;
  className?: string;
};

export function ArticlePanel({ card, onClose, className }: ArticlePanelProps) {
  return (
    <aside
      role="dialog"
      aria-modal="true"
      aria-labelledby="article-panel-title"
      className={cn(
        "fixed inset-0 z-30 flex w-full flex-col bg-background",
        "animate-in fade-in slide-in-from-right-4 duration-200",
        "sm:absolute sm:inset-y-0 sm:right-0 sm:left-auto sm:w-[min(34%,24rem)] sm:border-l sm:border-foreground/30",
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

      <div className="flex min-h-0 flex-1 flex-col">
        <div className="shrink-0 px-5 pt-8 pb-6 pr-12 sm:px-7">
          <h2
            id="article-panel-title"
            className="text-[clamp(1.75rem,4vw,2.5rem)] font-black leading-[0.95] tracking-tight"
            style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
          >
            {card.label}
          </h2>
          <p
            className="mt-4 text-[clamp(0.95rem,1.8vw,1.15rem)] leading-snug text-muted-foreground"
            style={{
              fontFamily: "var(--font-playfair), Georgia, serif",
              fontStyle: "italic",
            }}
          >
            {card.description}
          </p>
          <p
            className="mt-4 text-[10px] font-semibold tracking-widest text-muted-foreground uppercase"
            style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
          >
            {card.tag} · {card.date}
          </p>
          <Link
            href={card.href}
            className="mt-5 inline-flex items-center gap-1 text-[11px] font-semibold tracking-widest uppercase text-foreground transition-opacity hover:opacity-70"
            style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
          >
            View docs ↗
          </Link>
        </div>

        <div className="relative mt-auto min-h-0 flex-1 border-t border-foreground/25">
          <div className="flex h-full items-end justify-center p-6">
            <div className="aspect-[4/3] w-full overflow-hidden border border-foreground/25 bg-muted/30">
              <Image
                src="/swiftyAIlogobgRemoved.png"
                alt=""
                width={560}
                height={420}
                className="h-full w-full object-contain p-4"
              />
            </div>
          </div>
        </div>
      </div>
    </aside>
  );
}

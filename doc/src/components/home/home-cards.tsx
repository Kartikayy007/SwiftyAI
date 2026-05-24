"use client";

import { BookOpen } from "lucide-react";
import { homeCards, type HomeCard } from "@/components/home/home-card-data";
import { gridBorder } from "@/lib/layout-tokens";
import { cn } from "@/lib/utils";

type HomeCardsProps = {
  className?: string;
  onCardSelect: (card: HomeCard) => void;
};

export function HomeCards({ className, onCardSelect }: HomeCardsProps) {
  return (
    <section
      className={cn(
        "grid shrink-0 grid-cols-1 border-b sm:grid-cols-2 lg:grid-cols-4",
        "divide-y divide-foreground/25 sm:divide-x sm:divide-y-0",
        gridBorder,
        className
      )}
    >
      {homeCards.map((card, i) => (
        <button
          key={card.title}
          type="button"
          onClick={() => onCardSelect(card)}
          className={cn(
            "group flex cursor-pointer flex-col justify-between p-4 text-left transition-opacity hover:opacity-80 sm:p-6",
            i === 0 ? "min-h-36 sm:min-h-48" : "min-h-32 sm:min-h-40",
            card.accent
              ? "bg-[var(--swift-orange)] text-black"
              : "bg-background text-foreground"
          )}
        >
          <div>
            <div className="mb-2 flex items-center justify-between sm:mb-3">
              <span
                className={cn(
                  "text-[9px] font-bold tracking-widest uppercase",
                  card.accent ? "text-black/70" : "text-muted-foreground"
                )}
                style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
              >
                {card.tag}
              </span>
              <span
                className={cn(
                  "text-[9px] tracking-wide",
                  card.accent ? "text-black/60" : "text-muted-foreground"
                )}
                style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
              >
                {card.date}
              </span>
            </div>
            <h2
              className="text-sm font-bold leading-snug"
              style={{ fontFamily: "var(--font-fira-sans), sans-serif", fontWeight: 700 }}
            >
              {card.title}
            </h2>
          </div>
          <span
            className={cn(
              "mt-3 inline-flex items-center gap-1 text-[10px] font-semibold tracking-widest uppercase sm:mt-4",
              card.accent ? "text-black/70" : "text-muted-foreground"
            )}
            style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
          >
            <BookOpen className="h-3 w-3" />
            Read
          </span>
        </button>
      ))}
    </section>
  );
}

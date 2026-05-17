"use client";

import { homeCards, type HomeCard } from "@/components/home/home-card-data";

const gridBorder = "border-foreground/25";
const gridDivide = "divide-x divide-foreground/25";

type HomeCardsProps = {
  className?: string;
  onCardSelect: (card: HomeCard) => void;
};

export function HomeCards({ className, onCardSelect }: HomeCardsProps) {
  return (
    <section
      className={[className, `grid shrink-0 grid-cols-4 ${gridDivide} border-b ${gridBorder}`]
        .filter(Boolean)
        .join(" ")}
    >
      {homeCards.map((card, i) => (
        <button
          key={card.title}
          type="button"
          onClick={() => onCardSelect(card)}
          className={[
            "group flex cursor-pointer flex-col justify-between p-6 text-left transition-opacity hover:opacity-80",
            i === 0 ? "min-h-48" : "min-h-40",
            card.accent
              ? "bg-[var(--swift-orange)] text-black"
              : "bg-background text-foreground",
          ].join(" ")}
        >
          <div>
            <div className="mb-3 flex items-center justify-between">
              <span
                className={[
                  "text-[9px] font-bold tracking-widest uppercase",
                  card.accent ? "text-black/70" : "text-muted-foreground",
                ].join(" ")}
                style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
              >
                {card.tag}
              </span>
              <span
                className={[
                  "text-[9px] tracking-wide",
                  card.accent ? "text-black/60" : "text-muted-foreground",
                ].join(" ")}
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
            className={[
              "mt-4 text-[10px] font-semibold tracking-widest uppercase",
              card.accent ? "text-black/70" : "text-muted-foreground",
            ].join(" ")}
            style={{ fontFamily: "var(--font-fira-sans), sans-serif" }}
          >
            Read →
          </span>
        </button>
      ))}
    </section>
  );
}

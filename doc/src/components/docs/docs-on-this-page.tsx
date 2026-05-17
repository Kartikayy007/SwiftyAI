"use client";

import * as React from "react";
import { usePathname } from "next/navigation";
import { ScrollArea } from "@/components/ui/scroll-area";
import { cn } from "@/lib/utils";

type TocItem = {
  id: string;
  text: string;
  level: 2 | 3;
};

function slugify(text: string) {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, "")
    .replace(/\s+/g, "-");
}

export function DocsOnThisPage() {
  const pathname = usePathname();
  const [items, setItems] = React.useState<TocItem[]>([]);
  const [activeId, setActiveId] = React.useState("");

  React.useEffect(() => {
    const content = document.querySelector(".docs-content");
    if (!content) {
      setItems([]);
      return;
    }

    const headings = content.querySelectorAll("h2, h3");
    const toc: TocItem[] = [];

    headings.forEach((heading) => {
      const el = heading as HTMLElement;
      const text = el.textContent?.trim() ?? "";
      if (!text) return;

      const id = el.id || slugify(text);
      el.id = id;
      toc.push({ id, text, level: el.tagName === "H2" ? 2 : 3 });
    });

    setItems(toc);
    setActiveId(toc[0]?.id ?? "");

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);

        if (visible[0]?.target.id) {
          setActiveId(visible[0].target.id);
        }
      },
      { rootMargin: "-96px 0px -65% 0px", threshold: 0 }
    );

    headings.forEach((heading) => observer.observe(heading));
    return () => observer.disconnect();
  }, [pathname]);

  if (items.length === 0) return null;

  return (
    <aside className="hidden w-52 shrink-0 xl:block">
      <nav className="sticky top-20" aria-label="On this page">
        <p className="text-xs font-semibold tracking-widest text-foreground uppercase">
          On this page
        </p>
        <ScrollArea className="mt-4 max-h-[calc(100vh-6rem)]">
          <ul className="space-y-2 border-l border-border pr-3 pl-4 text-sm">
            {items.map((item) => (
              <li key={item.id}>
                <a
                  href={`#${item.id}`}
                  className={cn(
                    "block leading-snug text-muted-foreground transition-colors hover:text-foreground",
                    item.level === 3 && "pl-3 text-[13px]",
                    activeId === item.id && "font-medium text-[var(--swift-orange)]"
                  )}
                  onClick={(event) => {
                    event.preventDefault();
                    document.getElementById(item.id)?.scrollIntoView({ behavior: "smooth" });
                    setActiveId(item.id);
                    history.replaceState(null, "", `#${item.id}`);
                  }}
                >
                  {item.text}
                </a>
              </li>
            ))}
          </ul>
        </ScrollArea>
      </nav>
    </aside>
  );
}

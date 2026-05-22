"use client";

import * as React from "react";
import Link from "next/link";
import { Menu } from "lucide-react";
import { usePathname } from "next/navigation";
import { DocsSearch } from "@/components/docs/docs-search";
import { DocsSidebar } from "@/components/docs/docs-sidebar";
import { SwiftyLogo } from "@/components/docs/swifty-logo";
import { ThemeToggle } from "@/components/theme/theme-toggle";
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

const GitHubIcon = () => (
  <svg viewBox="0 0 24 24" className="h-4 w-4" fill="currentColor" aria-hidden>
    <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
  </svg>
);

export function DocsShell({ children, stars }: { children: React.ReactNode; stars?: number | null }) {
  const pathname = usePathname();
  const [open, setOpen] = React.useState(false);

  return (
    <div className={cn("min-h-dvh bg-background", pagePaddingX)}>
      <div className={cn("flex min-h-dvh flex-col border-x", gridBorder)}>
        <header
          className={cn(
            "sticky top-0 z-40 shrink-0 border-b bg-background/90 backdrop-blur",
            gridBorder
          )}
        >
          <div className={cn("flex h-14 items-center gap-2 sm:gap-3", sectionPaddingX)}>
            <Sheet open={open} onOpenChange={setOpen}>
              <SheetTrigger
                render={
                  <Button
                    variant="ghost"
                    size="icon"
                    className="lg:hidden"
                    aria-label="Open navigation"
                  />
                }
              >
                <Menu className="h-5 w-5" />
              </SheetTrigger>
              <SheetContent side="left" className="w-80 p-0">
                <SheetHeader className="border-b px-4 py-3 text-left">
                  <SheetTitle>
                    <SwiftyLogo />
                  </SheetTitle>
                </SheetHeader>
                <DocsSidebar pathname={pathname} onNavigate={() => setOpen(false)} />
              </SheetContent>
            </Sheet>

            <Link href="/docs" className="min-w-0 shrink-0 [&_span]:hidden sm:[&_span]:inline">
              <SwiftyLogo />
            </Link>

            <div className="ml-auto flex items-center gap-2">
              <DocsSearch />
              <a
                href="https://github.com/Kartikayy007/SwiftyAI"
                target="_blank"
                rel="noreferrer"
                aria-label="GitHub"
                className="inline-flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-xs font-medium text-muted-foreground ring-1 ring-border hover:bg-muted hover:text-foreground transition-colors"
              >
                <GitHubIcon />
                {stars != null && (
                  <span className="flex items-center gap-1">
                    <svg viewBox="0 0 16 16" className="h-3 w-3 fill-current" aria-hidden>
                      <path d="M8 .25a.75.75 0 0 1 .673.418l1.882 3.815 4.21.612a.75.75 0 0 1 .416 1.279l-3.046 2.97.719 4.192a.751.751 0 0 1-1.088.791L8 12.347l-3.766 1.98a.75.75 0 0 1-1.088-.79l.72-4.194L.818 6.374a.75.75 0 0 1 .416-1.28l4.21-.611L7.327.668A.75.75 0 0 1 8 .25Z" />
                    </svg>
                    {stars >= 1000 ? `${(stars / 1000).toFixed(1)}k` : stars}
                  </span>
                )}
              </a>
              <ThemeToggle />
            </div>
          </div>
        </header>

        <div className="flex min-h-0 flex-1">
          <aside
            className={cn(
              "sticky top-14 hidden h-[calc(100vh-3.5rem)] w-[280px] shrink-0 border-r lg:block",
              gridBorder
            )}
          >
            <DocsSidebar pathname={pathname} />
          </aside>

          <div className="min-w-0 flex-1">{children}</div>
        </div>

        {/* <footer
          className={cn(
            "shrink-0 border-t py-8 text-sm text-muted-foreground",
            gridBorder,
            sectionPaddingX
          )}
        >
          <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <p>SwiftyAI documentation.</p>
            <p>Built with Next.js, shadcn, and Swift-orange accents.</p>
          </div>
        </footer> */}
      </div>
    </div>
  );
}

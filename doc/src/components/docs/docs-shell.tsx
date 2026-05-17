"use client";

import * as React from "react";
import Link from "next/link";
import { GitBranch, Menu } from "lucide-react";
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

export function DocsShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [open, setOpen] = React.useState(false);

  return (
    <div className={cn("min-h-screen bg-background", pagePaddingX)}>
      <div className={cn("flex min-h-screen flex-col border-x", gridBorder)}>
        <header
          className={cn(
            "sticky top-0 z-40 shrink-0 border-b bg-background/90 backdrop-blur",
            gridBorder
          )}
        >
          <div className={cn("flex h-14 items-center gap-3", sectionPaddingX)}>
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

            <Link href="/docs" className="shrink-0">
              <SwiftyLogo />
            </Link>

            <div className="ml-auto flex items-center gap-2">
              <DocsSearch />
              <Button
                variant="ghost"
                size="icon"
                nativeButton={false}
                aria-label="GitHub"
                render={
                  <a
                    href="https://github.com/Kartikayy007/SwiftyAI"
                    target="_blank"
                    rel="noreferrer"
                  />
                }
              >
                <GitBranch className="h-4 w-4" />
              </Button>
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

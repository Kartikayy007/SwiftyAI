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
import { Separator } from "@/components/ui/separator";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";

export function DocsShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [open, setOpen] = React.useState(false);

  return (
    <div className="min-h-screen bg-background">
      <header className="sticky top-0 z-40 border-b bg-background/90 backdrop-blur">
        <div className="mx-auto flex h-14 max-w-[1500px] items-center gap-3 px-4">
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
              <DocsSidebar
                pathname={pathname}
                onNavigate={() => setOpen(false)}
              />
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

      <div className="mx-auto grid max-w-[1500px] lg:grid-cols-[280px_minmax(0,1fr)]">
        <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] border-r lg:block">
          <DocsSidebar pathname={pathname} />
        </aside>

        <div className="min-w-0">{children}</div>
      </div>

      <Separator />
      <footer className="mx-auto flex max-w-[1500px] flex-col gap-3 px-4 py-8 text-sm text-muted-foreground md:flex-row md:items-center md:justify-between">
        <p>SwiftyAI documentation scaffold.</p>
        <p>Built with Next.js, shadcn, and Swift-orange accents.</p>
      </footer>
    </div>
  );
}

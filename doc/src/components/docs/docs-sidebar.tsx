"use client";

import Link from "next/link";
import { docsNavGroups } from "@/components/docs/docs-config";
import { ScrollArea } from "@/components/ui/scroll-area";
import { cn } from "@/lib/utils";

type DocsSidebarProps = {
  pathname: string;
  onNavigate?: () => void;
};

export function DocsSidebar({ pathname, onNavigate }: DocsSidebarProps) {
  return (
    <ScrollArea className="h-full">
      <nav className="space-y-6 p-4">
        {docsNavGroups.map((group) => (
          <div key={group.title} className="space-y-1">
            <p className="px-3 pb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">
              {group.title}
            </p>
            {group.items.map((item) => {
              const isActive =
                item.href === "/docs"
                  ? pathname === "/docs"
                  : pathname.startsWith(item.href);
              const Icon = item.icon;

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={onNavigate}
                  className={cn(
                    "flex items-center gap-2 rounded-md px-3 py-2 text-sm text-muted-foreground transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
                    isActive &&
                      "bg-sidebar-accent font-medium text-sidebar-accent-foreground"
                  )}
                >
                  <Icon className="h-4 w-4 text-[var(--swift-orange)]" />
                  {item.title}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>
    </ScrollArea>
  );
}

"use client";

import * as React from "react";
import Link from "next/link";
import { ChevronDown, ChevronRight } from "lucide-react";
import { docsNavGroups } from "@/components/docs/docs-config";
import { cn } from "@/lib/utils";

type DocsSidebarProps = {
  pathname: string;
  onNavigate?: () => void;
};

function isItemActive(pathname: string, href: string) {
  return href === "/docs" ? pathname === "/docs" : pathname.startsWith(href);
}

function getOpenGroups(pathname: string) {
  const open = new Set<string>();
  for (const group of docsNavGroups) {
    if (group.items.some((item) => isItemActive(pathname, item.href))) {
      open.add(group.title);
    }
  }
  if (open.size === 0) {
    open.add(docsNavGroups[0]?.title ?? "");
  }
  return open;
}

export function DocsSidebar({ pathname, onNavigate }: DocsSidebarProps) {
  const [openGroups, setOpenGroups] = React.useState<Set<string>>(() =>
    getOpenGroups(pathname)
  );

  React.useEffect(() => {
    setOpenGroups((prev) => {
      const next = new Set(prev);
      for (const group of docsNavGroups) {
        if (group.items.some((item) => isItemActive(pathname, item.href))) {
          next.add(group.title);
        }
      }
      return next;
    });
  }, [pathname]);

  const toggleGroup = (title: string) => {
    setOpenGroups((prev) => {
      const next = new Set(prev);
      if (next.has(title)) {
        next.delete(title);
      } else {
        next.add(title);
      }
      return next;
    });
  };

  return (
    <nav
      className={cn(
        "h-full overflow-y-auto py-4 pr-2 pl-4",
        "[scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
      )}
    >
      <div className="space-y-1">
        {docsNavGroups.map((group) => {
          const isOpen = openGroups.has(group.title);

          return (
            <div key={group.title} className="space-y-0.5">
              <button
                type="button"
                onClick={() => toggleGroup(group.title)}
                className="flex w-full items-center justify-between rounded-md px-3 py-2 text-left text-sm font-medium text-foreground transition-colors hover:text-foreground/80"
              >
                <span>{group.title}</span>
                {isOpen ? (
                  <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground" />
                ) : (
                  <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground" />
                )}
              </button>

              {isOpen ? (
                <div className="space-y-0.5 pb-1">
                  {group.items.map((item) => {
                    const isActive = isItemActive(pathname, item.href);

                    return (
                      <Link
                        key={item.href}
                        href={item.href}
                        onClick={onNavigate}
                        className={cn(
                          "block rounded-md px-3 py-1.5 text-sm transition-colors",
                          isActive
                            ? "font-medium text-foreground"
                            : "text-muted-foreground hover:text-foreground"
                        )}
                      >
                        {item.title}
                      </Link>
                    );
                  })}
                </div>
              ) : null}
            </div>
          );
        })}
      </div>
    </nav>
  );
}

# SwiftyAI Docs

This is the Next.js documentation site for the SwiftyAI package.

## Development

Run the docs app from this directory:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in the browser.

## Source Layout

Canonical docs pages live under `src/app/docs`. The home page lives at `src/app/page.tsx`, and docs navigation is configured in `src/components/docs/docs-config.ts`.

Generated build output under `.next` and dependencies under `node_modules` are not source docs.

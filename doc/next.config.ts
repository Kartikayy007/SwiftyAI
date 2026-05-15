import createMDX from "@next/mdx";
import type { NextConfig } from "next";
import rehypePrettyCode from "rehype-pretty-code";

const nextConfig: NextConfig = {
  pageExtensions: ["js", "jsx", "md", "mdx", "ts", "tsx"],
};

const withMDX = createMDX({
  extension: /\.(md|mdx)$/,
  options: {
    rehypePlugins: [
      [
        rehypePrettyCode,
        {
          keepBackground: false,
          theme: {
            light: "github-light",
            dark: "github-dark",
          },
        },
      ],
    ],
  },
});

export default withMDX(nextConfig);

import { createSerwistRoute } from "@serwist/turbopack";

const revision = process.env.NEXT_PUBLIC_GIT_COMMIT ?? crypto.randomUUID();

export const { dynamic, dynamicParams, revalidate, generateStaticParams, GET } = createSerwistRoute(
  {
    additionalPrecacheEntries: [{ revision, url: "/offline" }],
    nextConfig: {},
    swSrc: "src/app/sw.ts",
  }
);

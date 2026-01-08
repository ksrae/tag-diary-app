import { useSyncExternalStore } from "react";

// biome-ignore lint/suspicious/noEmptyBlockStatements: noop function for subscribe
const emptySubscribe = () => () => {};

export function useIsClient() {
  return useSyncExternalStore(
    emptySubscribe,
    () => true,
    () => false
  );
}

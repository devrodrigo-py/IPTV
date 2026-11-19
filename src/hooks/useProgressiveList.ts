import { useCallback, useEffect, useRef, useState } from 'react';

/**
 * Renders a long list in pages. Rendering 20k+ cards at once freezes a TV
 * stick; this renders `pageSize` items and adds more as the end of the list
 * scrolls into view (which D-pad navigation does as focus moves down).
 *
 * Unlike strict windowing, items already rendered stay in the DOM, so the
 * spatial navigation in TvRemoteOverlay always finds the neighbouring card.
 */
export function useProgressiveList<T>(items: T[], pageSize = 60) {
  const [count, setCount] = useState(pageSize);
  const observerRef = useRef<IntersectionObserver | null>(null);

  // Start again from the first page when the list itself changes (new filter, category…).
  useEffect(() => {
    setCount(pageSize);
  }, [items, pageSize]);

  const sentinelRef = useCallback(
    (node: HTMLElement | null) => {
      observerRef.current?.disconnect();
      if (!node || typeof IntersectionObserver === 'undefined') return;
      observerRef.current = new IntersectionObserver(
        (entries) => {
          if (entries.some((e) => e.isIntersecting)) {
            setCount((c) => (c < items.length ? c + pageSize : c));
          }
        },
        // Load the next page well before the user reaches the end.
        { root: null, rootMargin: '800px 0px' }
      );
      observerRef.current.observe(node);
    },
    [items.length, pageSize]
  );

  useEffect(() => () => observerRef.current?.disconnect(), []);

  return {
    visible: items.length > count ? items.slice(0, count) : items,
    hasMore: items.length > count,
    sentinelRef,
    total: items.length,
  };
}

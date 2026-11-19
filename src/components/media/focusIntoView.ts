/**
 * Brings a focused card into view. Inside the TV Home rows area
 * ([data-rows]) the whole row, title included, is aligned to the top so the
 * shelf you are browsing is always fully visible, as in streaming apps.
 */
export function focusIntoView(el: HTMLElement): void {
  const rows = el.closest<HTMLElement>('[data-rows]');
  const section = el.closest<HTMLElement>('section');
  if (rows && section) {
    const top = section.offsetTop - 4;
    if (Math.abs(rows.scrollTop - top) > 2) rows.scrollTo({ top, behavior: 'smooth' });
    // Horizontal: keep the card inside its shelf without touching the page.
    const shelf = el.closest<HTMLElement>('[data-shelf]');
    if (shelf) {
      const r = el.getBoundingClientRect();
      const s = shelf.getBoundingClientRect();
      if (r.right > s.right - 24) shelf.scrollBy({ left: r.right - s.right + 48, behavior: 'smooth' });
      else if (r.left < s.left + 24) shelf.scrollBy({ left: r.left - s.left - 48, behavior: 'smooth' });
    }
    return;
  }
  el.scrollIntoView({ block: 'nearest', inline: 'nearest' });
}

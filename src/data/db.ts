/**
 * Minimal IndexedDB key/value store for large data (channels, VOD, series,
 * EPG, progress). localStorage caps at about 5 MB, which a single real
 * provider list exceeds; IndexedDB has no such small limit.
 */

const DB_NAME = 'nebula-iptv';
const DB_VERSION = 1;
const STORE = 'kv';

let dbPromise: Promise<IDBDatabase> | null = null;

function openDb(): Promise<IDBDatabase> {
  if (dbPromise) return dbPromise;
  dbPromise = new Promise((resolve, reject) => {
    if (typeof indexedDB === 'undefined') {
      reject(new Error('IndexedDB indisponível'));
      return;
    }
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(STORE)) db.createObjectStore(STORE);
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
  dbPromise.catch(() => {
    dbPromise = null;
  });
  return dbPromise;
}

function tx<T>(mode: IDBTransactionMode, run: (store: IDBObjectStore) => IDBRequest<T> | void): Promise<T | undefined> {
  return openDb().then(
    (db) =>
      new Promise<T | undefined>((resolve, reject) => {
        const t = db.transaction(STORE, mode);
        const req = run(t.objectStore(STORE));
        t.oncomplete = () => resolve(req ? (req.result as T) : undefined);
        t.onerror = () => reject(t.error);
        t.onabort = () => reject(t.error);
      })
  );
}

export async function dbGet<T>(key: string): Promise<T | undefined> {
  return tx<T>('readonly', (s) => s.get(key) as IDBRequest<T>);
}

export async function dbSet<T>(key: string, value: T): Promise<void> {
  await tx('readwrite', (s) => {
    s.put(value, key);
  });
}

export async function dbDelete(key: string): Promise<void> {
  await tx('readwrite', (s) => {
    s.delete(key);
  });
}

/** Test helper: forget the cached connection. */
export function __resetDbForTests(): void {
  dbPromise = null;
}

/**
 * Debounced writer so rapid state changes (e.g. progress every few seconds,
 * favourites toggles) produce one write instead of many.
 */
export function createDebouncedWriter(delayMs = 400) {
  const timers = new Map<string, ReturnType<typeof setTimeout>>();
  const pending = new Map<string, unknown>();

  const flushKey = (key: string) => {
    const t = timers.get(key);
    if (t) clearTimeout(t);
    timers.delete(key);
    if (!pending.has(key)) return Promise.resolve();
    const value = pending.get(key);
    pending.delete(key);
    return dbSet(key, value).catch((e) => console.error(`Falha ao salvar ${key}:`, e));
  };

  return {
    write(key: string, value: unknown) {
      pending.set(key, value);
      const t = timers.get(key);
      if (t) clearTimeout(t);
      timers.set(key, setTimeout(() => void flushKey(key), delayMs));
    },
    flushAll(): Promise<unknown> {
      return Promise.all(Array.from(pending.keys()).map(flushKey));
    },
  };
}

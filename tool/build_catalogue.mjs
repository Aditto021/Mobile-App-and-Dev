// Builds assets/data/products.json from real Daraz Bangladesh listings.
//
//   node tool/build_catalogue.mjs            build from the saved replies
//   node tool/build_catalogue.mjs --fetch    also fetch missing searches
//
// Each shop category is filled from a few Daraz searches. The script keeps
// well-reviewed, in-stock products, drops off-topic and replica listings, and
// mixes sellers (max 3 per seller per category). Prices are in Taka; the
// rating, rating count, units sold, seller and photo are Daraz's own.
//
// Search replies are saved in the cache folder, so a rebuild never needs to
// contact Daraz again. With --fetch it asks slowly (one request every few
// seconds) and stops for good the moment Daraz asks for a bot check.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const APP = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUT = path.join(APP, 'assets', 'data', 'products.json');
const CACHE = process.env.CATALOGUE_CACHE || path.join(APP, '.catalogue-cache');
const FETCH = process.argv.includes('--fetch');
const PER_CATEGORY = 15;
const PER_SELLER = 3;
const FIRST_ID = 1001;

// App category id -> the Daraz searches that fill it. `must` / `not` drop
// off-topic results (a "laptop" search also returns laptop bags).
const ACCESSORY = /\b(case|cover|protector|tempered|holder|stand|skin|sticker|cable|adapter|replacement|spare|parts?|strap)\b/i;
export const CATEGORIES = {
  smartphones: {
    from: ['smartphone official warranty', 'samsung galaxy', 'xiaomi redmi', 'realme'],
    must: /\d+\s*\/\s*\d+\s*gb|\d+gb|smartphone|official warranty/i,
    not: /\b(case|cover|protector|tempered|holder|stand|cable|adapter|mic|microphone|recording|pad|tab)\b|xpad/i,
  },
  laptops: {
    from: ['laptop', 'hp laptop', 'lenovo laptop', 'asus laptop'],
    must: /laptop|notebook|macbook|vivobook|ideapad|thinkpad|probook|elitebook|inspiron|vostro|aspire|chromebook|zenbook|prelude/i,
    not: /\b(bag|backpack|sleeve|cooling|cooler|pad|keyboard|charger|adapter|battery|table|desk|stand|skin|sticker|protector|toy|mouse|walpad)\b/i,
    maxPrice: 300000,
  },
  'mobile-accessories': {
    from: ['earbuds', 'power bank', 'fast charger', 'neckband'],
    not: /\b(case|cover|silicone|strap|sticker|holder only)\b|air\s*pods?|i\s*#\s*phone/i,
  },
  tablets: {
    from: ['tablet', 'samsung galaxy tab', 'xiaomi pad', 'kids tablet'],
    // A real tablet names its memory or screen size.
    must: /(\btab\b|tablet|\bpad\b|ipad|matepad).*(\d+\s*gb|\d+(\.\d+)?\s*(inch|"))|(\d+\s*gb|\d+(\.\d+)?\s*(inch|")).*(\btab\b|tablet|\bpad\b)/i,
    not: /writing|drawing|lcd|graphic|keyboard|mouse|\bpen\b|stylus|vitamin|\bjar\b|capsule|\d+\s*tablets|\b(case|cover|protector|glass|stand|holder|sleeve|bag|film)\b/i,
  },
  'mens-watches': {
    from: ['naviforce watch', 'men watch', 'casio watch'],
    must: /watch/i,
    not: /smart|strap|band only|\bbox\b|women|ladies|girls/i,
  },
  smartwatches: {
    from: ['smart watch', 'smartwatch calling', 'kieslect smart watch'],
    must: /smart\s*watch|smartwatch|\bsmart\b/i,
    not: /\b(strap|protector|case|charger|cable|film|glass)\b/i,
  },
  fragrances: { from: ['attar', 'perfume for men', 'body spray', 'perfume for women'], not: /bottle only|empty|dispenser|car\b/i },
  beauty: { from: ['lipstick', 'foundation makeup', 'kajal', 'nail polish'], not: /brush only|organizer|box|remover/i },
  'skin-care': { from: ['face wash', 'sunscreen', 'moisturizer cream', 'serum'], not: /hair serum|machine|brush|towel/i },
  'mens-fashion': {
    from: ['panjabi for men', 'polo shirt men', 'formal shirt men', 'lungi'],
    not: /women|ladies|girls|\bkids\b|baby/i,
  },
  'womens-fashion': { from: ['saree', 'three piece', 'kurti', 'hijab'], not: /\bmen\b|\bmens\b|boys|pin only|petticoat only/i },
  'womens-bags': { from: ['ladies bag', 'vanity bag', 'ladies purse', 'tote bag'], not: /\bmen\b|\bmens\b|laptop|school|organizer/i },
  'womens-jewellery': { from: ['jewellery set', 'nose pin', 'bracelet for women', 'earrings'], not: /\bmen\b|\bmens\b|box|organizer|stand/i },
  'mens-shoes': { from: ['sneakers for men'], must: /shoe|sneaker|loafer|boot|keds/i, not: /women|ladies|girls|lace only|insole|cleaner/i },
};
// Replicas, and listings that borrow a big brand's name.
const JUNK = /replica|master copy|1st copy|first copy|duplicate|dummy|fake|inspired by|cc,\s*sio|under armour|nike watch|casio casual watch/i;
// A famous brand on a listing whose title never names it is a red flag.
const FAMOUS = /^(casio|nike|apple|adidas|rolex|puma)$/i;

// Daraz often leaves the brand blank; recognise well-known ones from the title.
const BRANDS = ['Samsung', 'Xiaomi', 'Redmi', 'realme', 'TECNO', 'Infinix', 'Honor', 'Walton', 'Symphony', 'Oppo',
  'Vivo', 'HP', 'Lenovo', 'ASUS', 'Apple', 'Dell', 'Acer', 'MSI', 'Hoco', 'Joyroom', 'Oraimo', 'Baseus', 'Anker',
  'Ugreen', 'QCY', 'Teton', 'Naviforce', 'Poedagar', 'Olevs', 'Casio', 'Timack', 'Kieslect', 'Park Avenue',
  'Wild Stone', 'Jaara', 'Lakme', 'Sunisa', 'Kakashow', 'Beauty Glazed', 'Himalaya', "Pond's", 'Laikou', 'ROREC',
  'Rajkonna', 'Skin Cafe', 'SMUG', 'Black Shark', 'Fire HD'];
const brandFrom = (title) => {
  const t = title.toLowerCase().replace(/’/g, "'").replace(/^\[[^\]]*\]\s*/, '');
  const b = BRANDS.find((x) => t.startsWith(`${x.toLowerCase()} `) || t.startsWith(`${x.toLowerCase()}-`));
  if (b === 'Redmi') return 'Xiaomi';
  if (b === 'Fire HD') return 'Amazon';
  return b ?? null;
};

const HEADERS = {
  'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
  accept: 'application/json',
  'accept-language': 'en-US,en;q=0.9',
  referer: 'https://www.daraz.com.bd/',
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
fs.mkdirSync(CACHE, { recursive: true });

// --------------------------------------------------------------- fetching --
let stopped = !FETCH;
let last = 0;

/** A saved reply, or (with --fetch) a slow, polite request for it. */
async function get(url) {
  const file = path.join(CACHE, `search-${Buffer.from(url).toString('base64url').slice(-120)}.txt`);
  if (fs.existsSync(file)) return fs.readFileSync(file, 'utf8');
  if (stopped) return null;
  const wait = 6000 - (Date.now() - last);
  if (wait > 0) await sleep(wait);
  last = Date.now();
  try {
    const r = await fetch(url, { headers: HEADERS });
    const t = await r.text();
    if (r.ok && !/punish|x5secdata|slide to verify/i.test(t.slice(0, 3000))) {
      fs.writeFileSync(file, t);
      return t;
    }
  } catch {}
  // Daraz wants a human check: respect it and use what is already saved.
  stopped = true;
  console.warn('  Daraz asked for a bot check, so no more requests will be made.');
  return null;
}

// ---------------------------------------------------------------- helpers --
const ENTITIES = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', '#39': "'" };
const decode = (s) =>
  String(s ?? '')
    .replace(/&(#x?[0-9a-f]+|\w+);/gi, (m, e) => {
      if (e[0] === '#') {
        const hex = e[1] === 'x';
        return String.fromCodePoint(parseInt(e.slice(hex ? 2 : 1), hex ? 16 : 10));
      }
      return ENTITIES[e.toLowerCase()] ?? m;
    })
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

/**
 * Some listings were saved with their UTF-8 read as Windows-1252, so "’"
 * shows as "â€™". Turn the characters back into bytes and re-read them.
 */
const CP1252 = '€\u0081‚ƒ„…†‡ˆ‰Š‹Œ\u008dŽ\u008f\u0090‘’“”•–—˜™š›œ\u009džŸ';
function unmangle(s) {
  if (!/â€|Ã|Â/.test(s)) return s;
  const bytes = [];
  for (const ch of s) {
    const c = ch.codePointAt(0);
    const i = CP1252.indexOf(ch);
    if (i >= 0) bytes.push(0x80 + i);
    else if (c < 256) bytes.push(c);
    else return s; // not a simple mix-up: leave it alone
  }
  const fixed = Buffer.from(bytes).toString('utf8');
  return fixed.includes('�') ? s : fixed;
}

/** Daraz titles are keyword-stuffed: keep the first clause, at most ~70 chars. */
function cleanTitle(name) {
  let t = unmangle(decode(name)).split(/\s*[|｜]\s*/)[0].trim();
  t = t.replace(/^[\s\-–,]+|[\s\-–,(]+$/g, '');
  if (t.length > 70) t = t.slice(0, 70).replace(/\s+\S*$/, '');
  // Don't end on a dangling "for", "with", "&" and so on.
  for (let i = 0; i < 3; i++) {
    t = t.replace(/[\s,;:(–-]+$/, '').replace(/\s+(for|with|and|&|of|the|to|in|by|or|a|from)$/i, '');
  }
  return t;
}

const num = (s) => {
  const n = parseFloat(String(s ?? '').replace(/,/g, ''));
  return Number.isFinite(n) ? n : 0;
};
const soldCount = (s) => {
  const m = String(s ?? '').match(/([\d.]+)\s*([kKmM]?)/);
  if (!m) return 0;
  const unit = m[2].toLowerCase();
  return Math.round(parseFloat(m[1]) * (unit === 'k' ? 1000 : unit === 'm' ? 1e6 : 1));
};
const https = (u) => (u.startsWith('//') ? `https:${u}` : u.replace(/^http:/, 'https:'));
/** Daraz's image CDN serves smaller copies with a size suffix (JPEG only). */
const sized = (u, px) => (/\.jpe?g$/i.test(u) ? `${https(u)}_${px}x${px}q80.jpg_.webp` : https(u));
const hash = (s) => [...String(s)].reduce((h, c) => (h * 31 + c.charCodeAt(0)) >>> 0, 7);

// ------------------------------------------------------------- choosing ---
async function listing(q) {
  const t = await get(`https://www.daraz.com.bd/catalog/?ajax=true&page=1&q=${encodeURIComponent(q)}`);
  if (!t) return [];
  try {
    return JSON.parse(t).mods?.listItems ?? [];
  } catch {
    return [];
  }
}

const seenIds = new Set();
const seenTitles = new Set();

async function pickCategory(cat, spec) {
  const fits = (it) => {
    const name = decode(it.name);
    const brand = decode(it.brandName);
    if (FAMOUS.test(brand) && !name.toLowerCase().includes(brand.toLowerCase())) return false;
    return !JUNK.test(name) && (!spec.must || spec.must.test(name)) && (!spec.not || !spec.not.test(name));
  };
  // One ranked list per search, then take from each in turn so a category
  // mixes, say, earbuds, power banks and chargers.
  const lists = [];
  for (const q of spec.from) {
    lists.push(
      (await listing(q))
        .filter((it) => it.itemId && it.image && num(it.price) > 0 && num(it.price) <= (spec.maxPrice ?? Infinity))
        .filter((it) => it.inStock !== false && fits(it))
        .map((it) => ({ it, reviews: num(it.review), rating: num(it.ratingScore), sold: soldCount(it.itemSoldCntShow) }))
        // Well-reviewed first, then best-selling.
        .sort((a, b) => b.reviews * 3 + b.sold - (a.reviews * 3 + a.sold)),
    );
  }
  const out = [];
  const perSeller = {};
  for (const minReviews of [3, 1, 0]) {
    for (let round = 0; out.length < PER_CATEGORY && lists.some((l) => l.length > round); round++) {
      for (const l of lists) {
        const s = l[round];
        if (!s || out.length >= PER_CATEGORY) continue;
        const { it } = s;
        const title = cleanTitle(it.name);
        const key = title.toLowerCase().replace(/[^a-z0-9ঀ-৿]+/g, ' ').trim().slice(0, 28);
        const seller = decode(it.sellerName) || '?';
        if (s.reviews < minReviews || seenIds.has(it.itemId) || seenTitles.has(key) || title.length < 6) continue;
        if ((perSeller[seller] ?? 0) >= PER_SELLER) continue;
        perSeller[seller] = (perSeller[seller] ?? 0) + 1;
        seenIds.add(it.itemId);
        seenTitles.add(key);
        out.push({ cat, title, ...s });
      }
    }
  }
  return out;
}

function toProduct(p, id) {
  const { it } = p;
  const price = Math.round(num(it.price));
  const original = Math.round(num(it.originalPrice));
  const discount = original > price ? Math.round(((original - price) / original) * 100) : 0;
  const bullets = (Array.isArray(it.description) ? it.description : [])
    // Spec lines come as "Chipset    Helio G99": make the gap a colon first.
    .map((b) => unmangle(decode(String(b).replace(/(\S)[ \t]{2,}(?=\S)/g, '$1: '))))
    .map((b) => b.replace(/^[•\-*✔✅▪●]+\s*/, '').trim())
    .filter((b, i, a) => b.length > 3 && a.indexOf(b) === i)
    .slice(0, 6)
    .map((b) => (b.length > 160 ? `${b.slice(0, 157).replace(/\s+\S*$/, '')}…` : b));
  return {
    id,
    title: p.title,
    description: bullets.length ? bullets.join('\n') : decode(it.name),
    category: p.cat,
    price,
    discount,
    rating: Math.round(p.rating * 100) / 100,
    reviewCount: p.reviews,
    sold: p.sold,
    stock: 6 + (hash(it.itemId) % 140),
    // The brand in the title beats Daraz's field, which is often "No Brand"
    // and sometimes wrong (a Walton tablet listed as "RAPOO").
    brand: brandFrom(p.title) || decode(it.brandName).replace(/^no brand$/i, '') || 'No Brand',
    seller: unmangle(decode(it.sellerName)),
    location: decode(it.location),
    thumbnail: sized(it.image, 300),
    images: [sized(it.image, 600)],
    reviews: [],
    url: https(it.itemUrl).split('?')[0],
  };
}

// ------------------------------------------------------------------ main --
const products = [];
let id = FIRST_ID;
for (const [cat, spec] of Object.entries(CATEGORIES)) {
  const got = await pickCategory(cat, spec);
  console.log(`${cat.padEnd(20)} ${String(got.length).padStart(2)}  e.g. ${got.slice(0, 2).map((g) => g.title).join(' / ')}`);
  for (const p of got) products.push(toProduct(p, id++));
}
fs.writeFileSync(OUT, `${JSON.stringify(products, null, 1)}\n`);
console.log(`Wrote ${products.length} products to ${path.relative(APP, OUT)}`);

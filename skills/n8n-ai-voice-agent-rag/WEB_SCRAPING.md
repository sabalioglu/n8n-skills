# Web Scraping for RAG Knowledge Base

Strategies for extracting high-quality content from prospect websites to build a comprehensive RAG knowledge base.

---

## Scraping Strategy Overview

### Single-Page vs Multi-Page

**Single-Page** (quickest setup):
```
HTTP Request (GET homepage) → HTML Extract → Code (clean) → Vector Store
```
- Good for: Landing pages, simple websites
- Pros: Fast, simple, low resource use
- Cons: Limited knowledge, misses key pages

**Multi-Page** (recommended):
```
HTTP Request (GET homepage) → HTML Extract (links + content)
  → Code (select important links)
  → Split In Batches (process each link)
    → HTTP Request (GET subpage)
    → HTML Extract (content)
    → Code (clean + tag with page type)
  → Merge all content
  → Vector Store
```
- Good for: Full prospect research
- Pros: Comprehensive knowledge base
- Cons: Slower, more API calls, rate limiting needed

---

## Key Pages to Scrape

Prioritize these pages for maximum prospect insight:

| Priority | Page | Why | Typical URL Patterns |
|----------|------|-----|---------------------|
| 1 | Homepage | Company overview, value proposition | `/` |
| 2 | About | Company story, team, mission | `/about`, `/about-us`, `/company` |
| 3 | Products/Services | What they sell | `/products`, `/services`, `/solutions` |
| 4 | Pricing | Business model, tiers | `/pricing`, `/plans` |
| 5 | Blog (recent) | Current focus areas | `/blog`, `/news`, `/resources` |
| 6 | Case Studies | Customer success stories | `/case-studies`, `/customers`, `/testimonials` |
| 7 | Careers | Growth signals, tech stack | `/careers`, `/jobs` |

### Link Discovery Code Node
```javascript
const items = $input.all();
const baseUrl = $('Webhook').first().json.body.url.replace(/\/$/, '');

// Extract links from HTML
const html = items[0].json.data; // raw HTML from HTTP Request
const linkRegex = /href=["']([^"']+)["']/g;
const links = new Set();
let match;

while ((match = linkRegex.exec(html)) !== null) {
  let href = match[1];

  // Convert relative to absolute
  if (href.startsWith('/')) {
    href = baseUrl + href;
  }

  // Only same-domain links
  if (href.startsWith(baseUrl)) {
    links.add(href);
  }
}

// Priority page patterns
const priorityPatterns = [
  /\/(about|company|team)/i,
  /\/(products?|services?|solutions?|features?)/i,
  /\/(pricing|plans?)/i,
  /\/(blog|news|resources?)/i,
  /\/(case.?stud|customers?|testimonials?)/i,
  /\/(careers?|jobs?)/i,
  /\/(contact|support)/i
];

const priorityLinks = [];
const otherLinks = [];

for (const link of links) {
  const path = new URL(link).pathname;
  // Skip anchors, assets, auth pages
  if (path.match(/\.(css|js|png|jpg|svg|pdf|zip)$/i)) continue;
  if (path.match(/\/(login|signup|register|admin|api)\b/i)) continue;

  const isPriority = priorityPatterns.some(p => p.test(path));
  if (isPriority) {
    priorityLinks.push(link);
  } else if (path !== '/' && path.split('/').length <= 3) {
    otherLinks.push(link);
  }
}

// Return priority pages first, limit total
const selectedLinks = [
  ...priorityLinks.slice(0, 10),
  ...otherLinks.slice(0, 5)
];

return selectedLinks.map(url => ({
  json: { url, prospect_id: $('Webhook').first().json.body.prospect_id }
}));
```

---

## HTML Content Extraction

### HTML Extract Node Configuration

**Best selectors for content areas**:
```javascript
{
  extractionValues: [
    // Page title
    {
      key: "title",
      cssSelector: "title",
      returnValue: "text"
    },
    // Meta description (often a good summary)
    {
      key: "description",
      cssSelector: "meta[name='description']",
      returnValue: "attribute",
      attribute: "content"
    },
    // Open Graph description (sometimes better)
    {
      key: "ogDescription",
      cssSelector: "meta[property='og:description']",
      returnValue: "attribute",
      attribute: "content"
    },
    // Main content (try multiple selectors)
    {
      key: "mainContent",
      cssSelector: "main, article, [role='main'], .main-content, #main-content",
      returnValue: "text"
    },
    // Headings for structure
    {
      key: "headings",
      cssSelector: "h1, h2, h3",
      returnValue: "text"
    },
    // Fallback: body content
    {
      key: "bodyText",
      cssSelector: "body",
      returnValue: "text"
    }
  ]
}
```

### Content Cleaning Code Node

```javascript
const items = $input.all();
const results = [];

for (const item of items) {
  const data = item.json;

  // Prefer main content over body (less noise)
  let content = data.mainContent || data.bodyText || '';

  // Clean up
  content = content
    // Normalize whitespace
    .replace(/[\t ]+/g, ' ')
    // Collapse multiple newlines
    .replace(/\n{3,}/g, '\n\n')
    // Remove common boilerplate patterns
    .replace(/cookie\s*(policy|consent|notice)[\s\S]{0,200}/gi, '')
    .replace(/©\s*\d{4}[\s\S]{0,100}$/gi, '')
    .replace(/(accept|reject)\s*(all\s*)?cookies/gi, '')
    .replace(/subscribe\s*to\s*(our\s*)?(newsletter|updates)/gi, '')
    // Trim
    .trim();

  // Skip if too little content (nav-only pages, redirects)
  if (content.length < 100) continue;

  // Truncate very long pages
  if (content.length > 30000) {
    content = content.substring(0, 30000) + '\n[Content truncated]';
  }

  // Build structured text for embedding
  const title = (data.title || '').trim();
  const description = (data.description || data.ogDescription || '').trim();

  const structuredText = [
    title ? `Page: ${title}` : null,
    description ? `Summary: ${description}` : null,
    '',
    content
  ].filter(s => s !== null).join('\n');

  results.push({
    json: {
      text: structuredText,
      metadata: {
        source_url: data.url || item.json.url,
        prospect_id: item.json.prospect_id || $('Webhook').first().json.body.prospect_id,
        page_title: title,
        scraped_at: new Date().toISOString(),
        content_length: content.length,
        content_type: 'website_page'
      }
    }
  });
}

// Handle case where all pages were too short
if (results.length === 0) {
  results.push({
    json: {
      text: 'No substantial content could be extracted from this website.',
      metadata: {
        prospect_id: $('Webhook').first().json.body.prospect_id,
        scraped_at: new Date().toISOString(),
        content_type: 'error'
      }
    }
  });
}

return results;
```

---

## Advanced Scraping Techniques

### JavaScript-Rendered Pages (SPAs)

Some websites render content with JavaScript. The basic HTTP Request won't see this content.

**Solution 1: Use a headless browser service**
```javascript
// HTTP Request to a browser rendering API
{
  method: "POST",
  url: "https://api.browserless.io/content",
  body: {
    url: targetUrl,
    waitFor: 3000  // Wait for JS to render
  },
  authentication: "genericCredentialType",
  // Credential: Browserless.io API key
}
```

**Solution 2: Check for API endpoints**
Many SPAs load data from APIs. Look for `/api/` endpoints in the page source and fetch data directly.

### Handling Rate Limits

```
Split In Batches (batch size: 3)
  → HTTP Request (fetch page)
  → HTML Extract
  → Wait (1500ms)  // Rate limit delay
  → Loop back
```

### Handling Authentication Walls
- Skip pages that return 401/403
- Use `continueOnFail` setting on HTTP Request nodes
- Log failures for manual review

```javascript
// Code node - filter out failed fetches
const items = $input.all();
return items.filter(item => {
  const statusCode = item.json.statusCode || 200;
  return statusCode >= 200 && statusCode < 400;
});
```

---

## Content Quality Checks

### Minimum Content Validation
```javascript
// Code node after extraction
const items = $input.all();
const valid = [];
const invalid = [];

for (const item of items) {
  const text = item.json.text || '';
  const wordCount = text.split(/\s+/).length;

  if (wordCount < 30) {
    invalid.push({
      json: {
        url: item.json.metadata?.source_url,
        reason: 'Too short',
        wordCount
      }
    });
  } else {
    valid.push(item);
  }
}

// Output 1: valid content → Vector Store
// Output 2: invalid content → logging
return [valid, invalid];
```

### Duplicate Detection
```javascript
// Code node - deduplicate similar content
const items = $input.all();
const seen = new Set();
const unique = [];

for (const item of items) {
  // Simple fingerprint: first 200 chars normalized
  const fingerprint = (item.json.text || '')
    .substring(0, 200)
    .toLowerCase()
    .replace(/\s+/g, ' ');

  if (!seen.has(fingerprint)) {
    seen.add(fingerprint);
    unique.push(item);
  }
}

return unique;
```

---

## Sitemap-Based Scraping (Alternative)

Instead of crawling links, use the sitemap for comprehensive coverage:

```javascript
// Code node - parse sitemap XML
const sitemapXml = $input.first().json.data;

// Simple regex-based URL extraction from sitemap
const urlRegex = /<loc>(.*?)<\/loc>/g;
const urls = [];
let match;

while ((match = urlRegex.exec(sitemapXml)) !== null) {
  urls.push(match[1]);
}

// Filter to priority pages only
const priorityPatterns = [
  /\/(about|company|team)/i,
  /\/(products?|services?|solutions?|features?)/i,
  /\/(pricing|plans?)/i
];

const filtered = urls.filter(url =>
  url.endsWith('/') || // Top-level pages
  priorityPatterns.some(p => p.test(url))
).slice(0, 20); // Max 20 pages

return filtered.map(url => ({ json: { url } }));
```

**Workflow**:
```
HTTP Request (GET /sitemap.xml)
  → Code (parse URLs)
  → Split In Batches
    → HTTP Request (fetch each page)
    → HTML Extract
    → Wait (rate limit)
  → Merge → Vector Store
```

---

## Error Handling

### Common Scraping Failures

| Error | Cause | Solution |
|-------|-------|----------|
| 403 Forbidden | Bot protection | Add User-Agent header, use browser service |
| 429 Too Many Requests | Rate limited | Add Wait nodes, reduce batch size |
| Timeout | Slow server | Increase timeout to 30s, retry once |
| Empty content | JS-rendered SPA | Use headless browser API |
| Encoding issues | Non-UTF8 pages | Force UTF-8 in HTTP Request options |

### Resilient HTTP Request Configuration
```javascript
{
  method: "GET",
  url: "={{ $json.url }}",
  options: {
    timeout: 30000,
    redirect: {
      followRedirects: true,
      maxRedirects: 3
    }
  },
  sendHeaders: true,
  headerParameters: {
    "User-Agent": "Mozilla/5.0 (compatible; n8n-bot/1.0)",
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "en-US,en;q=0.9"
  }
}
```

---

## Summary

**Key Points**:
1. **Multi-page scraping** gives much better RAG results than single-page
2. **Priority pages** (about, products, pricing) contain the most useful prospect info
3. **Content cleaning** is critical - remove boilerplate, nav, footers
4. **Rate limiting** with Wait nodes prevents getting blocked
5. **Quality checks** filter out empty/duplicate content before embedding

**Recommended Flow**:
```
Webhook → Fetch Homepage → Extract Links → Filter Priority Pages
  → Batch Fetch → Extract Content → Clean → Quality Check
  → Text Splitter → Embeddings → Vector Store
```

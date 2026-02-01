# RAG Setup Guide

Complete guide for setting up Retrieval-Augmented Generation (RAG) in n8n using vector stores, embeddings, and text splitters.

---

## RAG Architecture in n8n

### How RAG Works

```
Ingestion (one-time per document):
  Document → Split into Chunks → Generate Embeddings → Store in Vector DB

Retrieval (per query):
  User Query → Generate Query Embedding → Find Similar Chunks → Return Context

Generation (per query):
  Context Chunks + User Query → LLM → Informed Response
```

### n8n RAG Components

| Component | n8n Node | AI Connection Type |
|-----------|----------|-------------------|
| Text Splitter | Token Splitter / Character Splitter / Recursive Splitter | ai_textSplitter |
| Embeddings | OpenAI Embeddings / Cohere Embeddings / HuggingFace | ai_embedding |
| Vector Store | Pinecone / Qdrant / Supabase / In-Memory | ai_vectorStore |
| Document Loader | Default Data Loader | ai_document |
| Retrieval Tool | Vector Store Tool | ai_tool |

---

## Text Splitting Strategies

### Why Split Text?

- LLMs have context limits - chunks must fit within them
- Embeddings work better on focused, coherent text segments
- Retrieval is more precise with smaller, specific chunks

### Splitter Comparison

| Splitter | Best For | Chunk Size | nodeType |
|----------|----------|------------|----------|
| Token Splitter | General text | 200-500 tokens | `@n8n/n8n-nodes-langchain.textSplitterTokenSplitter` |
| Character Splitter | Fixed-length chunks | 500-2000 chars | `@n8n/n8n-nodes-langchain.textSplitterCharacterTextSplitter` |
| Recursive Splitter | Structured text (markdown, code) | 500-1500 chars | `@n8n/n8n-nodes-langchain.textSplitterRecursiveCharacterTextSplitter` |

### Recommended Configuration for Website Content

**Token Splitter** (recommended for prospect websites):
```javascript
{
  chunkSize: 400,       // 400 tokens per chunk
  chunkOverlap: 50      // 50 token overlap
}
```

**Why these values?**
- **400 tokens**: Large enough for a coherent paragraph, small enough for precise retrieval
- **50 overlap**: Prevents losing context at chunk boundaries
- Website content is usually semi-structured prose - token splitter handles this well

### Chunk Size Trade-offs

| Size | Pros | Cons |
|------|------|------|
| Small (100-200) | Very precise retrieval | May lose context |
| Medium (300-500) | Good balance | Standard choice |
| Large (500-1000) | Full context preserved | Less precise, uses more tokens |

**For voice agents**: Use medium chunks (300-500 tokens). Voice responses need focused, relevant context without overwhelming the LLM.

---

## Embedding Models

### Available in n8n

| Model | Dimensions | Speed | Quality | Cost |
|-------|-----------|-------|---------|------|
| OpenAI text-embedding-3-small | 1536 | Fast | Good | $0.02/1M tokens |
| OpenAI text-embedding-3-large | 3072 | Medium | Best | $0.13/1M tokens |
| OpenAI text-embedding-ada-002 | 1536 | Fast | Good | $0.10/1M tokens |
| Cohere embed-english-v3.0 | 1024 | Fast | Good | $0.10/1M tokens |
| HuggingFace (various) | Varies | Varies | Varies | Free (self-hosted) |

### Recommended for Voice Agent RAG

**OpenAI text-embedding-3-small**:
- Best price-performance ratio
- Fast enough for real-time retrieval
- Good quality for website content

```javascript
// Embeddings OpenAI configuration
{
  model: "text-embedding-3-small"
  // Requires: OpenAI API credential
}
```

### Critical Rule: Embedding Consistency

```
⚠️ MUST use the SAME embedding model for BOTH ingestion AND retrieval

❌ Ingest with text-embedding-3-small → Retrieve with ada-002
   Result: Completely wrong search results (different vector spaces)

✅ Ingest with text-embedding-3-small → Retrieve with text-embedding-3-small
   Result: Accurate semantic search
```

---

## Vector Store Options

### Comparison for Prospect RAG

| Store | Free Tier | Managed | Metadata Filter | Best For |
|-------|-----------|---------|-----------------|----------|
| **Supabase** (pgvector) | Yes (500MB) | Yes | Yes | Getting started, existing Supabase users |
| **Pinecone** | Yes (1 index) | Yes | Yes (namespaces) | Production, multi-tenant |
| **Qdrant** | Yes (1GB cloud) | Cloud + self-host | Yes | Self-hosted, privacy |
| **In-Memory** | N/A | N/A | No | Testing only |

### Supabase Setup (Recommended for Getting Started)

**1. Enable pgvector extension** (in Supabase SQL editor):
```sql
-- Enable the vector extension
create extension if not exists vector;

-- Create the documents table
create table documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(1536)  -- Match your embedding dimensions
);

-- Create similarity search function
create or replace function match_documents (
  query_embedding vector(1536),
  match_count int default 5,
  filter jsonb default '{}'
)
returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    documents.id,
    documents.content,
    documents.metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where documents.metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- Create index for faster searches
create index on documents using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);
```

**2. n8n Supabase Vector Store configuration**:

**Insert mode** (ingestion workflow):
```javascript
{
  mode: "insert",
  tableName: "documents",
  // Connected AI nodes:
  // - Embeddings OpenAI (ai_embedding)
  // - Token Text Splitter (ai_textSplitter)
}
```

**Retrieve mode** (voice agent workflow):
```javascript
{
  mode: "retrieve",
  tableName: "documents",
  queryName: "match_documents",  // The function we created
  topK: 5,
  // Connected: Embeddings OpenAI (ai_embedding)
  // Optional: metadata filter for prospect_id
}
```

### Pinecone Setup

**1. Create index** (in Pinecone console):
- Name: `prospects`
- Dimensions: 1536 (for text-embedding-3-small)
- Metric: cosine

**2. n8n configuration**:

**Insert mode**:
```javascript
{
  mode: "insert",
  pineconeIndex: "prospects",
  pineconeNamespace: "={{ $json.metadata.prospect_id }}",
  // Namespace per prospect = data isolation
}
```

**Retrieve mode**:
```javascript
{
  mode: "retrieve",
  pineconeIndex: "prospects",
  pineconeNamespace: "={{ $json.body.prospect_id }}",
  topK: 5
}
```

**Advantage**: Namespaces provide natural prospect data isolation.

### Qdrant Setup

**1. Create collection** (via API or Qdrant console):
```bash
curl -X PUT 'http://localhost:6333/collections/prospects' \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 1536,
      "distance": "Cosine"
    }
  }'
```

**2. n8n configuration**:

**Insert mode**:
```javascript
{
  mode: "insert",
  qdrantCollection: "prospects"
}
```

**Retrieve mode**:
```javascript
{
  mode: "retrieve",
  qdrantCollection: "prospects",
  topK: 5
}
```

---

## Prospect Data Isolation

### Why Isolate?

When handling multiple prospects, you must ensure that:
- Prospect A's data doesn't appear in Prospect B's conversations
- Each voice call only retrieves relevant prospect info
- Cleanup/re-ingestion affects only one prospect

### Isolation Strategies

#### Strategy 1: Namespace (Pinecone)
```javascript
// Ingestion: store in prospect-specific namespace
{ pineconeNamespace: "={{ $json.metadata.prospect_id }}" }

// Retrieval: query only that prospect's namespace
{ pineconeNamespace: "={{ $json.body.prospect_id }}" }
```
**Pros**: Built-in isolation, easy cleanup (delete namespace)
**Cons**: Pinecone-specific

#### Strategy 2: Metadata Filtering (Supabase/Qdrant)
```javascript
// Ingestion: include prospect_id in metadata
{
  metadata: {
    prospect_id: "abc123",
    source_url: "https://prospect.com"
  }
}

// Retrieval: filter by prospect_id in the match function
// Supabase: update match_documents to accept and filter by prospect_id
```

**Supabase filter function**:
```sql
create or replace function match_documents_for_prospect (
  query_embedding vector(1536),
  p_prospect_id text,
  match_count int default 5
)
returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    documents.id,
    documents.content,
    documents.metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where documents.metadata->>'prospect_id' = p_prospect_id
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;
```

#### Strategy 3: Separate Collections (Qdrant)
```javascript
// Create collection per prospect (for large-scale deployments)
// Collection name: prospect_{prospect_id}
```
**Pros**: Complete isolation
**Cons**: Management overhead

### Recommended Approach

- **< 50 prospects**: Metadata filtering (simplest)
- **50-500 prospects**: Namespace-based (Pinecone) or metadata filtering
- **500+ prospects**: Separate collections with management automation

---

## Cleanup and Re-Ingestion

### Delete Prospect Data

**Pinecone** (delete namespace):
```javascript
// HTTP Request node
{
  method: "DELETE",
  url: "https://your-index-xyz.svc.pinecone.io/vectors/delete",
  body: {
    deleteAll: true,
    namespace: prospectId
  }
}
```

**Supabase** (delete by metadata):
```sql
DELETE FROM documents
WHERE metadata->>'prospect_id' = 'abc123';
```

### Re-Ingestion Workflow
```
1. Delete existing prospect data
2. Wait (ensure deletion propagates)
3. Run ingestion workflow with prospect URL
4. Update CRM status: "knowledge_refreshed"
```

---

## Monitoring and Debugging

### Check What's Stored
```javascript
// Code node - count chunks per prospect (Supabase)
// Use with HTTP Request to Supabase REST API
{
  method: "GET",
  url: "{{ $env.SUPABASE_URL }}/rest/v1/documents?select=id,metadata&metadata->>prospect_id=eq.abc123",
  headers: {
    apikey: "{{ $env.SUPABASE_KEY }}"
  }
}
```

### Test Retrieval Quality
```javascript
// Code node - test search manually
// Useful for debugging poor retrieval results
const testQuery = "What products does this company offer?";
// Run through embeddings → vector store retrieve
// Check: Are the returned chunks relevant?
```

### Common RAG Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| Poor results | AI gives generic answers | Check chunk size (too large?), check topK |
| Wrong prospect data | AI references wrong company | Check namespace/metadata filtering |
| Empty results | AI says "no information" | Verify ingestion completed, check vector dimensions match |
| Slow retrieval | Voice agent lags | Reduce topK, add index, use smaller embedding model |
| Stale data | AI references outdated info | Set up re-ingestion schedule |

---

## Summary

**Key Points**:
1. **Text Splitter**: Token splitter, 400 tokens, 50 overlap for website content
2. **Embeddings**: OpenAI text-embedding-3-small (best value)
3. **Vector Store**: Supabase for getting started, Pinecone for production multi-tenant
4. **Isolation**: Namespace (Pinecone) or metadata filtering (Supabase/Qdrant)
5. **Consistency**: Same embedding model for ingestion AND retrieval

**Quick Setup Checklist**:
- [ ] Choose vector store and create account
- [ ] Set up database/collection/index
- [ ] Configure n8n credentials for vector store + OpenAI
- [ ] Build ingestion workflow (insert mode)
- [ ] Build retrieval in agent workflow (retrieve mode)
- [ ] Test with sample prospect website
- [ ] Verify prospect data isolation

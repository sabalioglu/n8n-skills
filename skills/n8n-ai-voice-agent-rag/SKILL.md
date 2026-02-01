---
name: n8n-ai-voice-agent-rag
description: Build AI voice agents with RAG capabilities that scrape prospect websites, store knowledge in vector databases, and use it in real-time voice conversations. Use when building voice agents, implementing RAG pipelines, scraping websites for AI knowledge bases, or creating prospect research automation.
---

# AI Voice Agent with RAG

Build intelligent voice agents that automatically research prospects by scraping their websites, storing the knowledge in a vector database, and retrieving it during live voice conversations.

---

## Architecture Overview

This skill covers a **3-phase system**:

```
Phase 1: Knowledge Ingestion (runs on-demand or scheduled)
  Trigger → Scrape Website → Extract Text → Chunk → Embed → Store in Vector DB

Phase 2: Voice Agent (runs per call)
  Voice Platform Webhook → AI Agent (LLM + Vector Store Tool + Memory) → Voice Response

Phase 3: Prospect Management (optional)
  CRM Trigger → Fetch Prospect URL → Trigger Phase 1 → Update CRM
```

**Key Components**:
- **Web scraping**: HTTP Request + HTML extraction for prospect websites
- **RAG pipeline**: Text splitter → Embeddings → Vector store
- **Voice agent**: AI Agent with vector store retrieval tool + conversation memory
- **Voice integration**: Twilio, Vonage, Vapi, Bland.ai, or ElevenLabs webhooks

---

## Phase 1: Knowledge Ingestion Workflow

### Purpose
Scrape a prospect's website, extract meaningful content, chunk it, generate embeddings, and store in a vector database for later retrieval.

### Workflow Structure

```
1. Webhook/Manual Trigger
   - Input: { url: "https://prospect.com", prospect_id: "abc123" }

2. HTTP Request (fetch homepage)
   - GET the prospect URL
   - Return raw HTML

3. HTML Extract (extract text content)
   - Extract page title, meta description, body text
   - Strip navigation, footers, scripts

4. Code Node (clean & prepare text)
   - Remove excess whitespace
   - Combine title + description + body
   - Add metadata (source URL, prospect_id, scraped_at)

5. [Optional] HTTP Request (fetch subpages)
   - Follow key links: /about, /products, /services, /pricing
   - Repeat extraction for each page

6. Text Splitter → Embeddings → Vector Store (insert)
   - Chunk text into ~500 token segments
   - Generate embeddings via OpenAI/Cohere
   - Store in Pinecone/Qdrant/Supabase with metadata
```

### Node Configuration

#### Trigger Node
```javascript
// Webhook trigger - receives prospect URL
{
  path: "ingest-prospect",
  httpMethod: "POST",
  responseMode: "responseNode"
  // Body: { "url": "https://prospect.com", "prospect_id": "abc123" }
}
```

#### HTTP Request (Fetch Website)
```javascript
{
  method: "GET",
  url: "={{ $json.body.url }}",
  options: {
    response: {
      fullResponse: false
    },
    timeout: 15000
  }
}
```

#### HTML Extract Node
```javascript
// Extract key content areas from the HTML
{
  extractionValues: [
    {
      key: "title",
      cssSelector: "title",
      returnValue: "text"
    },
    {
      key: "metaDescription",
      cssSelector: "meta[name='description']",
      returnValue: "attribute",
      attribute: "content"
    },
    {
      key: "bodyText",
      cssSelector: "main, article, .content, #content, body",
      returnValue: "text"
    },
    {
      key: "headings",
      cssSelector: "h1, h2, h3",
      returnValue: "text"
    }
  ]
}
```

#### Code Node (Clean & Prepare)
```javascript
const items = $input.all();
const results = [];

for (const item of items) {
  const title = (item.json.title || '').trim();
  const description = (item.json.metaDescription || '').trim();
  const body = (item.json.bodyText || '')
    .replace(/\s+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim()
    .substring(0, 50000); // Limit to 50k chars

  const headings = (item.json.headings || '').trim();

  const fullText = [
    `Company: ${title}`,
    `Description: ${description}`,
    `Key Topics: ${headings}`,
    '',
    body
  ].filter(Boolean).join('\n');

  results.push({
    json: {
      text: fullText,
      metadata: {
        source_url: item.json.url || $('Webhook').first().json.body.url,
        prospect_id: $('Webhook').first().json.body.prospect_id,
        title: title,
        scraped_at: new Date().toISOString(),
        content_type: 'website'
      }
    }
  });
}

return results;
```

### RAG Storage Chain

The RAG storage uses n8n's built-in AI nodes connected via special AI ports:

```
Code Node (cleaned text)
  → Default Text Splitter (ai_textSplitter)
  → Embeddings OpenAI (ai_embedding)
  → Vector Store (ai_vectorStore) - INSERT mode
```

#### Text Splitter Configuration
```javascript
{
  chunkSize: 500,        // ~500 tokens per chunk
  chunkOverlap: 50,      // 50 token overlap between chunks
  // Splits on paragraph boundaries when possible
}
```

#### Embeddings Configuration
```javascript
{
  model: "text-embedding-3-small",  // or text-embedding-ada-002
  // Requires OpenAI API credential
}
```

#### Vector Store Configuration (Insert Mode)

**Pinecone**:
```javascript
{
  mode: "insert",
  pineconeIndex: "prospects",
  pineconeNamespace: "={{ $json.metadata.prospect_id }}",
  // Credential: Pinecone API key
}
```

**Qdrant**:
```javascript
{
  mode: "insert",
  qdrantCollection: "prospects",
  // Credential: Qdrant URL + API key
}
```

**Supabase** (pgvector):
```javascript
{
  mode: "insert",
  tableName: "documents",
  queryName: "match_documents",
  // Credential: Supabase URL + service key
}
```

For detailed configuration, see: [RAG_SETUP.md](RAG_SETUP.md)

---

## Phase 2: Voice Agent Workflow

### Purpose
Handle incoming voice calls, use the AI Agent with RAG retrieval to have informed conversations about the prospect's business.

### Workflow Structure

```
1. Webhook (voice platform callback)
   - Receives transcribed speech or call events
   - Input: { transcript: "...", call_id: "...", prospect_id: "..." }

2. AI Agent
   ├─ Language Model (ai_languageModel)
   │   OpenAI GPT-4 / Anthropic Claude
   ├─ Vector Store Tool (ai_tool)
   │   Searches prospect knowledge base
   ├─ Window Buffer Memory (ai_memory)
   │   Maintains conversation context per call
   └─ [Optional] Additional tools (ai_tool)
       CRM lookup, calendar booking, etc.

3. Code Node (format response for voice)
   - Extract agent response text
   - Format for TTS (text-to-speech)

4. HTTP Request (send to voice platform)
   - Return speech response to Twilio/Vapi/Bland.ai
```

### Voice Platform Integration

#### Option A: Vapi.ai (Recommended - Easiest)
```javascript
// Webhook receives Vapi server message
// Vapi handles STT + TTS automatically
{
  path: "vapi-agent",
  httpMethod: "POST",
  responseMode: "lastNode"
}

// Vapi sends:
// { message: { type: "function-call", functionCall: { name, parameters } } }
// or conversation transcript updates

// Response format for Vapi:
{
  results: [{
    toolCallId: "call_id",
    result: "Your response text here"
  }]
}
```

#### Option B: Bland.ai
```javascript
// Bland.ai webhook configuration
{
  path: "bland-agent",
  httpMethod: "POST",
  responseMode: "lastNode"
}

// Bland sends transcription + call context
// Response: plain text that Bland converts to speech
```

#### Option C: Twilio + ElevenLabs
```javascript
// Twilio Voice webhook
{
  path: "twilio-voice",
  httpMethod: "POST",
  responseMode: "responseNode"
}

// Twilio sends call events + transcription via <Gather>
// Response: TwiML with <Say> or <Play> for ElevenLabs audio

// Generate speech via ElevenLabs
{
  method: "POST",
  url: "https://api.elevenlabs.io/v1/text-to-speech/{{voice_id}}",
  body: { text: agentResponse, model_id: "eleven_monolingual_v1" }
}
```

For detailed voice platform setup, see: [VOICE_AGENT.md](VOICE_AGENT.md)

### AI Agent Configuration

#### System Prompt
```
You are a professional sales assistant with deep knowledge about the prospect's business.

You have access to detailed information about the prospect's company, gathered from their website. Use this knowledge to have informed, relevant conversations.

Guidelines:
- Reference specific details from the prospect's website naturally
- Be conversational and professional, not robotic
- Keep responses concise (2-3 sentences) since this is a voice call
- If you don't have specific information, acknowledge it honestly
- Focus on how your solution relates to their specific business needs
- Ask discovery questions based on what you know about their company

Available tools:
- search_prospect_knowledge: Search the prospect's website data for relevant information
- [Additional tools as configured]
```

#### Vector Store Tool Configuration
```javascript
{
  name: "search_prospect_knowledge",
  description: "Search the knowledge base for information about the prospect's company, products, services, and business details gathered from their website.",
  // Connected to Vector Store node in retrieval mode
}
```

#### Vector Store (Retrieval Mode)
```javascript
{
  mode: "retrieve",  // NOT insert
  topK: 5,           // Return top 5 matching chunks
  // Same vector store configuration as Phase 1
  // Filter by prospect_id if using namespace/metadata
}
```

#### Memory Configuration
```javascript
{
  sessionKey: "={{ $json.body.call_id }}",  // Per-call memory
  contextWindowLength: 20  // Last 20 exchanges
}
```

---

## Phase 3: Prospect Management (Optional)

### Auto-Ingest from CRM

```
1. CRM Trigger (new prospect added / URL updated)
   - HubSpot, Salesforce, or Pipedrive trigger

2. Set Node (extract prospect URL and ID)
   - Map CRM fields to ingestion format

3. HTTP Request (trigger Phase 1 ingestion)
   - POST to ingestion webhook with URL + prospect_id

4. IF Node (check ingestion success)
   - Update CRM with "knowledge_status: ready"
   - Or flag for manual review
```

### Scheduled Re-Scraping

```
1. Schedule Trigger (weekly)
2. Database Query (get all prospect URLs)
3. Split In Batches (process 10 at a time)
4. HTTP Request (trigger re-ingestion for each)
5. Wait (rate limiting between batches)
6. Log results
```

---

## Quick Start: Minimum Viable Voice Agent

For the fastest path to a working voice agent with RAG:

### Step 1: Create Ingestion Workflow
```
Nodes needed (5):
1. Webhook (trigger)
2. HTTP Request (fetch URL)
3. HTML Extract (get text)
4. Code (clean text)
5. Supabase Vector Store (insert mode)
   ├─ Default Text Splitter (ai_textSplitter)
   └─ Embeddings OpenAI (ai_embedding)
```

### Step 2: Create Voice Agent Workflow
```
Nodes needed (4):
1. Webhook (voice platform callback)
2. AI Agent
   ├─ OpenAI Chat Model (ai_languageModel)
   ├─ Vector Store Tool → Supabase Vector Store (retrieve mode)
   │   └─ Embeddings OpenAI (ai_embedding)
   └─ Window Buffer Memory (ai_memory)
3. Code (format response)
4. Respond to Webhook
```

### Step 3: Test
```
1. POST to ingestion webhook: { "url": "https://prospect.com", "prospect_id": "test1" }
2. Send test voice query: { "transcript": "Tell me about their products", "call_id": "test", "prospect_id": "test1" }
3. Verify AI response references prospect website content
```

---

## Node Discovery Reference

### Key n8n Nodes for This Pattern

| Component | Node Type | nodeType ID |
|-----------|-----------|-------------|
| Web trigger | Webhook | `nodes-base.webhook` |
| Fetch HTML | HTTP Request | `nodes-base.httpRequest` |
| Extract text | HTML Extract | `nodes-base.html` |
| Clean text | Code | `nodes-base.code` |
| AI Agent | AI Agent | `@n8n/n8n-nodes-langchain.agent` |
| OpenAI Model | OpenAI Chat Model | `@n8n/n8n-nodes-langchain.lmChatOpenAi` |
| Embeddings | Embeddings OpenAI | `@n8n/n8n-nodes-langchain.embeddingsOpenAi` |
| Text Splitter | Text Splitter | `@n8n/n8n-nodes-langchain.textSplitterTokenSplitter` |
| Vector Store (Pinecone) | Pinecone Vector Store | `@n8n/n8n-nodes-langchain.vectorStorePinecone` |
| Vector Store (Qdrant) | Qdrant Vector Store | `@n8n/n8n-nodes-langchain.vectorStoreQdrant` |
| Vector Store (Supabase) | Supabase Vector Store | `@n8n/n8n-nodes-langchain.vectorStoreSupabase` |
| Memory | Window Buffer Memory | `@n8n/n8n-nodes-langchain.memoryBufferWindow` |
| Vector Store Tool | Vector Store Tool | `@n8n/n8n-nodes-langchain.toolVectorStore` |

### MCP Tool Usage Pattern
```
search_nodes({query: "vector store"})
  → get_node_essentials({nodeType: "@n8n/n8n-nodes-langchain.vectorStorePinecone"})
  → get_node_essentials({nodeType: "@n8n/n8n-nodes-langchain.embeddingsOpenAi"})
  → n8n_create_workflow({...})
```

---

## Common Gotchas

### 1. Vector Store Mode Confusion
```
❌ Using "insert" mode in the voice agent workflow
✅ Use "insert" in ingestion, "retrieve" in agent
```
The same vector store node type is used for both, but the `mode` parameter changes behavior entirely.

### 2. Namespace/Collection Isolation
```
❌ All prospects in one namespace (cross-contamination)
✅ Use prospect_id as namespace or metadata filter
```

### 3. Voice Response Length
```
❌ Long paragraphs in voice responses (bad UX)
✅ Keep responses to 2-3 sentences for natural speech
```
Add explicit instructions in the system prompt: "Keep responses concise - 2 to 3 sentences maximum."

### 4. AI Connection Types
```
❌ Connecting Vector Store Tool to main port
✅ Connect via ai_tool port to AI Agent
```
All AI sub-nodes must use their specific AI connection types (ai_tool, ai_memory, ai_languageModel, etc.).

### 5. Embedding Model Consistency
```
❌ Using text-embedding-3-small for ingestion and ada-002 for retrieval
✅ Use the SAME embedding model for both ingestion and retrieval
```
Mismatched models produce incompatible vectors.

### 6. HTML Extraction Quality
```
❌ Extracting entire body including nav, footer, scripts
✅ Target specific content selectors: main, article, .content
```
See: [WEB_SCRAPING.md](WEB_SCRAPING.md)

---

## Security Considerations

### Web Scraping
- **Rate limiting**: Add Wait nodes between page fetches (1-2 seconds)
- **Robots.txt**: Respect site crawling rules
- **Input validation**: Validate URLs before fetching (no internal IPs)
- **Size limits**: Cap HTML size to prevent memory issues

### Vector Store
- **Access control**: Use separate API keys per environment
- **Data isolation**: Namespace by prospect_id
- **Retention**: Implement cleanup for stale prospect data

### Voice Agent
- **Authentication**: Verify webhook signatures from voice platforms
- **PII handling**: Don't store sensitive info from voice transcripts
- **Rate limiting**: Limit concurrent calls per agent
- **Prompt injection**: Sanitize transcript input before passing to AI

---

## Performance Optimization

### Ingestion Performance
- **Batch processing**: Scrape multiple pages in parallel (Split In Batches)
- **Incremental updates**: Only re-scrape changed pages (check Last-Modified header)
- **Chunk size tuning**: 300-500 tokens balances relevance and context

### Voice Agent Latency
- **Model selection**: Use GPT-4o-mini or Claude 3 Haiku for faster responses
- **Top-K tuning**: Retrieve 3-5 chunks (more = slower, fewer = less context)
- **Memory window**: 10-20 messages (larger windows slow down responses)
- **Streaming**: Use streaming responses where voice platform supports it

---

## Integration with Other Skills

**n8n Workflow Patterns** - AI Agent Workflow pattern is the foundation
**n8n MCP Tools Expert** - Find and configure AI/vector store nodes
**n8n Node Configuration** - AI connection types and property dependencies
**n8n Expression Syntax** - Access webhook data correctly (`$json.body.url`)
**n8n Validation Expert** - Validate AI workflow configurations
**n8n Code JavaScript** - Custom text cleaning and response formatting

---

## Detailed Reference Files

- **[WEB_SCRAPING.md](WEB_SCRAPING.md)** - Multi-page scraping, content extraction, cleaning strategies
- **[RAG_SETUP.md](RAG_SETUP.md)** - Vector store comparison, embedding models, chunking strategies
- **[VOICE_AGENT.md](VOICE_AGENT.md)** - Voice platform integration, TTS/STT setup, conversation flow

---

## Summary

**Key Points**:
1. **3-phase architecture**: Ingest → Store → Retrieve during voice calls
2. **Same vector store node, different modes**: Insert for ingestion, Retrieve for agent
3. **Namespace isolation**: Keep prospect data separated by prospect_id
4. **Voice-optimized responses**: Short, conversational, 2-3 sentences
5. **Consistent embeddings**: Same model for insert and retrieve

**Pattern**: Website → Extract → Chunk → Embed → Store → AI Agent (Voice) → Retrieve → Respond

**Related**:
- [WEB_SCRAPING.md](WEB_SCRAPING.md) - Website content extraction
- [RAG_SETUP.md](RAG_SETUP.md) - Vector database setup
- [VOICE_AGENT.md](VOICE_AGENT.md) - Voice platform integration
